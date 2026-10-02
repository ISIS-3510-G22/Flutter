import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:plansync/models/expense.dart';

class ExpenseRepository {
  CollectionReference<Map<String, dynamic>> _expenses(String planId) =>
      FirebaseFirestore.instance
          .collection('plans')
          .doc(planId)
          .collection('expenses');

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

  Stream<List<Expense>> expensesForPlan(String planId) {
    return _expenses(planId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(_fromDoc).toList());
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
