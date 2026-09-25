import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:plansync/models/user.dart';
import 'package:plansync/services/auth_service.dart';
import 'package:plansync/viewmodels/profile/profile_viewmodel.dart';
import 'package:plansync/views/profile/edit_profile_view.dart';
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

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ProfileViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => EditProfileView(user: vm.user)),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            const Spacer(),
            GestureDetector(
              onTap: vm.isUploadingPhoto
                  ? null
                  : () => _showPhotoSourceSheet(context, vm),
              child: Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(16),
                  image: vm.user.photoUrl != null
                      ? DecorationImage(
                          image: NetworkImage(vm.user.photoUrl!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: vm.isUploadingPhoto
                    ? const Center(child: CircularProgressIndicator())
                    : null,
              ),
            ),
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
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                onPressed: AuthService().signOut,
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
    );
  }

  void _showPhotoSourceSheet(BuildContext context, ProfileViewModel vm) {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take photo'),
              onTap: () {
                Navigator.pop(context);
                vm.pickAndUploadPhoto(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () {
                Navigator.pop(context);
                vm.pickAndUploadPhoto(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }
}
