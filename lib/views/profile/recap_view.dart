import 'package:flutter/material.dart';
import 'package:plansync/model/models/month_recap.dart';
import 'package:plansync/model/models/user.dart';
import 'package:plansync/viewmodels/global/connectivity_viewmodel.dart';
import 'package:plansync/viewmodels/profile/recap_viewmodel.dart';
import 'package:plansync/views/formatters/date_format.dart';
import 'package:plansync/views/formatters/text_format.dart';
import 'package:plansync/views/widgets/activity_photo.dart';
import 'package:plansync/views/widgets/offline_banner.dart';
import 'package:provider/provider.dart';

class RecapView extends StatelessWidget {
  const RecapView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => RecapViewModel(context.read<User>().id),
      child: const _RecapBody(),
    );
  }
}

class _RecapBody extends StatelessWidget {
  const _RecapBody();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<RecapViewModel>();
    final online = context.watch<ConnectivityViewModel>().isOnline;
    final recap = vm.recap;

    return Scaffold(
      appBar: AppBar(title: const Text('Your Recap')),
      body: Column(
        children: [
          if (!online)
            OfflineBanner(
              message: recap == null
                  ? "You're offline. Months you've opened before still work."
                  : "You're offline. This recap is from ${formatShortDate(recap.updatedAt)}; it'll update when you reconnect.",
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: vm.previousMonth,
              ),
              Text(
                formatMonth(vm.month),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: vm.canGoNext ? vm.nextMonth : null,
              ),
            ],
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: vm.refresh,
              child: _content(context, vm, recap, online),
            ),
          ),
        ],
      ),
    );
  }

  Widget _content(
    BuildContext context,
    RecapViewModel vm,
    MonthRecap? recap,
    bool online,
  ) {
    if (vm.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (recap == null) {
      return _message(
        online
            ? "Couldn't build your recap. Pull down to try again."
            : 'Connect to build your recap for ${formatMonth(vm.month)}.',
      );
    }
    if (recap.plans == 0) {
      return _message(
        'No plans this month.\nCreate a plan in My Plans to see it here.',
      );
    }
    final text = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            _stat(context, '${recap.plans}', 'Plans'),
            _stat(context, '${recap.activities}', 'Activities'),
            _stat(context, '\$${recap.spend.toStringAsFixed(0)}', 'Est. spend'),
          ],
        ),
        if (recap.topTags.isNotEmpty) ...[
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            children: [
              for (final tag in recap.topTags)
                Chip(label: Text(capitalize(tag))),
            ],
          ),
        ],
        const SizedBox(height: 24),
        Text('Places of this months\' plans', style: text.titleMedium),
        const SizedBox(height: 8),
        for (final place in recap.places)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: ActivityPhoto(
              url: place.activity.photoUrl,
              width: 56,
              height: 56,
              radius: 8,
            ),
            title: Text(place.activity.name),
            subtitle: Text(
              place.activity.address,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Text('×${place.times}', style: text.titleMedium),
          ),
      ],
    );
  }

  Widget _message(String message) => ListView(
    padding: const EdgeInsets.all(32),
    children: [Text(message, textAlign: TextAlign.center)],
  );

  Widget _stat(BuildContext context, String value, String label) => Expanded(
    child: Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        child: Column(
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(value, style: Theme.of(context).textTheme.titleLarge),
            ),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    ),
  );
}
