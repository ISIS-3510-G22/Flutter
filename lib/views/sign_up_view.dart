import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:plansync/theme/app_theme.dart';
import 'package:plansync/viewmodels/sign_up_viewmodel.dart';

class SignUpView extends StatelessWidget {
  const SignUpView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SignUpViewModel(),
      child: const _SignUpForm(),
    );
  }
}

class _SignUpForm extends StatefulWidget {
  const _SignUpForm();

  @override
  State<_SignUpForm> createState() => _SignUpFormState();
}

class _SignUpFormState extends State<_SignUpForm> {
  final _formKey = GlobalKey<FormState>();

  Future<void> _submit(SignUpViewModel vm) async {
    if (!_formKey.currentState!.validate()) return;
    if (await vm.createProfile() && mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SignUpViewModel>();
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 84,
        centerTitle: true,
        title: const Text('Create Profile', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
        leadingWidth: 88,
        leading: Padding(
          padding: const EdgeInsets.only(left: 40),
          child: IconButton(
            tooltip: 'Back to log in',
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back, color: AppTheme.black),
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFFFFF1ED),
              shape: const CircleBorder(),
            ),
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: colors.outline),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(40, 34, 40, 28),
                  child: Column(
                    children: [
                      _ProfileField(label: 'NAME', hint: 'e.g., Tomas', controller: vm.nameController),
                      _ProfileField(label: 'LAST NAME', hint: 'e.g., Sierra', controller: vm.lastNameController),
                      _ProfileField(label: 'USERNAME', hint: 'e.g., Tom1281', controller: vm.usernameController),
                      _ProfileField(
                        label: 'PHONE',
                        hint: 'e.g., 310xxxyyyy',
                        controller: vm.phoneController,
                        keyboardType: TextInputType.phone,
                      ),
                      _ProfileField(
                        label: 'EMAIL ADDRESS',
                        hint: '@gmail.com, @yahoo.com, etc',
                        controller: vm.emailController,
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) => value != null && value.contains('@') ? null : 'Enter a valid email address.',
                      ),
                      _ProfileField(
                        label: 'PASSWORD',
                        controller: vm.passwordController,
                        obscureText: true,
                        validator: (value) => value != null && value.length >= 6 ? null : 'Use at least 6 characters.',
                      ),
                      if (vm.errorMessage != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(vm.errorMessage!, style: TextStyle(color: colors.error)),
                        ),
                    ],
                  ),
                ),
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(40, 24, 28, 26),
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: colors.outline)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: vm.isLoading ? null : () => Navigator.of(context).pop(),
                      child: const Text('Cancel', style: TextStyle(fontSize: 20, color: Color(0xFF62636D))),
                    ),
                    SizedBox(
                      height: 52,
                      width: 140,
                      child: FilledButton(
                        onPressed: vm.isLoading ? null : () => _submit(vm),
                        style: FilledButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9))),
                        child: vm.isLoading
                            ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Text('Create', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileField extends StatelessWidget {
  const _ProfileField({
    required this.label,
    required this.controller,
    this.hint,
    this.keyboardType,
    this.obscureText = false,
    this.validator,
  });

  final String label;
  final String? hint;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final bool obscureText;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF62636D))),
          const SizedBox(height: 12),
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            obscureText: obscureText,
            validator: validator ?? (value) => value == null || value.trim().isEmpty ? 'This field is required.' : null,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(fontSize: 20, color: Color(0xFF9B9DAA)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 17),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(9)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(9),
                borderSide: const BorderSide(color: AppTheme.greyLight),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
