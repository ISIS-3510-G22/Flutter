import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:plansync/model/services/local/split_local_store.dart';
import 'package:plansync/model/data/split_outbox_repository.dart';
import 'package:plansync/model/models/expense.dart';
import 'package:plansync/model/models/pending_write.dart';
import 'package:plansync/model/models/split_method.dart';

class ExpenseRepository {
  CollectionReference<Map<String, dynamic>> _expenses(String planId) =>
      FirebaseFirestore.instance
          .collection('plans')
          .doc(planId)
          .collection('expenses');

  final _local = SplitLocalStore();

  SplitOutboxRepository get _queue => SplitOutboxRepository.instance;

  String newId(String planId) => _expenses(planId).doc().id;

  Expense _fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final data = d.data()!;
    var splitAmongIds = <String>[];
    if (data['splitAmongIds'] is List) {
      splitAmongIds = (data['splitAmongIds'] as List).cast<String>();
    }
    final customAmounts = <String, double>{};
    if (data['customAmounts'] is Map) {
      (data['customAmounts'] as Map).forEach((id, amount) {
        customAmounts[id as String] = (amount as num).toDouble();
      });
    }
    return Expense(
      id: d.id,
      name: data['name'] as String,
      value: (data['value'] as num).toDouble(),
      paidById: data['paidById'] as String,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      splitAmongIds: splitAmongIds,
      splitMethod:
          SplitMethod.values.asNameMap()[data['splitMethod']] ??
          SplitMethod.equal,
      customAmounts: customAmounts,
    );
  }

  Map<String, dynamic> _toData(Expense expense) => {
    'name': expense.name,
    'value': expense.value,
    'paidById': expense.paidById,
    'createdAt': Timestamp.fromDate(expense.createdAt),
    'splitAmongIds': expense.splitAmongIds,
    'splitMethod': expense.splitMethod.name,
    'customAmounts': expense.customAmounts,
  };

  Stream<List<Expense>?> expensesForPlan(String planId) async* {
    yield await _local.expenses(planId);
    yield* _expenses(planId)
        .orderBy('createdAt', descending: true)
        .snapshots(includeMetadataChanges: true)
        .where((snapshot) => !snapshot.metadata.isFromCache)
        .asyncMap((snapshot) async {
          final expenses = snapshot.docs.map(_fromDoc).toList();
          if (_queue.hasPendingFor(planId)) {
            return await _local.expenses(planId) ?? expenses;
          }
          await _local.saveExpenses(planId, expenses);
          return expenses;
        });
  }

  Future<List<Expense>?> savedExpenses(String planId) =>
      _local.expenses(planId);

  Future<bool> save(
    String planId,
    Expense expense, {
    required bool isNew,
  }) async {
    await _local.saveExpense(planId, expense);
    return _queue.submit(
      PendingWrite(
        kind: SplitWriteKind.expenseSave,
        docId: SplitOutboxRepository.docId(planId, expense.id),
        payload: {
          'planId': planId,
          'isNew': isNew,
          'expense': expense.toJson(),
        },
      ),
    );
  }

  Future<bool> remove(String planId, Expense expense) async {
    await _local.removeExpense(expense.id);
    return _queue.submit(
      PendingWrite(
        kind: SplitWriteKind.expenseDelete,
        docId: SplitOutboxRepository.docId(planId, expense.id),
        payload: {
          'planId': planId,
          'expenseId': expense.id,
          'name': expense.name,
        },
      ),
    );
  }

  Future<void> create(String planId, Expense expense) {
    return _expenses(planId).doc(expense.id).set(_toData(expense));
  }

  Future<void> update(String planId, Expense expense) {
    return _expenses(planId).doc(expense.id).update(_toData(expense));
  }

  Future<void> delete(String planId, String expenseId) {
    return _expenses(planId).doc(expenseId).delete();
  }
}
