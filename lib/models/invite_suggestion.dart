import 'package:plansync/models/user.dart';

class InviteSuggestion {
  final User user;
  final int invitesSent;
  final int sharedPlans;
  const InviteSuggestion(this.user, this.invitesSent, this.sharedPlans);
}
