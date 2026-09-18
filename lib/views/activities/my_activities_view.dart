import 'package:flutter/material.dart';
import 'package:plansync/models/user.dart';
import 'package:plansync/viewmodels/my_activities_viewmodel.dart';
import 'package:plansync/views/activities/activity_card.dart';
import 'package:plansync/views/activities/create_activity_view.dart';
import 'package:plansync/views/widgets/tab_button.dart';
import 'package:provider/provider.dart';

class MyActivitiesView extends StatelessWidget {
  const MyActivitiesView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => MyActivitiesViewmodel(context.read<User>().id),
      child: const _MyActivitiesBody(),
    );
  }
}

class _MyActivitiesBody extends StatelessWidget {
  const _MyActivitiesBody();

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final vm = context.watch<MyActivitiesViewmodel>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('My activities', style: text.headlineMedium),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CreateActivityView()),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: TabButton(
                  label: 'Saved',
                  selected: vm.currentTab == ActivitiesTab.liked,
                  onPressed: () => vm.selectTab(ActivitiesTab.liked),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TabButton(
                  label: 'Private',
                  selected: vm.currentTab == ActivitiesTab.private,
                  onPressed: () => vm.selectTab(ActivitiesTab.private),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: vm.activities.length,
            itemBuilder: (context, index) =>
                ActivityCard(activity: vm.activities[index]),
          ),
        ),
      ],
    );
  }
}
