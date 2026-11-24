import 'dart:isolate';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:plansync/model/data/cache/group_outings_cache.dart';
import 'package:plansync/model/data/connectivity_repository.dart';
import 'package:plansync/model/data/group_repository.dart';
import 'package:plansync/model/logic/group_outings.dart';
import 'package:plansync/model/models/group_history.dart';
import 'package:plansync/model/models/invitations.dart';
import 'package:plansync/model/models/plan.dart';
import 'package:plansync/model/services/local/crew_local_store.dart';

class GroupOutingsRepository {
  static final _cache = GroupOutingsCache();

  final _plans = FirebaseFirestore.instance.collection('plans');
  final _groups = GroupRepository();
  final _local = CrewLocalStore();

  static void clearCache() => _cache.clear();

  Future<GroupHistory?> history(String groupId, String uid) async {
    final cached = _cache.get(groupId);
    if (cached != null) return cached;

    try {
      ConnectivityRepository.instance.ensureOnline();
      final snapshot = await _plans
          .where('participantsIds', arrayContains: uid)
          .get(const GetOptions(source: Source.server))
          .timeout(const Duration(seconds: 8));
      final plans = snapshot.docs.map(_planFromDocument).toList();
      final memberIds = await _groups.memberIdsForGroup(groupId);
      final history = await Isolate.run(
        () => matchOutings(
          groupId: groupId,
          plans: plans,
          groupMemberIds: memberIds.toSet(),
          signedInUserId: uid,
        ),
      );
      await _local.saveGroupHistory(history);
      _cache.put(groupId, history);
      return history;
    } catch (_) {
      final stored = await _local.groupHistoryFor(groupId);
      if (stored == null) return null;
      _cache.put(groupId, stored);
      return stored;
    }
  }

  Plan _planFromDocument(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();
    return Plan(
      id: document.id,
      name: data['name'] as String,
      date: (data['date'] as Timestamp).toDate(),
      creatorId: data['creatorId'] as String,
      tags: (data['tags'] as List<dynamic>? ?? const <dynamic>[]).cast<String>(),
      activityIds: (data['activityIds'] as List<dynamic>? ?? const <dynamic>[])
          .cast<String>(),
      invitations: (data['invitations'] as List<dynamic>? ?? const <dynamic>[])
          .map((value) {
            final invitation = value as Map<String, dynamic>;
            return Invitation(
              userId: invitation['userId'] as String,
              rsvp: RsvpStatus.values.byName(invitation['rsvp'] as String),
              invitedAt: (invitation['invitedAt'] as Timestamp?)?.toDate(),
            );
          })
          .toList(),
      isPublic: data['isPublic'] as bool? ?? false,
    );
  }
}
