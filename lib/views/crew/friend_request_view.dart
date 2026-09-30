import 'package:flutter/material.dart';
import 'package:plansync/models/friend_request.dart';
import 'package:plansync/models/user.dart';
import 'package:plansync/theme/app_theme.dart';
import 'package:plansync/viewmodels/crew/friend_viewmodel.dart';
import 'package:provider/provider.dart';

class FriendRequestView extends StatelessWidget {
  const FriendRequestView({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<FriendsViewModel>();
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

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
        title: const Text('Friend Invites'),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: colors.outline),
        ),
      ),
      body: vm.areRequestsLoading
          ? const Center(child: CircularProgressIndicator())
          : vm.requestError != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(vm.requestError!, textAlign: TextAlign.center),
              ),
            )
          : vm.pendingRequests.isEmpty
          ? Center(
              child: Text(
                'No friend requests yet.',
                style: text.bodyLarge?.copyWith(color: colors.onSurfaceVariant),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
              itemCount: vm.pendingRequests.length,
              separatorBuilder: (_, _) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final request = vm.pendingRequests[index];
                final requester = vm.requesterFor(request);
                return _FriendRequestCard(
                  request: request,
                  requester: requester,
                );
              },
            ),
    );
  }
}

class _FriendRequestCard extends StatelessWidget {
  const _FriendRequestCard({required this.request, this.requester});

  final FriendRequest request;
  final User? requester;

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<FriendsViewModel>();
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final isBusy = vm.isBusy(request.id);
    final name = requester == null
        ? 'Unknown user'
        : '${requester!.name} ${requester!.lastName}'.trim();
    final username = requester?.username;

    Future<void> respond(Future<void> Function() action) async {
      await action();
      if (!context.mounted) return;
      final error = context.read<FriendsViewModel>().error;
      if (error != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error)));
      }
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        border: Border.all(color: colors.outline),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F000000),
            blurRadius: 7,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFFFB5A6),
              border: Border.all(color: AppTheme.coral, width: 1.5),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(
              Icons.person_outline,
              color: colors.onSurface,
              size: 24,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            name.isEmpty ? 'Friend request' : name,
            style: text.titleLarge?.copyWith(
              color: colors.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (username != null && username.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              '@$username',
              style: text.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
            ),
          ],
          const SizedBox(height: 26),
          Row(
            children: [
              Expanded(
                child: _ResponseButton(
                  label: 'Accept',
                  icon: Icons.check,
                  color: const Color(0xFF2FC65D),
                  isBusy: isBusy,
                  onPressed: isBusy
                      ? null
                      : () => respond(
                          () => context.read<FriendsViewModel>().acceptRequest(
                            request,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 2),
              Expanded(
                child: _ResponseButton(
                  label: 'Deny',
                  icon: Icons.close,
                  color: const Color(0xFFFF1010),
                  isBusy: isBusy,
                  onPressed: isBusy
                      ? null
                      : () => respond(
                          () => context.read<FriendsViewModel>().denyRequest(
                            request,
                          ),
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

class _ResponseButton extends StatelessWidget {
  const _ResponseButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.isBusy,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final Color color;
  final bool isBusy;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: color,
        foregroundColor: AppTheme.white,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        minimumSize: const Size(0, 42),
        shape: const StadiumBorder(),
      ),
      child: isBusy
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppTheme.white,
              ),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 22),
                const SizedBox(width: 8),
                Text(label),
              ],
            ),
    );
  }
}
