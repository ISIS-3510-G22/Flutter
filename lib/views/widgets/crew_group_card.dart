import 'package:flutter/material.dart';

class CrewGroupCard extends StatelessWidget {
  const CrewGroupCard({
    super.key,
    required this.name,
    required this.memberCount,
    required this.avatarCount,
    this.overflowCount,
    this.onAccept,
    this.onDeny,
  });

  final String name;
  final int memberCount;
  final int avatarCount;
  final int? overflowCount;
  final VoidCallback? onAccept;
  final VoidCallback? onDeny;

  @override
  Widget build(BuildContext context) {
    const avatarColors = [
      Color(0xFFFFB5A6),
      Color(0xFFD8C5FF),
      Color(0xFFAEC8E8),
    ];
    final avatarTotal = avatarCount + (overflowCount == null ? 0 : 1);
    final showActions = onAccept != null || onDeny != null;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE0E0E0)),
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F000000),
            blurRadius: 8,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 38,
            width: avatarTotal * 25.0 + 12,
            child: Stack(
              children: [
                for (var index = 0; index < avatarCount; index++)
                  Positioned(
                    left: index * 25.0,
                    child: _MemberAvatar(
                      color: avatarColors[index % avatarColors.length],
                    ),
                  ),
                if (overflowCount != null)
                  Positioned(
                    left: avatarCount * 25.0,
                    child: _OverflowAvatar(count: overflowCount!),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            name,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$memberCount Members',
            style: const TextStyle(fontSize: 14, color: Color(0xFF60636D)),
          ),
          const SizedBox(height: 10),
          if (showActions) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 42,
                    child: OutlinedButton(
                      onPressed: onDeny,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF60636D),
                        side: const BorderSide(color: Color(0xFFE0E0E0)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'Deny',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 42,
                    child: FilledButton(
                      onPressed: onAccept,
                      style: FilledButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'Accept',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _MemberAvatar extends StatelessWidget {
  const _MemberAvatar({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: color,
        border: Border.all(color: const Color(0xFFFF6B4A)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Icon(Icons.person_outline, size: 20, color: Colors.black),
    );
  }
}

class _OverflowAvatar extends StatelessWidget {
  const _OverflowAvatar({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1ED),
        border: Border.all(color: const Color(0xFFFF6B4A)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        '+$count',
        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
      ),
    );
  }
}
