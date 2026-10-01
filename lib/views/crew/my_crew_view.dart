import 'package:flutter/material.dart';
import 'package:plansync/models/group.dart';
import 'package:plansync/models/user.dart';
import 'package:plansync/theme/app_theme.dart';
import 'package:plansync/viewmodels/crew/friend_viewmodel.dart';
import 'package:plansync/viewmodels/crew/group_viewmodel.dart';
import 'package:plansync/views/crew/add_friend_view.dart';
import 'package:plansync/views/crew/create_group_view.dart';
import 'package:plansync/views/crew/friend_detail_view.dart';
import 'package:plansync/views/crew/friend_request_view.dart';
import 'package:plansync/views/crew/group_detail_view.dart';
import 'package:plansync/views/crew/group_invite_view.dart';
import 'package:plansync/views/widgets/crew_friends_card.dart';
import 'package:plansync/views/widgets/crew_group_card.dart';
import 'package:plansync/views/widgets/tab_button.dart';
import 'package:plansync/views/widgets/view_header.dart';
import 'package:provider/provider.dart';

class MyCrewView extends StatelessWidget {
  const MyCrewView({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = context.read<User>().id;

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CrewViewmodel(uid)),
        ChangeNotifierProvider(create: (_) => FriendsViewModel(uid)),
      ],
      child: const _MyCrewContent(),
    );
  }
}

class _MyCrewContent extends StatefulWidget {
  const _MyCrewContent();

  @override
  State<_MyCrewContent> createState() => _MyCrewContentState();
}

class _MyCrewContentState extends State<_MyCrewContent> {
  bool _showGroups = true;

  void _openAddFriend() {
    final friendsVm = context.read<FriendsViewModel>();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ChangeNotifierProvider.value(
          value: friendsVm,
          child: const AddFriendView(),
        ),
      ),
    );
  }

  void _openFriendRequests() {
    final friendsVm = context.read<FriendsViewModel>();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ChangeNotifierProvider.value(
          value: friendsVm,
          child: const FriendRequestView(),
        ),
      ),
    );
  }

  Future<void> _createGroup(CrewViewmodel vm) async {
    final friendsVm = context.read<FriendsViewModel>();
    final group = await Navigator.of(context).push<Group>(
      MaterialPageRoute<Group>(
        builder: (_) => ChangeNotifierProvider.value(
          value: vm,
          child: const CreateGroupView(),
        ),
      ),
    );
    if (group == null || !mounted) return;

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: vm),
            ChangeNotifierProvider.value(value: friendsVm),
          ],
          child: GroupDetailView(group: group),
        ),
      ),
    );
  }

  Future<void> _openInvitations(CrewViewmodel vm) async {
    final friendsVm = context.read<FriendsViewModel>();
    final group = await Navigator.of(context).push<Group>(
      MaterialPageRoute<Group>(
        builder: (_) => ChangeNotifierProvider.value(
          value: vm,
          child: const GroupInviteView(),
        ),
      ),
    );
    if (group == null || !mounted) return;

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: vm),
            ChangeNotifierProvider.value(value: friendsVm),
          ],
          child: GroupDetailView(group: group),
        ),
      ),
    );
  }

  void _openGroup(CrewViewmodel vm, Group group) {
    final friendsVm = context.read<FriendsViewModel>();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: vm),
            ChangeNotifierProvider.value(value: friendsVm),
          ],
          child: GroupDetailView(group: group),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<CrewViewmodel>();
    final colors = Theme.of(context).colorScheme;

    return ColoredBox(
      color: colors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const ViewHeader(title: 'My Crew'),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TabTrack(
              children: [
                TabButton(
                  label: 'My Groups',
                  selected: _showGroups,
                  onPressed: () => setState(() => _showGroups = true),
                ),
                TabButton(
                  label: 'My Friends',
                  selected: !_showGroups,
                  onPressed: () => setState(() => _showGroups = false),
                ),
              ],
            ),
          ),
          Expanded(
            child: _showGroups
                ? vm.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : vm.error != null
                      ? Center(child: Text(vm.error!))
                      : _GroupsList(
                          groups: vm.groups,
                          memberCountFor: vm.memberCountFor,
                          onGroupTap: (group) => _openGroup(vm, group),
                        )
                : const _FriendsList(),
          ),
          _showGroups
              ? Padding(
                  padding: const EdgeInsets.fromLTRB(36, 8, 36, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 46,
                          child: FilledButton(
                            onPressed: () => _openInvitations(vm),
                            style: FilledButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: Text(
                              'Invitations (${vm.invitations.length})',
                              style: Theme.of(context).textTheme.labelLarge!
                                  .copyWith(color: AppTheme.white),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SizedBox(
                          height: 46,
                          child: FilledButton(
                            onPressed: () => _createGroup(vm),
                            style: FilledButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: Text(
                              'Create Group',
                              style: Theme.of(context).textTheme.labelLarge!
                                  .copyWith(color: AppTheme.white),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.fromLTRB(36, 8, 36, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 46,
                          child: FilledButton(
                            onPressed: _openFriendRequests,
                            style: FilledButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: Text(
                              'Requests',
                              style: Theme.of(context).textTheme.labelLarge!
                                  .copyWith(color: AppTheme.white),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SizedBox(
                          height: 46,
                          child: FilledButton(
                            onPressed: _openAddFriend,
                            style: FilledButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: Text(
                              'Add Friends',
                              style: Theme.of(context).textTheme.labelLarge!
                                  .copyWith(color: AppTheme.white),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
        ],
      ),
    );
  }
}

class _GroupsList extends StatelessWidget {
  const _GroupsList({
    required this.groups,
    required this.memberCountFor,
    required this.onGroupTap,
  });

  final List<Group> groups;
  final int Function(String groupId) memberCountFor;
  final ValueChanged<Group> onGroupTap;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(34, 2, 34, 12),
      children: groups.isEmpty
          ? const [
              Padding(
                padding: EdgeInsets.only(top: 48),
                child: Center(child: Text('You have no groups yet')),
              ),
            ]
          : [
              for (var index = 0; index < groups.length; index++) ...[
                CrewGroupCard(
                  name: groups[index].name,
                  memberCount: memberCountFor(groups[index].id),
                  avatarCount: memberCountFor(groups[index].id) < 3
                      ? memberCountFor(groups[index].id)
                      : 3,
                  overflowCount: memberCountFor(groups[index].id) > 3
                      ? memberCountFor(groups[index].id) - 3
                      : null,
                  onTap: () => onGroupTap(groups[index]),
                ),
                if (index != groups.length - 1) const SizedBox(height: 28),
              ],
            ],
    );
  }
}

class _FriendsList extends StatelessWidget {
  const _FriendsList();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<FriendsViewModel>();

    if (vm.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (vm.error != null) {
      return Center(child: Text(vm.error!));
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
      itemCount: vm.friends.length,
      separatorBuilder: (_, _) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        final friend = vm.friends[index];

        return CrewFriendsCard(
          name: '${friend.name} ${friend.lastName}'.trim(),
          email: friend.email,
          initials:
              '${friend.name.isNotEmpty ? friend.name[0] : ''}'
              '${friend.lastName.isNotEmpty ? friend.lastName[0] : ''}',
          avatarColors: const Color(0xFFFFB5A6),
          photoUrl: friend.photoUrl,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => FriendDetailView(friend: friend),
              ),
            );
          },
        );
      },
    );
  }
}
