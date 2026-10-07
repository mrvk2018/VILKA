#!/usr/bin/env python3
"""
Build assets/course/ko/course.json from the same Python source as legacy.

Reads:
  - tools/python/course_content_phrases.py (copied into this repo)
  - legacy CourseContentSeeder.kt for the first 5 phrases of topics 1-14

Run from repo root:
  python tools/python/export_course_json.py
"""

from __future__ import annotations

import json
import os
import re
import sys
from pathlib import Path

SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPT_DIR.parents[1]
sys.path.insert(0, str(SCRIPT_DIR))

from course_content_phrases import EXTENSIONS_BY_TOPIC_ID, NEW_TOPIC_PHRASES  # noqa: E402

LEGACY_ROOT = Path(
    os.environ.get(
        "VILKA_LEGACY_ROOT",
        Path(r"C:\Users\user\projects\Vilka teacher"),
    )
)
SEEDER_PATH = (
    LEGACY_ROOT
    / "app/src/main/java/com/koreanimmersion/data/local/CourseContentSeeder.kt"
)
OUTPUT_PATH = REPO_ROOT / "assets/course/ko/course.json"

LEGACY_TOPICS = [
    (1, "shop", "Магазин", "Shop", 1),
    (2, "cafe", "Кафе", "Cafe", 2),
    (3, "metro", "Метро", "Subway", 3),
    (4, "bus", "Автобус", "Bus", 4),
    (5, "taxi", "Такси", "Taxi", 5),
    (6, "airport", "Аэропорт", "Airport", 6),
    (7, "train", "Ж/д вокзал", "Train station", 7),
    (8, "bus_station", "Автовокзал", "Bus terminal", 8),
    (9, "beach", "Пляж", "Beach", 9),
    (10, "park", "Парк", "Park", 10),
    (11, "aquapark", "Аквапарк", "Water park", 11),
    (12, "immigration", "Миграционная служба", "Immigration office", 12),
    (13, "greetings", "Знакомство / вежливость", "Greetings", 0),
    (14, "salon", "Парикмахерская", "Hair salon", 13),
]

NEW_TOPICS = [
    (15, "police_street", "Полиция: На улице", "Police: On the street", 14),
    (16, "police_station", "Полиция: В участке", "Police: At the station", 15),
    (17, "housing_agency", "Жилье: В агентстве", "Housing: Real estate agency", 16),
    (18, "housing_owner", "Жилье: С хозяином", "Housing: With landlord", 17),
    (19, "city_hall", "Мэрия / Администрация", "City hall / District office", 18),
    (20, "tax_office", "Налоговая инспекция", "Tax office", 19),
    (21, "telecom_shop", "Салон связи / SIM-карта", "Telecom shop / SIM card", 20),
    (22, "bank", "Банк / Открытие счета", "Bank / Open account", 21),
]

PHRASE_LINE_RE = re.compile(
    r'p\(\s*(\d+)L?\s*,\s*(\d+)L?\s*,\s*"((?:[^"\\]|\\.)*)"\s*,\s*'
    r'"((?:[^"\\]|\\.)*)"\s*,\s*"((?:[^"\\]|\\.)*)"\s*,\s*(\d+)\s*\)'
)

COURSE_VERSION = 1


def unescape_kotlin(text: str) -> str:
    return text.replace('\\"', '"').replace("\\\\", "\\")


def parse_legacy_phrases(seeder_text: str) -> dict[int, list[tuple[str, str, str, int]]]:
    by_topic: dict[int, list[tuple[str, str, str, int, int]]] = {}
    for match in PHRASE_LINE_RE.finditer(seeder_text):
        topic_id = int(match.group(2))
        ko = unescape_kotlin(match.group(3))
        ru = unescape_kotlin(match.group(4))
        en = unescape_kotlin(match.group(5))
        order = int(match.group(6))
        phrase_id = int(match.group(1))
        by_topic.setdefault(topic_id, []).append((ko, ru, en, order, phrase_id))

    result: dict[int, list[tuple[str, str, str, int]]] = {}
    for topic_id, items in by_topic.items():
        if topic_id > 14:
            continue
        items.sort(key=lambda x: x[3])
        legacy = [(ko, ru, en, order) for ko, ru, en, order, _pid in items if order <= 5]
        if len(legacy) != 5:
            raise ValueError(
                f"Topic {topic_id}: expected 5 legacy phrases (order 1-5), got {len(legacy)}"
            )
        result[topic_id] = legacy
    if len(result) != 14:
        raise ValueError(f"Expected 14 legacy topics in seeder, found {len(result)}")
    return result


def phrase_id(topic_id: int, order: int) -> int:
    return topic_id * 1000 + order


def build_course(legacy: dict[int, list[tuple[str, str, str, int]]]) -> dict:
    topics = []
    phrases = []
    for tid, key, ru, en, order in LEGACY_TOPICS + NEW_TOPICS:
        topics.append(
            {
                "id": tid,
                "key": key,
                "titleRu": ru,
                "titleEn": en,
                "order": order,
            }
        )

        built: list[tuple[str, str, str, int]] = []
        if tid <= 14:
            built.extend(legacy[tid])
            next_order = 6
            for ko, ru_t, en_t in EXTENSIONS_BY_TOPIC_ID[tid]:
                built.append((ko, ru_t, en_t, next_order))
                next_order += 1
            if next_order != 16:
                raise ValueError(f"Topic {tid}: expected 15 phrases, got {next_order - 1}")
        else:
            topic_phrases = NEW_TOPIC_PHRASES[tid]
            if len(topic_phrases) != 15:
                raise ValueError(f"New topic {tid}: need 15 phrases, got {len(topic_phrases)}")
            for index, (ko, ru_t, en_t) in enumerate(topic_phrases, start=1):
                built.append((ko, ru_t, en_t, index))

        for ko, ru_t, en_t, phrase_order in built:
            phrases.append(
                {
                    "id": phrase_id(tid, phrase_order),
                    "topicId": tid,
                    "koreanText": ko,
                    "russianTranslation": ru_t,
                    "englishTranslation": en_t,
                    "audioUrlOrPath": "",
                    "order": phrase_order,
                }
            )

    return {
        "learningLanguageCode": "ko",
        "version": COURSE_VERSION,
        "topics": topics,
        "phrases": phrases,
    }


def main() -> None:
    if not SEEDER_PATH.is_file():
        raise SystemExit(f"Legacy seeder not found: {SEEDER_PATH}")
    legacy = parse_legacy_phrases(SEEDER_PATH.read_text(encoding="utf-8"))
    course = build_course(legacy)
    OUTPUT_PATH.parent.mkdir(parents=True, exist_ok=True)
    OUTPUT_PATH.write_text(
        json.dumps(course, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
        newline="\n",
    )
    print(f"Wrote {OUTPUT_PATH.relative_to(REPO_ROOT)}")
    print(f"Topics: {len(course['topics'])}, phrases: {len(course['phrases'])}")


if __name__ == "__main__":
    main()
