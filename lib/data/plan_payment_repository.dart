import 'package:cloud_firestore/cloud_firestore.dart';

/// Which of their profile reimbursement methods each participant wants to
/// be paid with in a plan: plans/{planId}/paymentMethods/{userId}.
class PlanPaymentRepository {
  CollectionReference<Map<String, dynamic>> _choices(String planId) =>
      FirebaseFirestore.instance
          .collection('plans')
          .doc(planId)
          .collection('paymentMethods');

  /// userId -> chosen reimbursement method id.
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
