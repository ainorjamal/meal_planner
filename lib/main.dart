import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'pages/home_screen.dart';
import 'screens/add_meal_screen.dart';
import 'pages/login_screen.dart';
import 'pages/register_screen.dart';
import 'pages/editProfile_screen.dart';
import 'auth/auth_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'pages/favorites_screen.dart';
import 'pages/mealHistory_screen.dart';
import 'pages/helpAndSupport_screen.dart';
import 'pages/settings_screen.dart';
import 'package:provider/provider.dart';
import 'providers/theme_provider.dart';
import 'pages/theme_screen.dart';
import 'pages/notifications_screen.dart';
import 'pages/preferences_screen.dart';
import 'services/notification_service.dart';
import 'services/firestore.dart';
import 'package:shared_preferences/shared_preferences.dart'; // NEW
import 'pages/onboarding_screen.dart'
;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize notification service
  final NotificationService notificationService = NotificationService();
  await notificationService.initialize();

  // Check onboarding completion
  final prefs = await SharedPreferences.getInstance(); // NEW
  final seenOnboarding = prefs.getBool('onboarding_complete') ?? false; // NEW

  // Run app
  runApp(
    ChangeNotifierProvider(
      create: (context) => ThemeProvider(),
      child: MealPlannerApp(seenOnboarding: seenOnboarding), // MODIFIED
    ),
  );
}

class MealPlannerApp extends StatefulWidget {
  final bool seenOnboarding; // NEW

  const MealPlannerApp({super.key, required this.seenOnboarding}); // NEW

  @override
  _MealPlannerAppState createState() => _MealPlannerAppState();
}

class _MealPlannerAppState extends State<MealPlannerApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scheduleNotificationsIfLoggedIn();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _scheduleNotificationsIfLoggedIn();
    }
  }

  Future<void> _scheduleNotificationsIfLoggedIn() async {
    final User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      try {
        final firestoreService = FirestoreService();
        await firestoreService.scheduleNotificationsForAllUserMeals();
        debugPrint('Scheduled notifications for all meals of user: ${currentUser.uid}');
      } catch (e) {
        debugPrint('Error scheduling notifications: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      title: 'Meal Planner',
      theme: themeProvider.isDarkMode ? ThemeData.dark() : ThemeData.light(),
      home: widget.seenOnboarding ? AuthWrapper() : OnboardingScreen(), // MODIFIED
      routes: {
        '/login': (context) => LoginScreen(),
        '/register': (context) => RegisterScreen(),
        '/home': (context) => HomeScreen(),
        '/addMeal': (context) => AddMealScreen(),
        '/editProfile': (context) => EditProfileScreen(),
        '/favorites': (context) => FavoritesScreen(),
        '/mealHistory': (context) => MealHistoryScreen(),
        '/helpSupport': (context) => HelpSupportPage(),
        '/settings': (context) => SettingsPage(),
        '/theme': (context) => ThemeSettingsPage(),
        '/notifications': (context) => NotificationSettingsPage(),
        '/preferences': (context) => PreferencesSettingsPage(),
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: authService.value.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.active) {
          final user = snapshot.data;
          if (user == null) {
            return LoginScreen();
          } else {
            _scheduleUserMealNotifications(user.uid);
            return HomeScreen();
          }
        }
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      },
    );
  }

  Future<void> _scheduleUserMealNotifications(String userId) async {
    try {
      final firestoreService = FirestoreService();
      await firestoreService.scheduleNotificationsForAllUserMeals();
      debugPrint('Scheduled notifications for all meals of user: $userId');
    } catch (e) {
      debugPrint('Error scheduling notifications on login: $e');
    }
  }
}
