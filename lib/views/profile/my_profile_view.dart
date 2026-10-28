import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:plansync/model/data/pending_write_repository.dart';
import 'package:plansync/model/models/user.dart';
import 'package:plansync/model/services/theme_service.dart';
import 'package:plansync/viewmodels/global/connectivity_viewmodel.dart';
import 'package:plansync/viewmodels/profile/profile_viewmodel.dart';
import 'package:plansync/views/profile/edit_profile_view.dart';
import 'package:plansync/views/widgets/image_source_sheet.dart';
import 'package:plansync/views/widgets/offline_banner.dart';
import 'package:plansync/views/widgets/view_header.dart';
import 'package:plansync/views/widgets/waiting_to_sync.dart';
import 'package:provider/provider.dart';

class MyProfileView extends StatelessWidget {
  const MyProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => ProfileViewModel(context.read<User>()),
      child: const _MyProfileBody(),
    );
  }
}

class _MyProfileBody extends StatelessWidget {
  const _MyProfileBody();

  Future<void> _signOut(BuildContext context, ProfileViewModel vm) async {
    final warning = vm.signOutWarning;
    if (warning != null) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Log out?'),
          content: Text(warning),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Log out'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }
    await vm.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ProfileViewModel>();
    final online = context.watch<ConnectivityViewModel>().isOnline;
    final pending = context
        .watch<PendingWriteRepository>()
        .pendingDocIds
        .contains(vm.user.id);
    final themeService = context.watch<ThemeService>();
    final colors = Theme.of(context).colorScheme;

    final placeholder = Icon(
      Icons.person_outline,
      size: 48,
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );

    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(child: ViewHeader(title: 'Profile')),
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => EditProfileView(user: vm.user),
                    ),
                  );
                  if (context.mounted) await vm.refreshUser();
                },
              ),
              const SizedBox(width: 4),
            ],
          ),
          if (!online)
            const OfflineBanner(
              message: "You're offline. Showing your saved profile.",
            ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const Spacer(),
                  GestureDetector(
                    onTap: vm.isUploadingPhoto
                        ? null
                        : () async {
                            final messenger = ScaffoldMessenger.of(context);
                            final source = await showImageSourceSheet(context);
                            if (source == null) return;
                            final queued = await vm.pickAndUploadPhoto(source);
                            if (!queued) return;
                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text(
                                  "Photo saved on your phone. Friends will see it when you're back online.",
                                ),
                              ),
                            );
                          },
                    child: Stack(
                      children: [
                        Container(
                          width: 96,
                          height: 96,
                          clipBehavior: Clip.antiAlias,
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: vm.isUploadingPhoto
                              ? const Center(child: CircularProgressIndicator())
                              : vm.localPhotoPath != null
                              ? Image.file(
                                  File(vm.localPhotoPath!),
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) => placeholder,
                                )
                              : vm.user.photoUrl == null
                              ? placeholder
                              : Image(
                                  image: CachedNetworkImageProvider(
                                    vm.user.photoUrl!,
                                  ),
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) => placeholder,
                                ),
                        ),
                        if (!vm.isUploadingPhoto)
                          Positioned(
                            right: 4,
                            bottom: 4,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: colors.primary,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: colors.surface,
                                  width: 2,
                                ),
                              ),
                              child: Icon(
                                Icons.photo_camera_outlined,
                                size: 14,
                                color: colors.onPrimary,
                                semanticLabel: 'Change photo',
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (pending) ...[
                    const SizedBox(height: 8),
                    const WaitingToSync(),
                  ],
                  const SizedBox(height: 16),
                  Text(
                    '${vm.user.name} ${vm.user.lastName}',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    vm.user.email,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 24),
                  SegmentedButton<ThemePreference>(
                    segments: const [
                      ButtonSegment(
                        value: ThemePreference.system,
                        label: Text('System'),
                      ),
                      ButtonSegment(
                        value: ThemePreference.light,
                        label: Text('Light'),
                      ),
                      ButtonSegment(
                        value: ThemePreference.dark,
                        label: Text('Dark'),
                      ),
                      ButtonSegment(
                        value: ThemePreference.auto,
                        label: Text('Auto'),
                      ),
                    ],
                    selected: {themeService.preference},
                    onSelectionChanged: (selection) =>
                        themeService.setPreference(selection.first),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton(
                      onPressed: () => _signOut(context, vm),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Log Out', style: TextStyle(fontSize: 16)),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(flex: 2),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
