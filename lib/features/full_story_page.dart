import 'package:flutter/material.dart';

class FullStoryPage extends StatelessWidget {
  final String title;
  final String genre;
  final String synopsis;
  final String fullStory;
  final String user;
  final String avatar;

  const FullStoryPage({
    super.key,
    required this.title,
    required this.genre,
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
                radius: 50,
                backgroundImage: AssetImage(avatar),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.blueAccent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  genre,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Sinopsis:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(synopsis, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 20),
            const Text(
              'Cerita Lengkap:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(fullStory, style: const TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}
