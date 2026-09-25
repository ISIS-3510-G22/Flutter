class CrewGroup {
  const CrewGroup({
    required this.name,
    this.description = '',
    this.memberCount = 1,
  });

  final String name;
  final String description;
  final int memberCount;
}
