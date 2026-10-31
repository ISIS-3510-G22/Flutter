enum FriendRequestStatus { pending, accepted, denied }

class FriendRequest {
  final String id;
  final String fromUserId;
  final String toUserId;
  final DateTime sentOn;
  final FriendRequestStatus status;

  const FriendRequest({
    required this.id,
    required this.fromUserId,
    required this.toUserId,
    required this.sentOn,
    this.status = FriendRequestStatus.pending,
  });
}
