import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/auth_service.dart';
import 'full_story_page.dart';

class BookmarkPage extends StatefulWidget {
  const BookmarkPage({super.key});

  @override
  State<BookmarkPage> createState() => _BookmarkPageState();
}

class _BookmarkPageState extends State<BookmarkPage> with RouteAware {
  final AuthService _authService = AuthService();
  List<dynamic> _bookmarkedStories = [];
  bool _isLoading = true;
  final http.Client _httpClient = http.Client();

  @override
  void initState() {
    super.initState();
    _fetchBookmarkedStories();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh when page is focused
    if (ModalRoute.of(context)?.isCurrent ?? false) {
      _fetchBookmarkedStories();
    }
  }

  @override
  void dispose() {
    _httpClient.close();
    super.dispose();
  }

  Future<void> _fetchBookmarkedStories() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final token = await _authService.getToken();
      if (token == null) {
        _showError('Anda belum login');
        return;
      }

      final response = await _httpClient.get(
        Uri.parse('http://127.0.0.1:8000/api/user/getBookmark'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (mounted) {
        if (response.statusCode == 200) {
          setState(() {
            _bookmarkedStories = json.decode(response.body);
            _isLoading = false;
          });
        } else {
          setState(() {
            _isLoading = false;
          });
          _showError('Gagal memuat bookmark');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showError('Terjadi kesalahan: ${e.toString()}');
      }
    }
  }

  Future<void> _removeBookmark(int kisahId, int index) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        _showError('Anda belum login');
        return;
      }

      final response = await _httpClient.delete(
        Uri.parse('http://127.0.0.1:8000/api/bookmarks/$kisahId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (mounted) {
        if (response.statusCode == 200) {
          setState(() {
            _bookmarkedStories.removeAt(index);
          });
          _showSuccess('Bookmark berhasil dihapus');
        } else {
          _showError('Gagal menghapus bookmark');
        }
      }
    } catch (e) {
      if (mounted) {
        _showError('Terjadi kesalahan: ${e.toString()}');
      }
    }
  }

  Future<int?> _fetchUserIdByName(String userName) async {
    try {
      final token = await _authService.getToken();
      if (token == null) return null;
      
      final response = await _httpClient.get(
        Uri.parse('http://127.0.0.1:8000/api/user?name=${Uri.encodeComponent(userName)}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final userData = json.decode(response.body);
        
        // Handle different response formats
        if (userData is Map && userData.containsKey('id')) {
          return userData['id'] as int?;
        } else if (userData is List && userData.isNotEmpty) {
          return userData[0]['id'] as int?;
        }
      }
    } catch (e) {
      print('Error fetching user ID by name: $e');
    }
    return null;
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bookmark Saya'),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 1,
        foregroundColor: Colors.black,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchBookmarkedStories,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _bookmarkedStories.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.bookmark_border,
                        size: 64,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Belum ada bookmark',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Tambahkan kisah ke bookmark untuk membacanya nanti',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _fetchBookmarkedStories,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _bookmarkedStories.length,
                    itemBuilder: (context, index) {
                      final story = _bookmarkedStories[index];
                      final user = story['user'] ?? {};
                      final avatarPath = user['avatar'] ?? '';
                      final userName = user['name'] ?? 'Unknown';
                      
                      final String avatarUrl = avatarPath.isNotEmpty
                          ? 'http://127.0.0.1:8000/avatar/${Uri.encodeComponent(avatarPath.split('/').last)}'
                          : '';

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: InkWell(
                          onTap: () async {
                            // Show loading indicator
                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (context) => const Center(
                                child: CircularProgressIndicator(),
                              ),
                            );

                            try {
                              // Get the user ID by name first
                              final userId = await _fetchUserIdByName(userName);
                              
                              if (!mounted) return;
                              
                              // Close loading indicator
                              Navigator.of(context).pop();
                              
                              if (userId == null) {
                                _showError('Tidak dapat menemukan data user');
                                return;
                              }

                              if (mounted) {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => FullStoryPage(
                                      title: story['judul'] ?? '',
                                      genre: story['genres']?.isNotEmpty == true
                                          ? story['genres'][0]['genre'] ?? ''
                                          : '',
                                      synopsis: story['sinopsis'] ?? '',
                                      fullStory: story['isi'] ?? '',
                                      user: userName,
                                      avatar: avatarUrl,
                                      kisahId: story['id'] ?? 0,
                                      needsFullData: true, 
                                    ),
                                  ),
                                );
                                // Refresh when returning from full story page
                                _fetchBookmarkedStories();
                              }
                            } catch (e) {
                              if (mounted) {
                                Navigator.of(context).pop();
                                _showError('Error: ${e.toString()}');
                              }
                            }
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(16),
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
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            userName,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            story['created_at'] ?? '',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.bookmark,
                                        color: Colors.blue,
                                      ),
                                      onPressed: () {
                                        showDialog(
                                          context: context,
                                          builder: (BuildContext context) {
                                            return AlertDialog(
                                              title: const Text('Hapus Bookmark'),
                                              content: const Text(
                                                'Apakah Anda yakin ingin menghapus kisah ini dari bookmark?',
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () => Navigator.pop(context),
                                                  child: const Text('Batal'),
                                                ),
                                                ElevatedButton(
                                                  onPressed: () {
                                                    Navigator.pop(context);
                                                    _removeBookmark(story['id'] ?? 0, index);
                                                  },
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: Colors.red,
                                                  ),
                                                  child: const Text('Hapus'),
                                                ),
                                              ],
                                            );
                                          },
                                        );
                                      },
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  story['judul'] ?? '',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                if (story['genres']?.isNotEmpty == true)
                                  Wrap(
                                    spacing: 6,
                                    children: (story['genres'] as List)
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
                                Text(
                                  story['sinopsis'] ?? '',
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}