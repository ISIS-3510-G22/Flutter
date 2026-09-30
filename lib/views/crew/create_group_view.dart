import 'package:flutter/material.dart';
import 'package:plansync/viewmodels/crew/group_viewmodel.dart';
import 'package:provider/provider.dart';

class CreateGroupView extends StatefulWidget {
  const CreateGroupView({super.key});

  @override
  State<CreateGroupView> createState() => _CreateGroupViewState();
}

class _CreateGroupViewState extends State<CreateGroupView> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isSaving = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _createGroup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
      _error = null;
    });
    try {
      final group = await context.read<CrewViewmodel>().createGroup(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
      );
      if (mounted) Navigator.of(context).pop(group);
    } catch (error) {
      if (mounted) setState(() => _error = 'Could not create the group.');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Material(
      color: colors.surface,
      child: Column(
        children: [
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
              child: SizedBox(
                height: 48,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    const Text(
                      'Create Group',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: _BackButton(
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Divider(height: 1, color: colors.outline),
          Expanded(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(22, 24, 22, 24),
                children: [
                  const _FieldLabel('GROUP NAME'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _nameController,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    decoration: _inputDecoration('e.g., The Foosies'),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Enter a group name'
                        : null,
                  ),
                  const SizedBox(height: 20),
                  const _FieldLabel('DESCRIPTION'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _descriptionController,
                    textCapitalization: TextCapitalization.sentences,
                    minLines: 1,
                    maxLines: 4,
                    decoration: _inputDecoration('e.g., ...'),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(_error!, style: TextStyle(color: colors.error)),
                  ],
                ],
              ),
            ),
          ),
          Divider(height: 1, color: colors.outline),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 16, 22, 16),
              child: Row(
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      'Cancel',
                      style: text.bodyMedium?.copyWith(color: colors.onSurface),
                    ),
                  ),
                  const Spacer(),
                  SizedBox(
                    height: 46,
                    child: FilledButton(
                      onPressed: _isSaving ? null : _createGroup,
                      style: FilledButton.styleFrom(
                        backgroundColor: colors.primary,
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(9),
                        ),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Create Group'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return InputDecoration(
      hintText: hint,
      hintStyle: text.bodyMedium?.copyWith(color: const Color(0xFFA0A4AE)),
      filled: true,
      fillColor: colors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(7),
        borderSide: BorderSide(color: colors.outline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(7),
        borderSide: BorderSide(color: colors.outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(7),
        borderSide: BorderSide(color: colors.primary),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;

    return Text(
      label,
      style: text.labelLarge?.copyWith(
        color: colors.onSurfaceVariant,
        fontSize: 13,
        letterSpacing: 0.4,
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Material(
      color: colors.secondaryContainer,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(
            Icons.arrow_back,
            size: 20,
            color: colors.onSecondaryContainer,
          ),
        ),
      ),
    );
  }
}
