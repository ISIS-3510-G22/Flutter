import 'package:flutter/material.dart';
import 'package:plansync/models/user.dart';
import 'package:plansync/viewmodels/plans/plan_expenses_viewmodel.dart';
import 'package:plansync/views/plans/create_edit_expense_view.dart';
import 'package:plansync/views/plans/manage_splits_view.dart';
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
      create: (context) =>
          PlanExpensesViewModel(planId, participants, context.read<User>().id),
      child: const _PlanExpensesBody(),
    );
  }
}

class _PlanExpensesBody extends StatelessWidget {
  const _PlanExpensesBody();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<PlanExpensesViewModel>();

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
          : Column(
              children: [
                _PaymentMethodPicker(vm: vm),
                Expanded(child: _ExpensesList(vm: vm)),
              ],
            ),
    );
  }
}

class _ExpensesList extends StatelessWidget {
  const _ExpensesList({required this.vm});

  final PlanExpensesViewModel vm;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;

    return vm.expenses.isEmpty
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
          );
  }
}

class _PaymentMethodPicker extends StatelessWidget {
  const _PaymentMethodPicker({required this.vm});

  final PlanExpensesViewModel vm;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;

    Widget content;
    if (vm.myMethods.isEmpty) {
      content = Text(
        'Add a Bre-B key or bank account in your profile so others '
        'know where to pay you.',
        style: text.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
      );
    } else {
      content = DropdownButtonFormField<String>(
        initialValue: vm.selectedMethodId,
        hint: const Text('Choose one of your accounts'),
        isExpanded: true,
        items: [
          for (final m in vm.myMethods)
            DropdownMenuItem(
              value: m.id,
              child: Text(
                '${m.type}: ${m.account}',
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
        onChanged: (methodId) async {
          final messenger = ScaffoldMessenger.of(context);
          final saved = await vm.chooseMethod(methodId);
          messenger.showSnackBar(
            SnackBar(
              content: Text(
                saved
                    ? 'Payment method saved'
                    : 'Something went wrong. Try again.',
              ),
            ),
          );
        },
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Card.outlined(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.account_balance_outlined, color: colors.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Where others pay you in this plan',
                    style: text.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              content,
            ],
          ),
        ),
      ),
    );
  }
}
