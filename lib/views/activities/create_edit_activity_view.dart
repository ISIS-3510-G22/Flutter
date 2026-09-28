import 'package:flutter/material.dart';
import 'package:plansync/models/activity.dart';
import 'package:plansync/models/user.dart';
import 'package:plansync/utils/text_format.dart';
import 'package:plansync/viewmodels/activities/create_edit_activity_viewmodel.dart';
import 'package:plansync/views/widgets/activity_photo.dart';
import 'package:plansync/views/widgets/image_source_sheet.dart';
import 'package:plansync/views/widgets/tab_button.dart';
import 'package:provider/provider.dart';

class CreateEditActivityView extends StatelessWidget {
  const CreateEditActivityView({this.activity, super.key});

  final Activity? activity;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) =>
          CreateEditActivityViewmodel(context.read<User>().id, activity),
      child: const _CreateEditActivityForm(),
    );
  }
}

class _CreateEditActivityForm extends StatelessWidget {
  const _CreateEditActivityForm();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<CreateEditActivityViewmodel>();

    return Scaffold(
      appBar: AppBar(
        title: Text(vm.isEditing ? 'Edit Activity' : 'Create Activity'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () async {
                final source = await showImageSourceSheet(context);
                if (source != null) vm.pickPhoto(source);
              },
              child: vm.pickedPhoto != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.file(
                        vm.pickedPhoto!,
                        height: 180,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    )
                  : ActivityPhoto(
                      url: vm.currentPhotoUrl,
                      height: 180,
                      radius: 16,
                    ),
            ),
            const SizedBox(height: 16),
            const Text('PLACE NAME'),
            TextField(
              controller: vm.nameController,
              decoration: const InputDecoration(hintText: 'e.g. Dumbo House'),
            ),
            const SizedBox(height: 16),
            const Text('ADDRESS'),
            TextField(
              controller: vm.addressController,
              decoration: const InputDecoration(
                hintText: 'Address or location',
              ),
            ),
            const SizedBox(height: 16),
            const Text('EXPECTED PRICE'),
            TextField(
              controller: vm.expectedPriceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(hintText: 'e.g. 120,000'),
            ),
            const SizedBox(height: 16),
            const Text('TAGS'),
            const SizedBox(height: 8),
            if (vm.isLoadingTags)
              const Center(child: CircularProgressIndicator())
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: vm.tagOptions.map((name) {
                  return FilterChip(
                    label: Text(capitalize(name)),
                    selected: vm.tags.contains(name),
                    onSelected: (_) => vm.toggleTag(name),
                  );
                }).toList(),
              ),
            const SizedBox(height: 8),
            TextField(
              controller: vm.newTagController,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => vm.addNewTag(),
              decoration: InputDecoration(
                hintText: 'Add a new tag',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: vm.addNewTag,
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text('NOTES'),
            const SizedBox(height: 8),
            TextField(
              controller: vm.notesController,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Add notes for your group...',
              ),
            ),
            const SizedBox(height: 16),
            const Text('VISIBILITY'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TabButton(
                    label: 'Private',
                    selected:
                        vm.activityVisibility == ActivityVisibility.private,
                    onPressed: () =>
                        vm.selectVisibility(ActivityVisibility.private),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TabButton(
                    label: 'Public',
                    selected:
                        vm.activityVisibility == ActivityVisibility.public,
                    onPressed: () =>
                        vm.selectVisibility(ActivityVisibility.public),
                  ),
                ),
              ],
            ),
            if (vm.errorMessage != null) ...[
              const SizedBox(height: 16),
              Text(
                vm.errorMessage!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: vm.isLoading
                        ? null
                        : () async {
                            final saved = await vm.save();
                            if (saved != null && context.mounted) {
                              Navigator.pop(context, saved);
                            }
                          },
                    child: vm.isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(vm.isEditing ? 'Save Changes' : 'Save Activity'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
