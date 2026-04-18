class AppFeedback {
  final int id;
  final int appointmentId;
  final int userId;
  final int rating;
  final String reviewText;
  final String sentimentLabel;  // positive | neutral | negative
  final double sentimentScore;  // VADER compound -1.0 to 1.0
  final String? createdAt;

  const AppFeedback({
    required this.id,
    required this.appointmentId,
    required this.userId,
    required this.rating,
    required this.reviewText,
    required this.sentimentLabel,
    required this.sentimentScore,
    this.createdAt,
  });

  factory AppFeedback.fromJson(Map<String, dynamic> json) => AppFeedback(
        id: json['id'] as int,
        appointmentId: json['appointment_id'] as int,
        userId: json['user_id'] as int,
        rating: json['rating'] as int,
        reviewText: json['review_text'] as String,
        sentimentLabel: json['sentiment_label'] as String,
        sentimentScore: (json['sentiment_score'] as num).toDouble(),
        createdAt: json['created_at'] as String?,
      );
}
