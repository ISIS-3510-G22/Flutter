import 'package:flutter/material.dart';
import 'package:plansync/views/widgets/crew_friends_card.dart';
import 'package:plansync/views/widgets/crew_group_card.dart';

class MyCrewView extends StatefulWidget {
  const MyCrewView({super.key});

  @override
  State<MyCrewView> createState() => _MyCrewViewState();
}

class _MyCrewViewState extends State<MyCrewView> {
  bool _showGroups = true;

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
            child: _showGroups ? const _GroupsList() : const _FriendsList(),
          ),
          if (_showGroups)
            Padding(
              padding: const EdgeInsets.fromLTRB(36, 8, 36, 8),
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
                    'New Invitations (1)',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            )
          else
            Padding(
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
                          'Add Friend',
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
                          'Requests (1)',
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
  const _GroupsList();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(34, 2, 34, 12),
      children: const [
        CrewGroupCard(
          name: 'Weekend Hikers',
          memberCount: 7,
          avatarCount: 3,
          overflowCount: 4,
        ),
        SizedBox(height: 28),
        CrewGroupCard(name: 'Dinner Club', memberCount: 3, avatarCount: 3),
        SizedBox(height: 28),
        CrewGroupCard(
          name: 'College Reunion',
          memberCount: 13,
          avatarCount: 1,
          overflowCount: 12,
        ),
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
