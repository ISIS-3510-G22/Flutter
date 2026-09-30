import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:plansync/viewmodels/reset_password_viewmodel.dart';

class ResetPasswordView extends StatelessWidget {
  const ResetPasswordView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ResetPasswordViewModel(),
      child: const _ResetPasswordForm(),
    );
  }
}

class _ResetPasswordForm extends StatelessWidget {
  const _ResetPasswordForm();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ResetPasswordViewModel>();
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: colors.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.lock_reset_outlined, size: 28, color: colors.onSurfaceVariant),
                    ),
                    const SizedBox(height: 16),
                    Text('Reset Password', style: text.headlineMedium),
                    const SizedBox(height: 8),
                    Text(
                      vm.emailSent
                          ? 'Check your inbox for a link to reset your password.'
                          : 'Enter your email address and we\'ll send you a link to reset your password.',
                      textAlign: TextAlign.center,
                      style: text.bodyLarge?.copyWith(color: colors.onSurfaceVariant),
                    ),
                    const SizedBox(height: 32),
                    if (!vm.emailSent) ...[
                      TextField(
                        controller: vm.emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(labelText: 'Email address'),
                      ),
                      if (vm.errorMessage != null) ...[
                        const SizedBox(height: 12),
                        Text(vm.errorMessage!, style: TextStyle(color: colors.error)),
                      ],
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: FilledButton(
                          onPressed: vm.isLoading ? null : vm.resetPassword,
                          child: vm.isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text('Send Link', style: TextStyle(fontSize: 18)),
                                    SizedBox(width: 8),
                                    Icon(Icons.arrow_forward),
                                  ],
                                ),
                        ),
                      ),
                    ] else ...[
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: FilledButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('Back to Log In', style: TextStyle(fontSize: 18)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
