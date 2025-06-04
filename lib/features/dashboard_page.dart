import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:share_plus/share_plus.dart';
import 'package:test_komikuapp/features/home_page.dart';
import '../services/auth_service.dart';
import 'package:http/http.dart' as http;
import 'full_story_page.dart';
import 'profile.dart';
import 'tentang_kami.dart';
import 'tulisan_page.dart';
import 'search.dart';
import 'bookmark_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  
  int _selectedIndex = 0;
  final TextEditingController _commentController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = true;
  bool _userDataLoading = true;
  List<dynamic> _posts = [];
  
  // User data variables
  String _userName = 'Loading...';
  String? _userAvatar;
  bool _isUserOnline = false;

  // Flag to track if widget is still mounted
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _fetchPosts();
    _fetchUserData();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _commentController.dispose();
    super.dispose();
  }

  void _safeSetState(VoidCallback fn) {
    if (!_isDisposed && mounted) {
      setState(fn);
    }
  }

  String _formatTime(String? createdAt) {
    if (createdAt == null) return '';
    
    try {
      final DateTime dateTime = DateTime.parse(createdAt);
      final DateTime now = DateTime.now();
      final Duration difference = now.difference(dateTime);
      
      if (difference.inDays > 0) {
        return '${difference.inDays} hari yang lalu';
      } else if (difference.inHours > 0) {
        return '${difference.inHours} jam yang lalu';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes} menit yang lalu';
      } else {
        return 'Baru saja';
      }
    } catch (e) {
      return createdAt;
    }
  }

  Future<void> _fetchUserData() async {
    try {
      final token = await _authService.getToken();
      
      if (token == null) {
        _safeSetState(() {
          _userName = 'Guest';
          _userDataLoading = false;
          _isUserOnline = false;
        });
        return;
      }

      final response = await http.get(
        Uri.parse('http://127.0.0.1:8000/api/me'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (!_isDisposed && mounted) {
        if (response.statusCode == 200) {
          final responseData = json.decode(response.body);
          final userData = responseData['user'];
          
          _safeSetState(() {
            _userName = userData['name'] ?? 'Unknown User';
            _userAvatar = userData['avatar_url'];
            _isUserOnline = true;
            _userDataLoading = false;
          });
        } else {
          _safeSetState(() {
            _userName = 'Unknown User';
            _userDataLoading = false;
            _isUserOnline = false;
          });
        }
      }
    } catch (e) {
      if (!_isDisposed && mounted) {
        _safeSetState(() {
          _userName = 'Error loading name';
          _userDataLoading = false;
          _isUserOnline = false;
        });
        print('Error fetching user data: $e');
      }
    }
  }

  Future<void> _fetchPosts() async {
    try {
      final token = await _authService.getToken();
      final response = await http.get(
        Uri.parse('http://127.0.0.1:8000/api/kisah/all'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (!_isDisposed && mounted) {
        if (response.statusCode == 200) {
          _safeSetState(() {
            _posts = json.decode(response.body);
            _isLoading = false;
          });
        } else {
          throw Exception('Failed to load posts');
        }
      }
    } catch (e) {
      if (!_isDisposed && mounted) {
        _safeSetState(() {
          _isLoading = false;
        });
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${e.toString()}'))
          );
        }
      }
    }
  }

  Future<List<dynamic>> _fetchCommentsReturnList(int kisahId) async {
    try {
      final token = await _authService.getToken();
      final response = await http.get(
        Uri.parse('http://127.0.0.1:8000/api/komen/kisah/$kisahId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to fetch comments');
      }
    } catch (e) {
      print('Error fetching comments: $e');
      return [];
    }
  }

  Future<void> _handleReaction(int kisahId, int value, int postIndex) async {
    try {
      final token = await _authService.getToken();
      final currentPost = _posts[postIndex];
      final currentUserReaction = currentPost['user_reaction'];
      
      if (currentUserReaction == value) {
        final deleteResponse = await http.delete(
          Uri.parse('http://127.0.0.1:8000/api/kisah/$kisahId/reaction'),
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        );
        
        if (!_isDisposed && mounted && deleteResponse.statusCode == 200) {
          final responseData = json.decode(deleteResponse.body);
          _safeSetState(() {
            _posts[postIndex]['user_reaction'] = null;
            _posts[postIndex]['like_count'] = int.parse(responseData['like_count'] ?? '0');
            _posts[postIndex]['dislike_count'] = int.parse(responseData['dislike_count'] ?? '0');
          });
        }
      } else {
        final response = await http.post(
          Uri.parse('http://127.0.0.1:8000/api/kisah/$kisahId/reaction'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: json.encode({
            'value': value,
          }),
        );

        if (!_isDisposed && mounted && response.statusCode == 200) {
          final responseData = json.decode(response.body);
          _safeSetState(() {
            _posts[postIndex]['user_reaction'] = value;
            _posts[postIndex]['like_count'] = int.parse(responseData['like_count'] ?? '0');
            _posts[postIndex]['dislike_count'] = int.parse(responseData['dislike_count'] ?? '0');
          });
        }
      }
    } catch (e) {
      if (!_isDisposed && mounted && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating reaction: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _handleBookmark(int kisahId, int postIndex) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Anda harus login untuk menambahkan bookmark')),
          );
        }
        return;
      }

      final currentPost = _posts[postIndex];
      final isBookmarked = currentPost['is_bookmarked'] ?? false;

      if (isBookmarked) {
        final response = await http.delete(
          Uri.parse('http://127.0.0.1:8000/api/bookmarks/$kisahId'),
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        );

        if (!_isDisposed && mounted && response.statusCode == 200) {
          _safeSetState(() {
            _posts[postIndex]['is_bookmarked'] = false;
          });
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Bookmark dihapus')),
            );
          }
        }
      } else {
        final response = await http.post(
          Uri.parse('http://127.0.0.1:8000/api/user/addBookmark'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: json.encode({
            'kisah_id': kisahId,
          }),
        );

        if (!_isDisposed && mounted && response.statusCode == 200) {
          _safeSetState(() {
            _posts[postIndex]['is_bookmarked'] = true;
          });
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Ditambahkan ke bookmark')),
            );
          }
        }
      }
    } catch (e) {
      if (!_isDisposed && mounted && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  void _showComments(BuildContext context, int kisahId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            Future<List<dynamic>> commentsFuture = _fetchCommentsReturnList(kisahId);
          
          void refreshComments() {
            setModalState(() {
              commentsFuture = _fetchCommentsReturnList(kisahId);
            });
          }
            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.6,
              builder: (context, scrollController) {
                return FutureBuilder<List<dynamic>>(
                  future: _fetchCommentsReturnList(kisahId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(child: Text('No comments yet'));
                    }

                    final comments = snapshot.data!;
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
                          "Comments",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Expanded(
                          child: ListView.builder(
                            controller: scrollController,
                            itemCount: comments.length,
                            itemBuilder: (context, index) {
                              final comment = comments[index];
                              final user = comment['user'] ?? {};
                              final avatarPath = user['avatar'] ?? '';
                              final avatarUrl = avatarPath.isNotEmpty
                                  ? 'http://127.0.0.1:8000/avatar/${Uri.encodeComponent(avatarPath.split('/').last)}'
                                  : null;
                              final userName = user['name'] ?? 'Unknown User';
                              final createdAt = _formatTime(comment['created_at'] ?? '');

                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundImage: avatarUrl != null
                                      ? NetworkImage(avatarUrl)
                                      : null,
                                  child: avatarUrl == null
                                      ? const Icon(Icons.person)
                                      : null,
                                ),
                                title: Text(userName),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      createdAt,
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
                                      child: Text(comment['isi'] ?? ''),
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
                                  controller: _commentController,
                                  decoration: InputDecoration(
                                    hintText: 'Add your comment...',
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
                                  onPressed: () async {
                                    if (_commentController.text.isNotEmpty) {
                                      try {
                                        final token = await _authService.getToken();
                                        final response = await http.post(
                                          Uri.parse('http://127.0.0.1:8000/api/komen'),
                                          headers: {
                                            'Authorization': 'Bearer $token',
                                            'Content-Type': 'application/json',
                                          },
                                          body: json.encode({
                                            'isi': _commentController.text,
                                            'kisah_id': kisahId,
                                          }),
                                        );

                                        if (response.statusCode == 200) {
                                          _commentController.clear();
                                          refreshComments();
                                          setModalState(() {});
                                        }
                                      } catch (e) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('Failed to post comment: $e'),
                                          ),
                                        );
                                      }
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
      },
    );
  }

  Future<void> _handleLogout() async {
    try {
      // Tutup dialog konfirmasi
      Navigator.of(context).pop(); 
      
      // Panggil logout
      await _authService.logout();
      
      // Redirect ke HomePage
      if (!_isDisposed && mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const HomePage()),
          (route) => false,
        );
      }
    } catch (e) {
      print('Error selama logout: $e');
      // Tetap redirect meski ada error
      if (!_isDisposed && mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const HomePage()),
          (route) => false,
        );
      }
    }
  }

  void _onItemTapped(int index) {
    _safeSetState(() {
      _selectedIndex = index;
    });
  }

  List<Widget> _pages() => [
    _isLoading
        ? const Center(child: CircularProgressIndicator())
        : HomeContent(
          posts: _posts,
          showComments: _showComments,
          handleReaction: _handleReaction,
          handleBookmark: _handleBookmark,
          onPostTap: (post) {
              final user = post['user'] ?? {};
              final avatarPath = user['avatar'] ?? '';
              final avatarUrl = avatarPath.isNotEmpty
                  ? 'http://127.0.0.1:8000/avatar/${Uri.encodeComponent(avatarPath.split('/').last)}'
                  : '';
              
              if (!_isDisposed && mounted && context.mounted) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => FullStoryPage(
                      title: post['judul'] ?? '',
                      genre: post['genres']?.isNotEmpty == true
                          ? (post['genres'] as List).map((g) => g['genre'] ?? '').join(', ')
                          : '',
                      synopsis: post['sinopsis'] ?? '',
                      fullStory: post['isi'] ?? '',
                      user: user['name'] ?? 'Unknown',
                      avatar: avatarUrl,
                      kisahId: post['id'] ?? 0,
                    ),
                  ),
                );
              }
            },
          formatTime: _formatTime,
        ),
    const SearchPage(),
    const BookmarkPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: Builder(
          builder: (context) => IconButton(
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
            UserAccountsDrawerHeader(
              accountName: Text(
                _userName,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              accountEmail: Text(
                _isUserOnline ? 'Online' : 'Offline',
                style: TextStyle(
                  color: _isUserOnline ? Colors.green : Colors.grey,
                ),
              ),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                backgroundImage: _userAvatar != null && _userAvatar!.isNotEmpty
                    ? NetworkImage(
                        'http://127.0.0.1:8000/avatar/${Uri.encodeComponent(_userAvatar!.split('/').last)}',
                      )
                    : null,
                child: _userAvatar == null || _userAvatar!.isEmpty
                    ? Icon(Icons.person, size: 40, color: Colors.grey)
                    : null,
              ),
              decoration: BoxDecoration(
                color: Color.fromARGB(255, 159, 186, 188),
              ),
            ),
            ListTile(
              leading: Icon(Icons.person_outline, color: Colors.grey[700]),
              title: Text('Profile akun'),
              onTap: () {
                Navigator.pop(context);
                if (context.mounted) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ProfilePage()),
                  );
                }
              },
            ),
            ListTile(
              leading: Icon(Icons.info_outline, color: Colors.grey[700]),
              title: Text('Tentang Kami'),
              onTap: () {
                Navigator.pop(context);
                if (context.mounted) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const MyKisahPage()),
                  );
                }
              },
            ),
            Divider(),
            ListTile(
              leading: Icon(Icons.logout, color: Colors.red),
              title: Text('Logout', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                if (context.mounted) {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: const Text('Konfirmasi Logout'),
                        content: const Text('Apakah Anda yakin ingin logout?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Batal'),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              _handleLogout();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                            ),
                            child: const Text('Logout'),
                          ),
                        ],
                      );
                    },
                  );
                }
              },
            ),
          ],
        ),
      ),
      body: IndexedStack(index: _selectedIndex, children: _pages()),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const TulisanPage()),
          );
        },
        backgroundColor: const Color(0xFF40B5C3),
        child: const Icon(Icons.edit, color: Colors.white),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF40B5C3),
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.black45,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.bookmark), label: ''),
        ],
      ),
    );
  }
}

