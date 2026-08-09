import 'dart:async';

import 'package:flutter/material.dart';

import '../login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    Timer(const Duration(seconds: 3), () {
      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    });
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
