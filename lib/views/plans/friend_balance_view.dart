import 'package:flutter/material.dart';
import 'package:plansync/model/models/friend_balance.dart';
import 'package:plansync/viewmodels/global/connectivity_viewmodel.dart';
import 'package:plansync/views/formatters/date_format.dart';
import 'package:plansync/views/formatters/money_format.dart';
import 'package:plansync/views/plans/manage_splits_view.dart';
import 'package:plansync/views/widgets/offline_banner.dart';
import 'package:provider/provider.dart';

class FriendBalanceView extends StatelessWidget {
  const FriendBalanceView({required this.friend, super.key});

  final FriendBalance friend;

  @override
  Widget build(BuildContext context) {
    final online = context.watch<ConnectivityViewModel>().isOnline;

    return Scaffold(
      appBar: AppBar(
        title: Text(friend.name.isEmpty ? 'Unknown' : friend.name),
      ),
      body: Column(
        children: [
          if (!online)
            const OfflineBanner(
              message:
                  "You're offline. These plans and amounts are the last ones "
                  'loaded.',
            ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: friend.plans.length,
              itemBuilder: (context, index) {
                final plan = friend.plans[index];
                return Card(
                  child: ListTile(
                    title: Text(plan.name),
                    subtitle: Text(
                      '${formatShortDate(plan.date)} · '
                      '${formatDebt(plan.cents)}',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ManageSplitsView(
                          planId: plan.planId,
                          participantIds: plan.participantIds,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
