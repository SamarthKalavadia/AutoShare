import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';

import '../auth/presentation/controllers/auth_controller.dart';
import 'providers/user_profile_provider.dart';
import 'providers/profile_stats_provider.dart';
import 'edit_profile_page.dart';
import '../settings/providers/settings_provider.dart';
import '../settings/security_settings_page.dart';
import '../../data/models/user_model.dart';
import '../../data/models/rating_model.dart';
import '../../data/repositories/rating_repository.dart';
import '../../data/models/report_model.dart';
import '../../shared/utils/avatar_utils.dart';

/// The current logged-in user's own profile page (for bottom nav tab).
class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(authControllerProvider);
    return userAsync.when(
      data: (user) {
        if (user == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) {
              context.go('/login');
            }
          });
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        return _ProfileBody(userId: user.uid, isOwnProfile: true);
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
    );
  }
}

/// Public profile view for viewing another user's profile.
class PublicProfilePage extends ConsumerWidget {
  final String userId;
  const PublicProfilePage({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _ProfileBody(userId: userId, isOwnProfile: false);
  }
}

class _ProfileBody extends ConsumerWidget {
  final String userId;
  final bool isOwnProfile;

  const _ProfileBody({required this.userId, required this.isOwnProfile});

  void _showDeleteAccountDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Delete Account', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700, color: const Color(0xFFD32F2F))),
        content: Text(
          'Are you sure you want to delete your account? This action is permanent and will delete all your data, rides, and settings.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : const Color(0xFF6F6F72)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (_) => const Center(child: CircularProgressIndicator(color: Color(0xFFD32F2F))),
              );
              try {
                await ref.read(authControllerProvider.notifier).deleteAccount();
              } catch (_) {
              } finally {
                if (context.mounted) {
                  if (Navigator.of(context, rootNavigator: true).canPop()) {
                    Navigator.of(context, rootNavigator: true).pop();
                  }
                  context.go('/login');
                }
              }
            },
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFD32F2F)),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider(userId));
    final ratingsAsync = ref.watch(userRatingsProvider(userId));
    
    // For own profile settings
    final settings = ref.watch(settingsProvider);
    final settingsNotifier = ref.read(settingsProvider.notifier);

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final blackColor = theme.colorScheme.onSurface;
    final mutedText = isDark ? Colors.white60 : const Color(0xFF6F6F72);
    final backgroundColor = theme.scaffoldBackgroundColor;
    final cardColor = theme.cardTheme.color ?? (isDark ? const Color(0xFF1E1E1E) : const Color(0xFFFFFFFF));
    final borderColor = isDark ? const Color(0xFF333333) : const Color(0xFFEAE5DD);
    final primaryColor = theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: profileAsync.when(
        data: (user) {
          final ratings = ratingsAsync.value ?? [];
          return CustomScrollView(
            slivers: [
              // ── Header SliverAppBar ──
              SliverAppBar(
                expandedHeight: isOwnProfile ? 320 : 260,
                pinned: true,
                backgroundColor: backgroundColor,
                elevation: 0,
                scrolledUnderElevation: 0,
                actions: isOwnProfile
                    ? [] // Moved settings into body
                    : [
                        _MoreMenu(user: user, ref: ref),
                      ],
                flexibleSpace: FlexibleSpaceBar(
                  background: _ProfileHeader(user: user, isOwnProfile: isOwnProfile),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (isOwnProfile) ...[
                        // ── Statistics Grid ──
                        Consumer(
                          builder: (ctx, ref, _) {
                            final statsAsync = ref.watch(profileStatsProvider);
                            final stats = statsAsync.value ?? const ProfileStats();
                            return Column(
                              children: [
                                GridView.count(
                                  crossAxisCount: 2,
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 12,
                                  childAspectRatio: 2.2,
                                  children: [
                                    _StatCard(title: 'Created Rides', value: stats.createdRides.toString(), icon: Icons.local_taxi_rounded),
                                    _StatCard(title: 'Joined Rides', value: stats.joinedRides.toString(), icon: Icons.hail_rounded),
                                    _StatCard(title: 'Completed Rides', value: stats.completedRides.toString(), icon: Icons.check_circle_rounded, isSuccess: true),
                                    _StatCard(title: 'Cancelled Rides', value: stats.cancelledRides.toString(), icon: Icons.cancel_outlined),
                                  ],
                                ),
                              ],
                            );
                          }
                        ),
                        const SizedBox(height: 32),
                        
                        _buildSectionTitle(context, 'Account'),
                        _buildProfileTile(context, icon: Icons.person_outline, title: 'Edit Profile', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfilePage()))),
                        _buildProfileTile(context, icon: Icons.camera_alt_outlined, title: 'Change Profile Picture', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfilePage()))),
                        _buildProfileTile(context, icon: Icons.lock_outline, title: 'Change Password', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SecuritySettingsPage()))),
                        _buildProfileTile(context, icon: Icons.password_rounded, title: 'Forgot Password', onTap: () => context.push('/forgot-password')),
                        _buildProfileTile(
                          context,
                          icon: Icons.mark_email_read_outlined, 
                          title: 'Email Verification Status', 
                          trailingText: user.emailVerified ? 'Verified' : 'Unverified',
                          onTap: () {
                            if (!user.emailVerified) context.push('/email-verification');
                          }
                        ),
                        
                        const SizedBox(height: 24),
                        _buildSectionTitle(context, 'Settings'),
                        _buildSwitchTile(context, icon: Icons.notifications_none, title: 'Notifications', value: settings.pushNotifications, onChanged: settingsNotifier.togglePushNotifications),
                        _buildSwitchTile(context, icon: Icons.dark_mode_outlined, title: 'Dark Mode', value: settings.isDarkMode, onChanged: settingsNotifier.toggleDarkMode),
                        _buildProfileTile(context, icon: Icons.privacy_tip_outlined, title: 'Privacy', onTap: () {}),
                        _buildProfileTile(context, icon: Icons.language, title: 'Language', trailingText: settings.language, onTap: () {}),
                        
                        const SizedBox(height: 24),
                        _buildSectionTitle(context, 'About'),
                        _buildProfileTile(context, icon: Icons.info_outline, title: 'About AutoShare', onTap: () {}),
                        _buildProfileTile(context, icon: Icons.help_outline, title: 'Help & Support', onTap: () {}),
                        _buildProfileTile(context, icon: Icons.description_outlined, title: 'Terms & Conditions', onTap: () {}),
                        _buildProfileTile(context, icon: Icons.shield_outlined, title: 'Privacy Policy', onTap: () {}),

                        const SizedBox(height: 24),
                        _buildProfileTile(
                          context,
                          icon: Icons.delete_outline, 
                          title: 'Delete Account', 
                          color: const Color(0xFFD32F2F), 
                          onTap: () => _showDeleteAccountDialog(context, ref)
                        ),
                        _buildProfileTile(
                          context,
                          icon: Icons.logout_rounded, 
                          title: 'Logout', 
                          color: const Color(0xFFD32F2F), 
                          onTap: () async {
                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (_) => const Center(child: CircularProgressIndicator()),
                            );
                            try {
                              await ref.read(authControllerProvider.notifier).logout();
                            } catch (_) {
                            } finally {
                              if (context.mounted) {
                                if (Navigator.of(context, rootNavigator: true).canPop()) {
                                  Navigator.of(context, rootNavigator: true).pop();
                                }
                                context.go('/login');
                              }
                            }
                          }
                        ),
                        const SizedBox(height: 40),
                      ] else ...[
                        // ── Rating Summary Card (Public Profile) ──
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: borderColor),
                            boxShadow: const [
                              BoxShadow(color: Color(0x0F121212), blurRadius: 14, offset: Offset(0, 6)),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    user.averageRating > 0
                                        ? user.averageRating.toStringAsFixed(1)
                                        : '—',
                                    style: theme.textTheme.displayMedium?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      color: blackColor,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: List.generate(5, (i) {
                                          final filled = i < user.averageRating.round();
                                          return Icon(
                                            filled ? Icons.star_rounded : Icons.star_outline_rounded,
                                            color: filled ? primaryColor : const Color(0xFFE0E0E0),
                                            size: 20,
                                          );
                                        }),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${user.totalReviews} ${user.totalReviews == 1 ? 'review' : 'reviews'}',
                                        style: theme.textTheme.labelMedium?.copyWith(
                                          color: mutedText,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              if (ratings.isNotEmpty) ...[
                                const SizedBox(height: 20),
                                // Distribution bars
                                ...List.generate(5, (i) {
                                  final star = 5 - i;
                                  final count = ratings.where((r) => r.rating == star).length;
                                  final fraction = ratings.isEmpty ? 0.0 : count / ratings.length;
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 3),
                                    child: Row(
                                      children: [
                                        Text(
                                          '$star',
                                          style: theme.textTheme.labelSmall?.copyWith(
                                            color: mutedText,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        const Icon(Icons.star_rounded, size: 12, color: Color(0xFFF6C000)),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(4),
                                            child: LinearProgressIndicator(
                                              value: fraction,
                                              backgroundColor: const Color(0xFFF0EDE9),
                                              valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                                              minHeight: 8,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          '$count',
                                          style: theme.textTheme.labelSmall?.copyWith(
                                            color: mutedText,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                              ],
                            ],
                          ),
                        ),

                        const SizedBox(height: 28),

                        if (ratings.isNotEmpty) ...[
                          Text(
                            'Recent Reviews',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: blackColor,
                            ),
                          ),
                          const SizedBox(height: 14),
                          ...ratings
                              .where((r) => r.review.isNotEmpty)
                              .take(10)
                              .map((r) => _ReviewCard(rating: r)),
                        ],
                      ]
                    ],
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error loading profile: $e')),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title, {Color? color}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultColor = isDark ? Colors.white70 : const Color(0xFF6F6F72);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w700,
          color: color ?? defaultColor,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildProfileTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? trailingText,
    required VoidCallback onTap,
    Color? color,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveColor = color ?? (isDark ? Colors.white : const Color(0xFF121212));
    final chevronColor = color ?? (isDark ? Colors.white54 : const Color(0xFF8E8E93));
    final subtextColor = isDark ? Colors.white60 : const Color(0xFF6F6F72);

    return ListTile(
      onTap: onTap,
      title: Text(title, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600, color: effectiveColor)),
      leading: Icon(icon, color: effectiveColor, size: 22),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trailingText != null)
            Text(trailingText, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: subtextColor, fontWeight: FontWeight.w500)),
          if (trailingText != null) const SizedBox(width: 8),
          Icon(Icons.chevron_right_rounded, color: chevronColor, size: 20),
        ],
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  Widget _buildSwitchTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF121212);
    final theme = Theme.of(context);

    return SwitchListTile(
      value: value,
      onChanged: onChanged,
      title: Text(title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600, color: textColor)),
      secondary: Icon(icon, color: textColor, size: 22),
      activeTrackColor: theme.colorScheme.primary,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}

