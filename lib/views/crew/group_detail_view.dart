import 'package:flutter/material.dart';
import 'package:plansync/model/models/group.dart';
import 'package:plansync/model/models/user.dart';
import 'package:plansync/viewmodels/global/connectivity_viewmodel.dart';
import 'package:plansync/viewmodels/crew/friend_viewmodel.dart';
import 'package:plansync/viewmodels/crew/group_outings_viewmodel.dart';
import 'package:plansync/viewmodels/crew/group_viewmodel.dart';
import 'package:plansync/views/crew/group_outings_view.dart';
import 'package:plansync/views/crew/invite_friends_view.dart';
import 'package:plansync/views/theme/app_theme.dart';
import 'package:plansync/views/widgets/offline_banner.dart';
import 'package:provider/provider.dart';

class GroupDetailView extends StatefulWidget {
  const GroupDetailView({
    super.key,
    required this.group,
    required this.friendsViewModel,
  });

  final Group group;
  final FriendsViewModel friendsViewModel;

  @override
  State<GroupDetailView> createState() => _GroupDetailViewState();
}

class _GroupDetailViewState extends State<GroupDetailView> {
  Stream<List<User>>? _membersStream;

  void _openInviteFriends() {
    final groupVm = context.read<CrewViewmodel>();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: groupVm),
            ChangeNotifierProvider.value(value: widget.friendsViewModel),
          ],
          child: InviteFriendsView(group: widget.group),
        ),
      ),
    );
  }

  void _openOurOutings() {
    final uid = context.read<User>().id;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ChangeNotifierProvider(
          create: (_) => GroupOutingsViewModel(
            groupId: widget.group.id,
            uid: uid,
          ),
          child: GroupOutingsView(group: widget.group),
        ),
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _membersStream ??= context.read<CrewViewmodel>().watchMembersForGroup(
      widget.group.id,
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<CrewViewmodel>();
    final memberCount = vm.memberCountFor(widget.group.id);
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final online = context.watch<ConnectivityViewModel>().isOnline;

    return ColoredBox(
      color: colors.surface,
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
                      'Your Groups',
                      style: TextStyle(
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
          Divider(height: 1, color: colors.outline),
          if (!online)
            const OfflineBanner(
              message: "You're offline. Showing members as last saved.",
            ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(28, 32, 28, 32),
              children: [
                Text(
                  widget.group.name,
                  style: text.headlineLarge?.copyWith(
                    color: colors.onSurface,
                    fontSize: 42,
                    height: 1.25,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (vm.isWaitingToSync(widget.group.id)) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Waiting to sync',
                    style: text.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  memberCount == 0
                      ? 'Active group'
                      : 'Active group · $memberCount members',
                  style: text.bodyLarge?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
                if (widget.group.description.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    widget.group.description,
                    style: text.bodyMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                _OurOutingsEntry(onTap: _openOurOutings),
                const SizedBox(height: 24),
                StreamBuilder<List<User>>(
                  stream: _membersStream,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Text(
                        'Could not load group members. Check your connection and try again.',
                      );
                    }
                    final members = snapshot.data ?? const <User>[];
                    return Wrap(
                      spacing: 14,
                      runSpacing: 16,
                      children: [
                        for (var index = 0; index < members.length; index++)
                          _MemberTile(
                            user: members[index],
                            color: _memberColor(index),
                          ),
                        _InviteTile(onTap: _openInviteFriends),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _memberColor(int index) => switch (index % 3) {
    0 => AppTheme.coral,
    1 => const Color(0xFFFF9467),
    _ => const Color(0xFFFFD7AE),
  };
}

class _OurOutingsEntry extends StatelessWidget {
  const _OurOutingsEntry({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Material(
      color: colors.surfaceContainerLow,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: colors.outline),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: colors.primaryContainer,
                foregroundColor: colors.onPrimaryContainer,
                child: const Icon(Icons.history),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Our outings',
                      style: text.titleMedium?.copyWith(
                        color: colors.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'See what your group has done together',
                      style: text.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: colors.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

class _MemberTile extends StatelessWidget {
  const _MemberTile({required this.user, required this.color});

  final User user;
  final Color color;

  String _initials() {
    final words = '${user.name} ${user.lastName}'
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .toList();
    final initials = words.take(2).map((word) => word[0].toUpperCase()).join();
    return initials.isEmpty ? '?' : initials;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final fullName = '${user.name} ${user.lastName}'.trim();
    final name = fullName.isEmpty ? 'Member' : fullName;

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
              _initials(),
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
  const _InviteTile({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return SizedBox(
      width: 70,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Column(
            children: [
              Container(
                width: 52,
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: colors.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.person_add_alt_1,
                  color: colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Invite',
                style: text.bodySmall?.copyWith(color: colors.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Material(
      color: colors.surface,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(Icons.arrow_back, size: 20, color: colors.onSurface),
        ),
      ),
    );
  }
}
