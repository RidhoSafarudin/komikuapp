import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:test_komikuapp/features/home_page.dart';
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
      'genre': 'Petualangan',
      'synopsis': 'Ini adalah kisah tentang Jeky yang penuh petualangan.',
      'fullStory': '...',
      'time': '1 jam yang lalu',
      'avatar': 'assets/avatar1.png',
    },
    {
      'user': 'Inra',
      'title': 'KISAH Inra',
      'genre': 'Inspirasi',
      'synopsis': 'Perjalanan hidup Inra yang penuh inspirasi dan semangat.',
      'fullStory': '...',
      'time': '3 jam yang lalu',
      'avatar': 'assets/avatar2.png',
    },
    {
      'user': 'This is Loli',
      'title': 'KISAH Ridho',
      'genre': 'Petualangan',
      'synopsis': 'Kisah unik tentang Ridho dan pencariannya akan kebenaran.',
      'fullStory': '...',
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
      List<Map<String, String>> localComments = List.from(comments);
      final TextEditingController localCommentController = TextEditingController();

      return StatefulBuilder(
        builder: (context, setModalState) {
          return DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.6,
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
                      itemCount: localComments.length,
                      itemBuilder: (context, index) {
                        final comment = localComments[index];
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
                                style: const TextStyle(fontSize: 10, color: Colors.grey),
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
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).viewInsets.bottom,
                      left: 16,
                      right: 16,
                      top: 8,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: localCommentController,
                            decoration: InputDecoration(
                              hintText: 'Masukkan komentar anda',
                              filled: true,
                              fillColor: Colors.grey[200],
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                              if (localCommentController.text.isNotEmpty) {
                                final newComment = {
                                  'user': 'You',
                                  'time': 'baru saja',
                                  'text': localCommentController.text,
                                  'avatar': 'assets/your_avatar.png',
                                };
                                setModalState(() {
                                  localComments.add(newComment);
                                  localCommentController.clear();
                                });
                                addComment(newComment); // <- Tambahkan ke state utama
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
    },
  );
}
void addComment(Map<String, String> comment) {
  setState(() {
    comments.add(comment);
  });
}



  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  List<Widget> _pages() => [
    HomeContent(
      posts: posts,
      showComments: _showComments,
      onPostTap: (post) {
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
    ),
    const SearchPage(),
    const TulisanPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
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
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const SizedBox(height: 40),
            ListTile(
              leading: Icon(Icons.arrow_back),
              onTap: () => Navigator.pop(context),
            ),
            const SizedBox(height: 20),
            CircleAvatar(radius: 40, child: Icon(Icons.person, size: 50)),
            const SizedBox(height: 10),
            const Center(child: Text('No Name')),
            const Center(
              child: Text('Online', style: TextStyle(color: Colors.green)),
            ),
            const Divider(),
            ListTile(
              title: const Text('Profile akun'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfilePage()),
                );
              },
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
              title: const Text('Logout', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const HomePage()),
                );
              },
            ),
          ],
        ),
      ),
      body: IndexedStack(index: _selectedIndex, children: _pages()),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Color(0xFF40B5C3),
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.black45,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.edit), label: ''),
        ],
      ),
    );
  }
}

// Widget untuk halaman utama (post list)
class HomeContent extends StatelessWidget {
  final List<Map<String, String>> posts;
  final Function(BuildContext) showComments;
  final Function(Map<String, String>) onPostTap;

  const HomeContent({
    required this.posts,
    required this.showComments,
    required this.onPostTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: posts.length,
      itemBuilder: (context, index) {
        final post = posts[index];
        return GestureDetector(
          onTap: () => onPostTap(post),
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
                        icon: const Icon(Icons.thumb_up_alt_outlined),
                        onPressed: () {},
                      ),
                      IconButton(
                        icon: const Icon(Icons.thumb_down_alt_outlined),
                        onPressed: () {},
                      ),
                      IconButton(
                        icon: const Icon(Icons.comment_outlined),
                        onPressed: () => showComments(context),
                      ),
                      IconButton(
                        icon: const Icon(Icons.share),
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
    );
  }
}