class HomeContent extends StatelessWidget {
  final List<dynamic> posts;
  final Function(BuildContext, int) showComments;
  final Function(int, int, int) handleReaction;
  final Function(int, int) handleBookmark;
  final Function(dynamic) onPostTap;
  final String Function(String?) formatTime;

  const HomeContent({
    required this.posts,
    required this.showComments,
    required this.handleReaction,
    required this.handleBookmark,
    required this.onPostTap,
    required this.formatTime,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: posts.length,
      itemBuilder: (context, index) {
        final post = posts[index];
        final user = post['user'] ?? {};
        final avatarPath = user['avatar'] ?? '';
        final userName = user['name'] ?? 'Unknown';
        
        final String avatarUrl = avatarPath.isNotEmpty
            ? 'http://127.0.0.1:8000/avatar/${Uri.encodeComponent(avatarPath.split('/').last)}'
            : '';
        
        final int likeCount = post['like_count'] ?? 0;
        final int dislikeCount = post['dislike_count'] ?? 0;
        final int? userReaction = post['user_reaction'];
        final bool isBookmarked = post['is_bookmarked'] ?? false;

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
                        backgroundImage: avatarUrl.isNotEmpty 
                            ? NetworkImage(avatarUrl) 
                            : null,
                        child: avatarUrl.isEmpty 
                            ? const Icon(Icons.person) 
                            : null,
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            userName,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            formatTime(post['created_at']),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      IconButton(
                        icon: Icon(
                          isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                          color: isBookmarked ? Colors.blue : null,
                        ),
                        onPressed: () => handleBookmark(post['id'] ?? 0, index),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    post['judul'] ?? '',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (post['genres']?.isNotEmpty == true)
                    Wrap(
                      spacing: 6,
                      children: (post['genres'] as List)
                          .map((genre) => Chip(
                                label: Text(
                                  genre['genre'] ?? '',
                                  style: const TextStyle(fontSize: 12),
                                ),
                                backgroundColor: Colors.blue.shade100,
                              ))
                          .toList(),
                    ),
                  const SizedBox(height: 8),
                  const Text(
                    'Sinopsis:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(post['sinopsis'] ?? ''),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(
                              userReaction == 1 
                                  ? Icons.thumb_up_alt 
                                  : Icons.thumb_up_alt_outlined,
                              color: userReaction == 1 ? Colors.blue : null,
                            ),
                            onPressed: () => handleReaction(post['id'] ?? 0, 1, index),
                          ),
                          Text(
                            likeCount.toString(),
                            style: TextStyle(
                              color: userReaction == 1 ? Colors.blue : Colors.grey,
                              fontWeight: userReaction == 1 ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(
                              userReaction == -1 
                                  ? Icons.thumb_down_alt 
                                  : Icons.thumb_down_alt_outlined,
                              color: userReaction == -1 ? Colors.red : null,
                            ),
                            onPressed: () => handleReaction(post['id'] ?? 0, -1, index),
                          ),
                          Text(
                            dislikeCount.toString(),
                            style: TextStyle(
                              color: userReaction == -1 ? Colors.red : Colors.grey,
                              fontWeight: userReaction == -1 ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.comment_outlined),
                        onPressed: () => showComments(context, post['id'] ?? 0),
                      ),
                      IconButton(
                        icon: const Icon(Icons.share),
                        onPressed: () {
                          Share.share(
                            'Check out this story: ${post['judul'] ?? ''} - ${post['sinopsis'] ?? ''}',
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