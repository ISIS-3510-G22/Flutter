import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:plansync/models/user.dart';
import 'package:plansync/theme/app_theme.dart';

class FriendDetailView extends StatelessWidget {
  const FriendDetailView({super.key, required this.friend});

  final User friend;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    final fullName = '${friend.name} ${friend.lastName}'.trim();
    final initials =
        '${friend.name.isNotEmpty ? friend.name[0] : ''}'
        '${friend.lastName.isNotEmpty ? friend.lastName[0] : ''}';

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        backgroundColor: colors.surface,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back),
          style: IconButton.styleFrom(
            backgroundColor: colors.secondaryContainer,
            foregroundColor: colors.onSecondaryContainer,
            shape: const CircleBorder(),
          ),
        ),
        title: const Text('Friend Details'),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: colors.outline),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 24),
          Center(
            child: CircleAvatar(
              radius: 48,
              backgroundColor: const Color(0xFFFFB5A6),
              backgroundImage: friend.photoUrl == null
                  ? null
                  : NetworkImage(friend.photoUrl!),
              child: friend.photoUrl == null
                  ? Text(
                      initials.isEmpty ? '?' : initials.toUpperCase(),
                      style: text.headlineSmall?.copyWith(
                        color: AppTheme.black,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 18),
          Center(
            child: Text(
              fullName,
              textAlign: TextAlign.center,
              style: text.headlineSmall?.copyWith(
                color: colors.onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Center(
            child: Text(
              friend.email,
              style: text.bodyLarge?.copyWith(color: colors.onSurfaceVariant),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'REIMBURSEMENT METHODS',
            style: text.bodyLarge?.copyWith(
              color: AppTheme.greyDark,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          if (friend.reimbursementMethods.isEmpty) ...[
            Text(
              'No reimbursement methods available.',
              style: text.bodyLarge?.copyWith(color: AppTheme.greyDark),
            ),
          ] else ...[
            Text(
              'Send payments to ${friend.name} using any of these methods.',
              style: text.bodyLarge?.copyWith(color: AppTheme.greyDark),
            ),
            const SizedBox(height: 12),
            for (
              var index = 0;
              index < friend.reimbursementMethods.length;
              index++
            ) ...[
              const SizedBox(height: 12),
              _ReinbursementInfoTile(
                type: friend.reimbursementMethods[index].type,
                account: friend.reimbursementMethods[index].account,
                colorIndex: index,
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _ReinbursementInfoTile extends StatelessWidget {
  const _ReinbursementInfoTile({
    required this.type,
    required this.account,
    required this.colorIndex,
  });

  final String type;
  final String account;
  final int colorIndex;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    const iconColors = [
      Color(0xFF7564F2),
      Color(0xFFFF6B4A),
      Color(0xFFEF5350),
    ];

    const iconBackgrounds = [
      Color(0xFFE7E5FF),
      Color(0xFFFFF0E8),
      Color(0xFFFFE9E9),
    ];

    final iconColor = iconColors[colorIndex % iconColors.length];
    final iconBackground = iconBackgrounds[colorIndex % iconBackgrounds.length];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        border: Border.all(color: colors.outline),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: iconBackground,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.wallet, size: 26, color: iconColor),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  type,
                  style: text.titleMedium?.copyWith(
                    color: colors.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  account,
                  style: text.bodyLarge?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          TextButton(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: account));
              if (!context.mounted) return;
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text('$type account copied')));
            },
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.coral,
              backgroundColor: colors.secondaryContainer,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              textStyle: text.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            child: const Text('Copy'),
          ),
        ],
      ),
    );
  }
}
