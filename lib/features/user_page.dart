import 'package:flutter/material.dart';
import 'full_story_page.dart'; 

class UserPage extends StatefulWidget {
  final String user;
  final String avatar;

  const UserPage({super.key, required this.user, required this.avatar});

  @override
  State<UserPage> createState() => _UserPageState();
}

class _UserPageState extends State<UserPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

 
  final List<Map<String, String>> allPosts = [
    {
      'user': 'ZFAR',
      'title': 'KISAH JEKY',
      'synopsis': 'Ini adalah kisah tentang Jeky yang penuh petualangan.',
      'fullStory': 'Ini cerita lengkap tentang Jeky...',
      'genre': 'Petualangan',
      'time': '1 jam yang lalu',
      'avatar': 'assets/avatar1.png',
    },
    {
      'user': 'ZFAR',
      'title': 'KISAH Baru',
      'synopsis': 'Cerita baru dari ZFAR yang seru!',
      'fullStory': 'Kisah lengkap baru dari ZFAR...',
      'genre': 'Aksi',
      'time': '2 jam yang lalu',
      'avatar': 'assets/avatar1.png',
    },
    {
      'user': 'Inra',
      'title': 'KISAH Inra',
      'synopsis': 'Perjalanan hidup Inra yang penuh inspirasi.',
      'fullStory': 'Inra menghadapi banyak tantangan...',
      'genre': 'Drama',
      'time': '3 jam yang lalu',
      'avatar': 'assets/avatar2.png',
    },
    {
      'user': 'This is Loli',
      'title': 'KISAH Ridho',
      'genre': 'Petualangan',
      'synopsis': 'Kisah unik tentang Ridho dan pencariannya akan kebenaran.',
      'fullStory': 'Kisah lengkap Ridho...',
      'time': '5 jam yang lalu',
      'avatar': 'assets/avatar3.png',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  List<Map<String, String>> getUserPosts({required bool terbaru}) {
    
    List<Map<String, String>> userPosts =
        allPosts.where((post) => post['user'] == widget.user).toList();

    
    if (terbaru) {
      userPosts = userPosts.reversed.toList();
    }
    return userPosts;
  }

  Widget buildPostCard(Map<String, String> post) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => FullStoryPage(
              title: post['title'] ?? '',
              synopsis: post['synopsis'] ?? '',
              fullStory: post['fullStory'] ?? 'Belum ada cerita lengkap.',
              user: post['user'] ?? '',
              avatar: post['avatar'] ?? 'assets/default_avatar.png',
              genre: post['genre'] ?? 'Genre',
            ),
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundImage: AssetImage(post['avatar']!),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post['user']!,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        post['time'] ?? '',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                post['title']!,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 4),
              const Text('Sinopsis:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(post['synopsis']!),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  IconButton(icon: const Icon(Icons.thumb_up_alt_outlined), onPressed: () {}),
                  IconButton(icon: const Icon(Icons.thumb_down_alt_outlined), onPressed: () {}),
                  IconButton(icon: const Icon(Icons.comment_outlined), onPressed: () {}),
                  IconButton(icon: const Icon(Icons.share), onPressed: () {}),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.black,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.black,
          tabs: const [
            Tab(text: 'Terbaru'),
            Tab(text: 'Terlama'),
          ],
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 16),
          CircleAvatar(
            radius: 40,
            backgroundImage: AssetImage(widget.avatar),
          ),
          const SizedBox(height: 8),
          Text(
            '@${widget.user}',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          const Text('Bio', style: TextStyle(fontSize: 14)),
          const Divider(height: 32, thickness: 1),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Tab Terbaru
                ListView(
                  children: getUserPosts(terbaru: false).map(buildPostCard).toList(),
                ),
                // Tab Terlama
                ListView(
                  children: getUserPosts(terbaru: true).map(buildPostCard).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
