import 'package:flutter/material.dart';

class DummyDashboard extends StatelessWidget {
  const DummyDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Dashboard")),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            Navigator.pushReplacementNamed(context, '/signin');
          },
          child: const Text("Log Out"),
        ),
      ),
    );
  }
}
