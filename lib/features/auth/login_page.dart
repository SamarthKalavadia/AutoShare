import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/utils/result.dart';
import '../../core/utils/snackbar_helper.dart';
import '../../data/models/user_model.dart';
import 'presentation/controllers/auth_controller.dart';
import 'presentation/widgets/app_text_field.dart';
import 'presentation/widgets/auth_header.dart';
import 'presentation/widgets/divider_with_text.dart';
import 'presentation/widgets/google_button.dart';
import 'presentation/widgets/loading_button.dart';
import 'presentation/widgets/password_field.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

enum AuthAction { idle, email, google }

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _rememberMe = false;
  AuthAction _authAction = AuthAction.idle;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submitLogin() async {
    if (_authAction != AuthAction.idle) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _authAction = AuthAction.email);

    final result = await ref
        .read(authControllerProvider.notifier)
        .login(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

    setState(() => _authAction = AuthAction.idle);

    if (!mounted) return;

    if (result is Success<UserModel>) {
      final user = result.data;
      if (!user.emailVerified) {
        context.go('/email-verification');
      } else {
        context.go('/home');
      }
    } else if (result is Failure<UserModel>) {
      SnackbarHelper.show(context, result.message);
    }
  }

  Future<void> _handleGoogleSignIn() async {
    if (_authAction != AuthAction.idle) return;
    setState(() => _authAction = AuthAction.google);

    try {
      final result = await ref
          .read(authControllerProvider.notifier)
          .signInWithGoogle();

      if (!mounted) return;

      if (result is Success<UserModel>) {
        context.go('/home');
      } else if (result is Failure<UserModel>) {
        SnackbarHelper.show(context, result.message);
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.show(context, 'Google Sign-In failed: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _authAction = AuthAction.idle);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                const AuthHeader(
                  showLogo: true,
                  title: 'Welcome to AutoShare',
                  subtitle: 'Share rides. Save money. Travel together.',
                ),
                const SizedBox(height: 32),

                // Email Field
                AppTextField(
                  controller: _emailController,
                  labelText: 'Email address',
                  hintText: 'Enter your email address',
                  prefixIcon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!RegExp(
                      r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                    ).hasMatch(value.trim())) {
                      return 'Enter a valid email address';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Password Field
                PasswordField(
                  controller: _passwordController,
                  labelText: 'Password',
                  hintText: 'Enter your password',
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                // Remember Me & Forgot Password
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        SizedBox(
                          height: 24,
                          width: 24,
                          child: Checkbox(
                            value: _rememberMe,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                            onChanged: (val) {
                              setState(() {
                                _rememberMe = val ?? false;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Remember me',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.8,
                            ),
                          ),
                        ),
                      ],
                    ),
                    TextButton(
                      onPressed: () => context.push('/forgot-password'),
                      child: Text(
                        'Forgot password?',
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                // Login Button
                LoadingButton(
                  text: 'Sign In',
                  isLoading: _authAction == AuthAction.email,
                  onPressed: _authAction == AuthAction.idle
                      ? _submitLogin
                      : null,
                ),
                const SizedBox(height: 24),

                const DividerWithText(text: 'OR'),
                const SizedBox(height: 24),

                // Google Button
                GoogleButton(
                  onPressed: _authAction == AuthAction.idle
                      ? _handleGoogleSignIn
                      : null,
                  isLoading: _authAction == AuthAction.google,
                ),
                const SizedBox(height: 32),

                // Register Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Don't have an account? ",
                      style: TextStyle(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.7,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => context.push('/register'),
                      child: Text(
                        'Create Account',
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
