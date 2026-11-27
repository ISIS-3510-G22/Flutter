import 'package:flutter/material.dart';
import 'package:plansync/model/models/friend_balance.dart';
import 'package:plansync/model/models/user.dart';
import 'package:plansync/viewmodels/global/connectivity_viewmodel.dart';
import 'package:plansync/viewmodels/plans/balances_viewmodel.dart';
import 'package:plansync/views/formatters/date_format.dart';
import 'package:plansync/views/formatters/money_format.dart';
import 'package:plansync/views/plans/friend_balance_view.dart';
import 'package:plansync/views/widgets/avatar.dart';
import 'package:plansync/views/widgets/offline_banner.dart';
import 'package:plansync/views/widgets/payment_dialog.dart';
import 'package:plansync/views/widgets/waiting_to_sync.dart';
import 'package:provider/provider.dart';

class BalancesView extends StatelessWidget {
  const BalancesView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => BalancesViewModel(context.read<User>().id),
      child: const _BalancesBody(),
    );
  }
}

class _BalancesBody extends StatelessWidget {
  const _BalancesBody();

  @override
  Widget build(BuildContext context) {
    final online = context.watch<ConnectivityViewModel>().isOnline;
    final vm = context.watch<BalancesViewModel>();

    return Scaffold(
      appBar: AppBar(title: const Text('Balances')),
      body: Column(
        children: [
          if (!online) OfflineBanner(message: _offlineMessage(vm.savedAt)),
          if ((online && vm.isUpdating || vm.isSaving) && !vm.isLoading)
            const LinearProgressIndicator(),
          if (vm.hasPendingChanges)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: WaitingToSync(),
            ),
          Expanded(
            child: vm.isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: vm.refresh,
                    child: _content(context, vm, online),
                  ),
          ),
        ],
      ),
    );
  }

  String _offlineMessage(DateTime? savedAt) {
    if (savedAt == null) {
      return "You're offline. Balances haven't been saved on this phone yet.";
    }
    final time =
        '${formatShortDate(savedAt)}, '
        '${formatTime(TimeOfDay.fromDateTime(savedAt))}';
    return "You're offline. Balances as of $time plus your changes on this "
        "phone; others' newer changes aren't counted yet.";
  }

  Widget _content(BuildContext context, BalancesViewModel vm, bool online) {
    final friends = vm.friends;
    if (friends == null) {
      return _Message(
        text: vm.failed && online
            ? "Couldn't load your balances. Pull down to try again."
            : 'Connect to see your balances.',
      );
    }
    if (friends.isEmpty) {
      return const _Message(text: "You're all settled up");
    }
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: friends.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return _Totals(
            youOweCents: vm.youOweCents,
            owedToYouCents: vm.owedToYouCents,
          );
        }
        final friend = friends[index - 1];
        final pending = vm.isPending(friend);
        return _FriendRow(
          friend: friend,
          pending: pending,
          onPay: vm.isSaving ? null : () => _pay(context, friend),
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => FriendBalanceView(friend: friend),
              ),
            );
            await vm.refresh();
          },
        );
      },
    );
  }
}

Future<void> _pay(BuildContext context, FriendBalance friend) async {
  final vm = context.read<BalancesViewModel>();
  final messenger = ScaffoldMessenger.of(context);
  final name = friend.name.isEmpty ? 'Unknown' : friend.name;
  final cents = await showPaymentDialog(
    context,
    title: friend.totalCents > 0 ? '$name paid you' : 'You paid $name',
    owedCents: friend.totalCents.abs(),
  );
  if (cents == null) return;
  final result = await vm.recordPayment(friend, cents);
  showPaymentResult(
    messenger,
    result.message,
    undo: result.saved.isEmpty ? null : () => vm.undoPayment(result.saved),
  );
}

class _Message extends StatelessWidget {
  const _Message({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Text(
                text,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Totals extends StatelessWidget {
  const _Totals({required this.youOweCents, required this.owedToYouCents});

  final int youOweCents;
  final int owedToYouCents;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(
      context,
    ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('You owe ${formatMoney(youOweCents)}', style: style),
          const SizedBox(height: 4),
          Text("You're owed ${formatMoney(owedToYouCents)}", style: style),
        ],
      ),
    );
  }
}

class _FriendRow extends StatelessWidget {
  const _FriendRow({
    required this.friend,
    required this.pending,
    required this.onPay,
    required this.onTap,
  });

  final FriendBalance friend;
  final bool pending;
  final VoidCallback? onPay;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: UserAvatar(photoUrl: friend.photoUrl),
            title: Text(friend.name.isEmpty ? 'Unknown' : friend.name),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(formatDebt(friend.totalCents)),
                if (pending) const WaitingToSync(),
              ],
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: onTap,
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(0, 0, 8, 4),
              child: TextButton(
                onPressed: onPay,
                child: Text(friend.totalCents > 0 ? 'I got paid' : 'I paid'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
