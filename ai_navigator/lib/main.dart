import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/dashboard_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/login_screen.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart';
import 'services/resume_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!kIsWeb) {
    await NotificationService().init();
  }

  try {
    if (kIsWeb) {
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: "AIzaSyBr6hiegGsYgwy9krg3e8WqsKqglUASFsU",
          authDomain: "career-navigator-26eae.firebaseapp.com",
          projectId: "career-navigator-26eae",
          storageBucket: "career-navigator-26eae.firebasestorage.app",
          messagingSenderId: "397856270364",
          appId: "1:397856270364:web:8cec79741970f50c5217d9",
        ),
      );
    } else {
      await Firebase.initializeApp();
    }
  } catch (e) {
    debugPrint("Firebase initialization failed: $e");
  }

  final prefs = await SharedPreferences.getInstance();
  final onboardingCompleted = prefs.getBool('onboarding_completed') ?? false;

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => ResumeService()),
      ],
      child: MyApp(onboardingCompleted: onboardingCompleted),
    ),
  );
}

class MyApp extends StatelessWidget {
  final bool onboardingCompleted;
  const MyApp({super.key, required this.onboardingCompleted});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'AI Career Navigator',
      theme: AppTheme.darkTheme,
      home: _getInitialScreen(),
    );
  }

  Widget _getInitialScreen() {
    if (!onboardingCompleted) {
      return const OnboardingScreen();
    }

    return Consumer<AuthService>(
      builder: (context, auth, _) {
        if (auth.user != null) {
          return const DashboardScreen();
        }
        return const LoginScreen();
      },
    );
  }
}
