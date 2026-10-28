import 'dart:convert';
import 'dart:isolate';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:plansync/model/data/local/json_file_store.dart';
import 'package:plansync/model/models/invitations.dart';
import 'package:plansync/model/models/invite_suggestion_ids.dart';
import 'package:plansync/model/models/plan.dart';

class PlanRepository {
  final _plans = FirebaseFirestore.instance.collection('plans');

  final _inviteSuggestionRuns = FirebaseFirestore.instance
      .collection('transferConfigs')
      .doc('6ae2b120-0000-2b6e-904c-34c7e91a4533')
      .collection('runs');

  final _planRecommendationRuns = FirebaseFirestore.instance
      .collection('transferConfigs')
      .doc('6ad98dd9-0000-2094-90ce-f4f5e80b4358')
      .collection('runs');

  String newId() => _plans.doc().id;

  final _files = JsonFileStore();

  String _plansFile(String uid) => 'plans_$uid.json';

  Future<List<Plan>?> _readPlans(String name) async {
    final text = await _files.read(name);
    if (text == null) return null;
    try {
      return await Isolate.run(() => decodePlans(text));
    } catch (_) {
      return null;
    }
  }

  Plan _fromData(String id, Map<String, dynamic> data) {
    return Plan(
      id: id,
      name: data['name'] as String,
      date: (data['date'] as Timestamp).toDate(),
      creatorId: data['creatorId'] as String,
      tags: (data['tags'] as List).cast<String>(),
      activityIds: (data['activityIds'] as List).cast<String>(),
      invitations: (data['invitations'] as List)
          .map(
            (i) => Invitation(
              userId: i['userId'] as String,
              rsvp: RsvpStatus.values.byName(i['rsvp'] as String),
              invitedAt: (i['invitedAt'] as Timestamp?)?.toDate(),
            ),
          )
          .toList(),
      isPublic: data['isPublic'] as bool? ?? false,
    );
  }

  Stream<List<Plan>> plansForUser(String uid) async* {
    final file = _plansFile(uid);
    final saved = await _readPlans(file);
    if (saved != null) yield saved;
    yield* _plans
        .where('participantsIds', arrayContains: uid)
        .snapshots(includeMetadataChanges: true)
        .where((snapshot) => !snapshot.metadata.isFromCache)
        .asyncMap((snapshot) async {
          final plans = snapshot.docs
              .map((d) => _fromData(d.id, d.data()))
              .toList();
          await _files.write(
            file,
            jsonEncode([for (final p in plans) p.toJson()]),
          );
          return plans;
        });
  }

  Stream<Plan> planById(String id) {
    return _plans
        .doc(id)
        .snapshots(includeMetadataChanges: true)
        .where((d) => !d.metadata.isFromCache)
        .map((d) => _fromData(d.id, d.data()!));
  }

  Future<void> addActivity(String planId, String activityId) {
    return _plans.doc(planId).update({
      'activityIds': FieldValue.arrayUnion([activityId]),
    });
  }

  Future<void> removeActivity(String planId, String activityId) {
    return _plans.doc(planId).update({
      'activityIds': FieldValue.arrayRemove([activityId]),
    });
  }

  Future<void> saveLocal(String uid, Plan plan) async {
    final saved = await _readPlans(_plansFile(uid)) ?? [];
    final plans = <Plan>[];
    for (final p in saved) {
      if (p.id != plan.id) plans.add(p);
    }
    plans.add(plan);
    await _files.write(
      _plansFile(uid),
      jsonEncode([for (final p in plans) p.toJson()]),
    );
  }

  Future<void> create(Plan plan) {
    return _plans.doc(plan.id).set({
      'name': plan.name,
      'date': Timestamp.fromDate(plan.date),
      'creatorId': plan.creatorId,
      'tags': plan.tags,
      'activityIds': plan.activityIds,
      'participantsIds': [plan.creatorId],
      'invitations': plan.invitations
          .map((i) => {'userId': i.userId, 'rsvp': i.rsvp.name})
          .toList(),
      'isPublic': plan.isPublic,
    });
  }

