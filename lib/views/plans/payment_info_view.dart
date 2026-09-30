import 'package:flutter/material.dart';
import 'package:plansync/models/user.dart';
import 'package:plansync/viewmodels/plans/payment_info_viewmodel.dart';
import 'package:provider/provider.dart';

class PaymentInfoView extends StatelessWidget {
  const PaymentInfoView({required this.planId, super.key});

  final String planId;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) =>
          PaymentInfoViewModel(planId, context.read<User>().id),
      child: const _PaymentInfoBody(),
    );
  }
}

class _PaymentInfoBody extends StatelessWidget {
  const _PaymentInfoBody();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<PaymentInfoViewModel>();
    final text = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Bre-B or Account')),
      body: vm.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  color: colors.secondaryContainer,
                  child: ListTile(
                    leading: Icon(Icons.info_outline, color: colors.primary),
                    title: const Text('How others can pay you back'),
                    subtitle: const Text(
                      'Add your Bre-B key or the bank account where the other '
                      'participants can transfer you, for example '
                      '"Bre-B @juan123" or "Bancolombia savings 123-456789-00". '
                      'It only applies to this plan and is just a note for '
                      'your group: the app does not connect to any bank.',
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text('BRE-B KEY OR ACCOUNT'),
                TextField(
                  controller: vm.detailsController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'e.g. Bre-B @juan123',
                  ),
                ),
                if (vm.errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      vm.errorMessage!,
                      style: text.bodyMedium?.copyWith(color: colors.error),
                    ),
                  ),
              ],
            ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
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
                  onPressed: vm.isLoading || vm.isSaving
                      ? null
                      : () async {
                          final messenger = ScaffoldMessenger.of(context);
                          final updating = vm.hasExisting;
                          final ok = await vm.save();
                          if (!ok || !context.mounted) return;
                          Navigator.pop(context);
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text(
                                updating
                                    ? 'Bre-B or account updated'
                                    : 'Bre-B or account added',
                              ),
                            ),
                          );
                        },
                  child: const Text('Save'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
