import 'package:flutter/material.dart';
import 'package:plansync/models/plan.dart';
import 'package:plansync/models/user.dart';
import 'package:plansync/utils/avatar.dart';
import 'package:plansync/utils/date_format.dart';
import 'package:plansync/utils/text_format.dart';
import 'package:plansync/viewmodels/plans/plan_detail_viewmodel.dart';
import 'package:plansync/views/activities/activity_card.dart';
import 'package:plansync/views/activities/activity_detail_view.dart';
import 'package:plansync/views/plans/edit_plan_activities_view.dart';
import 'package:plansync/views/plans/plan_expenses_view.dart';
import 'package:provider/provider.dart';

class PlanDetailView extends StatelessWidget {
  const PlanDetailView({required this.plan, super.key});

  final Plan plan;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PlanDetailViewModel(plan),
      child: const _PlanDetailBody(),
    );
  }
}

class _PlanDetailBody extends StatelessWidget {
  const _PlanDetailBody();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<PlanDetailViewModel>();

    return Scaffold(
      appBar: AppBar(title: const Text('Plan Detail')),
      body: vm.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  vm.plan.name,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined, size: 16),
                    const SizedBox(width: 4),
                    Text(formatShortDate(vm.plan.date)),
                    const SizedBox(width: 16),
                    const Icon(Icons.payments_outlined, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      'Est. \$${vm.estimatedCostPerPerson.toStringAsFixed(0)}/pp',
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.list_alt_outlined, size: 16),
                    const SizedBox(width: 4),
                    Text('${vm.activities.length} Activities'),
                    if (vm.tags.isNotEmpty) ...[
                      const SizedBox(width: 16),
                      const Icon(Icons.sell_outlined, size: 16),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          vm.tags.map(capitalize).join(', '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
                if (vm.isActive > 0) ...[
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EditPlanActivitiesView(
                          planId: vm.plan.id,
                          existingActivityIds: vm.plan.activityIds,
                        ),
                      ),
                    ),
                    icon: const Icon(Icons.add),
                    label: const Text('Edit Activities'),
                  ),
                ],
                SizedBox(height: vm.isActive > 0 ? 8 : 16),
                FilledButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PlanExpensesView(
                        planId: vm.plan.id,
                        participants: vm.participants,
                      ),
                    ),
                  ),
                  icon: const Icon(Icons.receipt_long_outlined),
                  label: const Text('Expenses'),
                ),
                const Divider(height: 32),
                Text(
                  'Participants (${vm.participants.length})',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final p in vm.participants)
                      InitialsAvatar(name: '${p.name} ${p.lastName}'),
                  ],
                ),
                const Divider(height: 32),
                Text(
                  'Activities',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                for (final activity in vm.activities)
                  ActivityCard(
                    activity: activity,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ActivityDetailView(
                          activity: activity,
                          showAddToPlan: false,
                        ),
                      ),
                    ),
                  ),
                if (vm.plan.creatorId == context.read<User>().id)
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Public plan'),
                    value: vm.plan.isPublic,
                    onChanged: vm.setPublic,
                  ),
              ],
            ),
    );
  }
}
