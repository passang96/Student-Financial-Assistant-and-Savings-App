import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'screens/splash/splash_screen.dart';

Future<void> main() async {
  print('🔥🔥🔥 YO! MAIN.DART IS RUNNING 🔥🔥🔥');

  WidgetsFlutterBinding.ensureInitialized();

  try {
    print('===== FIREBASE INITIALIZATION START =====');

    final FirebaseApp app = await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    print('===== FIREBASE INITIALIZATION SUCCESS =====');
    print('Firebase app name: ${app.name}');
    print('Firebase project ID: ${app.options.projectId}');
    print('Firebase app ID: ${app.options.appId}');
  } catch (e, stackTrace) {
    print('===== FIREBASE INITIALIZATION FAILED =====');
    print('ERROR: $e');
    print('STACK TRACE:');
    print(stackTrace);
  }

  runApp(const StudentFinanceApp());
}

class StudentFinanceApp extends StatelessWidget {
  const StudentFinanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Student Financial Assistant App',
      theme: ThemeData(useMaterial3: true, fontFamily: 'Arial'),
      home: const SplashScreen(),
    );
  }
}
