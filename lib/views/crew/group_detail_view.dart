import 'package:flutter/material.dart';

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
    Color(0xFFFF6047),
    Color(0xFFFF9467),
    Color(0xFFFFD7AE),
  ];

  @override
  Widget build(BuildContext context) {
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
                        color: Color(0xFF171D2B),
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
          const Divider(height: 1, color: Color(0xFFE5E5E5)),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(28, 32, 28, 32),
              children: [
                Text(
                  groupName,
                  style: const TextStyle(
                    color: Color(0xFF171D2B),
                    fontSize: 42,
                    height: 1.25,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Active group · $memberCount members',
                  style: const TextStyle(
                    color: Color(0xFF707786),
                    fontSize: 18,
                  ),
                ),
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    description,
                    style: const TextStyle(
                      color: Color(0xFF707786),
                      fontSize: 16,
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
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Color(0xFF171D2B), fontSize: 13),
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
            child: const Icon(Icons.person_add_alt_1, color: Color(0xFF707786)),
          ),
          const SizedBox(height: 6),
          const Text(
            'Invite',
            style: TextStyle(color: Color(0xFF707786), fontSize: 13),
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
          child: Icon(Icons.arrow_back, size: 20, color: Color(0xFF171D2B)),
        ),
      ),
    );
  }
}
