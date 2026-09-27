enum ActivityVisibility { private, public }

class Activity {
  final String id;
  final String name;
  final String address;
  final double expectedPrice;
  final String notes;
  final List<String> tags;
  final ActivityVisibility visibility;
  final String ownerId;
  final List<String> likedBy;
  final String? photoUrl;

  const Activity({
    required this.id,
    required this.name,
    required this.address,
    required this.expectedPrice,
    required this.notes,
    required this.tags,
    required this.visibility,
    required this.ownerId,
    required this.likedBy,
    required this.photoUrl,
  });
}