class _ProfileHeader extends ConsumerWidget {
  final UserModel user;
  final bool isOwnProfile;

  const _ProfileHeader({required this.user, required this.isOwnProfile});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final blackColor = theme.colorScheme.onSurface;
    const successColor = Color(0xFF2E7D32);
    final avatarBgColor = isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE7E4DF);
    final chipBgColor = isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF0EDE9);
    final mutedTextColor = isDark ? Colors.white60 : const Color(0xFF6F6F72);

    return Container(
      color: theme.scaffoldBackgroundColor,
      padding: const EdgeInsets.fromLTRB(24, 100, 24, 16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 44,
            backgroundColor: avatarBgColor,
            backgroundImage: getAvatarImageProvider(user.profileImage),
            child: getAvatarImageProvider(user.profileImage) == null
                ? Text(
                    user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: blackColor,
                    ),
                  )
                : null,
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                user.name,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: blackColor,
                ),
              ),
              if (user.emailVerified) ...[
                const SizedBox(width: 6),
                const Icon(Icons.verified_rounded, color: successColor, size: 20),
              ]
            ],
          ),
          const SizedBox(height: 4),
          Text(
            user.email,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: mutedTextColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (isOwnProfile) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _Chip(
                  icon: Icons.star_rounded,
                  label: user.averageRating > 0 ? user.averageRating.toStringAsFixed(1) : 'No Ratings',
                  color: const Color(0xFF7C5700),
                  bgColor: const Color(0xFFFFF2CC),
                ),
                const SizedBox(width: 8),
                _Chip(
                  icon: Icons.calendar_today_rounded,
                  label: 'Joined ${DateFormat('MMM yyyy').format(user.createdAt)}',
                  color: blackColor,
                  bgColor: chipBgColor,
                ),
              ],
            ),
          ] else ...[
            const SizedBox(height: 16),
            // ── Verified / Gender Badge Row for Public Profile ──
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (user.emailVerified)
                  _Chip(
                    icon: Icons.verified_rounded,
                    label: 'Verified',
                    color: successColor,
                    bgColor: const Color(0xFFEAF5ED),
                  ),
                const SizedBox(width: 10),
                if (user.gender.isNotEmpty)
                  _Chip(
                    icon: user.gender.toLowerCase() == 'female'
                        ? Icons.female_rounded
                        : Icons.male_rounded,
                    label: user.gender,
                    color: blackColor,
                    bgColor: chipBgColor,
                  ),
                if (user.averageRating >= 4.5) ...[
                  const SizedBox(width: 10),
                  _Chip(
                    icon: Icons.star_rounded,
                    label: user.averageRating.toStringAsFixed(1),
                    color: const Color(0xFF7C5700),
                    bgColor: const Color(0xFFFFF2CC),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _MoreMenu extends StatelessWidget {
  final UserModel user;
  final WidgetRef ref;

  const _MoreMenu({required this.user, required this.ref});

  void _showReportDialog(BuildContext context) {
    const reasons = ['Spam', 'Fake Ride', 'Unsafe Behaviour', 'Late Arrival', 'Other'];
    String? selected = reasons.first;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Report User', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: reasons
                .map(
                  (reason) => ListTile(
                    title: Text(reason, style: Theme.of(context).textTheme.bodyLarge),
                    leading: Icon(
                      selected == reason
                          ? Icons.radio_button_checked
                          : Icons.radio_button_off,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    onTap: () => setS(() => selected = reason),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                )
                .toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                Navigator.pop(ctx);
                final currentUser = ref.read(authControllerProvider).value;
                if (currentUser == null) return;
                final repo = ref.read(ratingRepositoryProvider);
                await repo.reportUser(ReportModel(
                  reportId: '',
                  reporterUid: currentUser.uid,
                  reportedUid: user.uid,
                  reason: selected ?? 'Other',
                  createdAt: DateTime.now(),
                ));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Report submitted. We will review shortly.'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              style: FilledButton.styleFrom(backgroundColor: const Color(0xFF121212)),
              child: const Text('Submit Report'),
            ),
          ],
        ),
      ),
    );
  }

  void _showBlockDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Block ${user.name}?', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
        content: Text(
          'Blocking this user will prevent them from chatting, requesting rides, or seeing your listings.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : const Color(0xFF6F6F72)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final currentUser = ref.read(authControllerProvider).value;
              if (currentUser == null) return;
              final repo = ref.read(ratingRepositoryProvider);
              await repo.blockUser(currentUser.uid, user.uid);
              if (context.mounted) {
                Navigator.of(context).pop(); // Pop profile page
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${user.name} has been blocked.'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFD32F2F)),
            child: const Text('Block'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert_rounded, color: Color(0xFF121212)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      onSelected: (value) {
        if (value == 'report') _showReportDialog(context);
        if (value == 'block') _showBlockDialog(context);
      },
      itemBuilder: (_) => [
        PopupMenuItem(
          value: 'report',
          child: Row(
            children: [
              Icon(Icons.flag_outlined, color: Theme.of(context).colorScheme.onSurface, size: 20),
              const SizedBox(width: 12),
              Text('Report User', style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'block',
          child: Row(
            children: [
              const Icon(Icons.block_rounded, color: Color(0xFFD32F2F), size: 20),
              const SizedBox(width: 12),
              Text('Block User', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: const Color(0xFFD32F2F))),
            ],
          ),
        ),
      ],
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final RatingModel rating;
  const _ReviewCard({required this.rating});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardBg = theme.cardTheme.color ?? (isDark ? const Color(0xFF1E1E1E) : Colors.white);
    final borderColor = isDark ? const Color(0xFF333333) : const Color(0xFFEAE5DD);
    final textColor = theme.colorScheme.onSurface;
    final subtextColor = isDark ? Colors.white60 : const Color(0xFF6F6F72);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Row(
                children: List.generate(5, (i) {
                  final filled = i < rating.rating;
                  return Icon(
                    filled ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: filled ? const Color(0xFFF6C000) : (isDark ? Colors.grey[700] : const Color(0xFFE0E0E0)),
                    size: 16,
                  );
                }),
              ),
              const Spacer(),
              Text(
                DateFormat('MMM d, yyyy').format(rating.createdAt),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: subtextColor,
                ),
              ),
            ],
          ),
          if (rating.review.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              rating.review,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: textColor,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color bgColor;

  const _Chip({
    required this.icon,
    required this.label,
    required this.color,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final bool isSuccess;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    this.isSuccess = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isSuccess
        ? (isDark ? const Color(0xFF1B382B) : const Color(0xFFEAF5ED))
        : (isDark ? const Color(0xFF242424) : const Color(0xFFF0EDE9));
    final contentColor = isSuccess
        ? (isDark ? const Color(0xFF81C784) : const Color(0xFF2E7D32))
        : (isDark ? Colors.white : const Color(0xFF121212));
    final subtextColor = isDark ? Colors.white60 : const Color(0xFF6F6F72);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: contentColor),
              const SizedBox(width: 6),
              Text(
                value,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: contentColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: subtextColor,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _SustainabilityCard extends StatelessWidget {
  final double co2SavedKg;
  final int treesPlanted;
  final double greenMiles;

  const _SustainabilityCard({
    required this.co2SavedKg,
    required this.treesPlanted,
    required this.greenMiles,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final bgGradient = isDark
        ? const LinearGradient(colors: [Color(0xFF1A3824), Color(0xFF102818)])
        : const LinearGradient(colors: [Color(0xFFE8F5E9), Color(0xFFC8E6C9)]);
        
    final accentColor = isDark ? const Color(0xFF81C784) : const Color(0xFF2E7D32);
    final textColor = isDark ? Colors.white : const Color(0xFF1B5E20);
    final subtextColor = isDark ? Colors.white70 : const Color(0xFF388E3C);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: bgGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: isDark ? [] : [
          BoxShadow(
            color: const Color(0xFF4CAF50).withValues(alpha: 0.1),
            blurRadius: 16,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.eco_rounded, color: accentColor, size: 24),
              const SizedBox(width: 8),
              Text(
                'Impact',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: textColor,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'AutoShare Green',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: accentColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _ImpactMetric(
                  icon: Icons.cloud_outlined,
                  value: '${co2SavedKg.toStringAsFixed(1)} kg',
                  label: 'CO₂ Saved',
                  color: textColor,
                  subColor: subtextColor,
                ),
              ),
              Container(width: 1, height: 40, color: accentColor.withValues(alpha: 0.3)),
              Expanded(
                child: _ImpactMetric(
                  icon: Icons.forest_outlined,
                  value: '$treesPlanted',
                  label: 'Trees',
                  color: textColor,
                  subColor: subtextColor,
                ),
              ),
              Container(width: 1, height: 40, color: accentColor.withValues(alpha: 0.3)),
              Expanded(
                child: _ImpactMetric(
                  icon: Icons.directions_bike_outlined,
                  value: '${greenMiles.toStringAsFixed(0)} mi',
                  label: 'Green Miles',
                  color: textColor,
                  subColor: subtextColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ImpactMetric extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  final Color subColor;

  const _ImpactMetric({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    required this.subColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 20, color: subColor),
        const SizedBox(height: 6),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.w500,
            color: subColor,
          ),
        ),
      ],
    );
  }
}
