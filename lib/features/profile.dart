import 'package:flutter/material.dart';
import 'edit_profile_page.dart';
import 'edit_cerita_page.dart'; // Buat halaman ini jika belum ada

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with SingleTickerProviderStateMixin {
  String username = 'username';
  String bio = 'Bio pengguna';
  int followers = 124;
  int following = 89;
  String avatar = 'assets/avatar1.png';

  late TabController _tabController;

  List<Map<String, String>> posts = [
    {
      'title': 'KISAH Saya',
      'time': '20 menit yang lalu',
      'sinopsis': 'Ini sinopsis pertama',
      'fullStory': 'Ini cerita lengkap pertama',
      'genres': 'Romance, Action',
    },
    {
      'title': 'KISAH Adik Saya',
      'time': '30 menit yang lalu',
      'sinopsis': 'Ini sinopsis kedua',
      'fullStory': 'Ini cerita lengkap kedua',
      'genres': 'Fantasi, Misteri',
    },
    {
      'title': 'KISAH Jeky',
      'time': '1 jam yang lalu',
      'sinopsis': 'Ini sinopsis ketiga',
      'fullStory': 'Ini cerita lengkap ketiga',
      'genres': 'Petualangan',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  void navigateToEditProfile() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const EditProfilePage()),
    );

    if (result is Map<String, String>) {
      setState(() {
        username = result['username'] ?? username;
        bio = result['bio'] ?? bio;
      });
    }
  }

  void _showDeleteConfirmation(BuildContext context, int index) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Konfirmasi Hapus'),
          content: const Text(
            'Apakah Anda yakin ingin menghapus postingan ini?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  posts.removeAt(index);
                });
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );
  }

  Widget buildPostCard(Map<String, String> post, int index) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post['title'] ?? '',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        post['time'] ?? '',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (_) => EditCeritaPage(
                                story: post,
                                onSave: (editedStory) {
                                  setState(() {
                                    posts[index] = editedStory;
                                  });
                                },
                              ),
                        ),
                      );
                    } else if (value == 'hapus') {
                      _showDeleteConfirmation(context, index);
                    }
                  },
                  itemBuilder:
                      (context) => [
                        const PopupMenuItem(value: 'edit', child: Text('Edit')),
                        const PopupMenuItem(
                          value: 'hapus',
                          child: Text('Hapus'),
                        ),
                      ],
                  icon: const Icon(Icons.more_vert),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              children:
                  (post['genres'] ?? '')
                      .split(', ')
                      .map((genre) => Chip(label: Text(genre)))
                      .toList(),
            ),
            const SizedBox(height: 4),
            const Text(
              'Sinopsis:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(post['sinopsis'] ?? 'Tidak ada sinopsis.'),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: const [
                Icon(Icons.thumb_up_alt_outlined),
                Icon(Icons.thumb_down_alt_outlined),
                Icon(Icons.comment_outlined),
                Icon(Icons.share),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: navigateToEditProfile,
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 16),
          CircleAvatar(radius: 40, backgroundImage: AssetImage(avatar)),
          const SizedBox(height: 8),
          Text(
            '@$username',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 4),
          Text(bio, style: const TextStyle(fontSize: 14)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Column(
                children: [
                  Text(
                    '$followers',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const Text('Followers'),
                ],
              ),
              const SizedBox(width: 24),
              Column(
                children: [
                  Text(
                    '$following',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const Text('Following'),
                ],
              ),
            ],
          ),
          const Divider(height: 32, thickness: 1),
          TabBar(
            controller: _tabController,
            labelColor: Colors.black,
            tabs: const [Tab(text: 'Terbaru'), Tab(text: 'Terlama')],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                ListView(
                  children:
                      posts.asMap().entries.map((entry) {
                        // Gunakan posts tanpa reversed untuk 'Terbaru'
                        return buildPostCard(entry.value, entry.key);
                      }).toList(),
                ),
                ListView(
                  children:
                      posts.reversed.toList().asMap().entries.map((entry) {
                        // Gunakan reversed untuk 'Terlama'
                        return buildPostCard(entry.value, entry.key);
                      }).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
