import 'package:flutter/material.dart';
import 'package:plansync/model/models/plan.dart';
import 'package:plansync/model/models/user.dart';
import 'package:plansync/viewmodels/activities/my_activities_viewmodel.dart';
import 'package:plansync/viewmodels/global/connectivity_viewmodel.dart';
import 'package:plansync/viewmodels/plans/edit_plan_activities_viewmodel.dart';
import 'package:plansync/views/activities/activity_card.dart';
import 'package:plansync/views/widgets/offline_banner.dart';
import 'package:plansync/views/widgets/tab_button.dart';
import 'package:provider/provider.dart';

class EditPlanActivitiesView extends StatelessWidget {
  const EditPlanActivitiesView({required this.plan, super.key});

  final Plan plan;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) =>
          EditPlanActivitiesViewModel(plan, context.read<User>().id),
      child: const _EditPlanActivitiesBody(),
    );
  }
}

class _EditPlanActivitiesBody extends StatelessWidget {
  const _EditPlanActivitiesBody();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<EditPlanActivitiesViewModel>();
    final online = context.watch<ConnectivityViewModel>().isOnline;

    return Scaffold(
      appBar: AppBar(title: const Text('Add Activity')),
      body: Column(
        children: [
          if (!online)
            const OfflineBanner(
              message: "You're offline. Showing your saved activities to add.",
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: TabTrack(
              children: [
                TabButton(
                  label: 'Owned',
                  selected: vm.currentTab == ActivitiesTab.private,
                  onPressed: () => vm.selectTab(ActivitiesTab.private),
                ),
                TabButton(
                  label: 'Liked',
                  selected: vm.currentTab == ActivitiesTab.liked,
                  onPressed: () => vm.selectTab(ActivitiesTab.liked),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: vm.activities.length,
              itemBuilder: (context, index) {
                final activity = vm.activities[index];
                final added = vm.isAdded(activity);

                return ActivityCard(
                  activity: activity,
                  onTap: () {
                    final messenger = ScaffoldMessenger.of(context);
                    vm.toggleActivity(activity).then((queued) {
                      if (!queued) return;
                      messenger
                        ..hideCurrentSnackBar()
                        ..showSnackBar(
                          const SnackBar(
                            content: Text(
                              "Changes saved on your phone. The plan updates for everyone when you're back online.",
                            ),
                          ),
                        );
                    });
                  },
                  trailing: added ? const Icon(Icons.check_circle) : null,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
