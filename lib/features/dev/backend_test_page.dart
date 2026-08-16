// ignore_for_file: avoid_print
// DEV ONLY — Remove before shipping to production.

import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/services/auth_service.dart';
import '../../core/utils/result.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/user_repository.dart';
import '../../data/repositories/profile_repository.dart';
import '../../firebase_options.dart';

// ─── Console log entry ────────────────────────────────────────────────────────

enum _LogLevel { info, success, error, loading }

class _LogEntry {
  final String message;
  final _LogLevel level;
  final DateTime timestamp;

  _LogEntry({required this.message, required this.level, DateTime? timestamp})
    : timestamp = timestamp ?? DateTime.now();
}

// ─── Page ─────────────────────────────────────────────────────────────────────

class BackendTestPage extends StatefulWidget {
  const BackendTestPage({super.key});

  @override
  State<BackendTestPage> createState() => _BackendTestPageState();
}

class _BackendTestPageState extends State<BackendTestPage> {
  // Services
  final UserRepository _userRepository = UserRepository();
  final ProfileRepository _profileRepository = ProfileRepository();
  late final AuthService _authService;

  // Console state
  final List<_LogEntry> _logs = [];
  final ScrollController _scrollController = ScrollController();

  // Loading state per button key
  final Map<String, bool> _loading = {};

  // Stream subscription for "Stream Current User"
  StreamSubscription<Result<UserModel>>? _userStreamSub;

