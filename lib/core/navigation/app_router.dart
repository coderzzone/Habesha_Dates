import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/login_screen.dart';
import '../../features/discovery/discovery_screen.dart';
import '../../features/chat/chat_list_screen.dart';
import '../../features/chat/chat_room_screen.dart';
import '../../features/profile/settings_screen.dart';
import '../../features/profile/profile_view_screen.dart';
import '../../features/profile/profile_edit_screen.dart';
import '../../features/profile/verification_screen.dart'; // Import your new screen
import '../../features/discovery/profile_details_screen.dart';

class AppRouter {
  static final _rootNavigatorKey = GlobalKey<NavigatorState>();

  static final router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    debugLogDiagnostics: true,
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const LoginScreen(),
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

      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return ScaffoldWithNavBar(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/discovery', builder: (context, state) => const DiscoveryScreen()),
              GoRoute(path: '/profile_details/:userId', builder: (context, state) {
                final userId = state.pathParameters['userId']!;
                return ProfileDetailsScreen(userId: userId);
              }),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/chat', builder: (context, state) => const ChatListScreen()),
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
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/settings', builder: (context, state) => const SettingsScreen()),
            ],
          ),
        ],
      ),
    ],
  );
}

class ScaffoldWithNavBar extends StatelessWidget {
  final StatefulNavigationShell navigationShell;
  const ScaffoldWithNavBar({required this.navigationShell, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.black,
        type: BottomNavigationBarType.fixed,
        currentIndex: navigationShell.currentIndex,
        selectedItemColor: const Color(0xFFD4AF35),
        unselectedItemColor: Colors.white38,
        onTap: (index) => navigationShell.goBranch(index, initialLocation: index == navigationShell.currentIndex),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.explore), label: 'Discover'),
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble), label: 'Chats'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}