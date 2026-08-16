import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/utils/result.dart';
import '../../../../core/utils/snackbar_helper.dart';
import '../controllers/auth_controller.dart';
import '../widgets/app_text_field.dart';
import '../widgets/auth_header.dart';
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
  final _phoneController = TextEditingController();
  final _dobController = TextEditingController();
  final _cityController = TextEditingController();
  final _emergencyController = TextEditingController();

  String _selectedGender = 'Prefer not to say';
  XFile? _profileImage;
  Uint8List? _profileImageBytes;
  bool _isLoading = false;

  final List<String> _genders = [
    'Male',
    'Female',
    'Non-binary',
    'Prefer not to say',
  ];

  @override
  void dispose() {
    _phoneController.dispose();
    _dobController.dispose();
    _cityController.dispose();
    _emergencyController.dispose();
    super.dispose();
  }

  Future<void> _selectDateOfBirth() async {
    final now = DateTime.now();
    final initialDate = DateTime(now.year - 18, now.month, now.day);

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1920),
      lastDate: DateTime(now.year - 14),
    );

    if (picked != null) {
      setState(() {
        _dobController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
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
          phone: _phoneController.text.trim(),
          gender: _selectedGender,
          dob: _dobController.text.trim(),
          city: _cityController.text.trim(),
          emergencyContact: _emergencyController.text.trim(),
          profileImageFile: _profileImage,
        );

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (result is Success<void>) {
      context.go('/home');
    } else if (result is Failure<void>) {
      SnackbarHelper.show(context, result.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Complete Profile'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AuthHeader(
                  title: 'Almost There! 🌟',
                  subtitle:
                      'Please complete your profile information to start sharing and booking rides.',
                ),
                const SizedBox(height: 24),

                // Avatar Picker
                ProfileAvatarPicker(
                  imageFile: _profileImage,
                  imageBytes: _profileImageBytes,
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

                // Phone Number
                AppTextField(
                  controller: _phoneController,
                  labelText: 'Phone Number',
                  hintText: '+1 234 567 8900',
                  prefixIcon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Please enter phone number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Gender Dropdown
                Text(
                  'Gender',
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _selectedGender,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(
                      Icons.person_outline_rounded,
                      size: 22,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                  ),
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
                ),
                const SizedBox(height: 16),

                // Date of Birth
                AppTextField(
                  controller: _dobController,
                  labelText: 'Date of Birth',
                  hintText: 'YYYY-MM-DD',
                  prefixIcon: Icons.calendar_today_rounded,
                  readOnly: true,
                  onTap: _selectDateOfBirth,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Please select your birth date';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // City
                AppTextField(
                  controller: _cityController,
                  labelText: 'City',
                  hintText: 'New York, NY',
                  prefixIcon: Icons.location_city_rounded,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Please enter your city';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Emergency Contact
                AppTextField(
                  controller: _emergencyController,
                  labelText: 'Emergency Contact Phone (Optional)',
                  hintText: '+1 987 654 3210',
                  prefixIcon: Icons.contact_phone_outlined,
                  keyboardType: TextInputType.phone,
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
    );
  }
}
