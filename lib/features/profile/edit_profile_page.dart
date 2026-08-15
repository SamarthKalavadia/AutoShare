import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../auth/presentation/controllers/auth_controller.dart';
import '../auth/presentation/widgets/app_text_field.dart';
import '../auth/presentation/widgets/app_dropdown_field.dart';
import '../../core/utils/result.dart';
import '../../data/models/user_model.dart';
import '../../shared/providers.dart';
import '../../shared/utils/avatar_utils.dart';
import 'providers/user_profile_provider.dart';

class EditProfilePage extends ConsumerStatefulWidget {
  const EditProfilePage({super.key});

  @override
  ConsumerState<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends ConsumerState<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _cityController = TextEditingController();
  final _emergencyController = TextEditingController();
  final _bioController = TextEditingController();
  
  String _gender = '';
  String? _currentImageUrl;
  XFile? _newImageFile;
  Uint8List? _newImageBytes;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Use addPostFrameCallback or Future.microtask to read provider safely
    Future.microtask(() {
      final user = ref.read(authControllerProvider).value;
      if (user != null) {
        _nameController.text = user.name;
        _phoneController.text = user.phone;
        _cityController.text = user.city;
        _emergencyController.text = user.emergencyContact;
        _bioController.text = user.bio;
        _gender = user.gender;
        _currentImageUrl = user.profileImage.isNotEmpty ? user.profileImage : null;
        setState(() {});
      }
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

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 500,
      maxHeight: 500,
      imageQuality: 70,
    );
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _newImageFile = pickedFile;
        _newImageBytes = bytes;
      });
    }
  }

  Future<void> _removeImage() async {
    setState(() {
      _newImageFile = null;
      _newImageBytes = null;
      _currentImageUrl = null;
    });
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);

    final currentUser = ref.read(authControllerProvider).value;
    if (currentUser == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      String finalImageUrl = _currentImageUrl ?? '';

      // Upload new image if selected using ProfileRepository
      if (_newImageFile != null) {
        final profileRepo = ref.read(profileRepositoryProvider);
        final uploadResult = await profileRepo.uploadProfileImage(
          uid: currentUser.uid,
          imageFile: _newImageFile!,
        );
        if (uploadResult is Success<UserModel>) {
          finalImageUrl = uploadResult.data.profileImage;
        } else {
          throw Exception((uploadResult as Failure).message);
        }
      } 
      // If user removed their image
      else if (_currentImageUrl == null && currentUser.profileImage.isNotEmpty) {
        final profileRepo = ref.read(profileRepositoryProvider);
        await profileRepo.removeProfileImage(currentUser.uid);
        finalImageUrl = '';
      }

      // Update Firestore with full updated user info
      final updatedUser = currentUser.copyWith(
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        city: _cityController.text.trim(),
        emergencyContact: _emergencyController.text.trim(),
        bio: _bioController.text.trim(),
        gender: _gender,
        profileImage: finalImageUrl,
      );

      final repo = ref.read(userRepositoryProvider);
      final updateResult = await repo.updateProfile(
        uid: currentUser.uid,
        updates: updatedUser.toMap(),
      );

      if (updateResult is Success) {
        // Sync local authControllerProvider state
        ref.read(authControllerProvider.notifier).updateUser(updatedUser);
        ref.invalidate(userProfileProvider(currentUser.uid));
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile updated successfully'), backgroundColor: Color(0xFF2E7D32)),
          );
          Navigator.pop(context);
        }
      } else {
        throw Exception((updateResult as Failure).message);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: const Color(0xFFD32F2F)),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final blackColor = theme.colorScheme.onSurface;
    const primaryColor = Color(0xFFF6C000);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: blackColor, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Edit Profile',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: blackColor,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: primaryColor))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Profile Picture
                    Center(
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundColor: const Color(0xFFF0EDE9),
                            backgroundImage: _newImageBytes != null
                                ? MemoryImage(_newImageBytes!)
                                : getAvatarImageProvider(_currentImageUrl),
                            child: (_newImageBytes == null && getAvatarImageProvider(_currentImageUrl) == null)
                                ? const Icon(Icons.person, size: 50, color: Color(0xFFCCCCCC))
                                : null,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: _pickImage,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: blackColor,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.camera_alt_rounded, size: 16, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_newImageFile != null || _currentImageUrl != null)
                      Center(
                        child: TextButton(
                          onPressed: _removeImage,
                          child: Text('Remove Photo', style: GoogleFonts.inter(color: const Color(0xFFD32F2F))),
                        ),
                      ),
                    
                    const SizedBox(height: 32),

                    // Form Fields
                    AppTextField(
                      controller: _nameController,
                      labelText: 'Full name',
                      hintText: 'Enter your full name',
                      prefixIcon: Icons.person_outline_rounded,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'This field is required';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    AppTextField(
                      controller: _phoneController,
                      labelText: 'Phone number',
                      hintText: 'Enter your phone number',
                      prefixIcon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(10),
                      ],
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'This field is required';
                        }
                        final cleanValue = value.trim();
                        if (cleanValue.length != 10) {
                          return 'Please enter a valid 10-digit phone number';
                        }
                        final firstChar = cleanValue[0];
                        if (firstChar != '6' && firstChar != '7' && firstChar != '8' && firstChar != '9') {
                          return 'Please enter a valid 10-digit mobile number';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),
                    AppDropdownField<String>(
                      value: _gender.isNotEmpty ? _gender : null,
                      labelText: 'Gender',
                      hintText: 'Select your gender',
                      prefixIcon: Icons.person_outline_rounded,
                      items: const [
                        DropdownMenuItem(value: 'Male', child: Text('Male')),
                        DropdownMenuItem(value: 'Female', child: Text('Female')),
                        DropdownMenuItem(value: 'Other', child: Text('Other')),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _gender = val);
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select your gender';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),
                    AppTextField(
                      controller: _cityController,
                      labelText: 'City',
                      hintText: 'Enter your city',
                      prefixIcon: Icons.location_city_rounded,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'This field is required';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),
                    AppTextField(
                      controller: _emergencyController,
                      labelText: 'Emergency Contact (Optional)',
                      hintText: 'Relation & Number',
                      prefixIcon: Icons.health_and_safety_outlined,
                      validator: (value) {
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),
                    AppTextField(
                      controller: _bioController,
                      labelText: 'Bio (Optional)',
                      hintText: 'A bit about yourself...',
                      prefixIcon: Icons.edit_note_rounded,
                      maxLines: 3,
                      validator: (value) {
                        return null;
                      },
                    ),

                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: FilledButton(
                        onPressed: _saveChanges,
                        style: FilledButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: blackColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          'Save Changes',
                          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }


}
