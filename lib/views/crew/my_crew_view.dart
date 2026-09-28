import 'package:flutter/material.dart';
import 'package:plansync/models/user.dart';
import 'package:plansync/models/group.dart';
import 'package:plansync/theme/app_theme.dart';
import 'package:plansync/views/crew/create_group_view.dart';
import 'package:plansync/views/crew/group_detail_view.dart';
import 'package:plansync/views/crew/group_invite_view.dart';
import 'package:plansync/viewmodels/crew/group_viewmodel.dart';
import 'package:plansync/views/widgets/crew_friends_card.dart';
import 'package:plansync/views/widgets/crew_group_card.dart';
import 'package:provider/provider.dart';

class MyCrewView extends StatelessWidget {
  const MyCrewView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CrewViewmodel(context.read<User>().id),
      child: const _MyCrewContent(),
    );
  }
}

class _MyCrewContent extends StatefulWidget {
  const _MyCrewContent();

  @override
  State<_MyCrewContent> createState() => _MyCrewContentState();
}

class _MyCrewContentState extends State<_MyCrewContent> {
  bool _showGroups = true;

  Future<void> _createGroup(CrewViewmodel vm) async {
    final group = await Navigator.of(context).push<Group>(
      MaterialPageRoute<Group>(
        builder: (_) => ChangeNotifierProvider.value(
          value: vm,
          child: const CreateGroupView(),
        ),
      ),
    );
    if (group == null || !mounted) return;

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ChangeNotifierProvider.value(
          value: vm,
          child: GroupDetailView(group: group),
        ),
      ),
    );
  }

  Future<void> _openInvitations(CrewViewmodel vm) async {
    final group = await Navigator.of(context).push<Group>(
      MaterialPageRoute<Group>(
        builder: (_) => ChangeNotifierProvider.value(
          value: vm,
          child: const GroupInviteView(),
        ),
      ),
    );
    if (group == null || !mounted) return;

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ChangeNotifierProvider.value(
          value: vm,
          child: GroupDetailView(group: group),
        ),
      ),
    );
  }

  void _openGroup(CrewViewmodel vm, Group group) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ChangeNotifierProvider.value(
          value: vm,
          child: GroupDetailView(group: group),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<CrewViewmodel>();

    return ColoredBox(
      color: const Color(0xFFFAFAFA),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(34, 20, 20, 10),
            child: Text(
              'My Crew',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontSize: 36,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const Divider(height: 1, color: AppTheme.greyLight),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 20, 14, 16),
            child: _CrewTabs(
              showGroups: _showGroups,
              onGroupsPressed: () => setState(() => _showGroups = true),
              onFriendsPressed: () => setState(() => _showGroups = false),
            ),
          ),
          Expanded(
            child: _showGroups
                ? vm.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : vm.error != null
                      ? Center(child: Text(vm.error!))
                      : _GroupsList(
                          groups: vm.groups,
                          memberCountFor: vm.memberCountFor,
                          onGroupTap: (group) => _openGroup(vm, group),
                        )
                : const _FriendsList(),
          ),
          _showGroups
              ? Padding(
                  padding: const EdgeInsets.fromLTRB(36, 8, 36, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 46,
                          child: FilledButton(
                            onPressed: () => _openInvitations(vm),
                            style: FilledButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: Text(
                              'Invitations (${vm.invitations.length})',
                              style: Theme.of(context).textTheme.labelLarge!
                                  .copyWith(color: AppTheme.white),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SizedBox(
                          height: 46,
                          child: FilledButton(
                            onPressed: () => _createGroup(vm),
                            style: FilledButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: Text(
                              'Create Group',
                              style: Theme.of(context).textTheme.labelLarge!
                                  .copyWith(color: AppTheme.white),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.fromLTRB(36, 8, 36, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 46,
                          child: FilledButton(
                            onPressed: () {},
                            style: FilledButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: Text(
                              'Requests',
                              style: Theme.of(context).textTheme.labelLarge!
                                  .copyWith(color: AppTheme.white),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SizedBox(
                          height: 46,
                          child: FilledButton(
                            onPressed: () {},
                            style: FilledButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: Text(
                              'Add Friends',
                              style: Theme.of(context).textTheme.labelLarge!
                                  .copyWith(color: AppTheme.white),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
        ],
      ),
    );
  }
}

class _CrewTabs extends StatelessWidget {
  const _CrewTabs({
    required this.showGroups,
    required this.onGroupsPressed,
    required this.onFriendsPressed,
  });

  final bool showGroups;
  final VoidCallback onGroupsPressed;
  final VoidCallback onFriendsPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppTheme.white,
        border: Border.all(color: AppTheme.greyLight),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Row(
        children: [
          _TabButton(
            label: 'My Groups',
            selected: showGroups,
            onPressed: onGroupsPressed,
          ),
          _TabButton(
            label: 'My Friends',
            selected: !showGroups,
            onPressed: onFriendsPressed,
          ),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.label,
    required this.selected,
    required this.onPressed,
  });

  final String label;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          foregroundColor: selected ? AppTheme.white : const Color(0xFF747987),
          backgroundColor: selected ? AppTheme.coral : Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            fontSize: 16,
            color: selected ? AppTheme.white : AppTheme.greyDark,
          ),
        ),
      ),
    );
  }
}

class _GroupsList extends StatelessWidget {
  const _GroupsList({
    required this.groups,
    required this.memberCountFor,
    required this.onGroupTap,
  });

  final List<Group> groups;
  final int Function(String groupId) memberCountFor;
  final ValueChanged<Group> onGroupTap;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(34, 2, 34, 12),
      children: groups.isEmpty
          ? const [
              Padding(
                padding: EdgeInsets.only(top: 48),
                child: Center(child: Text('You have no groups yet')),
              ),
            ]
          : [
              for (var index = 0; index < groups.length; index++) ...[
                CrewGroupCard(
                  name: groups[index].name,
                  memberCount: memberCountFor(groups[index].id),
                  avatarCount: memberCountFor(groups[index].id) < 3
                      ? memberCountFor(groups[index].id)
                      : 3,
                  overflowCount: memberCountFor(groups[index].id) > 3
                      ? memberCountFor(groups[index].id) - 3
                      : null,
                  onTap: () => onGroupTap(groups[index]),
                ),
                if (index != groups.length - 1) const SizedBox(height: 28),
              ],
            ],
    );
  }
}

class _FriendsList extends StatelessWidget {
  const _FriendsList();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(34, 2, 34, 12),
      children: const [
        CrewFriendsCard(
          name: 'Pedro Martinez',
          email: 'andres@example.com',
          initials: 'AM',
          avatarColors: Color(0xFFFFB5A6),
        ),
        SizedBox(height: 14),
        CrewFriendsCard(
          name: 'Juan Diego Restrepo',
          email: 'juan@example.com',
          initials: 'JD',
          avatarColors: Color(0xFFD8C5FF),
        ),
        SizedBox(height: 14),
        CrewFriendsCard(
          name: 'Julian Ramirez',
          email: 'julian@example.com',
          initials: 'JR',
          avatarColors: Color(0xFFAEC8E8),
        ),
        SizedBox(height: 14),
        CrewFriendsCard(
          name: 'Samuel Ochoa',
          email: 'samuel@example.com',
          initials: 'So',
          avatarColors: Color(0xFFFFB5A6),
        ),
        SizedBox(height: 14),
        CrewFriendsCard(
          name: 'Carolina Lopez',
          email: 'carolina@example.com',
          initials: 'CL',
          avatarColors: Color(0xFFD8C5FF),
        ),
        SizedBox(height: 14),
        CrewFriendsCard(
          name: 'Carolina Lopez',
          email: 'carolina@example.com',
          initials: 'CL',
          avatarColors: Color(0xFFD8C5FF),
        ),
        SizedBox(height: 14),
        CrewFriendsCard(
          name: 'Carolina Lopez',
          email: 'carolina@example.com',
          initials: 'CL',
          avatarColors: Color(0xFFD8C5FF),
        ),
        SizedBox(height: 14),
        CrewFriendsCard(
          name: 'Carolina Lopez',
          email: 'carolina@example.com',
          initials: 'CL',
          avatarColors: Color(0xFFD8C5FF),
        ),
        SizedBox(height: 14),
      ],
    );
  }
}
