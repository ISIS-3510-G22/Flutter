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
  final double? lat;
  final double? lng;

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
    required this.lat,
    required this.lng,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'address': address,
    'expectedPrice': expectedPrice,
    'notes': notes,
    'tags': tags,
    'visibility': visibility.name,
    'ownerId': ownerId,
    'likedBy': likedBy,
    'photoUrl': photoUrl,
    'lat': lat,
    'lng': lng,
  };

  factory Activity.fromJson(Map<String, dynamic> json) => Activity(
    id: json['id'] as String,
    name: json['name'] as String,
    address: json['address'] as String,
    expectedPrice: (json['expectedPrice'] as num).toDouble(),
    notes: json['notes'] as String,
    tags: (json['tags'] as List).cast<String>(),
    visibility: ActivityVisibility.values.byName(json['visibility'] as String),
    ownerId: json['ownerId'] as String,
    likedBy: (json['likedBy'] as List).cast<String>(),
    photoUrl: json['photoUrl'] as String?,
    lat: (json['lat'] as num?)?.toDouble(),
    lng: (json['lng'] as num?)?.toDouble(),
  );
}
