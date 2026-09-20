import 'package:flutter/material.dart';
import 'package:plansync/models/user.dart';
import 'package:plansync/viewmodels/activities/my_activities_viewmodel.dart';
import 'package:plansync/viewmodels/plans/add_activity_to_plan_viewmodel.dart';
import 'package:plansync/views/widgets/tab_button.dart';
import 'package:provider/provider.dart';

class AddActivityToPlanView extends StatelessWidget {
  const AddActivityToPlanView({
    required this.planId,
    required this.existingActivityIds,
    super.key,
  });

  final String planId;
  final List<String> existingActivityIds;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => AddActivityToPlanViewModel(
        planId,
        List.of(existingActivityIds),
        context.read<User>().id,
      ),
      child: const _AddActivityToPlanBody(),
    );
  }
}

class _AddActivityToPlanBody extends StatelessWidget {
  const _AddActivityToPlanBody();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AddActivityToPlanViewModel>();

    return Scaffold(
      appBar: AppBar(title: const Text('Add Activity')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TabButton(
                    label: 'Private',
                    selected: vm.currentTab == ActivitiesTab.private,
                    onPressed: () => vm.selectTab(ActivitiesTab.private),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TabButton(
                    label: 'Liked',
                    selected: vm.currentTab == ActivitiesTab.liked,
                    onPressed: () => vm.selectTab(ActivitiesTab.liked),
                  ),
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

                return ListTile(
                  title: Text(activity.name),
                  subtitle: Text(activity.address),
                  trailing: added
                      ? const Icon(Icons.check_circle)
                      : IconButton(
                          icon: const Icon(Icons.add_circle_outline),
                          onPressed: () => vm.addActivity(activity),
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
