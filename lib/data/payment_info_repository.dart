import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:plansync/models/payment_info.dart';

class PaymentInfoRepository {
  CollectionReference<Map<String, dynamic>> _paymentInfo(String planId) =>
      FirebaseFirestore.instance
          .collection('plans')
          .doc(planId)
          .collection('paymentInfo');

  PaymentInfo _fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    return PaymentInfo(userId: d.id, details: d.data()!['details'] as String);
  }

  Stream<List<PaymentInfo>> paymentInfoForPlan(String planId) {
    return _paymentInfo(
      planId,
    ).snapshots().map((snapshot) => snapshot.docs.map(_fromDoc).toList());
  }

  Future<PaymentInfo?> paymentInfoBy(String planId, String userId) async {
    final doc = await _paymentInfo(planId).doc(userId).get();
    if (!doc.exists) return null;
    return _fromDoc(doc);
  }

  Future<void> save(String planId, PaymentInfo info) {
    return _paymentInfo(planId).doc(info.userId).set({'details': info.details});
  }
}
