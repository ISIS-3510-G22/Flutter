enum ActivityCategory {
  food,
  outdoors,
  culture,
  shopping;

  String get label => switch (this) {
    ActivityCategory.food => 'Food',
    ActivityCategory.outdoors => 'Outdoors',
    ActivityCategory.culture => 'Culture',
    ActivityCategory.shopping => 'Shopping',
  };
}

enum ActivityVisibility { private, public }

class Activity {
  final String id;
  final String name;
  final String address;
  final double expectedPrice;
  final String notes;
  final List<ActivityCategory> categories;
  final ActivityVisibility visibility;
  final String ownerId;
  final List<String> likedBy;

  const Activity({
    required this.id,
    required this.name,
    required this.address,
    required this.expectedPrice,
    required this.notes,
    required this.categories,
    required this.visibility,
    required this.ownerId,
    required this.likedBy,
  });
}
