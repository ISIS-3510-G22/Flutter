import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:plansync/model/services/local/split_local_store.dart';
import 'package:plansync/model/data/split_outbox_repository.dart';
import 'package:plansync/model/models/pending_write.dart';
import 'package:plansync/model/models/settlement.dart';

class SettlementRepository {
  CollectionReference<Map<String, dynamic>> _settlements(String planId) =>
      FirebaseFirestore.instance
          .collection('plans')
          .doc(planId)
          .collection('settlements');

  final _local = SplitLocalStore();

  // A getter, never a field: the queue's constructor creates this repository.
  SplitOutboxRepository get _queue => SplitOutboxRepository.instance;

  /// Generated once on the phone, so undo works while the payment is queued.
  String newId(String planId) => _settlements(planId).doc().id;

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
          if (_queue.hasPendingFor(planId)) {
            return await _local.settlements(planId) ?? settlements;
          }
          await _local.saveSettlements(planId, settlements);
          return settlements;
        });
  }

  Future<List<Settlement>?> savedSettlements(String planId) =>
      _local.settlements(planId);

  Future<bool> markPaid(String planId, Settlement settlement) async {
    await _local.saveSettlement(planId, settlement);
    return _queue.submit(
      PendingWrite(
        kind: SplitWriteKind.settlementAdd,
        docId: SplitOutboxRepository.docId(planId, settlement.id),
        payload: {'planId': planId, 'settlement': settlement.toJson()},
      ),
    );
  }

  Future<bool> undoPaid(String planId, String settlementId) async {
    await _local.removeSettlement(settlementId);
    return _queue.submit(
      PendingWrite(
        kind: SplitWriteKind.settlementRemove,
        docId: SplitOutboxRepository.docId(planId, settlementId),
        payload: {'planId': planId, 'settlementId': settlementId},
      ),
    );
  }

  // Server methods, called by the queue's `send`.

  Future<void> settle(String planId, Settlement settlement) {
    return _settlements(planId).doc(settlement.id).set({
      'fromId': settlement.fromId,
      'toId': settlement.toId,
      'amount': settlement.amount,
    });
  }

  Future<void> unsettle(String planId, String settlementId) {
    return _settlements(planId).doc(settlementId).delete();
  }
}
