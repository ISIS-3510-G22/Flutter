import 'package:flutter/material.dart';
import 'package:plansync/models/reimbursement_method.dart';
import 'package:plansync/models/user.dart';
import 'package:plansync/services/connectivity_service.dart';
import 'package:plansync/viewmodels/profile/edit_profile_viewmodel.dart';
import 'package:plansync/views/profile/add_reimbursment_method.dart';
import 'package:plansync/views/widgets/offline_banner.dart';
import 'package:provider/provider.dart';

class EditProfileView extends StatelessWidget {
  const EditProfileView({super.key, required this.user});

  final User user;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => EditProfileViewModel(user),
      child: const _EditProfileBody(),
    );
  }
}

class _EditProfileBody extends StatelessWidget {
  const _EditProfileBody();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<EditProfileViewModel>();
    final online = context.watch<ConnectivityService>().isOnline;

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: Column(
        children: [
          if (!online)
            const OfflineBanner(
              message:
                  "You're offline. Your changes will be saved on your phone and sent when you're back online.",
            ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Text(
                  'PERSONAL INFO',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: vm.nameController,
                  decoration: const InputDecoration(labelText: 'Full Name'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: vm.lastNameController,
                  decoration: const InputDecoration(labelText: 'Last Name'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: vm.phoneController,
                  decoration: const InputDecoration(labelText: 'Phone Number'),
                ),
                const SizedBox(height: 24),
                Text(
                  'REIMBURSEMENT METHODS',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
                const SizedBox(height: 8),
                for (final method in vm.reimbursementMethods)
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.account_balance_outlined),
                      title: Text(method.type),
                      subtitle: Text(method.account),
                      trailing: method == vm.reimbursementMethods.first
                          ? const Chip(label: Text('Primary'))
                          : null,
                    ),
                  ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () async {
                    final method = await Navigator.of(context)
                        .push<ReimbursementMethod>(
                          MaterialPageRoute(
                            builder: (_) => const AddReimbursementMethodView(),
                          ),
                        );
                    if (method != null) vm.addMethod(method);
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Add New Method'),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            Expanded(
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Discard'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: FilledButton(
                onPressed: vm.isSaving
                    ? null
                    : () async {
                        final messenger = ScaffoldMessenger.of(context);
                        final success = await vm.saveChanges();
                        if (!success || !context.mounted) return;
                        Navigator.of(context).pop();
                        if (vm.queued) {
                          messenger.showSnackBar(
                            const SnackBar(
                              content: Text(
                                "Profile saved on your phone. Friends see the change when you're back online.",
                              ),
                            ),
                          );
                        }
                      },
                child: vm.isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save Changes'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
