import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'full_story_page.dart';
import 'profile.dart';
import 'tentang_kami.dart';
import 'tulisan_page.dart';
import 'search.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _selectedIndex = 0;
  final TextEditingController _commentController = TextEditingController();

  final List<Map<String, String>> posts = [
    {
      'user': 'ZFAR',
      'title': 'KISAH JEKY',
      'synopsis': 'Ini adalah kisah tentang Jeky yang penuh petualangan.',
      'fullStory':
          'Ini adalah kisah lengkap tentang Jeky. Dia memulai perjalanan panjangnya dari sebuah desa kecil, menghadapi berbagai rintangan dan bertemu banyak karakter menarik sepanjang perjalanannya...',
      'time': '1 jam yang lalu',
      'avatar': 'assets/avatar1.png',
    },
    {
      'user': 'Inra',
      'title': 'KISAH Inra',
      'synopsis': 'Perjalanan hidup Inra yang penuh inspirasi dan semangat.',
      'fullStory':
          'Inra tumbuh dalam lingkungan yang penuh tantangan. Meskipun banyak halangan, dia terus maju untuk meraih mimpinya dan menginspirasi banyak orang dengan kisah hidupnya yang penuh harapan...',
      'time': '3 jam yang lalu',
      'avatar': 'assets/avatar2.png',
    },
    {
      'user': 'This is Loli',
      'title': 'KISAH Ridho',
      'synopsis': 'Kisah unik tentang Ridho dan pencariannya akan kebenaran.',
      'fullStory':
          'Ridho selalu bertanya-tanya tentang makna hidup. Dalam perjalanannya, ia menjelajah dunia, berbincang dengan orang-orang bijak, hingga akhirnya menemukan makna sejati dari kehidupan...',
      'time': '5 jam yang lalu',
      'avatar': 'assets/avatar3.png',
    },
  ];

  final List<Map<String, String>> comments = [
    {
      'user': 'T.W',
      'time': '5 menit yang lalu',
      'text': 'Ceritanya akhirnya umum kayak kebanyakan orang, jadi bosen',
      'avatar': 'assets/avatar1.png',
    },
    {
      'user': 'Namz3',
      'time': '23 menit yang lalu',
      'text': 'Aokwokwok ane nya locak banget bro',
      'avatar': 'assets/avatar2.png',
    },
    {
      'user': 'No Choice',
      'time': '40 menit yang lalu',
      'text':
          'Akhirnya ketebak soalnya mirip kayak cerita kebanyakan, tapi di bagian komedinya lumayan menghibur.',
      'avatar': 'assets/avatar3.png',
    },
  ];

  void _showComments(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            return Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  "Comment",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: comments.length,
                    itemBuilder: (context, index) {
                      final comment = comments[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundImage: AssetImage(comment['avatar']!),
                        ),
                        title: Text(comment['user']!),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              comment['time']!,
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(comment['text']!),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _commentController,
                          decoration: InputDecoration(
                            hintText: 'Masukkan komentar anda',
                            filled: true,
                            fillColor: Colors.grey[200],
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(25),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      CircleAvatar(
                        backgroundColor: Colors.blueAccent,
                        child: IconButton(
                          icon: const Icon(Icons.send, color: Colors.white),
                          onPressed: () {
                            if (_commentController.text.isNotEmpty) {
                              setState(() {
                                comments.add({
                                  'user': 'You',
                                  'time': 'baru saja',
                                  'text': _commentController.text,
                                  'avatar': 'assets/your_avatar.png',
                                });
                                _commentController.clear();
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const SearchPage()),
      );
    } else if (index == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const TulisanPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
        child: Container(
          color: Colors.lightBlue[100],
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              const SizedBox(height: 40),
              ListTile(
                leading: Icon(Icons.arrow_back),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: 20),
              CircleAvatar(
                radius: 40,
                backgroundColor: Colors.black12,
                child: Icon(Icons.person, size: 50),
              ),
              const SizedBox(height: 10),
              const Center(child: Text('No Name')),
              const Center(
                child: Text('Online', style: TextStyle(color: Colors.green)),
              ),
              const Divider(),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  'Pengaturan',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              ListTile(
                title: const Text('Profile akun'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const EditProfilePage()),
                  );
                },
              ),
              const Divider(),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  'Lainnya',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              ListTile(
                title: const Text('Tentang Kami'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const MyKisahPage()),
                  );
                },
              ),
              ListTile(
                title: const Text(
                  'Logout',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {},
              ),
            ],
          ),
        ),
      ),

      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 1,
        leading: Builder(
          builder:
              (context) => IconButton(
                icon: const Icon(Icons.person, color: Colors.black),
                onPressed: () {
                  Scaffold.of(context).openDrawer();
                },
              ),
        ),
        title: Center(
          child: Padding(
            padding: const EdgeInsets.only(right: 40),
            child: Image.asset('assets/logoh.png', width: 100),
          ),
        ),
      ),
      body: ListView.builder(
        itemCount: posts.length,
        itemBuilder: (context, index) {
          final post = posts[index];
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (_) => FullStoryPage(
                        title: post['title']!,
                        synopsis: post['synopsis']!,
                        fullStory: post['fullStory']!,
                        user: post['user']!,
                        avatar: post['avatar']!,
                        genre: post['genre']!,
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
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              post['time']!,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      post['title']!,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Sinopsis:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(post['synopsis']!),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.thumb_up_alt_outlined,
                            color: Colors.black,
                          ),
                          onPressed: () {},
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.thumb_down_alt_outlined,
                            color: Colors.black,
                          ),
                          onPressed: () {},
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.comment_outlined,
                            color: Colors.black,
                          ),
                          onPressed: () {
                            _showComments(context);
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.share, color: Colors.black),
                          onPressed: () {
                            Share.share(
                              'Check out this story: ${post['title']} - ${post['synopsis']}',
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.edit), label: ''),
        ],
        currentIndex: _selectedIndex,
        onTap: (index) {
          _onItemTapped(index);
        },
      ),
    );
  }
}
