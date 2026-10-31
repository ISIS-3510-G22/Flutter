class Review {
  final String userId;
  final String userName;
  final int rating;
  final String comment;
  final DateTime createdAt;

  const Review({
    required this.userId,
    required this.userName,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'userName': userName,
    'rating': rating,
    'comment': comment,
    'createdAt': createdAt.microsecondsSinceEpoch,
  };

  factory Review.fromJson(Map<String, dynamic> json) => Review(
    userId: json['userId'] as String,
    userName: json['userName'] as String,
    rating: json['rating'] as int,
    comment: json['comment'] as String,
    createdAt: DateTime.fromMicrosecondsSinceEpoch(json['createdAt'] as int),
  );
}
