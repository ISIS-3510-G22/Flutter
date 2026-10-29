import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:plansync/model/data/local/split_local_store.dart';
import 'package:plansync/model/models/settlement.dart';

class SettlementRepository {
  CollectionReference<Map<String, dynamic>> _settlements(String planId) =>
      FirebaseFirestore.instance
          .collection('plans')
          .doc(planId)
          .collection('settlements');

  final _local = SplitLocalStore();

  /// Same as `ExpenseRepository.expensesForPlan`: saved copy, then server.
  Stream<List<Settlement>?> settlementsForPlan(String planId) async* {
    yield await _local.settlements(planId);
    yield* _settlements(planId)
        .snapshots(includeMetadataChanges: true)
        .where((snapshot) => !snapshot.metadata.isFromCache)
        .asyncMap((snapshot) async {
          final settlements = snapshot.docs.map((d) {
            final data = d.data();
            return Settlement(
              id: d.id,
              fromId: data['fromId'] as String,
              toId: data['toId'] as String,
              amount: (data['amount'] as num).toDouble(),
            );
          }).toList();
          await _local.saveSettlements(planId, settlements);
          return settlements;
        });
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
