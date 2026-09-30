import 'package:flutter/material.dart';
import 'package:plansync/models/user.dart';
import 'package:plansync/viewmodels/plans/manage_splits_viewmodel.dart';
import 'package:provider/provider.dart';

class ManageSplitsView extends StatelessWidget {
  const ManageSplitsView({
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
          ManageSplitsViewModel(planId, participants, context.read<User>().id),
      child: const _ManageSplitsBody(),
    );
  }
}

class _ManageSplitsBody extends StatelessWidget {
  const _ManageSplitsBody();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ManageSplitsViewModel>();
    final text = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Manage Splits')),
      body: vm.isLoading
          ? const Center(child: CircularProgressIndicator())
          : vm.youOwe.isEmpty && vm.owedToYou.isEmpty
          ? Center(
              child: Text(
                'You are all settled up',
                style: text.bodyLarge?.copyWith(color: colors.onSurfaceVariant),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (vm.errorMessage != null) ...[
                  Text(vm.errorMessage!, style: TextStyle(color: colors.error)),
                  const SizedBox(height: 8),
                ],
                if (vm.youOwe.isNotEmpty) ...[
                  Text(
                    'You owe the following',
                    style: text.bodyMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  for (final balance in vm.youOwe)
                    Card(
                      child: SwitchListTile(
                        title: Text(
                          '${balance.user.name} ${balance.user.lastName}',
                          style: text.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        secondary: Text(
                          '\$${balance.remaining.toStringAsFixed(2)}',
                          style: text.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        value: balance.isSettled,
                        onChanged: (paid) => vm.togglePaid(balance, paid),
                      ),
                    ),
                ],
                if (vm.owedToYou.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Owed to you',
                    style: text.bodyMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  for (final balance in vm.owedToYou)
                    Card(
                      child: ListTile(
                        title: Text(
                          '${balance.user.name} ${balance.user.lastName}',
                          style: text.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(balance.isSettled ? 'Paid' : 'Pending'),
                        trailing: Text(
                          '\$${balance.remaining.toStringAsFixed(2)}',
                          style: text.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ],
            ),
    );
  }
}
