import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/utils/result.dart';
import '../../core/utils/snackbar_helper.dart';
import '../../data/models/user_model.dart';
import 'presentation/controllers/auth_controller.dart';
import 'presentation/widgets/app_dropdown_field.dart';
import 'presentation/widgets/app_text_field.dart';
import 'presentation/widgets/auth_header.dart';
import 'presentation/widgets/divider_with_text.dart';
import 'presentation/widgets/google_button.dart';
import 'presentation/widgets/loading_button.dart';
import 'presentation/widgets/password_field.dart';
import 'presentation/widgets/profile_avatar_picker.dart';
import 'presentation/widgets/validation_text.dart';
import '../../core/localization/app_localizations.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

enum AuthAction { idle, email, google }

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String? _selectedGender;
  XFile? _selectedImage;
  Uint8List? _selectedImageBytes;
  bool _acceptedTerms = false;
  AuthAction _authAction = AuthAction.idle;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submitRegister() async {
    if (_authAction != AuthAction.idle) return;
    if (!_formKey.currentState!.validate()) return;

    if (!_acceptedTerms) {
      SnackbarHelper.show(
        context,
        context.l10n.acceptTermsPrompt,
      );
      return;
    }

    setState(() => _authAction = AuthAction.email);

    final result = await ref
        .read(authControllerProvider.notifier)
        .register(
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
          phone: _phoneController.text.trim(),
          gender: _selectedGender ?? '',
          profileImageFile: _selectedImage,
        );

    setState(() => _authAction = AuthAction.idle);

    if (!mounted) return;

    if (result is Success<UserModel>) {
      context.go('/email-verification');
    } else if (result is Failure<UserModel>) {
      SnackbarHelper.show(context, result.message);
    }
  }

  Future<void> _handleGoogleSignUp() async {
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
        SnackbarHelper.show(context, 'Google Sign-Up failed: $e');
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
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AuthHeader(
                  showLogo: true,
                  title: context.l10n.createAccount,
                  subtitle: context.l10n.joinAutoShareSubtitle,
                ),
                const SizedBox(height: 12),

                // Avatar Picker
                ProfileAvatarPicker(
                  imageFile: _selectedImage,
                  imageBytes: _selectedImageBytes,
                  onImageSelected: (file) async {
                    Uint8List? bytes;
                    if (file != null) {
                      bytes = await file.readAsBytes();
                    }
                    setState(() {
                      _selectedImage = file;
                      _selectedImageBytes = bytes;
                    });
                  },
                ),
                const SizedBox(height: 20),

                // Full Name
                AppTextField(
                  controller: _nameController,
                  labelText: context.l10n.fullName,
                  hintText: context.l10n.enterFullName,
                  prefixIcon: Icons.person_outline_rounded,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return context.l10n.pleaseEnterName;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Email Address
                AppTextField(
                  controller: _emailController,
                  labelText: context.l10n.emailAddress,
                  hintText: context.l10n.enterEmail,
                  prefixIcon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return context.l10n.pleaseEnterEmail;
                    }
                    if (!RegExp(
                      r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                    ).hasMatch(value.trim())) {
                      return context.l10n.enterValidEmail;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Phone Number
                AppTextField(
                  controller: _phoneController,
                  labelText: context.l10n.phoneNumber,
                  hintText: context.l10n.enterPhoneNumber,
                  prefixIcon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return context.l10n.pleaseEnterPhone;
                    }
                    final cleanValue = value.trim();
                    if (cleanValue.length != 10) {
                      return context.l10n.enterValidPhone;
                    }
                    final firstChar = cleanValue[0];
                    if (firstChar != '6' &&
                        firstChar != '7' &&
                        firstChar != '8' &&
                        firstChar != '9') {
                      return context.l10n.enterValidPhone;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Gender
                AppDropdownField<String>(
                  value: _selectedGender,
                  labelText: context.l10n.gender,
                  hintText: context.l10n.gender,
                  prefixIcon: Icons.person_outline_rounded,
                  items: [
                    DropdownMenuItem(value: 'Male', child: Text(context.l10n.genderMale)),
                    DropdownMenuItem(value: 'Female', child: Text(context.l10n.genderFemale)),
                    DropdownMenuItem(value: 'Other', child: Text(context.l10n.genderOther)),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedGender = value;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return context.l10n.gender;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Password
                PasswordField(
                  controller: _passwordController,
                  labelText: context.l10n.password,
                  hintText: context.l10n.enterPassword,
                  onChanged: (_) => setState(() {}),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return context.l10n.pleaseEnterPassword;
                    }
                    if (value.length < 8) {
                      return context.l10n.passwordMinLength;
                    }
                    return null;
                  },
                ),
                ValidationText(password: _passwordController.text),
                const SizedBox(height: 16),

                // Confirm Password
                PasswordField(
                  controller: _confirmPasswordController,
                  labelText: context.l10n.confirmPassword,
                  hintText: context.l10n.reEnterPassword,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return context.l10n.confirmPassword;
                    }
                    if (value != _passwordController.text) {
                      return context.l10n.passwordsDoNotMatch;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Terms Checkbox
                Row(
                  children: [
                    SizedBox(
                      height: 24,
                      width: 24,
                      child: Checkbox(
                        value: _acceptedTerms,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                        onChanged: (val) {
                          setState(() {
                            _acceptedTerms = val ?? false;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          text: 'I agree to the ',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.7,
                            ),
                          ),
                          children: [
                            TextSpan(
                              text: 'Terms of Service',
                              style: TextStyle(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const TextSpan(text: ' and '),
                            TextSpan(
                              text: 'Privacy Policy',
                              style: TextStyle(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Register Button
                LoadingButton(
                  text: context.l10n.createAccount,
                  isLoading: _authAction == AuthAction.email,
                  onPressed: _authAction == AuthAction.idle
                      ? _submitRegister
                      : null,
                ),
                const SizedBox(height: 24),

                DividerWithText(text: context.l10n.orContinueWith),
                const SizedBox(height: 24),

                // Google Sign Up
                GoogleButton(
                  text: context.l10n.signInWithGoogle,
                  onPressed: _authAction == AuthAction.idle
                      ? _handleGoogleSignUp
                      : null,
                  isLoading: _authAction == AuthAction.google,
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
