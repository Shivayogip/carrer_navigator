import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/dashboard_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/login_screen.dart';
import 'services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // NOTE: Firebase initialization requires firebase_options.dart 
  // generated via FlutterFire CLI. For now, we wrap it in a try-catch
  // to allow the UI to function even if Firebase isn't fully configured yet.
  try {
    // await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  } catch (e) {
    debugPrint("Firebase initialization failed: $e");
  }

  final prefs = await SharedPreferences.getInstance();
  final onboardingCompleted = prefs.getBool('onboarding_completed') ?? false;

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
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
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6366F1),
          primary: const Color(0xFF6366F1),
          secondary: const Color(0xFF10B981),
        ),
      ),
      home: _getInitialScreen(),
    );
  }

  Widget _getInitialScreen() {
    if (!onboardingCompleted) {
      return const OnboardingScreen();
    }
    
    // Check auth status if onboarding is done
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