import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const HomeTab(),
    const SearchPage(),
    const ChatsListPage(),
    const NotificationsPage(),
    const ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    ref.listen(
      authControllerProvider,
      (previous, next) {
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
      },
    );

    ref.listen<AsyncValue<PendingRatingPrompt?>>(
      ratingsPromptProvider,
      (previous, next) {
        final prompt = next.value;
        if (prompt != null && (previous?.value?.ride.id != prompt.ride.id)) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              RatingBottomSheet.show(context, prompt);
            }
          });
        }
      },
    );

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: NavigationBar(
        height: 76,
        backgroundColor: isDark ? const Color(0xFF181818) : Colors.white,
        elevation: 0,
        indicatorColor: isDark ? const Color(0xFF4A3E00) : const Color(0xFFFFF2CC),
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          const NavigationDestination(
            icon: Icon(Icons.search_outlined),
            selectedIcon: Icon(Icons.search_rounded),
            label: 'Search',
          ),
          NavigationDestination(
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.chat_bubble_outline_rounded),
                Consumer(
                  builder: (ctx, ref, _) {
                    final chatCount = ref.watch(unreadChatCountProvider);
                    if (chatCount == 0) return const SizedBox.shrink();
                    return Positioned(
                      right: -4,
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
              ],
            ),
            selectedIcon: const Icon(Icons.chat_bubble_rounded),
            label: 'Chats',
          ),
          NavigationDestination(
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.notifications_none_rounded),
                Consumer(
                  builder: (ctx, ref, _) {
                    final count = ref.watch(unreadNotificationCountProvider);
                    if (count == 0) return const SizedBox.shrink();
                    return Positioned(
                      right: -4,
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
            selectedIcon: const Icon(Icons.notifications_rounded),
            label: 'Notifications',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
