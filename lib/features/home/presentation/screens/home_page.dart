import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'home_tab.dart';
import '../../../search/search_page.dart';
import '../../../chat/chats_list_page.dart';
import '../../../notifications/notifications_page.dart';
import '../../../profile/profile_page.dart';
import '../../providers/home_dashboard_provider.dart';
import '../../../notifications/providers/notification_provider.dart';
import '../../../ratings/providers/ratings_prompt_provider.dart';
import '../../../ratings/widgets/rating_bottom_sheet.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';

class HomeNavigationNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void setIndex(int index) {
    state = index;
  }
}
final homeNavigationProvider = NotifierProvider<HomeNavigationNotifier, int>(HomeNavigationNotifier.new);

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {

  final List<Widget> _pages = [
    const HomeTab(),
    const SearchPage(),
    const ChatsListPage(),
    const NotificationsPage(),
    const ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    ref.listen(authControllerProvider, (previous, next) {
      if (!next.isLoading && next.value == null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            if (Navigator.of(context, rootNavigator: true).canPop()) {
              Navigator.of(context, rootNavigator: true).pop();
            }
            context.go('/login');
          }
        });
      }
    });

    ref.listen<AsyncValue<PendingRatingPrompt?>>(ratingsPromptProvider, (
      previous,
      next,
    ) {
      final prompt = next.value;
      if (prompt != null && (previous?.value?.ride.id != prompt.ride.id)) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            RatingBottomSheet.show(context, prompt);
          }
        });
      }
    });

    final currentIndex = ref.watch(homeNavigationProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: IndexedStack(index: currentIndex, children: _pages),
      bottomNavigationBar: _buildBottomNavigationBar(context, isDark, currentIndex),
    );
  }

  Widget _buildBottomNavigationBar(BuildContext context, bool isDark, int currentIndex) {
    final surfaceColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final borderColor = isDark
        ? Colors.white10
        : Colors.black.withOpacity(0.05);
    final shadowColor = Colors.black.withOpacity(isDark ? 0.2 : 0.04);

    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        border: Border(top: BorderSide(color: borderColor, width: 0.5)),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Container(
          height: 64, // Compact height
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                0,
                'Home',
                Icons.home_rounded,
                Icons.home_outlined,
                isDark,
                currentIndex,
              ),
              _buildNavItem(
                1,
                'Search',
                Icons.search_rounded,
                Icons.search_outlined,
                isDark,
                currentIndex,
              ),
              _buildNavItem(
                2,
                'Chats',
                Icons.chat_bubble_rounded,
                Icons.chat_bubble_outline_rounded,
                isDark,
                currentIndex,
                hasChatBadge: true,
              ),
              _buildNavItem(
                3,
                'Notifications',
                Icons.notifications_rounded,
                Icons.notifications_none_rounded,
                isDark,
                currentIndex,
                hasNotifBadge: true,
              ),
              _buildNavItem(
                4,
                'Profile',
                Icons.person_rounded,
                Icons.person_outline_rounded,
                isDark,
                currentIndex,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    int index,
    String label,
    IconData activeIcon,
    IconData inactiveIcon,
    bool isDark,
    int currentIndex, {
    bool hasChatBadge = false,
    bool hasNotifBadge = false,
  }) {
    final isSelected = currentIndex == index;
    final inactiveColor = isDark
        ? const Color(0xFFA1A1A1)
        : const Color(0xFF6F6F72);
    final activeColor = const Color(0xFFFFC400); // AutoShare Yellow
    final activeIconColor =
        Colors.black87; // Dark icon for contrast inside yellow pill

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        ref.read(homeNavigationProvider.notifier).setIndex(index);
      },
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                // Active Indicator Capsule
                if (isSelected)
                  Container(
                    width: 44,
                    height: 28,
                    decoration: BoxDecoration(
                      color: activeColor,
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),

                // Icon
                SizedBox(
                  width: 44,
                  height: 28,
                  child: Center(
                    child: Icon(
                      isSelected ? activeIcon : inactiveIcon,
                      color: isSelected ? activeIconColor : inactiveColor,
                      size: 24,
                    ),
                  ),
                ),

                // Badges
                if (hasChatBadge)
                  Consumer(
                    builder: (ctx, ref, _) {
                      final chatCount = ref.watch(unreadChatCountProvider);
                      if (chatCount == 0) return const SizedBox.shrink();
                      return Positioned(
                        right: 2,
                        top: -4,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Color(0xFFFF4444),
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '$chatCount',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                if (hasNotifBadge)
                  Consumer(
                    builder: (ctx, ref, _) {
                      final count = ref.watch(unreadNotificationCountProvider);
                      if (count == 0) return const SizedBox.shrink();
                      return Positioned(
                        right: 2,
                        top: -4,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Color(0xFFFF4444),
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            count > 99 ? '99+' : '$count',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),

          ],
        ),
      ),
    );
  }
}
