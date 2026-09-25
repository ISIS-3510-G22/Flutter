import 'package:flutter/material.dart';
import 'package:plansync/models/reimbursement_method.dart';

class AddReimbursementMethodView extends StatefulWidget {
  const AddReimbursementMethodView({super.key});

  @override
  State<AddReimbursementMethodView> createState() =>
      _AddReimbursementMethodViewState();
}

class _AddReimbursementMethodViewState
    extends State<AddReimbursementMethodView> {
  final _typeController = TextEditingController();
  final _accountController = TextEditingController();

  @override
  void dispose() {
    _typeController.dispose();
    _accountController.dispose();
    super.dispose();
  }

  void _save() {
    Navigator.of(context).pop(
      ReimbursementMethod(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: _typeController.text.trim(),
        account: _accountController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Reimbursement Method')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            TextField(
              controller: _typeController,
              decoration: const InputDecoration(labelText: 'Account Type'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _accountController,
              decoration: const InputDecoration(labelText: 'Account'),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: FilledButton(
                onPressed: _save,
                child: const Text('Save Account'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
