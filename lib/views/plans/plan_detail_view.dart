import 'package:flutter/material.dart';
import 'package:plansync/models/group.dart';
import 'package:plansync/models/invitations.dart';
import 'package:plansync/models/invite_suggestion.dart';
import 'package:plansync/models/plan.dart';
import 'package:plansync/models/user.dart';
import 'package:plansync/theme/app_theme.dart';
import 'package:plansync/utils/avatar.dart';
import 'package:plansync/utils/date_format.dart';
import 'package:plansync/utils/text_format.dart';
import 'package:plansync/viewmodels/plans/plan_detail_viewmodel.dart';
import 'package:plansync/views/activities/activity_card.dart';
import 'package:plansync/views/activities/activity_detail_view.dart';
import 'package:plansync/views/plans/create_edit_plan_view.dart';
import 'package:plansync/views/plans/edit_plan_activities_view.dart';
import 'package:plansync/views/plans/plan_expenses_view.dart';
import 'package:plansync/views/plans/plan_route_view.dart';
import 'package:plansync/views/widgets/decision_dialog.dart';
import 'package:plansync/views/widgets/tab_button.dart';
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
      builder: (_) => _FriendPicker(friends: friends, viewModel: vm),
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
      appBar: AppBar(
        title: const Text('Plan Detail'),
        actions: [
          if (vm.isCreator && vm.isActive > 0)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CreateEditPlanView(editingPlan: vm.plan),
                ),
              ),
            ),
        ],
      ),
      body: vm.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                  const SizedBox(height: 4),
                  Row(
                    spacing: 8,
                    children: [
                      if (vm.isActive > 0) ...[
                        if (vm.myRsvp == RsvpStatus.going)
                          Expanded(
                            child: FilledButton.icon(
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
                          ),
                        if (vm.isCreator) ...[
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: () => _inviteFriends(context, vm),
                              icon: const Icon(Icons.person_add_alt),
                              label: const Text('Invite Friends'),
                            ),
                          ),
                        ] else ...[
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: () => _rsvp(context, vm),
                              icon: const Icon(Icons.event_available),
                              label: Text(switch (vm.myRsvp) {
                                RsvpStatus.going => "You're going",
                                RsvpStatus.notGoing => 'Not going',
                                _ => 'RSVP',
                              }),
                            ),
                          ),
                        ],
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    spacing: 8,
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PlanRouteView(
                                plan: vm.plan,
                                activities: vm.activities,
                              ),
                            ),
                          ),
                          icon: const Icon(Icons.map_outlined),
                          label: const Text('View Map'),
                        ),
                      ),
                      Expanded(
                        child: FilledButton.icon(
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
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TabTrack(
                    children: [
                      TabButton(
                        label: 'Activities',
                        selected: !vm.showInvitees,
                        onPressed: () => vm.setShowInvitees(false),
                      ),
                      TabButton(
                        label:
                            'Invitees (${vm.participants.length}/${vm.invitees.length})',
                        selected: vm.showInvitees,
                        onPressed: () => vm.setShowInvitees(true),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView(
                      children: [
                        if (vm.showInvitees)
                          for (final p in vm.invitees)
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: UserAvatar(photoUrl: p.photoUrl),
                              title: Text('${p.name} ${p.lastName}'),
                              trailing: Text(switch (vm.plan.rsvpFor(p.id)) {
                                RsvpStatus.going => 'Going',
                                RsvpStatus.notGoing => 'Not going',
                                _ => 'Pending',
                              }),
                            )
                        else
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
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _FriendPicker extends StatefulWidget {
  const _FriendPicker({required this.friends, required this.viewModel});

  final List<User> friends;
  final PlanDetailViewModel viewModel;

  @override
  State<_FriendPicker> createState() => _FriendPickerState();
}

class _FriendPickerState extends State<_FriendPicker> {
  final _selected = <String>{};

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.viewModel,
      builder: (context, _) {
        final vm = widget.viewModel;
        final friendIds = widget.friends.map((friend) => friend.id).toSet();
        final suggestions = vm.suggestedPeople
            .where((suggestion) => friendIds.contains(suggestion.user.id))
            .toList();
        final suggestedIds = suggestions
            .map((suggestion) => suggestion.user.id)
            .toSet();
        final friends = widget.friends
            .where((friend) => !suggestedIds.contains(friend.id))
            .toList();
        final showSuggested =
            suggestions.isNotEmpty || vm.suggestedGroups.isNotEmpty;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (showSuggested) ...[
              Text(
                'SUGGESTED',
                style: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(color: AppTheme.greyDark),
              ),
              const SizedBox(height: 8),
              for (final suggestion in suggestions)
                _suggestedPersonTile(suggestion),
              if (vm.suggestedGroups.isNotEmpty)
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    for (final group in vm.suggestedGroups)
                      ActionChip(
                        label: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 160),
                          child: Text(
                            group.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        onPressed: () => _addGroup(context, vm, group),
                      ),
                  ],
                ),
              const SizedBox(height: 12),
            ],
            if (showSuggested && friends.isNotEmpty) ...[
              Text(
                'FRIENDS',
                style: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(color: AppTheme.greyDark),
              ),
              const SizedBox(height: 2),
            ],
            if (friends.isEmpty && suggestions.isEmpty)
              const Text('No friends left to invite.'),
            for (final friend in friends)
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                secondary: UserAvatar(photoUrl: friend.photoUrl),
                value: _selected.contains(friend.id),
                title: Text(
                  '${friend.name} ${friend.lastName}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  '@${friend.username}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                onChanged: (checked) => _toggle(friend.id, checked),
              ),
            FilledButton(
              onPressed: _selected.isEmpty
                  ? null
                  : () => Navigator.pop(context, _selected),
              child: const Text('Invite'),
            ),
          ],
        );
      },
    );
  }

  Widget _suggestedPersonTile(InviteSuggestion suggestion) {
    final user = suggestion.user;
    final details = <String>[];
    if (suggestion.invitesSent > 0) {
      details.add('Invited ${suggestion.invitesSent}x');
    }
    if (suggestion.sharedPlans > 0) {
      details.add(
        '${suggestion.sharedPlans} ${suggestion.sharedPlans == 1 ? 'plan' : 'plans'} together',
      );
    }

    return CheckboxListTile(
      contentPadding: EdgeInsets.zero,
      secondary: UserAvatar(photoUrl: user.photoUrl),
      value: _selected.contains(user.id),
      title: Text(
        '${user.name} ${user.lastName}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: details.isEmpty
          ? null
          : Text(
              details.join(' · '),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
      onChanged: (checked) => _toggle(user.id, checked),
    );
  }

  void _toggle(String id, bool? checked) => setState(() {
    if (checked == true) {
      _selected.add(id);
    } else {
      _selected.remove(id);
    }
  });

  Future<void> _addGroup(
    BuildContext context,
    PlanDetailViewModel vm,
    Group group,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final ids = await vm.invitableMemberIds(group);
    if (!mounted) return;
    if (ids.isEmpty) {
      messenger.showSnackBar(
        SnackBar(content: Text('No one left to invite from ${group.name}.')),
      );
      return;
    }
    setState(() => _selected.addAll(ids));
  }
}
