import 'package:flutter/material.dart';
import 'package:plansync/models/activity.dart';
import 'package:plansync/models/plan.dart';
import 'package:plansync/models/user.dart';
import 'package:plansync/utils/date_format.dart';
import 'package:plansync/viewmodels/activities/add_to_plan_viewmodel.dart';
import 'package:plansync/views/activities/activity_card.dart';
import 'package:plansync/views/plans/create_edit_plan_view.dart';
import 'package:provider/provider.dart';

class AddToPlanView extends StatelessWidget {
  const AddToPlanView({required this.activity, super.key});

  final Activity activity;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) =>
          AddToPlanViewModel(activity.id, context.read<User>().id),
      child: _AddToPlanBody(activity: activity),
    );
  }
}

class _AddToPlanBody extends StatelessWidget {
  const _AddToPlanBody({required this.activity});

  final Activity activity;

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AddToPlanViewModel>();
    final text = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Add to Plan')),
      body: vm.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                ActivityCard(activity: activity, onTap: () {}),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Row(
                    children: [
                      const Icon(Icons.format_list_bulleted, size: 20),
                      const SizedBox(width: 8),
                      Text('Choose a plan', style: text.titleMedium),
                    ],
                  ),
                ),
                for (final plan in vm.plans)
                  _PlanOption(
                    plan: plan,
                    selected: vm.selectedPlanId == plan.id,
                    added: vm.alreadyAdded(plan),
                    onTap: () => vm.selectPlan(plan.id),
                  ),
                Card.outlined(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: colors.primaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.add, color: colors.primary),
                    ),
                    title: const Text('Create a new plan'),
                    subtitle: const Text('Start a plan for this activity'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            CreateEditPlanView(activityId: activity.id),
                      ),
                    ),
                  ),
                ),
              ],
            ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: FilledButton(
          onPressed: vm.selectedPlanId == null || vm.isSaving
              ? null
              : () async {
                  final messenger = ScaffoldMessenger.of(context);
                  final ok = await vm.addToSelectedPlan();
                  if (!context.mounted) return;
                  if (ok) Navigator.pop(context);
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(
                        ok
                            ? 'Added to plan'
                            : 'Something went wrong. Try again.',
                      ),
                    ),
                  );
                },
          child: const Text('Add to Plan'),
        ),
      ),
    );
  }
}

class _PlanOption extends StatelessWidget {
  const _PlanOption({
    required this.plan,
    required this.selected,
    required this.added,
    required this.onTap,
  });

  final Plan plan;
  final bool selected;
  final bool added;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final count = plan.goingIds.length;
    final peopleLabel = count == 1 ? 'Solo Trip' : '$count People';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: selected
            ? BorderSide(color: colors.primary, width: 2)
            : BorderSide.none,
      ),
      child: ListTile(
        enabled: !added,
        onTap: onTap,
        title: Text(plan.name, style: text.titleMedium),
        subtitle: Text('${formatShortDate(plan.date)} • $peopleLabel'),
        trailing: added
            ? const Text('Added')
            : selected
            ? Icon(Icons.check_circle, color: colors.primary)
            : null,
      ),
    );
  }
}
