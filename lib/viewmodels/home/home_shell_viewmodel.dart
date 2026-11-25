import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:plansync/model/data/friend_repository.dart';
import 'package:plansync/model/data/group_repository.dart';
import 'package:plansync/model/data/plan_repository.dart';
import 'package:plansync/model/models/invitations.dart';

class HomeShellViewModel extends ChangeNotifier {
  HomeShellViewModel(String userId) {
    _subs = [
      PlanRepository().plansForUser(userId).listen((plans) {
        hasPlanInvites = plans.any(
          (p) =>
              p.rsvpFor(userId) == RsvpStatus.invited &&
              p.date.isAfter(DateTime.now()),
        );
        notifyListeners();
      }),
      FriendRepository().pendingRequestsForUser(userId).listen((requests) {
        _hasFriendRequests = requests.isNotEmpty;
        notifyListeners();
      }),
      GroupRepository().pendingInvitationsForUser(userId).listen((invitations) {
        _hasGroupInvitations = invitations.isNotEmpty;
        notifyListeners();
      }),
    ];
  }

  late final List<StreamSubscription<Object?>> _subs;

  bool hasPlanInvites = false;
  bool _hasFriendRequests = false;
  bool _hasGroupInvitations = false;

  bool get hasCrewRequests => _hasFriendRequests || _hasGroupInvitations;

  @override
  void dispose() {
    for (final sub in _subs) {
      sub.cancel();
    }
    super.dispose();
  }
}
