import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'controllers/auth_controller.dart';
import 'firebase_options.dart';
import 'screens/auth/login_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'services/auth_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  Object? initializationError;
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (error) {
    initializationError = error;
  }

  runApp(MyApp(initializationError: initializationError));
}

class MyApp extends StatelessWidget {
  const MyApp({
    super.key,
    this.authService,
    this.initializationError,
  });

  final AuthService? authService;
  final Object? initializationError;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Student Financial Assistant',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00897B),
        ),
        scaffoldBackgroundColor: const Color(0xFFF7FAF9),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
        ),
        useMaterial3: true,
      ),
      home: initializationError == null
          ? AuthGate(
              controller: AuthController(
                authService: authService ?? AuthService(),
              ),
            )
          : const FirebaseStartupErrorScreen(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key, required this.controller});

  final AuthController controller;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: controller.authStateChanges,
      initialData: controller.currentUser,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const FirebaseStartupErrorScreen();
        }

        if (snapshot.connectionState == ConnectionState.waiting &&
            snapshot.data == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.data == null) {
          return LoginScreen(authController: controller);
        }

        return DashboardScreen(authController: controller);
      },
    );
  }
}

class FirebaseStartupErrorScreen extends StatelessWidget {
  const FirebaseStartupErrorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.cloud_off_outlined, size: 56),
                SizedBox(height: 16),
                Text(
                  'Firebase is unavailable',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  'Check this platform\'s Firebase configuration and restart '
                  'the app.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
