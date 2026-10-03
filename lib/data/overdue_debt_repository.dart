import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:plansync/models/overdue_debt.dart';

class OverdueDebtRepository {
  CollectionReference<Map<String, dynamic>> _overdue(String planId) =>
      FirebaseFirestore.instance
          .collection('plans')
          .doc(planId)
          .collection('overdueDebts');

  Future<void> sync(String planId, List<OverdueDebt> current) async {
    final existing = await _overdue(planId).get();
    final currentIds = current.map((d) => d.id).toSet();
    final batch = FirebaseFirestore.instance.batch();

    for (final doc in existing.docs) {
      if (!currentIds.contains(doc.id)) batch.delete(doc.reference);
    }
    for (final debt in current) {
      batch.set(_overdue(planId).doc(debt.id), {
        'fromId': debt.fromId,
        'toId': debt.toId,
        'amount': debt.amount,
        'daysOverdue': debt.daysOverdue,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }
}
