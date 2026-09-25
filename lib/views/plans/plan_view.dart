import 'package:flutter/material.dart';
import 'package:plansync/models/user.dart';
import 'package:plansync/viewmodels/plans/plan_viewmodel.dart';
import 'package:plansync/views/plans/plan_card.dart';
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
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('My Plans', style: text.headlineMedium),
        actions: [IconButton(icon: const Icon(Icons.add), onPressed: () {})],
      ),
      body: Column(
        children: [
          Row(
            children: PlanTab.values.map((tab) {
              final selected = vm.selectedTab == tab;
              return Expanded(
                child: GestureDetector(
                  onTap: () => vm.selectTab(tab),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: selected ? colors.primary : Colors.transparent,
                          width: 2,
                        ),
                      ),
                    ),
                    child: Text(
                      _tabLabel(tab),
                      textAlign: TextAlign.center,
                      style: text.titleSmall?.copyWith(
                        color: selected
                            ? colors.primary
                            : colors.onSurfaceVariant,
                        fontWeight: selected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          Expanded(
            child: vm.isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: vm.visiblePlans
                        .map(
                          (plan) => PlanCard(plan: plan, tab: vm.selectedTab),
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
    PlanTab.pendingInvite => 'Pending Invites',
    PlanTab.past => 'Past',
  };
}
