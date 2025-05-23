import 'package:flutter/material.dart';
import 'features/animatedlogo_screen.dart';
import 'features/home_page.dart';
import 'features/signup_page.dart';
import 'features/signin_page.dart';
import 'features/dashboard_page.dart';

void main() {
  runApp(const MyKisahApp());
}

class MyKisahApp extends StatelessWidget {
  const MyKisahApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: AnimatedLogoScreen(),
      routes: {
        '/home': (context) => const HomePage(),
        '/signup': (context) => const SignUpPage(),
        '/signin': (context) => const SignInPage(),
        '/dashboard': (context) => const DashboardPage(),
      },
    );
  }
}
