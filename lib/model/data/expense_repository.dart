import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:plansync/model/data/local/split_local_store.dart';
import 'package:plansync/model/models/expense.dart';

class ExpenseRepository {
  CollectionReference<Map<String, dynamic>> _expenses(String planId) =>
      FirebaseFirestore.instance
          .collection('plans')
          .doc(planId)
          .collection('expenses');

  final _local = SplitLocalStore();

  Expense _fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final data = d.data()!;
    var splitAmongIds = <String>[];
    if (data['splitAmongIds'] is List) {
      splitAmongIds = (data['splitAmongIds'] as List).cast<String>();
    }
    return Expense(
      id: d.id,
      name: data['name'] as String,
      value: (data['value'] as num).toDouble(),
      paidById: data['paidById'] as String,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      splitAmongIds: splitAmongIds,
    );
  }

  Map<String, dynamic> _toData(Expense expense) => {
    'name': expense.name,
    'value': expense.value,
    'paidById': expense.paidById,
    'createdAt': Timestamp.fromDate(expense.createdAt),
    'splitAmongIds': expense.splitAmongIds,
  };

  /// The saved copy first (`null` if never saved), then each server answer,
  /// saved before it's emitted. Offline the listener stays silent (R2).
  Stream<List<Expense>?> expensesForPlan(String planId) async* {
    yield await _local.expenses(planId);
    yield* _expenses(planId)
        .orderBy('createdAt', descending: true)
        .snapshots(includeMetadataChanges: true)
        .where((snapshot) => !snapshot.metadata.isFromCache)
        .asyncMap((snapshot) async {
          final expenses = snapshot.docs.map(_fromDoc).toList();
          await _local.saveExpenses(planId, expenses);
          return expenses;
        });
  }

  Future<void> create(String planId, Expense expense) {
    return _expenses(planId).add(_toData(expense));
  }

  Future<void> update(String planId, Expense expense) {
    return _expenses(planId).doc(expense.id).update(_toData(expense));
  }

  Future<void> delete(String planId, String expenseId) {
    return _expenses(planId).doc(expenseId).delete();
  }
}
