import 'package:flutter/material.dart';
import 'package:plansync/model/models/friend_balance.dart';
import 'package:plansync/model/models/user.dart';
import 'package:plansync/viewmodels/global/connectivity_viewmodel.dart';
import 'package:plansync/viewmodels/plans/friend_balance_viewmodel.dart';
import 'package:plansync/views/formatters/date_format.dart';
import 'package:plansync/views/formatters/money_format.dart';
import 'package:plansync/views/plans/manage_splits_view.dart';
import 'package:plansync/views/widgets/offline_banner.dart';
import 'package:plansync/views/widgets/payment_dialog.dart';
import 'package:plansync/views/widgets/waiting_to_sync.dart';
import 'package:provider/provider.dart';

class FriendBalanceView extends StatelessWidget {
  const FriendBalanceView({required this.friend, super.key});

  final FriendBalance friend;

  @override
  Widget build(BuildContext context) {
    final name = friend.name.isEmpty ? 'Unknown' : friend.name;
    return ChangeNotifierProvider(
      create: (context) =>
          FriendBalanceViewModel(context.read<User>().id, friend),
      child: _FriendBalanceBody(name: name),
    );
  }
}

class _FriendBalanceBody extends StatelessWidget {
  const _FriendBalanceBody({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final online = context.watch<ConnectivityViewModel>().isOnline;
    final vm = context.watch<FriendBalanceViewModel>();

    return Scaffold(
      appBar: AppBar(title: Text(name)),
      body: Column(
        children: [
          if (!online)
            const OfflineBanner(
              message:
                  "You're offline. Payments you record are saved and sync "
                  'later; the amounts here update after that.',
            ),
          if (vm.isSaving) const LinearProgressIndicator(),
          Expanded(
            child: vm.plans.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Text(
                        'Your balance with $name is zero.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: vm.plans.length,
                    itemBuilder: (context, index) => _PlanCard(
                      plan: vm.plans[index],
                      name: name,
                      pending: vm.isPending(vm.plans[index].planId),
                      saving: vm.isSaving,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.plan,
    required this.name,
    required this.pending,
    required this.saving,
  });

  final PlanBalance plan;
  final String name;
  final bool pending;
  final bool saving;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          ListTile(
            title: Text(plan.name),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${formatShortDate(plan.date)} · ${formatDebt(plan.cents)}',
                ),
                if (pending) const WaitingToSync(),
              ],
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              final vm = context.read<FriendBalanceViewModel>();
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ManageSplitsView(
                    planId: plan.planId,
                    participantIds: plan.participantIds,
                  ),
                ),
              );
              await vm.reload();
            },
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(0, 0, 8, 4),
              child: TextButton(
                onPressed: pending || saving ? null : () => _pay(context),
                child: Text(plan.cents > 0 ? 'I got paid' : 'I paid'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pay(BuildContext context) async {
    final vm = context.read<FriendBalanceViewModel>();
    final messenger = ScaffoldMessenger.of(context);
    final cents = await showPaymentDialog(
      context,
      title: plan.cents > 0 ? '$name paid you' : 'You paid $name',
      owedCents: plan.cents.abs(),
    );
    if (cents == null) return;
    final result = await vm.recordPayment(plan, cents);
    final settlementId = result.settlementId;
    messenger.showSnackBar(
      SnackBar(
        content: Text(result.message),
        persist: false,
        action: settlementId == null
            ? null
            : SnackBarAction(
                label: 'Undo',
                onPressed: () async {
                  final message = await vm.undoPayment(
                    plan.planId,
                    settlementId,
                  );
                  messenger.showSnackBar(SnackBar(content: Text(message)));
                },
              ),
      ),
    );
  }
}
