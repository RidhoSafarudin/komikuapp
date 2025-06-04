import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'edit_profile_page.dart';
import 'edit_cerita_page.dart';
import '../services/auth_service.dart';
import 'full_story_page.dart'; // Import FullStoryPage

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with SingleTickerProviderStateMixin {
  String username = '';
  int followers = 0;
  int following = 0;
  String? avatarUrl;
  bool isLoading = true;

  late TabController _tabController;
  final AuthService _authService = AuthService();

  List<Map<String, dynamic>> posts = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadUserData();
  }
  Future<Map<String, dynamic>> _getUserKisah(int userId) async {
  try {
    final token = await _authService.getToken();
    final response = await http.get(
      Uri.parse('http://127.0.0.1:8000/api/kisah/user/$userId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );
    
    if (response.statusCode == 200) {
      return {
        'success': true,
        'kisah': json.decode(response.body),
      };
    } else {
      return {'success': false, 'message': 'Failed to load kisah'};
    }
  } catch (e) {
    return {'success': false, 'message': 'Error: $e'};
  }
}

  Future<void> _loadUserData() async {
    setState(() {
      isLoading = true;
    });

    try {
      final profileResult = await _getUserProfile();
      
      if (profileResult['success'] == true && profileResult['user'] != null) {
        final userData = profileResult['user'];
        final userId = userData['id'];
        final kisahResult = await _getUserKisah(userId);
        
        final Future<Map<String, dynamic>> followersResult = _getFollowers();
        final Future<Map<String, dynamic>> followingResult = _getFollowing();
        
        final results = await Future.wait([followersResult, followingResult]);
        final followersData = results[0];
        final followingData = results[1];
        
        setState(() {
          username = userData['name'] ?? '';
          avatarUrl = userData['avatar_url'];
          
          if (followersData['success'] == true && followersData['followers'] != null) {
            final followersArray = followersData['followers'];
            followers = followersArray is List ? followersArray.length : 0;
          } else {
            followers = 0;
          }
          
          if (followingData['success'] == true && followingData['following'] != null) {
            final followingArray = followingData['following'];
            following = followingArray is List ? followingArray.length : 0;
          } else {
            following = 0;
          }
          
          if (kisahResult['success'] == true) {
  posts = (kisahResult['kisah'] as List).map((kisah) {
    // Perbaikan untuk menangani format genre
    List<dynamic> genres = kisah['genres'] ?? [];
    List<String> genreNames = genres.map((g) => g['genre']?.toString() ?? '').toList();
    
    return {
      'id': kisah['id'],
      'title': kisah['judul'] ?? '',
      'time': _formatTime(kisah['created_at']),
      'created_at': kisah['created_at'],
      'sinopsis': kisah['sinopsis'] ?? 'Tidak ada sinopsis.',
      'isi': kisah['isi'] ?? '',
      'genres': genreNames, // Simpan sebagai list nama genre
      'genres_data': genres, // Simpan data lengkap untuk keperluan lain
    };
  }).toList();
            
            posts.sort((a, b) {
              final aTime = DateTime.tryParse(a['created_at'] ?? '') ?? DateTime(1970);
              final bTime = DateTime.tryParse(b['created_at'] ?? '') ?? DateTime(1970);
              return bTime.compareTo(aTime);
            });
          }
          
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(profileResult['message'] ?? 'Failed to load profile data'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading profile: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<Map<String, dynamic>> _getUserProfile() async {
    try {
      final token = await _authService.getToken();
      
      if (token == null) {
        return {'success': false, 'message': 'No token found'};
      }

      final response = await http.get(
        Uri.parse('http://127.0.0.1:8000/api/me'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return {
          'success': true, 
          'user': responseData['user'],
          'kisah': responseData['kisah']
        };
      } else {
        return {'success': false, 'message': 'Failed to get user data'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  Future<Map<String, dynamic>> _getFollowers() async {
    try {
      final token = await _authService.getToken();
      
      if (token == null) {
        return {'success': false, 'message': 'No token found'};
      }
      
      final response = await http.get(
        Uri.parse('http://127.0.0.1:8000/api/followers'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        
        dynamic followersData;
        if (responseData is Map && responseData.containsKey('followers')) {
          followersData = responseData['followers'];
        } else if (responseData is List) {
          followersData = responseData;
        } else if (responseData is Map && responseData.containsKey('data')) {
          followersData = responseData['data'];
        } else {
          followersData = responseData;
        }
        
        return {
          'success': true, 
          'followers': followersData
        };
      } else {
        return {'success': false, 'message': 'Failed to get followers data: ${response.statusCode}'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  Future<Map<String, dynamic>> _getFollowing() async {
    try {
      final token = await _authService.getToken();
      
      if (token == null) {
        return {'success': false, 'message': 'No token found'};
      }
      
      final response = await http.get(
        Uri.parse('http://127.0.0.1:8000/api/followings'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        
        dynamic followingData;
        if (responseData is Map && responseData.containsKey('following')) {
          followingData = responseData['following'];
        } else if (responseData is List) {
          followingData = responseData;
        } else if (responseData is Map && responseData.containsKey('data')) {
          followingData = responseData['data'];
        } else {
          followingData = responseData;
        }
        
        return {
          'success': true, 
          'following': followingData
        };
      } else {
        return {'success': false, 'message': 'Failed to get following data: ${response.statusCode}'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
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

  List<Map<String, dynamic>> get newestPosts {
    return posts;
  }

  List<Map<String, dynamic>> get oldestPosts {
    return posts.reversed.toList();
  }

  void navigateToEditProfile() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => EditProfilePage()),
    );

    if (result is Map<String, String>) {
      _loadUserData();
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
              onPressed: () async {
                Navigator.pop(context);
                await _deleteKisah(index);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteKisah(int index) async {
    try {
      final token = await _authService.getToken();
      
      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Token tidak ditemukan. Silakan login kembali.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final kisahId = posts[index]['id'];
      
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      final response = await http.delete(
        Uri.parse('http://127.0.0.1:8000/api/kisah/delete/$kisahId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      Navigator.pop(context);

      if (response.statusCode == 200) {
        setState(() {
          posts.removeAt(index);
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kisah berhasil dihapus'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        final responseData = json.decode(response.body);
        final errorMessage = responseData['message'] ?? 'Gagal menghapus kisah';
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // New method to show comments management
  void _showCommentsManagement(int kisahId) async {
    try {
      final token = await _authService.getToken();
      if (token == null) return;

      // Fetch comments for this story
      final response = await http.get(
        Uri.parse('http://127.0.0.1:8000/api/komen/kisah/$kisahId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final comments = json.decode(response.body) as List;
        
        if (!mounted) return;
        
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          builder: (context) {
            return Container(
              padding: const EdgeInsets.all(16),
              height: MediaQuery.of(context).size.height * 0.8,
              child: Column(
                children: [
                  const Text(
                    'Kelola Komentar',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: comments.isEmpty
                        ? const Center(child: Text('Tidak ada komentar'))
                        : ListView.builder(
                            itemCount: comments.length,
                            itemBuilder: (context, index) {
                              final comment = comments[index];
                              return Card(
                                margin: const EdgeInsets.symmetric(vertical: 8),
                                child: ListTile(
                                  title: Text(comment['isi'] ?? ''),
                                  subtitle: Text(
                                    'Oleh: ${comment['user_name'] ?? 'Anonim'}\n'
                                    '${_formatTime(comment['created_at'])}',
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () => _deleteComment(comment['id']),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memuat komentar: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // New method to delete a comment
  Future<void> _deleteComment(int commentId) async {
    try {
      final token = await _authService.getToken();
      if (token == null) return;

      final response = await http.delete(
        Uri.parse('http://127.0.0.1:8000/api/komen/$commentId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Komentar berhasil dihapus'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context); // Close the bottom sheet
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menghapus komentar: ${response.statusCode}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildProfileAvatar() {
  return Container(
    width: 80,
    height: 80,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: Colors.grey[300],
    ),
    child: avatarUrl != null && avatarUrl!.isNotEmpty
        ? ClipOval(
            child: Image.network(
              'http://127.0.0.1:8000/avatar/${Uri.encodeComponent(avatarUrl!.split('/').last)}',
              width: 80,
              height: 80,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      username.isNotEmpty ? username[0].toUpperCase() : 'U',
                      style: const TextStyle(
                        fontSize: 24,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              },
            ),
          )
        : Center(
            child: Text(
              username.isNotEmpty ? username[0].toUpperCase() : 'U',
              style: const TextStyle(
                fontSize: 24,
                color: Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
  );
}

  Widget buildPostCard(Map<String, dynamic> post, int originalIndex) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: InkWell(
        onTap: () {
          Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => FullStoryPage(
      title: post['title'] ?? post['judul'] ?? 'No Title', // Handle both possible keys
      genre: post['genres'] is List 
          ? (post['genres'] as List<dynamic>).join(', ')
          : post['genres']?.toString() ?? '',
      synopsis: post['sinopsis'] ?? 'No Synopsis',
      fullStory: post['isi'] ?? post['fullStory'] ?? 'No Content', // Handle both possible keys
      user: username,
      avatar: avatarUrl != null && avatarUrl!.isNotEmpty
            ? 'http://127.0.0.1:8000/avatar/${Uri.encodeComponent(avatarUrl!.split('/').last)}'
            : '',
      kisahId: post['id'],
      needsFullData: (post['fullStory']?.isEmpty ?? true) && (post['isi']?.isEmpty ?? true),

              ),
            ),
          );
        },
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
                    onSelected: (value) async {
                      if (value == 'edit') {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => EditCeritaPage(
                              story: post,
                              onSave: (editedStory) {
                                setState(() {
                                  posts[originalIndex] = editedStory;
                                });
                              },
                            ),
                          ),
                        );
                        
                        if (result != null) {
                          setState(() {
                            posts[originalIndex] = result;
                          });
                        }
                      } else if (value == 'hapus') {
                        _showDeleteConfirmation(context, originalIndex);
                      } else if (value == 'komentar') {
                        _showCommentsManagement(post['id']);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'edit', child: Text('Edit')),
                      const PopupMenuItem(
                        value: 'hapus',
                        child: Text('Hapus'),
                      ),
                      const PopupMenuItem(
                        value: 'komentar',
                        child: Text('Kelola Komentar'),
                      ),
                    ],
                    icon: const Icon(Icons.more_vert),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (post['genres'] != null && (post['genres'] as List).isNotEmpty)
              Wrap(
                spacing: 6,
                children: (post['genres'] as List)
                    .where((genre) => genre.toString().isNotEmpty)
                    .map((genre) => Chip(
                          label: Text(genre),
                          backgroundColor: Colors.blue.shade100,
                        ))
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
                children: [
                  IconButton(
                    icon: const Icon(Icons.comment),
                    onPressed: () => _showCommentsManagement(post['id']),
                  ),
                  const Icon(Icons.share),
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
        title: const Text('Profil'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: navigateToEditProfile,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadUserData,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadUserData,
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  _buildProfileAvatar(),
                  const SizedBox(height: 8),
                  Text(
                    username.isNotEmpty ? username : 'Loading...',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
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
                        ListView.builder(
                          itemCount: newestPosts.length,
                          itemBuilder: (context, index) {
                            return buildPostCard(newestPosts[index], index);
                          },
                        ),
                        ListView.builder(
                          itemCount: oldestPosts.length,
                          itemBuilder: (context, index) {
                            final post = oldestPosts[index];
                            final originalIndex = posts.indexWhere((p) => p['id'] == post['id']);
                            return buildPostCard(post, originalIndex);
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}