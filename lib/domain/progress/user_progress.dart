import 'dart:convert';

class UserProgress {
  const UserProgress({
    required this.userId,
    this.currentTopicId,
    this.currentTopicKey,
    this.currentSubStage = 1,
    this.learnedPhraseIds = const [],
  });

  final String userId;
  final int? currentTopicId;
  final String? currentTopicKey;
  final int currentSubStage;
  final List<int> learnedPhraseIds;

  String get learnedPhraseIdsJson => encodeLearnedPhraseIds(learnedPhraseIds);

  UserProgress copyWith({
    String? userId,
    int? currentTopicId,
    String? currentTopicKey,
    int? currentSubStage,
    List<int>? learnedPhraseIds,
  }) {
    return UserProgress(
      userId: userId ?? this.userId,
      currentTopicId: currentTopicId ?? this.currentTopicId,
      currentTopicKey: currentTopicKey ?? this.currentTopicKey,
      currentSubStage: currentSubStage ?? this.currentSubStage,
      learnedPhraseIds: learnedPhraseIds ?? this.learnedPhraseIds,
    );
  }

  Map<String, Object?> toSqlMap() {
    return {
      'userId': userId,
      'currentTopicId': currentTopicId,
      'currentTopicKey': currentTopicKey,
      'currentSubStage': currentSubStage,
      'learnedPhraseIdsJson': learnedPhraseIdsJson,
    };
  }

  factory UserProgress.fromSqlMap(Map<String, Object?> map) {
    return UserProgress(
      userId: map['userId'] as String,
      currentTopicId: map['currentTopicId'] as int?,
      currentTopicKey: map['currentTopicKey'] as String?,
      currentSubStage: map['currentSubStage'] as int? ?? 1,
      learnedPhraseIds: parseLearnedPhraseIds(
        map['learnedPhraseIdsJson'] as String? ?? '[]',
      ),
    );
  }

  static String encodeLearnedPhraseIds(List<int> phraseIds) {
    if (phraseIds.isEmpty) {
      return '[]';
    }
    return '[${phraseIds.join(', ')}]';
  }

  static List<int> parseLearnedPhraseIds(String json) {
    final trimmed = json.trim();
    if (trimmed.isEmpty || trimmed == '[]') {
      return const [];
    }
    try {
      final decoded = jsonDecode(trimmed);
      if (decoded is! List<dynamic>) {
        return const [];
      }
      return [
        for (final item in decoded)
          if (item is num) item.toInt(),
      ];
    } on FormatException {
      return trimmed
          .replaceFirst('[', '')
          .replaceFirst(RegExp(r']$'), '')
          .split(',')
          .map((item) => int.tryParse(item.trim()))
          .whereType<int>()
          .toList();
    }
  }
}
