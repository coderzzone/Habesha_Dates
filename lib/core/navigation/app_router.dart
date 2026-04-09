import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/complete_profile_screen.dart';
import '../../features/auth/register_screen.dart';
import '../../features/discovery/discovery_screen.dart';
import '../../features/chat/chat_list_screen.dart';
import '../../features/chat/chat_room_screen.dart';
import '../../features/profile/settings_screen.dart';
import '../../features/profile/profile_view_screen.dart';
import '../../features/profile/profile_edit_screen.dart';
import '../../features/profile/verification_screen.dart'; // Import your new screen
import '../../features/discovery/profile_details_screen.dart';
import '../../features/profile/following_screen.dart';
import '../../features/discovery/nearby_users_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/monetization/paywall_screen.dart';
import '../../features/monetization/telebirr_payment_screen.dart';
import '../../features/discovery/gold_membership_screen.dart';
import '../../features/notifications/notifications_screen.dart';

class AppRouter {
  AppRouter(String initialLocation) {
    router = GoRouter(
      navigatorKey: _rootNavigatorKey,
      initialLocation: initialLocation,
      debugLogDiagnostics: true,
      routes: [
        GoRoute(
          path: '/onboarding',
          name: 'onboarding',
          builder: (context, state) => const OnboardingScreen(),
        ),
        GoRoute(
          path: '/',
          name: 'login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/register',
          name: 'register',
          builder: (context, state) => const RegisterScreen(),
        ),
        GoRoute(
          path: '/complete-profile',
          name: 'complete-profile',
          builder: (context, state) => const CompleteProfileScreen(),
        ),

        // GLOBAL ROUTE: Chat Room
        GoRoute(
          path: '/chat_room/:chatId',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) {
            final chatId = state.pathParameters['chatId']!;
            final name = state.uri.queryParameters['name'] ?? 'Chat';
            return ChatRoomScreen(chatId: chatId, partnerName: name);
          },
        ),

        // GLOBAL ROUTE: Verification (FIXED)
        GoRoute(
          path: '/verification',
          parentNavigatorKey: _rootNavigatorKey, // This makes it cover the bottom bar
          builder: (context, state) => const VerificationScreen(),
        ),

        GoRoute(
          path: '/nearby',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) => const NearbyUsersScreen(),
        ),

        GoRoute(
          path: '/profile_details/:userId',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) {
            final userId = state.pathParameters['userId']!;
            return ProfileDetailsScreen(userId: userId);
          },
        ),

        GoRoute(
          path: '/premium',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) => const GoldMembershipScreen(),
        ),

        GoRoute(
          path: '/paywall',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) {
            final reason = state.uri.queryParameters['reason'] ?? 'Upgrade to continue using premium features.';
            return PaywallScreen(reason: reason);
          },
        ),

        GoRoute(
          path: '/telebirr',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) {
            final amount = double.tryParse(state.uri.queryParameters['amount'] ?? '') ?? 600.0;
            return TelebirrPaymentScreen(amount: amount);
          },
        ),

        GoRoute(
          path: '/notifications',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) => const NotificationsScreen(),
        ),

        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) {
            return ScaffoldWithNavBar(navigationShell: navigationShell);
          },
          branches: [
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/discovery',
                  builder: (context, state) => const DiscoveryScreen(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/chat',
                  builder: (context, state) => const ChatListScreen(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/profile_view',
                  builder: (context, state) => const ProfileViewScreen(),
                ),
                GoRoute(
                  path: '/profile_edit',
                  builder: (context, state) => const ProfileEditScreen(),
                ),
                GoRoute(
                  path: '/following',
                  builder: (context, state) => const FollowingScreen(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/settings',
                  builder: (context, state) => const SettingsScreen(),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();
  late final GoRouter router;
}

class ScaffoldWithNavBar extends StatelessWidget {
  final StatefulNavigationShell navigationShell;
  const ScaffoldWithNavBar({required this.navigationShell, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      body: Stack(
        children: [
          // MAIN CONTENT (Takes full height)
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 90),
              child: navigationShell,
            ),
          ),

          // GLASSMORPHIC FLOATING NAV BAR
          Positioned(
            left: 20,
            right: 20,
            bottom: 25,
            child: _buildGlassNavBar(context),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassNavBar(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          height: 75,
          decoration: BoxDecoration(
            // Semi-transparent background (Glass)
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(30),
            // Glass edge
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.1),
              width: 1.5,
            ),
            // Soft shadows (Neumorphism)
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 20,
                offset: const Offset(5, 10),
              ),
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(-2, -2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildNavItem(0, Icons.explore_rounded, 'Discover'),
              _buildNavItem(1, Icons.chat_bubble_rounded, 'Chats'),
              _buildNavItem(2, Icons.person_rounded, 'Profile'),
              _buildNavItem(3, Icons.settings_rounded, 'Settings'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = navigationShell.currentIndex == index;

    return GestureDetector(
      onTap: () => navigationShell.goBranch(
        index,
        initialLocation: index == navigationShell.currentIndex,
      ),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.gold : Colors.white30,
              size: isSelected ? 28 : 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? AppColors.gold : Colors.white30,
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