  @override
  void initState() {
    super.initState();
    _authService = AuthService(userRepository: _userRepository);
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  void _log(String message, {_LogLevel level = _LogLevel.info}) {
    setState(() => _logs.add(_LogEntry(message: message, level: level)));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _startLoading(String key) => setState(() => _loading[key] = true);
  void _stopLoading(String key) => setState(() => _loading[key] = false);
  bool _isLoading(String key) => _loading[key] ?? false;

  void _clearConsole() => setState(() => _logs.clear());

  // ── Test Credentials (edit as needed) ────────────────────────────────────

  final String _testEmail =
      'devtest_${DateTime.now().millisecondsSinceEpoch}@autoshare.dev';
  final String _testPassword = 'DevTest@1234';
  final String _testName = 'Dev Tester';

  // ── Action Handlers ───────────────────────────────────────────────────────

  Future<void> _initializeFirebase() async {
    const key = 'initFirebase';
    _startLoading(key);
    _log('⏳ Initializing Firebase…', level: _LogLevel.loading);
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      _log('✅ Firebase initialized successfully.', level: _LogLevel.success);
    } on FirebaseException catch (e) {
      if (e.code == 'duplicate-app') {
        _log(
          '✅ Firebase already initialized (duplicate-app is OK).',
          level: _LogLevel.success,
        );
      } else {
        _log('❌ Firebase init error: ${e.message}', level: _LogLevel.error);
      }
    } catch (e) {
      _log('❌ Unexpected error: $e', level: _LogLevel.error);
    } finally {
      _stopLoading(key);
    }
  }

  Future<void> _registerUser() async {
    const key = 'register';
    _startLoading(key);
    _log('⏳ Registering user → $_testEmail', level: _LogLevel.loading);
    try {
      final result = await _authService.signUpWithEmail(
        name: _testName,
        email: _testEmail,
        password: _testPassword,
      );
      if (result is Success<UserModel>) {
        _log(
          '✅ Register success → uid: ${result.data.uid}',
          level: _LogLevel.success,
        );
      } else if (result is Failure<UserModel>) {
        _log('❌ Register failed: ${result.message}', level: _LogLevel.error);
      }
    } catch (e) {
      _log('❌ Register exception: $e', level: _LogLevel.error);
    } finally {
      _stopLoading(key);
    }
  }

  Future<void> _loginUser() async {
    const key = 'login';
    _startLoading(key);
    _log('⏳ Logging in → $_testEmail', level: _LogLevel.loading);
    try {
      final result = await _authService.loginWithEmail(
        email: _testEmail,
        password: _testPassword,
      );
      if (result is Success<UserModel>) {
        _log(
          '✅ Login success → uid: ${result.data.uid}  name: ${result.data.name}',
          level: _LogLevel.success,
        );
      } else if (result is Failure<UserModel>) {
        _log('❌ Login failed: ${result.message}', level: _LogLevel.error);
      }
    } catch (e) {
      _log('❌ Login exception: $e', level: _LogLevel.error);
    } finally {
      _stopLoading(key);
    }
  }

  Future<void> _googleLogin() async {
    const key = 'google';
    _startLoading(key);
    _log('⏳ Starting Google Sign-In…', level: _LogLevel.loading);
    try {
      final result = await _authService.signInWithGoogle();
      if (result is Success<UserModel>) {
        _log(
          '✅ Google login success → uid: ${result.data.uid}  email: ${result.data.email}',
          level: _LogLevel.success,
        );
      } else if (result is Failure<UserModel>) {
        _log(
          '❌ Google login failed: ${result.message}',
          level: _LogLevel.error,
        );
      }
    } catch (e) {
      _log('❌ Google login exception: $e', level: _LogLevel.error);
    } finally {
      _stopLoading(key);
    }
  }

  Future<void> _sendEmailVerification() async {
    const key = 'emailVerify';
    _startLoading(key);
    _log('⏳ Sending email verification…', level: _LogLevel.loading);
    try {
      final result = await _authService.sendEmailVerification();
      if (result is Success<void>) {
        _log('✅ Verification email sent.', level: _LogLevel.success);
      } else if (result is Failure<void>) {
        _log(
          '❌ Send verification failed: ${result.message}',
          level: _LogLevel.error,
        );
      }
    } catch (e) {
      _log('❌ Send verification exception: $e', level: _LogLevel.error);
    } finally {
      _stopLoading(key);
    }
  }

  Future<void> _createFirestoreUser() async {
    const key = 'createUser';
    _startLoading(key);
    _log('⏳ Creating Firestore user document…', level: _LogLevel.loading);
    try {
      final uid = _authService.currentUser?.uid;
      if (uid == null) {
        _log('❌ No authenticated user. Login first.', level: _LogLevel.error);
        _stopLoading(key);
        return;
      }
      final userModel = UserModel(
        uid: uid,
        name: _testName,
        email: _testEmail,
        phone: '+91 9000000000',
        profileImage: '',
        emailVerified: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        lastSeen: DateTime.now(),
        isOnline: true,
        gender: '',
      );
      final result = await _userRepository.createUser(userModel);
      if (result is Success<void>) {
        _log(
          '✅ Firestore user document created → uid: $uid',
          level: _LogLevel.success,
        );
      } else if (result is Failure<void>) {
        _log(
          '❌ Create Firestore user failed: ${result.message}',
          level: _LogLevel.error,
        );
      }
    } catch (e) {
      _log('❌ Create Firestore user exception: $e', level: _LogLevel.error);
    } finally {
      _stopLoading(key);
    }
  }

  Future<void> _readFirestoreUser() async {
    const key = 'readUser';
    _startLoading(key);
    _log('⏳ Reading Firestore user document…', level: _LogLevel.loading);
    try {
      final uid = _authService.currentUser?.uid;
      if (uid == null) {
        _log('❌ No authenticated user. Login first.', level: _LogLevel.error);
        _stopLoading(key);
        return;
      }
      final result = await _userRepository.getUser(uid);
      if (result is Success<UserModel>) {
        final u = result.data;
        _log(
          '✅ Read success →\n'
          '   uid:   ${u.uid}\n'
          '   name:  ${u.name}\n'
          '   email: ${u.email}\n'
          '   phone: ${u.phone}\n'
          '   img:   ${u.profileImage.isEmpty ? "(empty)" : u.profileImage}',
          level: _LogLevel.success,
        );
      } else if (result is Failure<UserModel>) {
        _log('❌ Read failed: ${result.message}', level: _LogLevel.error);
      }
    } catch (e) {
      _log('❌ Read exception: $e', level: _LogLevel.error);
    } finally {
      _stopLoading(key);
    }
  }

  Future<void> _updateFirestoreUser() async {
    const key = 'updateUser';
    _startLoading(key);
    _log('⏳ Updating Firestore user profile fields…', level: _LogLevel.loading);
    try {
      final uid = _authService.currentUser?.uid;
      if (uid == null) {
        _log('❌ No authenticated user. Login first.', level: _LogLevel.error);
        _stopLoading(key);
        return;
      }
      final result = await _userRepository.updateProfile(
        uid: uid,
        updates: {'name': 'Test User Updated', 'phone': '9876543210'},
      );
      if (result is Success<void>) {
        _log(
          '✅ Firestore user profile updated successfully.',
          level: _LogLevel.success,
        );
      } else if (result is Failure<void>) {
        _log('❌ Update failed: ${result.message}', level: _LogLevel.error);
      }
    } catch (e) {
      _log('❌ Update exception: $e', level: _LogLevel.error);
    } finally {
      _stopLoading(key);
    }
  }

  Future<void> _uploadProfileImageToCloudinary() async {
    const key = 'uploadImage';
    _startLoading(key);
    _log('⏳ Picking image from gallery…', level: _LogLevel.loading);
    try {
      final uid = _authService.currentUser?.uid;
      if (uid == null) {
        _log('❌ No authenticated user. Login first.', level: _LogLevel.error);
        _stopLoading(key);
        return;
      }

      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 75,
        maxWidth: 800,
      );

      if (picked == null) {
        _log('⚠️ Image pick cancelled by user.', level: _LogLevel.info);
        _stopLoading(key);
        return;
      }

      _log('⏳ Uploading image via Firebase…', level: _LogLevel.loading);
      final result = await _profileRepository.uploadProfileImage(
        uid: uid,
        imageFile: picked,
      );

      if (result is Success<UserModel>) {
        _log(
          '✅ Image uploaded & Firestore updated →\n'
          '   profileImage: ${result.data.profileImage}',
          level: _LogLevel.success,
        );
      } else if (result is Failure<UserModel>) {
        _log('❌ Upload failed: ${result.message}', level: _LogLevel.error);
      }
    } catch (e) {
      _log('❌ Upload exception: $e', level: _LogLevel.error);
    } finally {
      _stopLoading(key);
    }
  }

