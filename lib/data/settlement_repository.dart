import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:plansync/models/settlement.dart';

class SettlementRepository {
  CollectionReference<Map<String, dynamic>> _settlements(String planId) =>
      FirebaseFirestore.instance
          .collection('plans')
          .doc(planId)
          .collection('settlements');

  Stream<List<Settlement>> settlementsForPlan(String planId) {
    return _settlements(planId).snapshots().map(
      (snapshot) => snapshot.docs.map((d) {
        final data = d.data();
        return Settlement(
          id: d.id,
          fromId: data['fromId'] as String,
          toId: data['toId'] as String,
          amount: (data['amount'] as num).toDouble(),
        );
      }).toList(),
    );
  }

  Future<void> settle(String planId, Settlement settlement) {
    return _settlements(planId).add({
      'fromId': settlement.fromId,
      'toId': settlement.toId,
      'amount': settlement.amount,
    });
  }

  Future<void> unsettle(String planId, String settlementId) {
    return _settlements(planId).doc(settlementId).delete();
  }
}
