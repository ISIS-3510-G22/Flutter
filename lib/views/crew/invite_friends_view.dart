import 'package:flutter/material.dart';
import 'package:plansync/models/group.dart';
import 'package:plansync/models/user.dart';
import 'package:plansync/theme/app_theme.dart';
import 'package:plansync/viewmodels/crew/friend_viewmodel.dart';
import 'package:plansync/viewmodels/crew/group_viewmodel.dart';
import 'package:plansync/views/widgets/crew_friends_card.dart';
import 'package:provider/provider.dart';

class InviteFriendsView extends StatefulWidget {
  const InviteFriendsView({super.key, required this.group});

  final Group group;

  @override
  State<InviteFriendsView> createState() => _InviteFriendsViewState();
}

class _InviteFriendsViewState extends State<InviteFriendsView> {
  Future<List<User>>? _membersFuture;
  Future<Set<String>>? _pendingInvitesFuture;
  final Set<String> _busyUserIds = {};
  final Set<String> _sentUserIds = {};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final groupVm = context.read<CrewViewmodel>();
    _membersFuture ??= groupVm.membersForGroup(widget.group.id);
    _pendingInvitesFuture ??= groupVm.pendingInviteeIdsForGroup(
      widget.group.id,
    );
  }

  Future<void> _invite(User friend) async {
    setState(() => _busyUserIds.add(friend.id));
    final success = await context.read<CrewViewmodel>().inviteFriend(
      widget.group.id,
      friend.id,
    );
    if (!mounted) return;

    setState(() {
      _busyUserIds.remove(friend.id);
      if (success) _sentUserIds.add(friend.id);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Invitation sent to ${friend.name}.'
              : context.read<CrewViewmodel>().error ??
                    'Could not send the invitation.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final friendsVm = context.watch<FriendsViewModel>();
    final colors = Theme.of(context).colorScheme;

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
        title: const Text('Invite Friends'),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: colors.outline),
        ),
      ),
      body: friendsVm.isLoading
          ? const Center(child: CircularProgressIndicator())
          : friendsVm.error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(friendsVm.error!, textAlign: TextAlign.center),
              ),
            )
          : FutureBuilder<List<User>>(
              future: _membersFuture,
              builder: (context, membersSnapshot) {
                if (membersSnapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (membersSnapshot.hasError) {
                  return Center(
                    child: Text(
                      'Could not load group members: ${membersSnapshot.error}',
                    ),
                  );
                }
                final memberIds = (membersSnapshot.data ?? const <User>[])
                    .map((user) => user.id)
                    .toSet();

                return FutureBuilder<Set<String>>(
                  future: _pendingInvitesFuture,
                  builder: (context, invitationsSnapshot) {
                    if (invitationsSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (invitationsSnapshot.hasError) {
                      return Center(
                        child: Text(
                          'Could not load pending invitations: ${invitationsSnapshot.error}',
                        ),
                      );
                    }
                    final invitedIds = invitationsSnapshot.data ?? <String>{};
                    if (friendsVm.friends.isEmpty) {
                      return const Center(
                        child: Text(
                          'Add friends before inviting them to a group.',
                        ),
                      );
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                      itemCount: friendsVm.friends.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 14),
                      itemBuilder: (context, index) {
                        final friend = friendsVm.friends[index];
                        final isMember = memberIds.contains(friend.id);
                        final isInvited =
                            invitedIds.contains(friend.id) ||
                            _sentUserIds.contains(friend.id);
                        final isBusy = _busyUserIds.contains(friend.id);
                        final initials =
                            '${friend.name.isNotEmpty ? friend.name[0] : ''}'
                            '${friend.lastName.isNotEmpty ? friend.lastName[0] : ''}';

                        return CrewFriendsCard(
                          name: '${friend.name} ${friend.lastName}'.trim(),
                          email: '@${friend.username}',
                          initials: initials.isEmpty
                              ? '?'
                              : initials.toUpperCase(),
                          avatarColors: const Color(0xFFFFB5A6),
                          photoUrl: friend.photoUrl,
                          trailing: FilledButton(
                            onPressed: isMember || isInvited || isBusy
                                ? null
                                : () => _invite(friend),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppTheme.coral,
                              foregroundColor: AppTheme.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                              ),
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
                                : Text(
                                    isMember
                                        ? 'Member'
                                        : isInvited
                                        ? 'Invited'
                                        : 'Invite',
                                  ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
    );
  }
}
