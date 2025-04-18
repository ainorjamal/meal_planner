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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(MealPlannerApp());
}

class MealPlannerApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Meal Planner',
      theme: ThemeData(primarySwatch: Colors.green),
      home: AuthWrapper(),
      routes: {
        '/login': (context) => LoginScreen(),
        '/register': (context) => RegisterScreen(),
        '/home': (context) => HomeScreen(),
        '/addMeal': (context) => AddMealScreen(),
        '/editProfile': (context) => EditProfileScreen(),
        '/favorites': (context) => FavoritesScreen(), 
      },
    );
  }
}

// A wrapper widget to handle auth state changes
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
          }
          return HomeScreen();
        }
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      },
    );
  }
}
