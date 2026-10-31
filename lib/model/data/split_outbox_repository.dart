import 'package:plansync/model/data/expense_repository.dart';
import 'package:plansync/model/data/plan_payment_repository.dart';
import 'package:plansync/model/data/plan_repository.dart';
import 'package:plansync/model/data/settlement_repository.dart';
import 'package:plansync/model/data/write_queue.dart';
import 'package:plansync/model/models/expense.dart';
import 'package:plansync/model/models/pending_write.dart';
import 'package:plansync/model/models/settlement.dart';

enum SplitWriteKind {
  expenseSave,
  expenseDelete,
  settlementAdd,
  settlementRemove,
  paymentChoose,
  planReorder,
}

/// Every `docId` is `'<planId>/<id>'`, so a repository can tell whether a
/// plan has writes waiting without reading the payloads.
class SplitOutboxRepository extends WriteQueue<SplitWriteKind> {
  SplitOutboxRepository._internal()
    : super('split_outbox', SplitWriteKind.values);

  static final instance = SplitOutboxRepository._internal();

  final _expenses = ExpenseRepository();
  final _settlements = SettlementRepository();
  final _payments = PlanPaymentRepository();
  final _plans = PlanRepository();

  static String docId(String planId, String id) => '$planId/$id';

  bool hasPendingFor(String planId) =>
      pendingDocIds.any((id) => id.startsWith('$planId/'));

  /// The pending IDs of one plan, without the plan prefix (for the labels).
  Set<String> pendingIdsFor(String planId) => {
    for (final id in pendingDocIds)
      if (id.startsWith('$planId/')) id.substring(planId.length + 1),
  };

  @override
  Future<void> send(PendingWrite<SplitWriteKind> write) async {
    final payload = write.payload;
    final planId = payload['planId'] as String;
    await switch (write.kind) {
      SplitWriteKind.expenseSave => _sendExpense(planId, payload),
      SplitWriteKind.expenseDelete => _expenses.delete(
        planId,
        payload['expenseId'] as String,
      ),
      SplitWriteKind.settlementAdd => _settlements.settle(
        planId,
        Settlement.fromJson(payload['settlement'] as Map<String, dynamic>),
      ),
      SplitWriteKind.settlementRemove => _settlements.unsettle(
        planId,
        payload['settlementId'] as String,
      ),
      SplitWriteKind.paymentChoose => _payments.choose(
        planId,
        payload['userId'] as String,
        payload['methodId'] as String,
      ),
      SplitWriteKind.planReorder => _plans.setActivityOrder(
        planId,
        (payload['activityIds'] as List).cast<String>(),
      ),
    };
  }

  /// New → `set` (safe twice). Edit → `update`, which fails with `not-found`
  /// if someone deleted the expense meanwhile, so it's dropped, not recreated.
  Future<void> _sendExpense(String planId, Map<String, dynamic> payload) {
    final expense = Expense.fromJson(
      payload['expense'] as Map<String, dynamic>,
    );
    if (payload['isNew'] as bool) return _expenses.create(planId, expense);
    return _expenses.update(planId, expense);
  }

  @override
  String describeDropped(PendingWrite<SplitWriteKind> write) {
    final payload = write.payload;
    return switch (write.kind) {
      SplitWriteKind.expenseSave when payload['isNew'] as bool =>
        "We couldn't add the expense ${_nameOf(payload)}.",
      SplitWriteKind.expenseSave =>
        '${_nameOf(payload)} was deleted, so your changes couldn\'t sync.',
      SplitWriteKind.expenseDelete =>
        "We couldn't delete ${payload['name']} on the server.",
      SplitWriteKind.settlementAdd =>
        "A payment you marked couldn't sync. Check Manage splits.",
      SplitWriteKind.settlementRemove =>
        "A payment you undid couldn't sync. Check Manage splits.",
      SplitWriteKind.paymentChoose =>
        "Your payment method for a plan couldn't sync.",
      SplitWriteKind.planReorder when payload['planName'] is String =>
        "The new stop order for ${payload['planName']} couldn't sync.",
      SplitWriteKind.planReorder =>
        "The new stop order for a plan couldn't sync.",
    };
  }

  String _nameOf(Map<String, dynamic> payload) =>
      (payload['expense'] as Map<String, dynamic>)['name'] as String;
}
