import 'package:flutter/material.dart';
import 'features/home_page.dart';
import 'features/signup_page.dart';
import 'features/signin_page.dart';
import 'features/dummy_dashboard.dart'; // Import the dummy dashboard page

void main() {
  runApp(const MyKisahApp());
}

class MyKisahApp extends StatelessWidget {
  const MyKisahApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const HomePage(),
      routes: {
        '/signup': (context) => const SignUpPage(),
        '/signin': (context) => const SignInPage(),
        '/dashboard': (context) => const DummyDashboard(),
      },
    );
  }
}
