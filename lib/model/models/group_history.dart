import 'package:plansync/model/models/group_outing.dart';

class GroupHistory {
  final String groupId;
  final List<GroupOuting> outings;
  final List<GroupMemberAttendance> attendanceRanking;

  const GroupHistory({
    required this.groupId,
    required this.outings,
    required this.attendanceRanking,
  });

  GroupOuting? get lastOuting => outings.isEmpty ? null : outings.first;
}

class GroupMemberAttendance {
  final String userId;
  final int outingCount;

  const GroupMemberAttendance({
    required this.userId,
    required this.outingCount,
  });
}
