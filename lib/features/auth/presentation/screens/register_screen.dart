import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/providers/auth_providers.dart';
import '../../../../app/router.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/constants/app_strings.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  String? _passwordError;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleRegister() async {
    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() {
        _passwordError = 'Passwords do not match';
      });
      return;
    }

    setState(() {
      _passwordError = null;
    });

    final controller = ref.read(authControllerProvider.notifier);
    await controller.register(
      _nameController.text.trim(),
      _emailController.text.trim(),
      _passwordController.text,
    );

    final state = ref.read(authControllerProvider);
    if (state.isAuthenticated && mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRouter.signIn,
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.signUp),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              Text(
                'Create Account',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              AppTextField(
                label: AppStrings.name,
                hint: 'Your full name',
                controller: _nameController,
                keyboardType: TextInputType.name,
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: AppStrings.email,
                hint: 'your@email.com',
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: AppStrings.password,
                hint: 'Enter your password',
                controller: _passwordController,
                obscureText: true,
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: AppStrings.confirmPassword,
                hint: 'Confirm your password',
                controller: _confirmPasswordController,
                obscureText: true,
                errorText: _passwordError,
              ),
              if (authState.errorMessage != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    authState.errorMessage!,
                    style: TextStyle(color: Colors.red.shade900),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              AppButton(
                text: AppStrings.signUp,
                onPressed: _handleRegister,
                isLoading: authState.isSubmitting,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(AppStrings.alreadyHaveAccount),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: Text(AppStrings.signIn),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
