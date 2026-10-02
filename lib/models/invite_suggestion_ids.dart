class InviteSuggestionIds {
  final List<String> userIds;
  final List<int> invitesSent;
  final List<int> sharedPlans;
  final List<String> groupIds;

  const InviteSuggestionIds({
    required this.userIds,
    required this.invitesSent,
    required this.sharedPlans,
    required this.groupIds,
  });

  static const empty = InviteSuggestionIds(
    userIds: [],
    invitesSent: [],
    sharedPlans: [],
    groupIds: [],
  );
}
