import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:plansync/models/reimbursement_method.dart';
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
                      preferredMethod: vm.preferredMethodOf(row.userId),
                      allMethods: vm.allMethodsOf(row.userId),
                      paid: false,
                      onToggle: (_) => vm.markPaid(row),
                    ),
                  const SizedBox(height: 16),
                ],
                if (vm.owedToYou.isNotEmpty) ...[
                  Text('Owed to you', style: sectionStyle),
                  const SizedBox(height: 8),
                  for (final row in vm.owedToYou)
                    _SplitCard(
                      row: row,
                      subtitle: _owedSubtitle(row),
                      alert: row.overdueDays != null,
                    ),
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

String _owedSubtitle(SplitRow row) {
  final days = row.overdueDays;
  if (days == null) return 'Pending';
  return 'Overdue · $days days since the plan';
}

class _SplitCard extends StatelessWidget {
  const _SplitCard({
    required this.row,
    this.subtitle,
    this.alert = false,
    this.preferredMethod,
    this.allMethods,
    this.paid,
    this.onToggle,
  });

  final SplitRow row;
  final String? subtitle;

  /// Shows the subtitle in the error color (overdue debts).
  final bool alert;

  /// Where to pay this person: their preferred method for the plan is
  /// shown, and the three dots open all the methods in their profile.
  /// Null when the card is not about paying someone.
  final ReimbursementMethod? preferredMethod;
  final List<ReimbursementMethod>? allMethods;
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
    if (subtitle != null) {
      TextStyle? style;
      if (alert) {
        style = TextStyle(
          color: Theme.of(context).colorScheme.error,
          fontWeight: FontWeight.w600,
        );
      }
      subtitleWidget = Text(subtitle!, style: style);
    }
    final methods = allMethods;
    if (methods != null) {
      final preferred = preferredMethod;
      if (preferred == null) {
        subtitleWidget = const Text('No Bre-B or account in their profile');
      } else {
        subtitleWidget = Row(
          children: [
            Flexible(
              child: SelectableText('${preferred.type}: ${preferred.account}'),
            ),
            IconButton(
              icon: const Icon(Icons.copy, size: 18),
              tooltip: 'Copy',
              visualDensity: VisualDensity.compact,
              onPressed: () => _copy(context, preferred.account),
            ),
            if (methods.length > 1)
              IconButton(
                icon: const Icon(Icons.more_horiz, size: 20),
                tooltip: 'All payment methods',
                visualDensity: VisualDensity.compact,
                onPressed: () => _showAllMethods(context, methods, preferred),
              ),
          ],
        );
      }
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

  void _showAllMethods(
    BuildContext context,
    List<ReimbursementMethod> methods,
    ReimbursementMethod preferred,
  ) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => _AllMethodsSheet(
        name: row.name,
        methods: methods,
        preferredId: preferred.id,
      ),
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

/// All the reimbursement methods of a person, in the style of
/// Friend Details, each one with its own Copy button.
class _AllMethodsSheet extends StatelessWidget {
  const _AllMethodsSheet({
    required this.name,
    required this.methods,
    required this.preferredId,
  });

  final String name;
  final List<ReimbursementMethod> methods;
  final String preferredId;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;

    return SafeArea(
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          Text(
            "$name's payment methods",
            style: text.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'Send the payment using any of these methods.',
            style: text.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          for (final method in methods) ...[
            _MethodTile(method: method, preferred: method.id == preferredId),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _MethodTile extends StatelessWidget {
  const _MethodTile({required this.method, required this.preferred});

  final ReimbursementMethod method;
  final bool preferred;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: preferred ? colors.primary : colors.outline,
          width: preferred ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  method.type,
                  style: text.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SelectableText(method.account),
                if (preferred)
                  Text(
                    'Preferred for this plan',
                    style: text.bodySmall?.copyWith(
                      color: colors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ),
          TextButton(
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              await Clipboard.setData(ClipboardData(text: method.account));
              messenger.showSnackBar(
                SnackBar(content: Text('${method.type} account copied')),
              );
            },
            style: TextButton.styleFrom(
              foregroundColor: colors.primary,
              backgroundColor: colors.secondaryContainer,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text('Copy'),
          ),
        ],
      ),
    );
  }
}
