import 'package:flutter/material.dart';
import 'package:plansync/models/crew_group.dart';
import 'package:plansync/theme/app_theme.dart';
import 'package:plansync/views/crew/create_group_view.dart';
import 'package:plansync/views/crew/group_detail_view.dart';
import 'package:plansync/views/crew/group_invite_view.dart';
import 'package:plansync/views/widgets/crew_friends_card.dart';
import 'package:plansync/views/widgets/crew_group_card.dart';

class MyCrewView extends StatefulWidget {
  const MyCrewView({super.key});

  @override
  State<MyCrewView> createState() => _MyCrewViewState();
}

class _MyCrewViewState extends State<MyCrewView> {
  bool _showGroups = true;
  final List<CrewGroup> _groups = [
    const CrewGroup(name: 'Weekend Hikers', memberCount: 7),
    const CrewGroup(name: 'Dinner Club', memberCount: 3),
    const CrewGroup(name: 'College Reunion', memberCount: 13),
  ];
  final List<CrewGroup> _invitations = [
    const CrewGroup(name: 'Old School Film', memberCount: 7),
  ];

  Future<void> _createGroup() async {
    final group = await Navigator.of(context).push<CrewGroup>(
      MaterialPageRoute<CrewGroup>(builder: (_) => const CreateGroupView()),
    );
    if (group == null || !mounted) return;

    setState(() => _groups.insert(0, group));
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => GroupDetailView(
          groupName: group.name,
          description: group.description,
          memberCount: group.memberCount,
        ),
      ),
    );
  }

  Future<void> _openInvitations() async {
    final group = await Navigator.of(context).push<CrewGroup>(
      MaterialPageRoute<CrewGroup>(
        builder: (_) => GroupInviteView(
          invitations: List.of(_invitations),
          onDeny: _denyInvitation,
        ),
      ),
    );
    if (group == null || !mounted) return;

    setState(() {
      _invitations.removeWhere((invite) => invite.name == group.name);
      final existingIndex = _groups.indexWhere(
        (existing) => existing.name == group.name,
      );
      if (existingIndex == -1) {
        _groups.insert(0, group);
      } else {
        _groups[existingIndex] = group;
      }
    });

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => GroupDetailView(
          groupName: group.name,
          description: group.description,
          memberCount: group.memberCount,
        ),
      ),
    );
  }

  void _denyInvitation(CrewGroup invitation) {
    setState(() {
      _invitations.removeWhere((invite) => invite.name == invitation.name);
    });
  }

  void _openGroup(CrewGroup group) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => GroupDetailView(
          groupName: group.name,
          description: group.description,
          memberCount: group.memberCount,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                ? _GroupsList(groups: _groups, onGroupTap: _openGroup)
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
                            onPressed: _openInvitations,
                            style: FilledButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: Text(
                              'Invitations',
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
                            onPressed: _createGroup,
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
  const _GroupsList({required this.groups, required this.onGroupTap});

  final List<CrewGroup> groups;
  final ValueChanged<CrewGroup> onGroupTap;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(34, 2, 34, 12),
      children: [
        for (var index = 0; index < groups.length; index++) ...[
          CrewGroupCard(
            name: groups[index].name,
            memberCount: groups[index].memberCount,
            avatarCount: groups[index].memberCount < 3
                ? groups[index].memberCount
                : 3,
            overflowCount: groups[index].memberCount > 3
                ? groups[index].memberCount - 3
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
          avatarColors: const Color(0xFFFFB5A6),
        ),
        SizedBox(height: 14),
        CrewFriendsCard(
          name: 'Juan Diego Restrepo',
          email: 'juan@example.com',
          initials: 'JD',
          avatarColors: const Color(0xFFD8C5FF),
        ),
        SizedBox(height: 14),
        CrewFriendsCard(
          name: 'Julian Ramirez',
          email: 'julian@example.com',
          initials: 'JR',
          avatarColors: const Color(0xFFAEC8E8),
        ),
        SizedBox(height: 14),
        CrewFriendsCard(
          name: 'Samuel Ochoa',
          email: 'samuel@example.com',
          initials: 'So',
          avatarColors: const Color(0xFFFFB5A6),
        ),
        SizedBox(height: 14),
        CrewFriendsCard(
          name: 'Carolina Lopez',
          email: 'carolina@example.com',
          initials: 'CL',
          avatarColors: const Color(0xFFD8C5FF),
        ),
        SizedBox(height: 14),
        CrewFriendsCard(
          name: 'Carolina Lopez',
          email: 'carolina@example.com',
          initials: 'CL',
          avatarColors: const Color(0xFFD8C5FF),
        ),
        SizedBox(height: 14),
        CrewFriendsCard(
          name: 'Carolina Lopez',
          email: 'carolina@example.com',
          initials: 'CL',
          avatarColors: const Color(0xFFD8C5FF),
        ),
        SizedBox(height: 14),
        CrewFriendsCard(
          name: 'Carolina Lopez',
          email: 'carolina@example.com',
          initials: 'CL',
          avatarColors: const Color(0xFFD8C5FF),
        ),
        SizedBox(height: 14),
      ],
    );
  }
}