  Future<void> _updateFirestoreProfileImageUrl() async {
    const key = 'updateImageUrl';
    _startLoading(key);
    _log(
      '⏳ Updating Firestore profileImage URL directly…',
      level: _LogLevel.loading,
    );
    try {
      final uid = _authService.currentUser?.uid;
      if (uid == null) {
        _log('❌ No authenticated user. Login first.', level: _LogLevel.error);
        _stopLoading(key);
        return;
      }
      const testUrl = 'https://res.cloudinary.com/demo/image/upload/sample.jpg';
      final result = await _userRepository.updateProfileImage(uid, testUrl);
      if (result is Success<void>) {
        _log(
          '✅ profileImage URL updated in Firestore → $testUrl',
          level: _LogLevel.success,
        );
      } else if (result is Failure<void>) {
        _log(
          '❌ Update profileImage URL failed: ${result.message}',
          level: _LogLevel.error,
        );
      }
    } catch (e) {
      _log('❌ Update profileImage URL exception: $e', level: _LogLevel.error);
    } finally {
      _stopLoading(key);
    }
  }

  Future<void> _streamCurrentUser() async {
    const key = 'stream';
    if (_userStreamSub != null) {
      await _userStreamSub!.cancel();
      _userStreamSub = null;
      _log('⏹  Stream stopped.', level: _LogLevel.info);
      setState(() => _loading[key] = false);
      return;
    }

    final uid = _authService.currentUser?.uid;
    if (uid == null) {
      _log('❌ No authenticated user. Login first.', level: _LogLevel.error);
      return;
    }

    _startLoading(key);
    _log(
      '📡 Subscribing to Firestore stream for uid: $uid',
      level: _LogLevel.loading,
    );

    _userStreamSub = _userRepository
        .streamUser(uid)
        .listen(
          (result) {
            if (result is Success<UserModel>) {
              final u = result.data;
              _log(
                '🔄 Stream update → name: ${u.name}  online: ${u.isOnline}  updatedAt: ${u.updatedAt}',
                level: _LogLevel.success,
              );
            } else if (result is Failure<UserModel>) {
              _log('❌ Stream error: ${result.message}', level: _LogLevel.error);
            }
          },
          onError: (Object e) {
            _log('❌ Stream exception: $e', level: _LogLevel.error);
            _userStreamSub = null;
            setState(() => _loading[key] = false);
          },
          onDone: () {
            _log('⏹  Stream closed.', level: _LogLevel.info);
            _userStreamSub = null;
            setState(() => _loading[key] = false);
          },
        );
  }

