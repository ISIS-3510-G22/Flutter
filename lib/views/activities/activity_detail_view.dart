import 'package:flutter/material.dart';
import 'package:plansync/models/activity.dart';
import 'package:plansync/models/user.dart';
import 'package:plansync/viewmodels/activities/activity_detail_viewmodel.dart';
import 'package:plansync/views/activities/activity_info.dart';
import 'package:plansync/views/activities/add_to_plan_view.dart';
import 'package:plansync/views/activities/create_edit_activity_view.dart';
import 'package:plansync/views/widgets/circle_back_button.dart';
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

    return Scaffold(
      appBar: AppBar(
        leading: const Padding(
          padding: EdgeInsets.only(left: 8),
          child: CircleBackButton(),
        ),
        actions: [
          IconButton(
            icon: Icon(vm.isLiked ? Icons.star : Icons.star_border),
            onPressed: vm.toggleLike,
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
                } /* else if (value == 'delete') {
                  final success = await vm.delete();
                  if (success && context.mounted) {
                    Navigator.pop(context);
                  }
                } Volver a poner cuando planes esten funcionando */
              },
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'edit', child: Text('Edit')),
                //PopupMenuItem(value: 'delete', child: Text('Delete')), Volver a poner cuando planes esten funcionando
              ],
            ),
        ],
      ),
      body: ActivityInfo(activity: vm.activity),
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
