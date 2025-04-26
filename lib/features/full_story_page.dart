import 'package:flutter/material.dart';

class FullStoryPage extends StatelessWidget {
  final String title;
  final String synopsis;
  final String fullStory;
  final String user;
  final String avatar;

  const FullStoryPage({
    super.key,
    required this.title,
    required this.synopsis,
    required this.fullStory,
    required this.user,
    required this.avatar,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(user), backgroundColor: Colors.blueAccent),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: CircleAvatar(
                radius: 40,
                backgroundImage: AssetImage(avatar),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              'Sinopsis:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(synopsis, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 20),
            const Text(
              'Cerita Lengkap:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(fullStory, style: const TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}