  Future<void> _logout() async {
    const key = 'logout';
    _startLoading(key);
    _log('⏳ Logging out…', level: _LogLevel.loading);

    await _userStreamSub?.cancel();
    _userStreamSub = null;

    try {
      final result = await _authService.logout();
      if (result is Success<void>) {
        _log('✅ Logged out successfully.', level: _LogLevel.success);
      } else if (result is Failure<void>) {
        _log('❌ Logout failed: ${result.message}', level: _LogLevel.error);
      }
    } catch (e) {
      _log('❌ Logout exception: $e', level: _LogLevel.error);
    } finally {
      _stopLoading(key);
    }
  }

  Future<void> _deleteAccount() async {
    const key = 'delete';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          '⚠️  Delete Account?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'This permanently deletes the Firebase Auth user AND the Firestore document. This cannot be undone.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white54),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Color(0xFFFF4C6A)),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      _log('⚠️  Delete account cancelled.', level: _LogLevel.info);
      return;
    }

    _startLoading(key);
    _log('⏳ Deleting account…', level: _LogLevel.loading);

    await _userStreamSub?.cancel();
    _userStreamSub = null;

    try {
      final result = await _authService.deleteAccount();
      if (result is Success<void>) {
        _log(
          '✅ Account deleted from Auth & Firestore.',
          level: _LogLevel.success,
        );
      } else if (result is Failure<void>) {
        _log('❌ Delete failed: ${result.message}', level: _LogLevel.error);
      }
    } catch (e) {
      _log('❌ Delete exception: $e', level: _LogLevel.error);
    } finally {
      _stopLoading(key);
    }
  }

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  @override
  void dispose() {
    _userStreamSub?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0D1A),
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF00E5A0).withAlpha(26),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFF00E5A0).withAlpha(77),
                ),
              ),
              child: const Icon(
                Icons.bug_report_rounded,
                color: Color(0xFF00E5A0),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Backend Test Console',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'DEV ONLY — Not for production',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 10,
                    color: const Color(0xFFFF4C6A),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: StreamBuilder<User?>(
              stream: FirebaseAuth.instance.authStateChanges(),
              builder: (context, snapshot) {
                final user = snapshot.data;
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: user != null
                        ? const Color(0xFF00E5A0).withAlpha(26)
                        : const Color(0xFFFF4C6A).withAlpha(26),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: user != null
                          ? const Color(0xFF00E5A0).withAlpha(128)
                          : const Color(0xFFFF4C6A).withAlpha(128),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: user != null
                              ? const Color(0xFF00E5A0)
                              : const Color(0xFFFF4C6A),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        user != null ? 'Auth: Active' : 'Auth: None',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 11,
                          color: user != null
                              ? const Color(0xFF00E5A0)
                              : const Color(0xFFFF4C6A),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(height: 1, color: const Color(0xFF1E1E3A)),

          // ── Button Grid ────────────────────────────────────────────────────
          Expanded(
            flex: 4,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _SectionLabel(label: 'Firebase'),
                  _TestButton(
                    id: 'initFirebase',
                    label: '1. Initialize Firebase',
                    icon: Icons.local_fire_department_rounded,
                    color: const Color(0xFFFF9800),
                    isLoading: _isLoading('initFirebase'),
                    onTap: _initializeFirebase,
                  ),
                  const SizedBox(height: 8),

                  _SectionLabel(label: 'Authentication'),
                  _TestButton(
                    id: 'register',
                    label: '2. Register User',
                    icon: Icons.person_add_alt_1_rounded,
                    color: const Color(0xFF7C4DFF),
                    isLoading: _isLoading('register'),
                    onTap: _registerUser,
                  ),
                  const SizedBox(height: 8),
                  _TestButton(
                    id: 'login',
                    label: '3. Login User',
                    icon: Icons.login_rounded,
                    color: const Color(0xFF448AFF),
                    isLoading: _isLoading('login'),
                    onTap: _loginUser,
                  ),
                  const SizedBox(height: 8),
                  _TestButton(
                    id: 'google',
                    label: '4. Google Login',
                    icon: Icons.g_mobiledata_rounded,
                    color: const Color(0xFFEA4335),
                    isLoading: _isLoading('google'),
                    onTap: _googleLogin,
                  ),
                  const SizedBox(height: 8),
                  _TestButton(
                    id: 'emailVerify',
                    label: '5. Send Email Verification',
                    icon: Icons.mark_email_read_rounded,
                    color: const Color(0xFF00BCD4),
                    isLoading: _isLoading('emailVerify'),
                    onTap: _sendEmailVerification,
                  ),
                  const SizedBox(height: 8),

                  _SectionLabel(label: 'Firestore'),
                  _TestButton(
                    id: 'createUser',
                    label: '6. Create Firestore User',
                    icon: Icons.cloud_upload_rounded,
                    color: const Color(0xFF00E5A0),
                    isLoading: _isLoading('createUser'),
                    onTap: _createFirestoreUser,
                  ),
                  const SizedBox(height: 8),
                  _TestButton(
                    id: 'readUser',
                    label: '7. Read Firestore User',
                    icon: Icons.cloud_download_rounded,
                    color: const Color(0xFF4CAF50),
                    isLoading: _isLoading('readUser'),
                    onTap: _readFirestoreUser,
                  ),
                  const SizedBox(height: 8),
                  _TestButton(
                    id: 'updateUser',
                    label: '8. Update Firestore User',
                    icon: Icons.edit_document,
                    color: const Color(0xFFFFC107),
                    isLoading: _isLoading('updateUser'),
                    onTap: _updateFirestoreUser,
                  ),
                  const SizedBox(height: 8),

                  _SectionLabel(label: 'Firebase Storage / Firestore'),
                  _TestButton(
                    id: 'uploadImage',
                    label: '9. Upload Profile Image via Firebase',
                    icon: Icons.image_rounded,
                    color: const Color(0xFFFF5722),
                    isLoading: _isLoading('uploadImage'),
                    onTap: _uploadProfileImageToCloudinary,
                  ),
                  const SizedBox(height: 8),
                  _TestButton(
                    id: 'updateImageUrl',
                    label: '10. Update Firestore profileImage URL',
                    icon: Icons.link_rounded,
                    color: const Color(0xFF9C27B0),
                    isLoading: _isLoading('updateImageUrl'),
                    onTap: _updateFirestoreProfileImageUrl,
                  ),
                  const SizedBox(height: 8),

                  _SectionLabel(label: 'Realtime'),
                  _TestButton(
                    id: 'stream',
                    label: _isLoading('stream')
                        ? '11. Stop Streaming User  ▐  Active'
                        : '11. Stream Current User',
                    icon: _isLoading('stream')
                        ? Icons.stop_circle_rounded
                        : Icons.stream_rounded,
                    color: const Color(0xFF00BCD4),
                    isLoading: false,
                    isActive: _isLoading('stream'),
                    onTap: _streamCurrentUser,
                  ),
                  const SizedBox(height: 8),

                  _SectionLabel(label: 'Session'),
                  _TestButton(
                    id: 'logout',
                    label: '12. Logout',
                    icon: Icons.logout_rounded,
                    color: const Color(0xFFFF9800),
                    isLoading: _isLoading('logout'),
                    onTap: _logout,
                  ),
                  const SizedBox(height: 8),
                  _TestButton(
                    id: 'delete',
                    label: '13. Delete Account',
                    icon: Icons.delete_forever_rounded,
                    color: const Color(0xFFFF4C6A),
                    isLoading: _isLoading('delete'),
                    onTap: _deleteAccount,
                    isDangerous: true,
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),

          // ── Console ────────────────────────────────────────────────────────
          Container(height: 1, color: const Color(0xFF00E5A0).withAlpha(77)),
          Container(
            color: const Color(0xFF06060F),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                const Icon(
                  Icons.terminal_rounded,
                  color: Color(0xFF00E5A0),
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  'Console Output',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 12,
                    color: const Color(0xFF00E5A0),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  '${_logs.length} entries',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 11,
                    color: Colors.white38,
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: _clearConsole,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E3A),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Text(
                      'Clear',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 11,
                        color: Colors.white54,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 3,
            child: _logs.isEmpty
                ? Center(
                    child: Text(
                      '// No output yet. Run a test above.',
                      style: GoogleFonts.jetBrainsMono(
                        color: Colors.white24,
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    itemCount: _logs.length,
                    itemBuilder: (context, index) {
                      final entry = _logs[index];
                      return _ConsoleLine(entry: entry);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// ─── Sub-widgets ──────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 6),
      child: Row(
        children: [
          Text(
            '// $label',
            style: GoogleFonts.jetBrainsMono(
              fontSize: 11,
              color: Colors.white30,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: Container(height: 1, color: Colors.white10)),
        ],
      ),
    );
  }
}

class _TestButton extends StatelessWidget {
  final String id;
  final String label;
  final IconData icon;
  final Color color;
  final bool isLoading;
  final bool isActive;
  final bool isDangerous;
  final VoidCallback onTap;

  const _TestButton({
    required this.id,
    required this.label,
    required this.icon,
    required this.color,
    required this.isLoading,
    required this.onTap,
    this.isActive = false,
    this.isDangerous = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isLoading ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        splashColor: color.withAlpha(51),
        highlightColor: color.withAlpha(26),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: isActive ? color.withAlpha(38) : const Color(0xFF13132A),
            border: Border.all(
              color: isActive
                  ? color.withAlpha(179)
                  : isDangerous
                  ? const Color(0xFFFF4C6A).withAlpha(77)
                  : color.withAlpha(51),
              width: isActive ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withAlpha(26),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: isLoading
                    ? Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(color),
                        ),
                      )
                    : Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: isLoading ? Colors.white38 : Colors.white,
                  ),
                ),
              ),
              if (isActive)
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color,
                    boxShadow: [
                      BoxShadow(color: color.withAlpha(128), blurRadius: 6),
                    ],
                  ),
                ),
              if (!isLoading && !isActive)
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.white24,
                  size: 14,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConsoleLine extends StatelessWidget {
  final _LogEntry entry;
  const _ConsoleLine({required this.entry});

  Color get _textColor {
    switch (entry.level) {
      case _LogLevel.success:
        return const Color(0xFF00E5A0);
      case _LogLevel.error:
        return const Color(0xFFFF4C6A);
      case _LogLevel.loading:
        return const Color(0xFFFFD54F);
      case _LogLevel.info:
        return const Color(0xFF90CAF9);
    }
  }

  Color get _bgColor {
    switch (entry.level) {
      case _LogLevel.success:
        return const Color(0xFF00E5A0).withAlpha(13);
      case _LogLevel.error:
        return const Color(0xFFFF4C6A).withAlpha(13);
      case _LogLevel.loading:
        return const Color(0xFFFFD54F).withAlpha(10);
      case _LogLevel.info:
        return Colors.transparent;
    }
  }

  String get _prefix {
    final ts = entry.timestamp;
    final h = ts.hour.toString().padLeft(2, '0');
    final m = ts.minute.toString().padLeft(2, '0');
    final s = ts.second.toString().padLeft(2, '0');
    return '[$h:$m:$s]';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _prefix,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 11,
              color: Colors.white24,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              entry.message,
              style: GoogleFonts.jetBrainsMono(
                fontSize: 12,
                color: _textColor,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
