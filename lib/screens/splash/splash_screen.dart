import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../login_screen.dart';
import '../main_navigation_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    _checkAuthentication();
  }

  Future<void> _checkAuthentication() async {
    // Keep the splash screen visible for the original 3 seconds.
    await Future.delayed(const Duration(seconds: 3));

    final preferences = await SharedPreferences.getInstance();

    final bool rememberMe = preferences.getBool('remember_me') ?? false;

    User? currentUser = FirebaseAuth.instance.currentUser;

    // If Remember Me is OFF, do not restore the old Firebase session.
    if (!rememberMe && currentUser != null) {
      await FirebaseAuth.instance.signOut();
      currentUser = null;
    }

    if (!mounted) return;

    if (rememberMe && currentUser != null) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
      );
    } else {
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF20C9C3), Color(0xFF087F7A)],
          ),
        ),
        child: const SafeArea(
          child: Column(
            children: [
              Spacer(flex: 2),

              Icon(
                Icons.account_balance_wallet_outlined,
                size: 130,
                color: Color(0xFF166C8A),
              ),

              SizedBox(height: 40),

              Text(
                'Student Financial\nAssistant App',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                  height: 1.3,
                ),
              ),

              SizedBox(height: 22),

              Text(
                'Track. Save. Achieve.',
                style: TextStyle(color: Colors.white, fontSize: 20),
              ),

              Spacer(flex: 3),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(radius: 5, backgroundColor: Colors.white38),
                  SizedBox(width: 8),
                  CircleAvatar(radius: 6, backgroundColor: Colors.white),
                  SizedBox(width: 8),
                  CircleAvatar(radius: 5, backgroundColor: Colors.white38),
                ],
              ),

              SizedBox(height: 50),
            ],
          ),
        ),
      ),
    );
  }
}
