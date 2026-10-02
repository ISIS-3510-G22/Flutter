import 'dart:async';

import 'package:flutter/material.dart';
import 'package:plansync/models/user.dart';
import 'package:plansync/theme/app_theme.dart';
import 'package:plansync/viewmodels/crew/bluetooth_friend_viewmodel.dart';
import 'package:plansync/viewmodels/crew/friend_viewmodel.dart';
import 'package:plansync/views/widgets/crew_friends_card.dart';
import 'package:provider/provider.dart';

class AddFriendView extends StatefulWidget {
  const AddFriendView({super.key});

  @override
  State<AddFriendView> createState() => _AddFriendViewState();
}

class _AddFriendViewState extends State<AddFriendView> {
  final _searchController = TextEditingController();
  Timer? _debounce;

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) context.read<FriendsViewModel>().searchUsers(value);
    });
  }

  Future<void> _openBluetoothInvites() async {
    final userId = context.read<User>().id;
    final friendsViewModel = context.read<FriendsViewModel>();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: friendsViewModel),
          ChangeNotifierProvider(
            create: (_) => BluetoothFriendViewModel(userId: userId),
          ),
        ],
        child: const _BluetoothInviteSheet(),
      ),
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<FriendsViewModel>();
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colors.surface,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              height: 68,
              padding: const EdgeInsets.symmetric(horizontal: 22),
              decoration: BoxDecoration(
                color: colors.surface,
                border: Border(bottom: BorderSide(color: colors.outline)),
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.arrow_back),
                    style: IconButton.styleFrom(
                      backgroundColor: colors.secondaryContainer,
                      fixedSize: const Size(42, 42),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Find Friends',
                      textAlign: TextAlign.center,
                      style: text.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colors.onSurface,
                      ),
                    ),
                  ),
                  const SizedBox(width: 42),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                children: [
                  TextField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: 'Search by name or username...',
                      prefixIcon: const Icon(Icons.search, size: 27),
                      filled: true,
                      fillColor: colors.surface,
                      contentPadding: const EdgeInsets.symmetric(vertical: 17),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide(color: colors.outline),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide(color: colors.outline),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _openBluetoothInvites,
                      icon: const Icon(Icons.bluetooth_searching),
                      label: const Text('Find friends nearby with Bluetooth'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.coral,
                        side: const BorderSide(color: AppTheme.coral),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'SEARCH RESULTS',
                    style: text.labelLarge?.copyWith(
                      color: colors.onSurfaceVariant,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (_searchController.text.trim().isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'Search for someone by name or username.',
                        style: text.bodyMedium?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    )
                  else if (vm.isSearching)
                    const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (vm.error != null)
                    Text(vm.error!, style: text.bodyMedium)
                  else if (vm.searchResults.isEmpty)
                    Text(
                      'No users found.',
                      style: text.bodyMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    )
                  else
                    ...vm.searchResults.map(
                      (user) => Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: _SearchResultCard(user: user),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BluetoothInviteSheet extends StatefulWidget {
  const _BluetoothInviteSheet();

  @override
  State<_BluetoothInviteSheet> createState() => _BluetoothInviteSheetState();
}

class _BluetoothInviteSheetState extends State<_BluetoothInviteSheet> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<BluetoothFriendViewModel>().start();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return FractionallySizedBox(
      heightFactor: 0.82,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.outline,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 12, 10),
                child: Row(
                  children: [
                    Icon(Icons.bluetooth, color: AppTheme.coral),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Invite a nearby friend',
                            style: text.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Both phones need this screen open.',
                            style: text.bodySmall?.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Close',
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: colors.outline),
              Consumer<BluetoothFriendViewModel>(
                builder: (context, vm, _) {
                  if (vm.error != null) {
                    return Container(
                      width: double.infinity,
                      color: colors.errorContainer,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 10,
                      ),
                      child: Text(
                        vm.error!,
                        style: text.bodySmall?.copyWith(
                          color: colors.onErrorContainer,
                        ),
                      ),
                    );
                  }
                  if (vm.statusMessage != null) {
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(18, 10, 18, 0),
                      child: Text(
                        vm.statusMessage!,
                        style: text.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
              Expanded(
                child: Consumer<BluetoothFriendViewModel>(
                  builder: (context, vm, _) {
                    if (vm.isStarting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (vm.error != null && !vm.isActive) {
                      return _BluetoothEmptyState(
                        message: vm.error!,
                        action: FilledButton.icon(
                          onPressed: vm.start,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Try again'),
                        ),
                      );
                    }
                    if (!vm.isActive) {
                      return _BluetoothEmptyState(
                        message: 'Bluetooth scanning is stopped.',
                        action: FilledButton.icon(
                          onPressed: vm.start,
                          icon: const Icon(Icons.bluetooth_searching),
                          label: const Text('Start scanning'),
                        ),
                      );
                    }
                    if (vm.nearbyFriends.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(28),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const CircularProgressIndicator(),
                              const SizedBox(height: 18),
                              Text(
                                'Looking for nearby PlanSync users…',
                                textAlign: TextAlign.center,
                                style: text.bodyLarge?.copyWith(
                                  color: colors.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
                      itemCount: vm.nearbyFriends.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) => _NearbyFriendCard(
                        nearbyFriend: vm.nearbyFriends[index],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BluetoothEmptyState extends StatelessWidget {
  const _BluetoothEmptyState({required this.message, required this.action});

  final String message;
  final Widget action;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bluetooth_disabled, size: 42, color: colors.primary),
            const SizedBox(height: 14),
            Text(message, textAlign: TextAlign.center, style: text.bodyLarge),
            const SizedBox(height: 18),
            action,
          ],
        ),
      ),
    );
  }
}

class _NearbyFriendCard extends StatelessWidget {
  const _NearbyFriendCard({required this.nearbyFriend});

  final NearbyBluetoothFriend nearbyFriend;

  @override
  Widget build(BuildContext context) {
    final bluetoothVm = context.watch<BluetoothFriendViewModel>();
    final user = nearbyFriend.user;
    final friendVm = context.watch<FriendsViewModel>();
    final fullName = '${user.name} ${user.lastName}'.trim();
    final initials =
        '${user.name.isNotEmpty ? user.name[0] : ''}'
        '${user.lastName.isNotEmpty ? user.lastName[0] : ''}';
    final isBusy = bluetoothVm.isSendingTo(nearbyFriend.deviceId);
    final isFriend =
        bluetoothVm.isFriend(user.id) || friendVm.isFriend(user.id);
    final isPending =
        bluetoothVm.hasPendingRequestWith(user.id) ||
        friendVm.hasSentRequestTo(user.id) ||
        bluetoothVm.hasSentBluetoothRequestTo(user.id);

    return CrewFriendsCard(
      name: fullName.isEmpty ? user.username : fullName,
      email: '@${user.username}',
      initials: initials.isEmpty ? '?' : initials.toUpperCase(),
      avatarColors: const Color(0xFFFFB5A6),
      photoUrl: user.photoUrl,
      trailing: FilledButton(
        onPressed:
            isBusy ||
                bluetoothVm.isResolvingNearbyUsers ||
                isFriend ||
                isPending
            ? null
            : () => bluetoothVm.sendFriendRequest(nearbyFriend.deviceId),
        style: FilledButton.styleFrom(
          backgroundColor: AppTheme.coral,
          foregroundColor: AppTheme.white,
          padding: const EdgeInsets.symmetric(horizontal: 14),
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
                isFriend
                    ? 'Friends'
                    : isPending
                    ? 'Sent'
                    : 'Invite',
              ),
      ),
    );
  }
}

class _SearchResultCard extends StatelessWidget {
  const _SearchResultCard({required this.user});

  final User user;

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<FriendsViewModel>();
    final name = '${user.name} ${user.lastName}'.trim();
    final initials =
        '${user.name.isNotEmpty ? user.name[0] : ''}'
        '${user.lastName.isNotEmpty ? user.lastName[0] : ''}';
    final isBusy = vm.isBusy(user.id);
    final sent = vm.hasSentRequestTo(user.id);
    final friend = vm.isFriend(user.id);

    return CrewFriendsCard(
      name: name.isEmpty ? user.username : name,
      email: '@${user.username}',
      initials: initials.isEmpty ? '?' : initials.toUpperCase(),
      avatarColors: const Color(0xFFFFB5A6),
      photoUrl: user.photoUrl,
      trailing: FilledButton(
        onPressed: isBusy || sent || friend
            ? null
            : () async {
                await context.read<FriendsViewModel>().sendFriendRequest(
                  user.id,
                );
              },
        style: FilledButton.styleFrom(
          backgroundColor: AppTheme.coral,
          foregroundColor: AppTheme.white,
          disabledBackgroundColor: Theme.of(
            context,
          ).colorScheme.surfaceContainerHighest,
          disabledForegroundColor: Theme.of(
            context,
          ).colorScheme.onSurfaceVariant,
          padding: const EdgeInsets.symmetric(horizontal: 17),
          minimumSize: const Size(0, 42),
        ),
        child: isBusy
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(
                friend
                    ? 'Friends'
                    : sent
                    ? 'Sent'
                    : 'Request',
              ),
      ),
    );
  }
}
