class PhraseSrs {
  const PhraseSrs({
    required this.userId,
    required this.phraseId,
    required this.nextReviewDate,
    required this.currentIntervalDays,
    this.timesReviewed = 0,
  });

  final String userId;
  final int phraseId;
  final int nextReviewDate;
  final int currentIntervalDays;
  final int timesReviewed;

  PhraseSrs copyWith({
    String? userId,
    int? phraseId,
    int? nextReviewDate,
    int? currentIntervalDays,
    int? timesReviewed,
  }) {
    return PhraseSrs(
      userId: userId ?? this.userId,
      phraseId: phraseId ?? this.phraseId,
      nextReviewDate: nextReviewDate ?? this.nextReviewDate,
      currentIntervalDays: currentIntervalDays ?? this.currentIntervalDays,
      timesReviewed: timesReviewed ?? this.timesReviewed,
    );
  }

  Map<String, Object?> toSqlMap() {
    return {
      'userId': userId,
      'phraseId': phraseId,
      'nextReviewDate': nextReviewDate,
      'currentIntervalDays': currentIntervalDays,
      'timesReviewed': timesReviewed,
    };
  }

  factory PhraseSrs.fromSqlMap(Map<String, Object?> map) {
    return PhraseSrs(
      userId: map['userId'] as String,
      phraseId: map['phraseId'] as int,
      nextReviewDate: map['nextReviewDate'] as int,
      currentIntervalDays: map['currentIntervalDays'] as int,
      timesReviewed: map['timesReviewed'] as int? ?? 0,
    );
  }
}
