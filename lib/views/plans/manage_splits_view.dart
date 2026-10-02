import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:plansync/models/user.dart';
import 'package:plansync/viewmodels/plans/manage_splits_viewmodel.dart';
import 'package:provider/provider.dart';

class ManageSplitsView extends StatelessWidget {
  const ManageSplitsView({
    required this.planId,
    this.participants,
    this.participantIds = const [],
    super.key,
  });

  final String planId;

  /// Already loaded participants. When null they are loaded from
  /// [participantIds].
  final List<User>? participants;
  final List<String> participantIds;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => ManageSplitsViewModel(
        planId,
        context.read<User>().id,
        participants: participants,
        participantIds: participantIds,
      ),
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
    final sectionStyle = text.bodyMedium?.copyWith(
      color: colors.onSurfaceVariant,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Manage Splits')),
      body: vm.isLoading
          ? const Center(child: CircularProgressIndicator())
          : !vm.hasExpenses
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.receipt_long_outlined,
                      size: 48,
                      color: colors.onSurfaceVariant,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'There are no expenses for this plan yet',
                      textAlign: TextAlign.center,
                      style: text.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'When someone adds an expense, you will see here '
                      'who owes whom.',
                      textAlign: TextAlign.center,
                      style: text.bodyMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : vm.isEmpty
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
                if (vm.youOwe.isEmpty && vm.owedToYou.isEmpty) ...[
                  Text('You are all settled up', style: sectionStyle),
                  const SizedBox(height: 16),
                ],
                if (vm.youOwe.isNotEmpty) ...[
                  Text('You owe the following', style: sectionStyle),
                  const SizedBox(height: 8),
                  for (final row in vm.youOwe)
                    _SplitCard(
                      row: row,
                      subtitle: _paymentSubtitle(
                        vm.paymentDetailsOf(row.userId),
                      ),
                      copyText: vm.paymentDetailsOf(row.userId),
                      paid: false,
                      onToggle: (_) => vm.markPaid(row),
                    ),
                  const SizedBox(height: 16),
                ],
                if (vm.owedToYou.isNotEmpty) ...[
                  Text('Owed to you', style: sectionStyle),
                  const SizedBox(height: 8),
                  for (final row in vm.owedToYou)
                    _SplitCard(row: row, subtitle: 'Pending'),
                  const SizedBox(height: 16),
                ],
                if (vm.paidByYou.isNotEmpty || vm.paidToYou.isNotEmpty) ...[
                  Text('Paid', style: sectionStyle),
                  const SizedBox(height: 8),
                  for (final row in vm.paidByYou)
                    _SplitCard(
                      row: row,
                      subtitle: 'You paid',
                      paid: true,
                      onToggle: (_) => vm.undoPaid(row),
                    ),
                  for (final row in vm.paidToYou)
                    _SplitCard(row: row, subtitle: 'Paid you'),
                ],
              ],
            ),
    );
  }
}

String _paymentSubtitle(String? details) {
  if (details == null) return 'No Bre-B or account added yet';
  return details;
}

class _SplitCard extends StatelessWidget {
  const _SplitCard({
    required this.row,
    this.subtitle,
    this.copyText,
    this.paid,
    this.onToggle,
  });

  final SplitRow row;
  final String? subtitle;
  final String? copyText;
  final bool? paid;
  final ValueChanged<bool>? onToggle;

  @override
  Widget build(BuildContext context) {
    final bold = Theme.of(
      context,
    ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold);
    final title = Text(row.name, style: bold);
    final amount = Text('\$${row.amount.toStringAsFixed(2)}', style: bold);
    Widget? subtitleWidget;
    if (subtitle != null) subtitleWidget = Text(subtitle!);
    if (copyText != null) {
      subtitleWidget = Row(
        children: [
          Flexible(child: SelectableText(copyText!)),
          IconButton(
            icon: const Icon(Icons.copy, size: 18),
            tooltip: 'Copy',
            visualDensity: VisualDensity.compact,
            onPressed: () => _copy(context, copyText!),
          ),
        ],
      );
    }

    if (paid != null && onToggle != null) {
      return Card(
        child: SwitchListTile(
          title: title,
          subtitle: subtitleWidget,
          secondary: amount,
          value: paid!,
          onChanged: onToggle,
        ),
      );
    }
    return Card(
      child: ListTile(title: title, subtitle: subtitleWidget, trailing: amount),
    );
  }

  Future<void> _copy(BuildContext context, String value) async {
    final messenger = ScaffoldMessenger.of(context);
    await Clipboard.setData(ClipboardData(text: value));
    messenger.showSnackBar(
      const SnackBar(content: Text('Bre-B or account copied')),
    );
  }
}
