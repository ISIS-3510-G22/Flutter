import 'package:flutter/material.dart';
import 'package:plansync/models/user.dart';
import 'package:plansync/viewmodels/activities/my_activities_viewmodel.dart';
import 'package:plansync/views/activities/activity_card.dart';
import 'package:plansync/views/activities/create_edit_activity_view.dart';
import 'package:plansync/views/widgets/tab_button.dart';
import 'package:plansync/views/widgets/view_header.dart';
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
    final vm = context.watch<MyActivitiesViewmodel>();

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CreateEditActivityView()),
        ),
        child: const Icon(Icons.add),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ViewHeader(title: 'My activities'),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TabTrack(
              children: [
                TabButton(
                  label: 'For you',
                  selected: vm.currentTab == ActivitiesTab.recommended,
                  onPressed: () => vm.selectTab(ActivitiesTab.recommended),
                ),
                TabButton(
                  label: 'Liked',
                  selected: vm.currentTab == ActivitiesTab.liked,
                  onPressed: () => vm.selectTab(ActivitiesTab.liked),
                ),
                TabButton(
                  label: 'Private',
                  selected: vm.currentTab == ActivitiesTab.private,
                  onPressed: () => vm.selectTab(ActivitiesTab.private),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 88),
              itemCount: vm.activities.length,
              itemBuilder: (context, index) =>
                  ActivityCard(activity: vm.activities[index]),
            ),
          ),
        ],
      ),
    );
  }
}
