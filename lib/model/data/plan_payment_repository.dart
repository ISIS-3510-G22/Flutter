import 'package:cloud_firestore/cloud_firestore.dart';

class PlanPaymentRepository {
  CollectionReference<Map<String, dynamic>> _choices(String planId) =>
      FirebaseFirestore.instance
          .collection('plans')
          .doc(planId)
          .collection('paymentMethods');

  Stream<Map<String, String>> choicesForPlan(String planId) {
    return _choices(planId).snapshots().map(
      (snapshot) => {
        for (final d in snapshot.docs) d.id: d.data()['methodId'] as String,
      },
    );
  }

  Future<void> choose(String planId, String userId, String methodId) {
    return _choices(planId).doc(userId).set({'methodId': methodId});
  }
}
