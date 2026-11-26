import 'package:flutter/material.dart';
import 'package:plansync/model/models/group.dart';
import 'package:plansync/model/models/group_history.dart';
import 'package:plansync/model/models/group_outing.dart';
import 'package:plansync/model/models/user.dart';
import 'package:plansync/viewmodels/crew/group_outings_viewmodel.dart';
import 'package:plansync/viewmodels/global/connectivity_viewmodel.dart';
import 'package:plansync/views/formatters/date_format.dart';
import 'package:plansync/views/widgets/avatar.dart';
import 'package:plansync/views/widgets/offline_banner.dart';
import 'package:provider/provider.dart';

class GroupOutingsView extends StatelessWidget {
  const GroupOutingsView({super.key, required this.group});

  final Group group;

  @override
  Widget build(BuildContext context) {
    final online = context.watch<ConnectivityViewModel>().isOnline;
    final vm = context.watch<GroupOutingsViewModel>();
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final history = vm.history;

    return Scaffold(
      backgroundColor: colors.surface,
      body: Column(
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
                      'Our outings',
                      style: text.titleLarge?.copyWith(
                        color: colors.onSurface,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.arrow_back),
                        style: IconButton.styleFrom(
                          backgroundColor: colors.surfaceContainerHighest,
                          foregroundColor: colors.onSurface,
                          shape: const CircleBorder(),
                        ),
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
              message:
                  "You're offline. Showing this group's outings as last saved.",
            ),
          Expanded(
            child: vm.isLoading
                ? const Center(child: CircularProgressIndicator())
                : _body(context, vm, history, online),
          ),
        ],
      ),
    );
  }

  Widget _body(
    BuildContext context,
    GroupOutingsViewModel vm,
    GroupHistory? history,
    bool online,
  ) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    if (history == null) {
      final message = online
          ? 'Could not load this group’s outings. Please try again.'
          : 'Connect to see this group’s outings.';
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                message,
                textAlign: TextAlign.center,
                style: text.bodyLarge?.copyWith(color: colors.onSurfaceVariant),
              ),
              if (online) ...[
                const SizedBox(height: 16),
                OutlinedButton(onPressed: vm.load, child: const Text('Retry')),
              ],
            ],
          ),
        ),
      );
    }

    if (online && history.outings.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            'No outings with this group yet',
            textAlign: TextAlign.center,
            style: text.bodyLarge?.copyWith(color: colors.onSurfaceVariant),
          ),
        ),
      );
    }

    final latest = history.lastOuting;
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
      children: [
        Text(
          group.name,
          style: text.headlineLarge?.copyWith(
            color: colors.onSurface,
            fontSize: 34,
            height: 1.2,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${history.outings.length} '
          '${history.outings.length == 1 ? 'outing' : 'outings'} together',
          style: text.bodyLarge?.copyWith(color: colors.onSurfaceVariant),
        ),
        if (latest != null) ...[
          const SizedBox(height: 4),
          Text(
            'Last outing · ${formatShortDate(latest.date)}',
            style: text.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
          ),
        ],
        const SizedBox(height: 28),
        Text(
          'Most present',
          style: text.titleLarge?.copyWith(
            color: colors.onSurface,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        if (history.attendanceRanking.isEmpty)
          Text(
            'No attendance to rank yet.',
            style: text.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
          )
        else
          for (var index = 0; index < history.attendanceRanking.length; index++)
            _AttendanceTile(
              rank: index + 1,
              attendance: history.attendanceRanking[index],
              user: vm.memberFor(history.attendanceRanking[index].userId),
            ),
        const SizedBox(height: 28),
        Text(
          'Outings',
          style: text.titleLarge?.copyWith(
            color: colors.onSurface,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        for (final outing in history.outings)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _OutingCard(outing: outing, viewModel: vm),
          ),
      ],
    );
  }
}

class _AttendanceTile extends StatelessWidget {
  const _AttendanceTile({
    required this.rank,
    required this.attendance,
    required this.user,
  });

  final int rank;
  final GroupMemberAttendance attendance;
  final User? user;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final name = user == null
        ? 'Member'
        : '${user!.name} ${user!.lastName}'.trim();

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text(
              '$rank.',
              style: text.labelLarge?.copyWith(color: colors.onSurfaceVariant),
            ),
          ),
          _PersonAvatar(user: user, userId: attendance.userId),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name.isEmpty ? 'Member' : name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: text.bodyLarge?.copyWith(color: colors.onSurface),
            ),
          ),
          Text(
            '${attendance.outingCount} '
            '${attendance.outingCount == 1 ? 'outing' : 'outings'}',
            style: text.bodySmall?.copyWith(color: colors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _OutingCard extends StatelessWidget {
  const _OutingCard({required this.outing, required this.viewModel});

  final GroupOuting outing;
  final GroupOutingsViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final attendeeIds = outing.attendingMemberIds;
    final visibleIds = attendeeIds.take(5).toList();
    final overflow = attendeeIds.length - visibleIds.length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        border: Border.all(color: colors.outline),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            outing.name,
            style: text.titleMedium?.copyWith(
              color: colors.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            formatShortDate(outing.date),
            style: text.bodySmall?.copyWith(color: colors.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              for (final userId in visibleIds)
                _PersonAvatar(
                  user: viewModel.memberFor(userId),
                  userId: userId,
                ),
              if (overflow > 0)
                CircleAvatar(
                  radius: 16,
                  backgroundColor: colors.primaryContainer,
                  child: Text(
                    '+$overflow',
                    style: text.labelSmall?.copyWith(
                      color: colors.onPrimaryContainer,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PersonAvatar extends StatelessWidget {
  const _PersonAvatar({required this.user, required this.userId});

  final User? user;
  final String userId;

  @override
  Widget build(BuildContext context) {
    final photoUrl = user?.photoUrl?.trim();
    if (photoUrl != null && photoUrl.isNotEmpty) {
      return UserAvatar(photoUrl: photoUrl);
    }

    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final initials = _initials(user, userId);
    return CircleAvatar(
      radius: 16,
      backgroundColor: colors.primaryContainer,
      child: Text(
        initials,
        style: text.labelSmall?.copyWith(color: colors.onPrimaryContainer),
      ),
    );
  }

  String _initials(User? user, String fallbackId) {
    final words = '${user?.name ?? ''} ${user?.lastName ?? ''}'
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .toList();
    if (words.isEmpty) {
      return fallbackId.isEmpty ? '?' : fallbackId[0].toUpperCase();
    }
    return words.take(2).map((word) => word[0].toUpperCase()).join();
  }
}
