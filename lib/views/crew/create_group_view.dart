import 'package:flutter/material.dart';
import 'package:plansync/models/crew_group.dart';

class CreateGroupView extends StatefulWidget {
  const CreateGroupView({super.key});

  @override
  State<CreateGroupView> createState() => _CreateGroupViewState();
}

class _CreateGroupViewState extends State<CreateGroupView> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _createGroup() {
    if (!_formKey.currentState!.validate()) return;

    Navigator.of(context).pop(
      CrewGroup(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFFAFAFA),
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
                        color: Color(0xFF171D2B),
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
          const Divider(height: 1, color: Color(0xFFE5E5E5)),
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
                ],
              ),
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE5E5E5)),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 16, 22, 16),
              child: Row(
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        color: Color(0xFF60636D),
                        fontSize: 15,
                      ),
                    ),
                  ),
                  const Spacer(),
                  SizedBox(
                    height: 46,
                    child: FilledButton(
                      onPressed: _createGroup,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFFF6047),
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(9),
                        ),
                      ),
                      child: const Text('Create Group'),
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

  InputDecoration _inputDecoration(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: Color(0xFFA0A4AE), fontSize: 15),
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(7),
      borderSide: const BorderSide(color: Color(0xFFE0E2E5)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(7),
      borderSide: const BorderSide(color: Color(0xFFE0E2E5)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(7),
      borderSide: const BorderSide(color: Color(0xFFFF6047)),
    ),
  );
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: Color(0xFF60636D),
        fontSize: 13,
        fontWeight: FontWeight.w600,
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
    return Material(
      color: const Color(0xFFFFF0EC),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: const SizedBox(
          width: 40,
          height: 40,
          child: Icon(Icons.arrow_back, size: 20, color: Color(0xFF171D2B)),
        ),
      ),
    );
  }
}
