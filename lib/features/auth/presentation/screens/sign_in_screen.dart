import 'package:flutter/material.dart';
import '../../domain/providers/auth_providers.dart';
import '../../../../app/router.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/constants/app_strings.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleSignIn() async {
    final controller = ref.read(authControllerProvider.notifier);
    await controller.login(
      _emailController.text.trim(),
      _passwordController.text,
    );

    final state = ref.read(authControllerProvider);
    if (state.isAuthenticated && mounted) {
      Navigator.of(context).pushReplacementNamed(AppRouter.dashboard);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                AppStrings.signIn,
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
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
                text: AppStrings.signIn,
                onPressed: _handleSignIn,
                isLoading: authState.isSubmitting,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(AppStrings.dontHaveAccount),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pushNamed(AppRouter.register);
                    },
                    child: Text(AppStrings.signUp),
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
