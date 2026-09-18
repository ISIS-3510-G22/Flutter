import 'package:flutter/material.dart';
import 'package:plansync/models/activity.dart';
import 'package:plansync/models/user.dart';
import 'package:plansync/viewmodels/activities/activity_detail_viewmodel.dart';
import 'package:plansync/views/activities/activity_info.dart';
import 'package:plansync/views/activities/create_edit_activity_view.dart';
import 'package:provider/provider.dart';

class ActivityDetailView extends StatelessWidget {
  const ActivityDetailView({required this.activity, super.key});

  final Activity activity;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) =>
          ActivityDetailViewmodel(activity, context.read<User>().id),
      child: const _ActivityDetailBody(),
    );
  }
}

class _ActivityDetailBody extends StatelessWidget {
  const _ActivityDetailBody();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ActivityDetailViewmodel>();

    return Scaffold(
      appBar: AppBar(
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
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: FilledButton(
          onPressed: () {},
          child: const Text('Add to a plan'),
        ),
      ),
    );
  }
}
