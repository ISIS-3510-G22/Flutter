import 'package:flutter/material.dart';
import 'package:plansync/models/crew_group.dart';
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
          const Padding(
            padding: EdgeInsets.fromLTRB(34, 20, 20, 10),
            child: Text(
              'My Crew',
              style: TextStyle(fontSize: 36, fontWeight: FontWeight.w800),
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE5E5E5)),
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
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => const GroupInviteView(),
                              ),
                            ),
                            style: FilledButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text(
                              'Invitations',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
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
                            child: const Text(
                              'Create Group',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
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
                            child: const Text(
                              'Requests',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
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
                            child: const Text(
                              'Add Friends',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
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
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE5E5E5)),
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
          foregroundColor: selected ? Colors.white : const Color(0xFF747987),
          backgroundColor: selected
              ? const Color(0xFFFF6B4A)
              : Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
        ),
        child: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
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
            avatarCount: groups[index].memberCount < 3 ? groups[index].memberCount : 3,
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
