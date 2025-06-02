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
  bool _commentsLoading = false;
  bool _userDataLoading = true;
  List<dynamic> _posts = [];
  List<dynamic> _comments = [];
  
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
    _fetchComments();
    _fetchUserData();
  }

  @override
  void dispose() {
    // Set flag to indicate widget is disposed
    _isDisposed = true;
    
    // Clean up controllers
    _commentController.dispose();
    
    super.dispose();
  }

  // Safe setState method that checks if widget is still mounted
  void _safeSetState(VoidCallback fn) {
    if (!_isDisposed && mounted) {
      setState(fn);
    }
  }

  // Fetch user data from API
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

      // Check if widget is still mounted before updating state
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

      // Check if widget is still mounted before updating state
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

  Future<void> _fetchComments() async {
    try {
      final token = await _authService.getToken();
      final response = await http.get(
        Uri.parse('http://127.0.0.1:8000/api/komen/all'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (!_isDisposed && mounted && response.statusCode == 200) {
        _safeSetState(() {
          _comments = json.decode(response.body);
        });
      }
    } catch (e) {
      print('Error fetching comments: $e');
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
        throw Exception('Failed to fetch updated comments');
      }
    } catch (e) {
      print('Error fetching updated comments: $e');
      return [];
    }
  }

  // Function to handle like/dislike reactions
  Future<void> _handleReaction(int kisahId, int value, int postIndex) async {
    try {
      final token = await _authService.getToken();
      
      // Check if user already has a reaction on this post
      final currentPost = _posts[postIndex];
      final currentUserReaction = currentPost['user_reaction'];
      
      // If user clicks the same reaction they already have, remove it (delete)
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
          
          // Remove user's reaction
          _safeSetState(() {
            _posts[postIndex]['user_reaction'] = null;
            _posts[postIndex]['like_count'] = int.parse(responseData['like_count'] ?? '0');
            _posts[postIndex]['dislike_count'] = int.parse(responseData['dislike_count'] ?? '0');
          });
        }
      } else {
        // User clicks different reaction or has no reaction - add/update reaction
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
          
          // Update user's reaction to new value
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

  // Function to handle bookmarking a story
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
        // Remove bookmark
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
        // Add bookmark
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

  void _showComments(BuildContext context, int kisahId) async {
    _safeSetState(() {
      _commentsLoading = true;
    });

    try {
      final token = await _authService.getToken();
      final response = await http.get(
        Uri.parse('http://127.0.0.1:8000/api/komen/kisah/$kisahId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (!_isDisposed && mounted) {
        if (response.statusCode == 200) {
          final List<dynamic> responseData = json.decode(response.body);
          _safeSetState(() {
            _comments = responseData;
          });
        } else {
          throw Exception('Failed to load comments');
        }
      }
    } catch (e) {
      if (!_isDisposed && mounted && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading comments: ${e.toString()}')),
        );
      }
    } finally {
      if (!_isDisposed && mounted) {
        _safeSetState(() {
          _commentsLoading = false;
        });
      }
    }

    // Only show modal if widget is still mounted
    if (!_isDisposed && mounted && context.mounted) {
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
                        "Comments",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _commentsLoading
                          ? const Center(child: CircularProgressIndicator())
                          : Expanded(
                            child:
                                _comments.isEmpty
                                    ? const Center(child: Text('No comments yet'))
                                    : ListView.builder(
                                      controller: scrollController,
                                      itemCount: _comments.length,
                                      itemBuilder: (context, index) {
                                        final comment = _comments[index];
                                        final user = comment['user'] ?? {};
                                        final avatar =
                                            user['avatar'] != null
                                                ? 'http://127.0.0.1:8000/${user['avatar']}'
                                                : null;
                                        final userName =
                                            user['name'] ?? 'Unknown User';
                                        final createdAt =
                                            comment['created_at'] ?? '';

                                        return ListTile(
                                          leading: CircleAvatar(
                                            backgroundImage:
                                                avatar != null
                                                    ? NetworkImage(avatar)
                                                    : null,
                                            child:
                                                avatar == null
                                                    ? const Icon(Icons.person)
                                                    : null,
                                          ),
                                          title: Text(userName),
                                          subtitle: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
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
                                                  borderRadius:
                                                      BorderRadius.circular(10),
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
                                        Uri.parse(
                                          'http://127.0.0.1:8000/api/komen',
                                        ),
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
                                        // Immediately refresh comments after posting
                                        final updatedComments = await _fetchCommentsReturnList(kisahId);
                                        
                                        if (context.mounted) {
                                          setModalState(() {
                                            _comments = updatedComments;
                                          });
                                        }
                                      }
                                    } catch (e) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Failed to post comment: ${e.toString()}',
                                            ),
                                          ),
                                        );
                                      }
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
    }
  }

  Future<void> _handleLogout() async {
    await _authService.logout();
    if (!_isDisposed && mounted && context.mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
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
                ? 'http://127.0.0.1:8000/$avatarPath' 
                : '';
            
            if (!_isDisposed && mounted && context.mounted) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => FullStoryPage(
                    title: post['judul'] ?? '',
                    genre: post['genres']?.isNotEmpty == true
                        ? post['genres'][0]['genre'] ?? ''
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
            const SizedBox(height: 40),
            ListTile(
              leading: const Icon(Icons.arrow_back),
              onTap: () => Navigator.pop(context),
            ),
            const SizedBox(height: 20),
            // User Avatar - Now uses actual user data
            CircleAvatar(
              radius: 40,
              backgroundImage: _userAvatar != null && _userAvatar!.isNotEmpty
                  ? NetworkImage(_userAvatar!)
                  : null,
              onBackgroundImageError: _userAvatar != null 
                  ? (_, __) {} 
                  : null,
              child: _userAvatar == null || _userAvatar!.isEmpty
                  ? (_userName.isNotEmpty && _userName != 'Loading...' && _userName != 'Error loading name'
                      ? Text(
                          _userName[0].toUpperCase(),
                          style: const TextStyle(fontSize: 24, color: Colors.white),
                        )
                      : const Icon(Icons.person, size: 50))
                  : null,
            ),
            const SizedBox(height: 10),
            // User Name - Now shows actual user name
            Center(
              child: _userDataLoading 
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      _userName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
            // Online Status
            Center(
              child: Text(
                _isUserOnline ? 'Online' : 'Offline',
                style: TextStyle(
                  color: _isUserOnline ? Colors.green : Colors.grey,
                  fontSize: 14,
                ),
              ),
            ),
            const Divider(),
            ListTile(
              title: const Text('Profile akun'),
              leading: const Icon(Icons.person_outline),
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
              title: const Text('Tentang Kami'),
              leading: const Icon(Icons.info_outline),
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
            const Divider(),
            ListTile(
              title: const Text('Logout', style: TextStyle(color: Colors.red)),
              leading: const Icon(Icons.logout, color: Colors.red),
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

  const HomeContent({
    required this.posts,
    required this.showComments,
    required this.handleReaction,
    required this.handleBookmark,
    required this.onPostTap,
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
        
        // Fix avatar URL
        final String avatarUrl = avatarPath.isNotEmpty
            ? 'http://127.0.0.1:8000/$avatarPath'
            : '';
        
        // Get reaction data
        final int likeCount = post['like_count'] ?? 0;
        final int dislikeCount = post['dislike_count'] ?? 0;
        final int? userReaction = post['user_reaction']; // 1 for like, -1 for dislike, null for no reaction
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
                            post['created_at'] ?? '',
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
                  // Add genres display similar to bookmark page
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
                      // Like button with count
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
                      // Dislike button with count
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
                      // Comment button
                      IconButton(
                        icon: const Icon(Icons.comment_outlined),
                        onPressed: () => showComments(context, post['id'] ?? 0),
                      ),
                      // Share button
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