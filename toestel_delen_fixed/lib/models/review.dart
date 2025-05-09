class Review {
  final String id;
  final String applianceId;
  final String reviewerId;
  final String comment;
  final double rating;
  final DateTime createdAt;

  Review({
    required this.id,
    required this.applianceId,
    required this.reviewerId,
    required this.comment,
    required this.rating,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'applianceId': applianceId,
      'reviewerId': reviewerId,
      'comment': comment,
      'rating': rating,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Review.fromMap(Map<String, dynamic> map) {
    return Review(
      id: map['id'],
      applianceId: map['applianceId'],
      reviewerId: map['reviewerId'],
      comment: map['comment'],
      rating: (map['rating'] as num).toDouble(),
      createdAt: DateTime.parse(map['createdAt']),
    );
  }
}