  Future<void> update(Plan plan) {
    return _plans.doc(plan.id).update({
      'name': plan.name,
      'date': Timestamp.fromDate(plan.date),
      'isPublic': plan.isPublic,
    });
  }

  Future<void> updateTags(String planId, Set<String> tags) {
    return _plans.doc(planId).update({'tags': tags.toList()});
  }

  Future<List<Plan>> publicPlans() async {
    final snapshot = await _plans.where('isPublic', isEqualTo: true).get();
    return snapshot.docs.map((d) => _fromData(d.id, d.data())).toList();
  }

  Future<List<String>> recommendedPlanIds(String uid) async {
    final latest = await _planRecommendationRuns.doc('latest').get();
    final latestData = latest.data();
    if (latestData == null) return [];
    final runId = latestData['latestRunId'];
    if (runId is! String) return [];

    final output = await _planRecommendationRuns
        .doc(runId)
        .collection('output')
        .where('uid', isEqualTo: uid)
        .limit(1)
        .get();
    if (output.docs.isEmpty) return [];

    final map = output.docs.first['plan_ids'] as Map<String, dynamic>;
    return List.generate(map.length, (i) => map['$i'] as String);
  }

  Future<void> invite(String planId, List<String> userIds) {
    final invitedAt = Timestamp.now();
    return _plans.doc(planId).update({
      'participantsIds': FieldValue.arrayUnion(userIds),
      'invitations': FieldValue.arrayUnion([
        for (final id in userIds)
          {
            'userId': id,
            'rsvp': RsvpStatus.invited.name,
            'invitedAt': invitedAt,
          },
      ]),
    });
  }

  List<dynamic> _listFromFirestore(dynamic raw) {
    if (raw is List) return raw;
    if (raw is Map) return List.generate(raw.length, (i) => raw['$i']);
    return const [];
  }

  Future<InviteSuggestionIds> inviteSuggestions(String uid) async {
    final latest = await _inviteSuggestionRuns.doc('latest').get();
    final runId = latest.data()?['latestRunId'] as String?;
    if (runId == null) return InviteSuggestionIds.empty;

    final output = await _inviteSuggestionRuns
        .doc(runId)
        .collection('output')
        .where('uid', isEqualTo: uid)
        .limit(1)
        .get();
    if (output.docs.isEmpty) return InviteSuggestionIds.empty;

    final data = output.docs.first.data();
    return InviteSuggestionIds(
      userIds: _listFromFirestore(data['user_ids']).cast<String>(),
      invitesSent: _listFromFirestore(
        data['invites_sent'],
      ).map((e) => (e as num).toInt()).toList(),
      sharedPlans: _listFromFirestore(
        data['shared_plans'],
      ).map((e) => (e as num).toInt()).toList(),
      groupIds: _listFromFirestore(data['group_ids']).cast<String>(),
    );
  }

  Future<void> setRsvp(String planId, String userId, RsvpStatus rsvp) {
    final ref = _plans.doc(planId);
    return _plans.firestore.runTransaction((tx) async {
      final snapshot = await tx.get(ref);
      final invitations = snapshot.data()!['invitations'] as List;
      tx.update(ref, {
        'invitations': [
          for (final i in invitations)
            i['userId'] == userId ? {...i, 'rsvp': rsvp.name} : i,
        ],
      });
    });
  }

  Future<Plan?> savedPlan(String uid, String id) async {
    final plans = await _readPlans(_plansFile(uid)) ?? [];
    for (final p in plans) {
      if (p.id == id) return p;
    }
    return null;
  }
}

List<Plan> decodePlans(String text) => [
  for (final p in jsonDecode(text) as List)
    Plan.fromJson(p as Map<String, dynamic>),
];
