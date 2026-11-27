import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:plansync/views/formatters/money_format.dart';

Future<int?> showPaymentDialog(
  BuildContext context, {
  required String title,
  required int owedCents,
}) => showDialog<int>(
  context: context,
  builder: (_) => _PaymentDialog(title: title, owedCents: owedCents),
);

void showPaymentResult(
  ScaffoldMessengerState messenger,
  String message, {
  Future<String> Function()? undo,
}) {
  messenger.showSnackBar(
    SnackBar(
      content: Text(message),
      persist: false,
      action: undo == null
          ? null
          : SnackBarAction(
              label: 'Undo',
              onPressed: () async {
                final undone = await undo();
                messenger.showSnackBar(SnackBar(content: Text(undone)));
              },
            ),
    ),
  );
}

class _PaymentDialog extends StatefulWidget {
  const _PaymentDialog({required this.title, required this.owedCents});

  final String title;
  final int owedCents;

  @override
  State<_PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<_PaymentDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cents = parseMoney(_controller.text);
    final valid = cents != null && cents > 0 && cents <= widget.owedCents;
    String? error;
    if (_controller.text.isNotEmpty && !valid) {
      error = 'Enter up to ${formatMoney(widget.owedCents)}';
    }

    return AlertDialog(
      title: Text(widget.title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Pending: ${formatMoney(widget.owedCents)}'),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => Navigator.pop(context, widget.owedCents),
              child: const Text('Paid in full'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9,]')),
              ],
              decoration: InputDecoration(
                labelText: 'Or enter the amount paid',
                prefixText: '\$ ',
                helperText: valid ? formatMoney(cents) : 'Use , for cents',
                errorText: error,
              ),
              onChanged: (_) => setState(() {}),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: valid ? () => Navigator.pop(context, cents) : null,
          child: const Text('Save amount'),
        ),
      ],
    );
  }
}
