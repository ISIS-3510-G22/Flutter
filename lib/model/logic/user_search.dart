import 'package:plansync/model/models/user.dart';

/// Filters users by [query] and sorts exact-prefix matches ahead of broader
/// substring matches for the Add friend search.
List<User> rankUsers(List<User> users, String query) {
  final normalized = query.trim().replaceFirst(RegExp(r'^@'), '').toLowerCase();
  if (normalized.isEmpty) return [];

  final ranked = <({User user, int rank, int index})>[];
  for (var index = 0; index < users.length; index++) {
    final user = users[index];
    final username = user.username.toLowerCase();
    final name = user.name.toLowerCase();
    final lastName = user.lastName.toLowerCase();
    final fullName = '$name $lastName'.trim();

    final rank = username.startsWith(normalized)
        ? 0
        : (name.startsWith(normalized) || fullName.startsWith(normalized))
        ? 1
        : (username.contains(normalized) ||
              name.contains(normalized) ||
              lastName.contains(normalized) ||
              fullName.contains(normalized))
        ? 2
        : null;

    if (rank != null) ranked.add((user: user, rank: rank, index: index));
  }

  ranked.sort((a, b) {
    final rankOrder = a.rank.compareTo(b.rank);
    return rankOrder != 0 ? rankOrder : a.index.compareTo(b.index);
  });
  return ranked.map((entry) => entry.user).toList();
}
