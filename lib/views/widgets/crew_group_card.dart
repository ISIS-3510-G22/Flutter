import 'package:flutter/material.dart';
import 'package:plansync/theme/app_theme.dart';

class CrewGroupCard extends StatelessWidget {
  const CrewGroupCard({
    super.key,
    required this.name,
    required this.memberCount,
    required this.avatarCount,
    this.overflowCount,
    this.onAccept,
    this.onDeny,
    this.onTap,
  });

  final String name;
  final int memberCount;
  final int avatarCount;
  final int? overflowCount;
  final VoidCallback? onAccept;
  final VoidCallback? onDeny;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    const avatarColors = [
      Color(0xFFFFB5A6),
      Color(0xFFD8C5FF),
      Color(0xFFAEC8E8),
    ];
    final avatarTotal = avatarCount + (overflowCount == null ? 0 : 1);
    final showActions = onAccept != null || onDeny != null;

    return Material(
      color: colors.surfaceContainerLow,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: colors.surfaceContainerLow,
            border: Border.all(color: colors.outline),
            borderRadius: BorderRadius.circular(18),
            boxShadow: const [
              BoxShadow(
                color: const Color(0x1F000000),
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
                style: text.titleLarge?.copyWith(
                  color: colors.onSurface,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$memberCount ${memberCount == 1 ? 'Member' : 'Members'}',
                style: text.bodySmall?.copyWith(color: colors.onSurfaceVariant),
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
                            foregroundColor: colors.onSurfaceVariant,
                            side: BorderSide(color: colors.outline),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(
                            'Deny',
                            style: text.labelLarge?.copyWith(
                              fontSize: 15,
                              color: colors.onSurfaceVariant,
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
                          child: Text(
                            'Accept',
                            style: text.labelLarge?.copyWith(
                              fontSize: 15,
                              color: AppTheme.white,
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
        ),
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
        border: Border.all(color: AppTheme.coral),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Icon(Icons.person_outline, size: 20, color: AppTheme.black),
    );
  }
}

class _OverflowAvatar extends StatelessWidget {
  const _OverflowAvatar({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Container(
      width: 38,
      height: 38,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: colors.secondaryContainer,
        border: Border.all(color: AppTheme.coral),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text('+$count', style: text.labelLarge?.copyWith(fontSize: 17)),
    );
  }
}
