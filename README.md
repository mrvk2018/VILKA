# Vilka

Cross-platform Flutter app for phonetic immersion (Android + iOS).  
MVP learning language: **Korean**. The content model already has `learningLanguageCode` so Japanese/Chinese can be added later without rewriting the core.

Store / display name: **Vilka**  
Application id / bundle id: **`com.vilka.teacher`**

## Stack

Flutter, sqflite (same schema as legacy Room; Drift codegen does not resolve on Flutter 3.38), go_router, Riverpod, http, flutter_tts, speech_to_text, audio_service, just_audio.

## First run

```bash
flutter pub get
python tools/python/export_course_json.py
flutter run
```

Course JSON is generated from the same Python source as the legacy Android seeder (`tools/python/course_content_phrases.py` + phrases 1–5 from the legacy `CourseContentSeeder.kt`). Point `VILKA_LEGACY_ROOT` at the old repo if it is not at `C:\Users\user\projects\Vilka teacher`.

## API key (OpenRouter)

Do **not** commit the key. Pass it at build time:

```bash
flutter run --dart-define=OPENROUTER_API_KEY=YOUR_KEY
flutter build apk --dart-define=OPENROUTER_API_KEY=YOUR_KEY
```

Optional:

```bash
--dart-define=OPENROUTER_MODEL=openrouter/free
--dart-define=DEBUG_LLM_LOGGING=true
```

A CI APK without the key will fail LLM calls with a clear “cannot reach server / missing key” error. Keep the secret in Codemagic / GitHub Actions encrypted variables only.

See `env.example`.

## iOS without a Mac

This machine is Windows-only. iOS builds go through **Codemagic** or **GitHub Actions (macos)**, then **TestFlight** on iPhone 12.

Workflow stub comes in a later phase. Do not put signing certs or API keys in the repo.

## Devices

- Android field device: Samsung S21
- iOS TestFlight: iPhone 12

## Project layout

```
lib/
  core/       config, sqflite, providers, language codes
  data/       course JSON import + repository
  domain/     Topic/Phrase, LLM parser/prompts
  features/   Home → Topics → Phrases
  l10n/       RU/EN UI
assets/course/ko/course.json
tools/python/ export_course_json.py
```
