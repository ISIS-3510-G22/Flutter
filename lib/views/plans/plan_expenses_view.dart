import 'package:flutter/material.dart';
import 'package:plansync/models/user.dart';
import 'package:plansync/viewmodels/plans/plan_expenses_viewmodel.dart';
import 'package:plansync/views/plans/create_edit_expense_view.dart';
import 'package:plansync/views/plans/manage_splits_view.dart';
import 'package:plansync/views/plans/payment_info_view.dart';
import 'package:provider/provider.dart';

class PlanExpensesView extends StatelessWidget {
  const PlanExpensesView({
    required this.planId,
    required this.participants,
    super.key,
  });

  final String planId;
  final List<User> participants;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PlanExpensesViewModel(planId, participants),
      child: const _PlanExpensesBody(),
    );
  }
}

class _PlanExpensesBody extends StatelessWidget {
  const _PlanExpensesBody();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<PlanExpensesViewModel>();
    final text = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Plan Expenses'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CreateEditExpenseView(
                  planId: vm.planId,
                  participants: vm.participants,
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              OutlinedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PaymentInfoView(planId: vm.planId),
                  ),
                ),
                icon: const Icon(Icons.account_balance_outlined),
                label: const Text('Add Bre-B or account'),
              ),
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ManageSplitsView(
                      planId: vm.planId,
                      participants: vm.participants,
                    ),
                  ),
                ),
                icon: const Icon(Icons.account_balance_wallet_outlined),
                label: const Text('Manage Splits'),
              ),
            ],
          ),
        ),
      ),
      body: vm.isLoading
          ? const Center(child: CircularProgressIndicator())
          : vm.expenses.isEmpty
          ? Center(
              child: Text(
                'No expenses yet',
                style: text.bodyLarge?.copyWith(color: colors.onSurfaceVariant),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: vm.expenses.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final expense = vm.expenses[i];
                return Card(
                  child: ListTile(
                    title: Text(
                      '${expense.name} - \$${expense.value.toStringAsFixed(2)}',
                      style: text.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      '${vm.payerName(expense)} · ${vm.splitLabel(expense)}',
                    ),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CreateEditExpenseView(
                          planId: vm.planId,
                          participants: vm.participants,
                          expense: expense,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
