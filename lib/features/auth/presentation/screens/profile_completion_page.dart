import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/utils/result.dart';
import '../../../../core/utils/snackbar_helper.dart';
import '../controllers/auth_controller.dart';
import '../widgets/app_dropdown_field.dart';
import '../widgets/app_text_field.dart';
import '../widgets/loading_button.dart';
import '../widgets/profile_avatar_picker.dart';

class ProfileCompletionPage extends ConsumerStatefulWidget {
  const ProfileCompletionPage({super.key});

  @override
  ConsumerState<ProfileCompletionPage> createState() =>
      _ProfileCompletionPageState();
}

class _ProfileCompletionPageState extends ConsumerState<ProfileCompletionPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _cityController = TextEditingController();
  final _emergencyController = TextEditingController();
  final _bioController = TextEditingController();

  String? _selectedGender;
  String? _initialImageUrl;
  XFile? _profileImage;
  Uint8List? _profileImageBytes;
  bool _isLoading = false;

  final List<String> _genders = ['Male', 'Female', 'Other'];

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final user = ref.read(authControllerProvider).value;
      User? fbUser;
      try {
        fbUser = FirebaseAuth.instance.currentUser;
      } catch (_) {}

      String name = user?.name.trim() ?? '';
      if (name.isEmpty && fbUser != null) {
        name = (fbUser.displayName != null && fbUser.displayName!.trim().isNotEmpty)
            ? fbUser.displayName!.trim()
            : (fbUser.email != null && fbUser.email!.contains('@')
                ? fbUser.email!.split('@').first
                : '');
      }

      String phone = user?.phone.trim() ?? '';
      if (phone.isEmpty && fbUser?.phoneNumber != null) {
        phone = fbUser!.phoneNumber!.replaceAll(RegExp(r'[^0-9]'), '');
        if (phone.length > 10) {
          phone = phone.substring(phone.length - 10);
        }
      }

      _nameController.text = name;
      _phoneController.text = phone;
      _cityController.text = user?.city ?? '';
      _emergencyController.text = user?.emergencyContact ?? '';
      _bioController.text = user?.bio ?? '';

      final gender = user?.gender ?? '';
      if (_genders.contains(gender)) {
        _selectedGender = gender;
      } else {
        _selectedGender = 'Male';
      }

      _initialImageUrl = (user?.profileImage.isNotEmpty == true)
          ? user!.profileImage
          : (fbUser?.photoURL?.isNotEmpty == true ? fbUser!.photoURL : null);

      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _cityController.dispose();
    _emergencyController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _handleLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log Out'),
        content: const Text(
          'Are you sure you want to log out? You will need to complete your profile when you log in again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );

    if (shouldLogout == true && mounted) {
      await ref.read(authControllerProvider.notifier).logout();
      if (mounted) {
        context.go('/login');
      }
    }
  }

  Future<void> _submitProfileCompletion() async {
    if (!_formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      SnackbarHelper.show(context, 'User not authenticated.');
      context.go('/login');
      return;
    }

    setState(() => _isLoading = true);

    final result = await ref
        .read(authControllerProvider.notifier)
        .completeProfile(
          uid: user.uid,
          name: _nameController.text.trim(),
          phone: _phoneController.text.trim(),
          gender: _selectedGender ?? 'Male',
          city: _cityController.text.trim(),
          emergencyContact: _emergencyController.text.trim(),
          bio: _bioController.text.trim(),
          profileImageFile: _profileImage,
        );

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (result is Success<void>) {
      SnackbarHelper.show(context, 'Profile completed successfully! Welcome to AutoShare.');
      context.go('/home');
    } else if (result is Failure<void>) {
      SnackbarHelper.show(context, result.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        SnackbarHelper.show(
          context,
          'Please complete all required profile fields to continue.',
        );
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Almost There'),
          backgroundColor: Colors.transparent,
          elevation: 0,
          automaticallyImplyLeading: false,
          actions: [
            IconButton(
              icon: const Icon(Icons.logout_rounded),
              tooltip: 'Log Out',
              onPressed: _handleLogout,
            ),
          ],
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Please fill in your compulsory profile details to start sharing and booking rides.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.65),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Avatar Picker
                  ProfileAvatarPicker(
                    imageFile: _profileImage,
                    imageBytes: _profileImageBytes,
                    imageUrl: _initialImageUrl,
                    onImageSelected: (file) async {
                      Uint8List? bytes;
                      if (file != null) {
                        bytes = await file.readAsBytes();
                      }
                      setState(() {
                        _profileImage = file;
                        _profileImageBytes = bytes;
                      });
                    },
                  ),
                  const SizedBox(height: 24),

                  // Full Name (Compulsory)
                  AppTextField(
                    controller: _nameController,
                    labelText: 'Full Name *',
                    hintText: 'Enter your full name',
                    prefixIcon: Icons.person_outline_rounded,
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Please enter your full name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Phone Number (Compulsory & Unique)
                  AppTextField(
                    controller: _phoneController,
                    labelText: 'Mobile Number *',
                    hintText: 'Enter 10-digit mobile number',
                    prefixIcon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(10),
                    ],
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Please enter mobile number';
                      }
                      final clean = val.trim();
                      if (clean.length != 10) {
                        return 'Please enter a valid 10-digit mobile number';
                      }
                      final firstChar = clean[0];
                      if (firstChar != '6' &&
                          firstChar != '7' &&
                          firstChar != '8' &&
                          firstChar != '9') {
                        return 'Please enter a valid 10-digit mobile number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Gender (Compulsory)
                  AppDropdownField<String>(
                    value: _selectedGender,
                    labelText: 'Gender *',
                    hintText: 'Select your gender',
                    prefixIcon: Icons.person_outline_rounded,
                    items: _genders.map((g) {
                      return DropdownMenuItem(value: g, child: Text(g));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _selectedGender = val;
                        });
                      }
                    },
                    validator: (val) {
                      if (val == null || val.isEmpty) {
                        return 'Please select your gender';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // City (Compulsory)
                  AppTextField(
                    controller: _cityController,
                    labelText: 'City *',
                    hintText: 'Enter your city (e.g. Surat, Mumbai)',
                    prefixIcon: Icons.location_city_rounded,
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Please enter your city';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Emergency Contact (Optional)
                  AppTextField(
                    controller: _emergencyController,
                    labelText: 'Emergency Contact (Optional)',
                    hintText: 'Emergency contact number or name',
                    prefixIcon: Icons.contact_phone_outlined,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 16),

                  // Bio (Optional)
                  AppTextField(
                    controller: _bioController,
                    labelText: 'Bio (Optional)',
                    hintText: 'A bit about yourself...',
                    prefixIcon: Icons.edit_note_rounded,
                    maxLines: 2,
                  ),
                  const SizedBox(height: 28),

                  // Save Profile Button
                  LoadingButton(
                    text: 'Save & Continue',
                    isLoading: _isLoading,
                    onPressed: _submitProfileCompletion,
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
