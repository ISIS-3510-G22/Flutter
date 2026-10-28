class Group {
  final String id;
  final String name;
  final String description;

  const Group({
    required this.id,
    required this.name,
    required this.description,
  });

  factory Group.fromFirestore(String id, Map<String, dynamic> data) {
    return Group(
      id: id,
      name: data['name'] as String,
      description: data['description'] as String,
    );
  }

  Map<String, dynamic> toMap() => {'name': name, 'description': description};
}
