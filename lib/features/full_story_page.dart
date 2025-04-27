import 'package:flutter/material.dart';
import 'user_page.dart'; // Import UserPage

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

  void _navigateToUserPage(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UserPage(user: user, avatar: avatar),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Color(0xFFB2CEF8),
        actions: [
          IconButton(
            icon: const Icon(Icons.warning_amber_outlined, color: Colors.white),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Laporkan Postingan'),
                  content: const Text('Laporkan postingan ini?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Tidak'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Postingan telah dilaporkan.'),
                          ),
                        );
                      },
                      child: const Text('Ya'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: () => _navigateToUserPage(context),
              child: CircleAvatar(
                radius: 50,
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
