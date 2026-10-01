import 'package:flutter/material.dart';
import 'package:plansync/models/user.dart';
import 'package:plansync/viewmodels/plans/plan_viewmodel.dart';
import 'package:plansync/views/plans/create_plan_view.dart';
import 'package:plansync/views/plans/plan_card.dart';
import 'package:plansync/views/widgets/tab_button.dart';
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
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('My Plans', style: text.headlineMedium),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CreatePlanView()),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
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
                    padding: const EdgeInsets.all(16),
                    children: vm.visiblePlans
                        .map(
                          (plan) => PlanCard(
                            plan: plan,
                            tab: vm.selectedTab,
                            going: vm.isGoing(plan),
                            notification: vm.notificationFor(plan),
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
