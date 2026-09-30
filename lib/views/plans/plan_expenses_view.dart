import 'package:flutter/material.dart';
import 'package:plansync/models/user.dart';
import 'package:plansync/viewmodels/plans/plan_expenses_viewmodel.dart';
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
      appBar: AppBar(title: const Text('Plan Expenses')),
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
                    subtitle: Text(vm.payerName(expense)),
                  ),
                );
              },
            ),
    );
  }
}
