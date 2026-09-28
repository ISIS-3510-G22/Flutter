import 'package:flutter/material.dart';
import 'package:plansync/models/group.dart';
import 'package:plansync/models/user.dart';
import 'package:plansync/theme/app_theme.dart';
import 'package:plansync/viewmodels/crew/group_viewmodel.dart';
import 'package:provider/provider.dart';

class GroupDetailView extends StatefulWidget {
  const GroupDetailView({super.key, required this.group});

  final Group group;

  @override
  State<GroupDetailView> createState() => _GroupDetailViewState();
}

class _GroupDetailViewState extends State<GroupDetailView> {
  Future<List<User>>? _membersFuture;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _membersFuture ??= context.read<CrewViewmodel>().membersForGroup(
      widget.group.id,
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<CrewViewmodel>();
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
                  widget.group.name,
                  style: text.headlineLarge?.copyWith(
                    color: colors.onSurface,
                    fontSize: 42,
                    height: 1.25,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                FutureBuilder<List<User>>(
                  future: _membersFuture,
                  builder: (context, snapshot) {
                    final count = snapshot.hasData
                        ? snapshot.data!.length
                        : vm.memberCountFor(widget.group.id);
                    final summary = count == 0
                        ? 'Active group'
                        : 'Active group · $count members';
                    return Text(
                      summary,
                      style: text.bodyLarge?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    );
                  },
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
                FutureBuilder<List<User>>(
                  future: _membersFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Text(
                        'Could not load group members: ${snapshot.error}',
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
                        const _InviteTile(),
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
    return words.take(2).map((word) => word[0].toUpperCase()).join();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final name = '${user.name} ${user.lastName}'.trim();

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
