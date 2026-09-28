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
}
