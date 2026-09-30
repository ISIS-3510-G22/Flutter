import 'package:flutter/material.dart';
import 'package:plansync/models/invitations.dart';
import 'package:plansync/models/plan.dart';
import 'package:plansync/models/user.dart';
import 'package:plansync/utils/avatar.dart';
import 'package:plansync/utils/date_format.dart';
import 'package:plansync/utils/text_format.dart';
import 'package:plansync/viewmodels/plans/plan_detail_viewmodel.dart';
import 'package:plansync/views/activities/activity_card.dart';
import 'package:plansync/views/activities/activity_detail_view.dart';
import 'package:plansync/views/plans/edit_plan_activities_view.dart';
import 'package:plansync/views/widgets/decision_dialog.dart';
import 'package:provider/provider.dart';

class PlanDetailView extends StatelessWidget {
  const PlanDetailView({required this.plan, super.key});

  final Plan plan;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => PlanDetailViewModel(plan, context.read<User>().id),
      child: const _PlanDetailBody(),
    );
  }
}

class _PlanDetailBody extends StatelessWidget {
  const _PlanDetailBody();

  Future<void> _inviteFriends(
    BuildContext context,
    PlanDetailViewModel vm,
  ) async {
    final friends = await vm.invitableFriends();
    if (!context.mounted) return;
    final selected = await showModalBottomSheet<Set<String>>(
      context: context,
      builder: (_) => _FriendPicker(friends: friends),
    );
    if (selected != null) await vm.invite(selected.toList());
  }

  Future<void> _rsvp(BuildContext context, PlanDetailViewModel vm) async {
    final plan = vm.plan;
    final going = await showDecisionDialog(
      context,
      icon: Icons.event_available,
      title: plan.name,
      subtitle:
          '${formatShortDate(plan.date)} · ${formatTime(TimeOfDay.fromDateTime(plan.date))} · ${plan.invitations.length} people invited',
      message: 'Are you going?',
      acceptLabel: "I'm going",
      declineLabel: "Can't make it",
      cancelLabel: 'Maybe later',
    );
    if (going == null) return;
    final saved = await vm.respondRsvp(going);
    if (!saved && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not save your RSVP. Try again.')),
      );
    }
  }

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
                  if (vm.isCreator) ...[
                    const SizedBox(height: 8),
                    FilledButton.icon(
                      onPressed: () => _inviteFriends(context, vm),
                      icon: const Icon(Icons.person_add_alt),
                      label: const Text('Invite Friends'),
                    ),
                  ] else ...[
                    const SizedBox(height: 8),
                    FilledButton.icon(
                      onPressed: () => _rsvp(context, vm),
                      icon: const Icon(Icons.event_available),
                      label: Text(switch (vm.myRsvp) {
                        RsvpStatus.going => "You're going · Change",
                        RsvpStatus.notGoing => 'Not going · Change',
                        _ => 'RSVP',
                      }),
                    ),
                  ],
                ],
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
                if (vm.isCreator)
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

class _FriendPicker extends StatefulWidget {
  const _FriendPicker({required this.friends});

  final List<User> friends;

  @override
  State<_FriendPicker> createState() => _FriendPickerState();
}

class _FriendPickerState extends State<_FriendPicker> {
  final _selected = <String>{};

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (widget.friends.isEmpty) const Text('No friends left to invite.'),
        for (final friend in widget.friends)
          CheckboxListTile(
            value: _selected.contains(friend.id),
            title: Text('${friend.name} ${friend.lastName}'),
            subtitle: Text('@${friend.username}'),
            onChanged: (checked) => setState(() {
              if (checked!) {
                _selected.add(friend.id);
              } else {
                _selected.remove(friend.id);
              }
            }),
          ),
        FilledButton(
          onPressed: _selected.isEmpty
              ? null
              : () => Navigator.pop(context, _selected),
          child: const Text('Invite'),
        ),
      ],
    );
  }
}
