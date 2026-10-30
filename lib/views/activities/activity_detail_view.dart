import 'package:flutter/material.dart';
import 'package:plansync/model/models/activity.dart';
import 'package:plansync/model/models/user.dart';
import 'package:plansync/viewmodels/activities/activity_detail_viewmodel.dart';
import 'package:plansync/viewmodels/global/connectivity_viewmodel.dart';
import 'package:plansync/views/activities/activity_info.dart';
import 'package:plansync/views/activities/add_to_plan_view.dart';
import 'package:plansync/views/activities/create_edit_activity_view.dart';
import 'package:plansync/views/widgets/circle_back_button.dart';
import 'package:plansync/views/widgets/offline_banner.dart';
import 'package:provider/provider.dart';

class ActivityDetailView extends StatelessWidget {
  const ActivityDetailView({
    required this.activity,
    this.showAddToPlan = true,
    super.key,
  });

  final Activity activity;
  final bool showAddToPlan;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) =>
          ActivityDetailViewmodel(activity, context.read<User>().id),
      child: _ActivityDetailBody(showAddToPlan: showAddToPlan),
    );
  }
}

class _ActivityDetailBody extends StatelessWidget {
  const _ActivityDetailBody({required this.showAddToPlan});

  final bool showAddToPlan;

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ActivityDetailViewmodel>();
    final online = context.watch<ConnectivityViewModel>().isOnline;

    return Scaffold(
      appBar: AppBar(
        leading: const Padding(
          padding: EdgeInsets.only(left: 8),
          child: CircleBackButton(),
        ),
        actions: [
          IconButton(
            icon: Icon(vm.isLiked ? Icons.star : Icons.star_border),
            onPressed: () {
              final messenger = ScaffoldMessenger.of(context);
              vm.toggleLike().then((queued) {
                if (!queued) return;
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(
                      vm.isLiked
                          ? 'Like saved on your phone.'
                          : 'Like removed on your phone.',
                    ),
                  ),
                );
              });
            },
          ),
          if (vm.isOwner)
            PopupMenuButton<String>(
              icon: const Icon(Icons.edit_outlined),
              onSelected: (value) async {
                if (value == 'edit') {
                  final updated = await Navigator.push<Activity>(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          CreateEditActivityView(activity: vm.activity),
                    ),
                  );
                  if (updated != null) {
                    vm.applyUpdate(updated);
                  }
                }
              },
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'edit', child: Text('Edit')),
              ],
            ),
        ],
      ),
      body: Column(
        children: [
          if (!online)
            const OfflineBanner(
              message:
                  "You're offline. Likes and changes are saved on your phone and sync when you're back online.",
            ),
          Expanded(
            child: ActivityInfo(
              activity: vm.activity,
              localPhoto: vm.localPhotoPath,
            ),
          ),
        ],
      ),
      bottomNavigationBar: showAddToPlan
          ? Padding(
              padding: const EdgeInsets.all(16),
              child: FilledButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AddToPlanView(activity: vm.activity),
                  ),
                ),
                child: const Text('Add to a plan'),
              ),
            )
          : null,
    );
  }
}
