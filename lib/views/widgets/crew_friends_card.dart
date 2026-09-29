import 'package:flutter/material.dart';
import 'package:plansync/theme/app_theme.dart';

class CrewFriendsCard extends StatelessWidget {
  const CrewFriendsCard({
    super.key,
    required this.name,
    required this.email,
    required this.initials,
    required this.avatarColors,
    this.onTap,
    this.trailing,
  });

  final String name;
  final String email;
  final String initials;
  final Color avatarColors;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: colors.surfaceContainerLow,
            border: Border.all(color: colors.outline),
            borderRadius: BorderRadius.circular(14),
            boxShadow: const [
              BoxShadow(
                color: const Color(0x1F000000),
                blurRadius: 8,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.fromBorderSide(
                    BorderSide(color: AppTheme.coral, width: 1.5),
                  ),
                ),
                child: CircleAvatar(
                  radius: 22,
                  backgroundColor: avatarColors,
                  child: Text(
                    initials,
                    style: text.labelLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      color: AppTheme.black,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: text.bodyLarge?.copyWith(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      email,
                      style: text.bodyMedium?.copyWith(
                        fontSize: 14,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 10),
                trailing!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
