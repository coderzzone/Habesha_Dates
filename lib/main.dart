import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'core/navigation/app_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/services/ad_service.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'core/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize AdMob (do not block app start if it fails)
  try {
    await AdService().init();
  } catch (e) {
    debugPrint("AdMob initialization error: $e");
  }
  
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      
      /*
      // Initialize App Check to resolve the "No AppCheckProvider installed" error
      await FirebaseAppCheck.instance.activate(
        androidProvider: AndroidProvider.debug,
      );
      */
    }
    // Set persistence to ensure the user stays logged in across restarts (web only)
    if (kIsWeb) {
      await FirebaseAuth.instance.setPersistence(Persistence.LOCAL);
    }
  } catch (e) {
    debugPrint("Firebase initialization error: $e");
  }

  // Session Management: Check both Onboarding and Auth status
  bool onboardingCompleted = false;
  try {
    final prefs = await SharedPreferences.getInstance();
    onboardingCompleted = prefs.getBool('onboarding_completed') ?? false;
  } catch (e) {
    debugPrint("SharedPreferences error: $e");
  }

  User? user;
  if (Firebase.apps.isNotEmpty) {
    user = FirebaseAuth.instance.currentUser;
  }

  String initialRoute = '/onboarding';
  if (onboardingCompleted) {
    // If onboarding is done, send to discovery if logged in, otherwise login screen
    initialRoute = (user != null) ? '/discovery' : '/';
  }

  runApp(MyApp(initialRoute: initialRoute));
}

class MyApp extends StatefulWidget {
  final String initialRoute;
  const MyApp({super.key, required this.initialRoute, this.enablePresenceUpdates = true});

  final bool enablePresenceUpdates;

  @override
  State<MyApp> createState() => _MyAppState();
}

// WidgetsBindingObserver allows us to listen to app lifecycle (background/foreground)
class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  late final AppRouter _appRouter = AppRouter(widget.initialRoute);
  late final GoRouter _router = _appRouter.router;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _updatePresence(true); // Mark as online when app starts
    NotificationService.instance.init();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // App in foreground
      _updatePresence(true);
    } else {
      // App in background or closed
      _updatePresence(false);
    }
  }

  /// Updates the user's online status and last seen timestamp in Firestore
  void _updatePresence(bool isOnline) {
    if (!widget.enablePresenceUpdates || Firebase.apps.isEmpty) return;
    final User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
            'isOnline': isOnline,
            'lastSeen': FieldValue.serverTimestamp(),
          })
          .catchError((e) {
            debugPrint("Error updating presence: $e");
          });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Habesha Dates',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      routerConfig: _router,
    );
  }
}
