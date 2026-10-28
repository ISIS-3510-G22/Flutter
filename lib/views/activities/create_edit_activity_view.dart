import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:plansync/model/models/activity.dart';
import 'package:plansync/model/models/place.dart';
import 'package:plansync/model/models/user.dart';
import 'package:plansync/viewmodels/global/connectivity_viewmodel.dart';
import 'package:plansync/viewmodels/activities/create_edit_activity_viewmodel.dart';
import 'package:plansync/views/formatters/text_format.dart';
import 'package:plansync/views/widgets/activity_photo.dart';
import 'package:plansync/views/widgets/image_source_sheet.dart';
import 'package:plansync/views/widgets/offline_banner.dart';
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
    final online = context.watch<ConnectivityViewModel>().isOnline;

    return Scaffold(
      appBar: AppBar(
        title: Text(vm.isEditing ? 'Edit Activity' : 'Create Activity'),
      ),
      body: Column(
        children: [
          if (!online)
            const OfflineBanner(
              message: 'Offline: suggested tags may be out of date.',
            ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () async {
                      final source = await showImageSourceSheet(context);
                      if (source != null) vm.pickPhoto(source);
                    },
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        vm.pickedPhoto != null
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
                        const Padding(
                          padding: EdgeInsets.all(8),
                          child: CircleAvatar(
                            radius: 18,
                            child: Icon(Icons.photo_camera_outlined, size: 18),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('PLACE NAME'),
                  TextField(
                    controller: vm.nameController,
                    decoration: const InputDecoration(
                      hintText: 'e.g. Dumbo House',
                      counterText: "",
                    ),
                    maxLength: 50,
                  ),
                  const SizedBox(height: 16),
                  const Text('ADDRESS'),
                  Autocomplete<Place>(
                    textEditingController: vm.addressController,
                    focusNode: vm.addressFocus,
                    displayStringForOption: (place) => place.address,
                    optionsBuilder: (value) => vm.searchPlaces(value.text),
                    onSelected: vm.pickPlace,
                    fieldViewBuilder:
                        (context, controller, focusNode, onSubmitted) =>
                            TextField(
                              controller: controller,
                              focusNode: focusNode,
                              onSubmitted: (_) => onSubmitted(),
                              decoration: const InputDecoration(
                                hintText: 'Search a place or address',
                              ),
                            ),
                  ),
                  if (vm.searchFailed)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'Address suggestions need a connection. Type the full address; the map pin will be skipped.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  const SizedBox(height: 16),
                  const Text('EXPECTED PRICE'),
                  TextField(
                    controller: vm.expectedPriceController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(9),
                    ],
                    decoration: const InputDecoration(
                      hintText: 'e.g. 120,000',
                      counterText: "",
                    ),
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
                      errorText: vm.tagError,
                      counterText: "",
                    ),
                    maxLength: 50,
                  ),
                  const SizedBox(height: 16),
                  const Text('NOTES'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: vm.notesController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      hintText: 'Add notes for your group...',
                      counterText: "",
                    ),
                    maxLength: 300,
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Public activity'),
                    subtitle: const Text('Anyone can find it in Explore'),
                    value: vm.activityVisibility == ActivityVisibility.public,
                    onChanged: (isPublic) => vm.selectVisibility(
                      isPublic
                          ? ActivityVisibility.public
                          : ActivityVisibility.private,
                    ),
                  ),
                  if (vm.errorMessage != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      vm.errorMessage!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
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
                                  final messenger = ScaffoldMessenger.of(
                                    context,
                                  );
                                  final saved = await vm.save();
                                  if (saved == null || !context.mounted) return;
                                  if (vm.queued) {
                                    messenger.showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          vm.isEditing
                                              ? "Changes saved on your phone. They'll sync when you're back online."
                                              : "Activity saved on your phone. It'll be published when you're back online.",
                                        ),
                                      ),
                                    );
                                  }
                                  Navigator.pop(context, saved);
                                },
                          child: vm.isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  vm.isEditing
                                      ? 'Save Changes'
                                      : 'Save Activity',
                                ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
