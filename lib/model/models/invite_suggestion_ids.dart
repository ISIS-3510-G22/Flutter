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

  Map<String, dynamic> toJson() => {
    'user_ids': userIds,
    'invites_sent': invitesSent,
    'shared_plans': sharedPlans,
    'group_ids': groupIds,
  };

  factory InviteSuggestionIds.fromJson(Map<String, dynamic> json) {
    return InviteSuggestionIds(
      userIds: List<String>.from(json['user_ids'] as List? ?? const []),
      invitesSent: (json['invites_sent'] as List? ?? const [])
          .map((value) => (value as num).toInt())
          .toList(),
      sharedPlans: (json['shared_plans'] as List? ?? const [])
          .map((value) => (value as num).toInt())
          .toList(),
      groupIds: List<String>.from(json['group_ids'] as List? ?? const []),
    );
  }

  static const empty = InviteSuggestionIds(
    userIds: [],
    invitesSent: [],
    sharedPlans: [],
    groupIds: [],
  );
}
