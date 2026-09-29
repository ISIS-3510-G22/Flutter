import 'dart:async';

import 'package:flutter/material.dart';
import 'package:plansync/models/user.dart';
import 'package:plansync/theme/app_theme.dart';
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
                        'Search for someone by username.',
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
