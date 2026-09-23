import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:plansync/models/invitations.dart';
import 'package:plansync/models/plan.dart';

class PlanRepository {
  final _plans = FirebaseFirestore.instance.collection('plans');

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
}
