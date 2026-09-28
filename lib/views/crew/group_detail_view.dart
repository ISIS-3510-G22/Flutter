import 'package:flutter/material.dart';
import 'package:plansync/theme/app_theme.dart';

class GroupDetailView extends StatelessWidget {
  const GroupDetailView({
    super.key,
    required this.groupName,
    this.description = '',
    this.memberCount = 8,
    this.members = const ['Alex', 'Sam', 'Jordan'],
  });

  final String groupName;
  final String description;
  final int memberCount;
  final List<String> members;

  static const _memberColors = [
    AppTheme.coral,
    Color(0xFFFF9467),
    Color(0xFFFFD7AE),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return ColoredBox(
      color: const Color(0xFFF7F7F8),
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
                    const Text(
                      'Your Groups',
                      style: TextStyle(
                        color: AppTheme.black,
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
              padding: const EdgeInsets.fromLTRB(28, 32, 28, 32),
              children: [
                Text(
                  groupName,
                  style: text.headlineLarge?.copyWith(
                    color: colors.onSurface,
                    fontSize: 42,
                    height: 1.25,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Active group · $memberCount members',
                  style: text.bodyLarge?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    description,
                    style: text.bodyMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                Wrap(
                  spacing: 14,
                  runSpacing: 16,
                  children: [
                    for (var index = 0; index < members.length; index++)
                      _MemberTile(
                        name: members[index],
                        color: _memberColors[index % _memberColors.length],
                      ),
                    const _InviteTile(),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MemberTile extends StatelessWidget {
  const _MemberTile({required this.name, required this.color});

  final String name;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final initials = name.isEmpty ? '' : name[0].toUpperCase();
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return SizedBox(
      width: 70,
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              initials,
              style: text.titleMedium?.copyWith(color: colors.onPrimary),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: text.bodySmall?.copyWith(color: colors.onSurface),
          ),
        ],
      ),
    );
  }
}

class _InviteTile extends StatelessWidget {
  const _InviteTile();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return SizedBox(
      width: 70,
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFF0F1F3),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(Icons.person_add_alt_1, color: colors.onSurfaceVariant),
          ),
          const SizedBox(height: 6),
          Text(
            'Invite',
            style: text.bodySmall?.copyWith(color: colors.onSurfaceVariant),
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
      color: const Color(0xFFF7F7F8),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: const SizedBox(
          width: 40,
          height: 40,
          child: Icon(Icons.arrow_back, size: 20, color: AppTheme.black),
        ),
      ),
    );
  }
}
