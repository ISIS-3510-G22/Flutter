import 'package:plansync/model/models/group_history.dart';
import 'package:plansync/model/models/group_outing.dart';
import 'package:plansync/model/models/plan.dart';

GroupHistory matchOutings({
  required String groupId,
  required List<Plan> plans,
  required Set<String> groupMemberIds,
  required String signedInUserId,
}) {
  final memberIds = groupMemberIds.toSet();
  final outings = <GroupOuting>[];

  for (final plan in plans) {
    final goingIds = plan.goingIds.toSet();

    if (!goingIds.contains(signedInUserId)) continue;

    final attendingMemberIds = goingIds
        .where(memberIds.contains)
        .toList(growable: false);
    final anotherMemberIsGoing = attendingMemberIds.any(
      (userId) => userId != signedInUserId,
    );
    if (!anotherMemberIsGoing) continue;

    outings.add(
      GroupOuting(
        planId: plan.id,
        name: plan.name,
        date: plan.date,
        attendingMemberIds: attendingMemberIds,
      ),
    );
  }

  outings.sort((a, b) => b.date.compareTo(a.date));

  final appearancesByMember = <String, int>{};
  for (final outing in outings) {
    for (final userId in outing.attendingMemberIds) {
      appearancesByMember.update(
        userId,
        (count) => count + 1,
        ifAbsent: () => 1,
      );
    }
  }

  final attendanceRanking = appearancesByMember.entries
      .map(
        (entry) => GroupMemberAttendance(
          userId: entry.key,
          outingCount: entry.value,
        ),
      )
      .toList();
  attendanceRanking.sort((a, b) {
    final countOrder = b.outingCount.compareTo(a.outingCount);
    return countOrder != 0 ? countOrder : a.userId.compareTo(b.userId);
  });

  return GroupHistory(
    groupId: groupId,
    outings: outings,
    attendanceRanking: attendanceRanking,
  );
}
