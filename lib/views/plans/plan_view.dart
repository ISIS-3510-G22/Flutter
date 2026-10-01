import 'package:flutter/material.dart';
import 'package:plansync/models/user.dart';
import 'package:plansync/viewmodels/plans/plan_viewmodel.dart';
import 'package:plansync/views/plans/create_edit_plan_view.dart';
import 'package:plansync/views/plans/plan_card.dart';
import 'package:plansync/views/widgets/tab_button.dart';
import 'package:plansync/views/widgets/view_header.dart';
import 'package:provider/provider.dart';

class PlanView extends StatelessWidget {
  const PlanView({super.key, required this.user});

  final User user;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => MyPlansViewModel(user.id),
      child: const _PlanScreen(),
    );
  }
}

class _PlanScreen extends StatelessWidget {
  const _PlanScreen();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<MyPlansViewModel>();

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CreateEditPlanView()),
        ),
        child: const Icon(Icons.add),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ViewHeader(title: 'My Plans'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TabTrack(
              children: [
                for (final tab in PlanTab.values)
                  TabButton(
                    label: _tabLabel(tab),
                    selected: vm.selectedTab == tab,
                    onPressed: () => vm.selectTab(tab),
                  ),
              ],
            ),
          ),
          Expanded(
            child: vm.isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
                    children: vm.visiblePlans
                        .map(
                          (plan) => PlanCard(
                            plan: plan,
                            tab: vm.selectedTab,
                            going: vm.isGoing(plan),
                            notification: vm.notificationFor(plan),
                            photoUrls: vm.photoUrlsFor(plan),
                          ),
                        )
                        .toList(),
                  ),
          ),
        ],
      ),
    );
  }

  String _tabLabel(PlanTab tab) => switch (tab) {
    PlanTab.upcoming => 'Upcoming',
    PlanTab.pendingInvite => 'My Invites',
    PlanTab.past => 'Past',
  };
}
