import 'package:flutter/material.dart';
import 'package:plansync/models/expense.dart';
import 'package:plansync/models/user.dart';
import 'package:plansync/viewmodels/plans/create_edit_expense_viewmodel.dart';
import 'package:provider/provider.dart';

class CreateEditExpenseView extends StatelessWidget {
  const CreateEditExpenseView({
    required this.planId,
    required this.participants,
    this.expense,
    super.key,
  });

  final String planId;
  final List<User> participants;
  final Expense? expense;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => CreateEditExpenseViewModel(
        planId,
        participants,
        expense?.paidById ?? context.read<User>().id,
        expense,
      ),
      child: const _CreateEditExpenseForm(),
    );
  }
}

class _CreateEditExpenseForm extends StatelessWidget {
  const _CreateEditExpenseForm();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<CreateEditExpenseViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: Text(vm.isEditing ? 'Edit Expense' : 'New Expense'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('NAME'),
            TextField(
              controller: vm.nameController,
              decoration: const InputDecoration(hintText: 'e.g. Coffee'),
            ),
            const SizedBox(height: 16),
            const Text('VALUE'),
            TextField(
              controller: vm.valueController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(hintText: 'e.g. 20'),
            ),
            const SizedBox(height: 16),
            const Text('WHO'),
            DropdownButtonFormField<String>(
              initialValue: vm.paidById,
              items: [
                for (final p in vm.participants)
                  DropdownMenuItem(
                    value: p.id,
                    child: Text('${p.name} ${p.lastName}'),
                  ),
              ],
              onChanged: vm.selectPayer,
            ),
            if (vm.isEditing) ...[
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.error,
                    foregroundColor: Theme.of(context).colorScheme.onError,
                  ),
                  onPressed: vm.isLoading
                      ? null
                      : () async {
                          final confirmed = await _confirmDelete(context);
                          if (!confirmed) return;
                          final deleted = await vm.delete();
                          if (deleted && context.mounted) {
                            Navigator.pop(context);
                          }
                        },
                  child: const Text('Delete Expense'),
                ),
              ),
            ],
            if (vm.errorMessage != null) ...[
              const SizedBox(height: 16),
              Text(
                vm.errorMessage!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: vm.isLoading
                        ? null
                        : () async {
                            final saved = await vm.save();
                            if (saved && context.mounted) {
                              Navigator.pop(context);
                            }
                          },
                    child: vm.isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(vm.isEditing ? 'Save' : 'Create'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<bool> _confirmDelete(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete expense?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}
