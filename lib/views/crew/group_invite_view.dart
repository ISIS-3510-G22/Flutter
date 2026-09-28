import 'package:flutter/material.dart';
import 'package:plansync/models/crew_group.dart';
import 'package:plansync/theme/app_theme.dart';
import 'package:plansync/views/widgets/crew_group_card.dart';

class GroupInviteView extends StatefulWidget {
  const GroupInviteView({
    super.key,
    required this.invitations,
    required this.onDeny,
  });

  final List<CrewGroup> invitations;
  final ValueChanged<CrewGroup> onDeny;

  @override
  State<GroupInviteView> createState() => _GroupInviteViewState();
}

class _GroupInviteViewState extends State<GroupInviteView> {
  late final List<CrewGroup> _invitations = List.of(widget.invitations);

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return ColoredBox(
      color: const Color(0xFFFAFAFA),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
              child: SizedBox(
                height: 48,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Text(
                      'Group Invite',
                      style: text.titleLarge?.copyWith(
                        color: colors.onSurface,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: _BackButton(
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const Divider(height: 1, color: AppTheme.greyLight),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(34, 18, 34, 12),
              children: _invitations.isEmpty
                  ? [
                      Padding(
                        padding: EdgeInsets.only(top: 48),
                        child: Center(
                          child: Text(
                            'No group invitations',
                            style: text.bodyMedium?.copyWith(
                              color: colors.onSurfaceVariant,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ]
                  : [
                      for (var index = 0; index < _invitations.length; index++)
                        Padding(
                          padding: EdgeInsets.only(
                            bottom: index == _invitations.length - 1 ? 0 : 28,
                          ),
                          child: CrewGroupCard(
                            name: _invitations[index].name,
                            memberCount: _invitations[index].memberCount,
                            avatarCount: 3,
                            overflowCount: _invitations[index].memberCount > 3
                                ? _invitations[index].memberCount - 3
                                : null,
                            onAccept: () {
                              final invitation = _invitations[index];
                              Navigator.of(context).pop(
                                CrewGroup(
                                  name: invitation.name,
                                  description: invitation.description,
                                  memberCount: invitation.memberCount + 1,
                                ),
                              );
                            },
                            onDeny: () {
                              final invitation = _invitations[index];
                              widget.onDeny(invitation);
                              setState(() => _invitations.removeAt(index));
                            },
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

class _BackButton extends StatelessWidget {
  const _BackButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFFFF0EC),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: const Padding(
          padding: EdgeInsets.all(10),
          child: Icon(Icons.arrow_back, size: 20, color: AppTheme.black),
        ),
      ),
    );
  }
}
