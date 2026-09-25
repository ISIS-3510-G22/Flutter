import 'package:flutter/material.dart';
import 'package:plansync/views/crew/group_detail_view.dart';
import 'package:plansync/views/widgets/crew_group_card.dart';

class GroupInviteView extends StatefulWidget {
  const GroupInviteView({super.key});

  @override
  State<GroupInviteView> createState() => _GroupInviteViewState();
}

class _GroupInviteViewState extends State<GroupInviteView> {
  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFFFAFAFA),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
              child: Row(
                children: [
                  _BackButton(onPressed: () => Navigator.of(context).pop()),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Text(
                      'Group Invites',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE5E5E5)),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(34, 18, 34, 12),
              children: [
                CrewGroupCard(
                  name: 'Old School Film',
                  memberCount: 7,
                  avatarCount: 3,
                  overflowCount: 4,
                  onAccept: () => Navigator.of(context).pushReplacement(
                    MaterialPageRoute<void>(
                      builder: (_) => const GroupDetailView(
                        groupName: 'Old School Film',
                        memberCount: 8,
                      ),
                    ),
                  ),
                  onDeny: () {
                    // handle deny
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFFBE3DC),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: const Padding(
          padding: EdgeInsets.all(10),
          child: Icon(Icons.arrow_back, size: 20, color: Colors.black),
        ),
      ),
    );
  }
}
