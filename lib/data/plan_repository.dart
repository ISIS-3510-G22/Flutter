import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:plansync/models/invitations.dart';
import 'package:plansync/models/plan.dart';

class PlanRepository {
  final _plans = FirebaseFirestore.instance.collection('plans');

  String newId() => _plans.doc().id;

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
            ),
          )
          .toList(),
      isPublic: data['isPublic'] as bool? ?? false,
    );
  }

  Stream<List<Plan>> plansForUser(String uid) {
    return _plans
        .where('participantsIds', arrayContains: uid)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((d) => _fromData(d.id, d.data())).toList(),
        );
  }

  Stream<Plan> planById(String id) {
    return _plans.doc(id).snapshots().map((d) => _fromData(d.id, d.data()!));
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

  Future<void> updateTags(String planId, Set<String> tags) {
    return _plans.doc(planId).update({'tags': tags.toList()});
  }

  Future<void> setPublic(String planId, bool isPublic) {
    return _plans.doc(planId).update({'isPublic': isPublic});
  }

  Future<List<Plan>> publicPlans() async {
    final snapshot = await _plans.where('isPublic', isEqualTo: true).get();
    return snapshot.docs.map((d) => _fromData(d.id, d.data())).toList();
  }
}
