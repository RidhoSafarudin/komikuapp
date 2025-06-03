import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:test_komikuapp/services/auth_service.dart';
import 'full_story_page.dart';
import 'user_page.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  final AuthService _authService = AuthService();
  int selectedFilterIndex = 0;
  List<String> selectedGenres = [];
  bool _isLoading = false;
  List<dynamic> _posts = [];
  List<dynamic> _filteredPosts = [];

  // Add this to track if widget is still mounted
  bool _isDisposed = false;

  final List<String> genres = [
    'Romance',
    'Fantasi',
    'Horor',
    'Misteri',
    'Action',
    'Sejarah',
    'Fiksi Ilmiah',
    'Petualangan',
  ];

  @override
  void initState() {
    super.initState();
    _fetchAllStories();
    _searchController.addListener(_searchPosts);
  }

  Future<void> _fetchAllStories() async {
    // Check if widget is still mounted before calling setState
    if (_isDisposed || !mounted) return;
    
    setState(() => _isLoading = true);

    try {
      final token = await _authService.getToken();
      final response = await http.get(
        Uri.parse('http://127.0.0.1:8000/api/kisah/search'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      // Check again before calling setState
      if (_isDisposed || !mounted) return;

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        
        // Debug: Print first few items to see structure
        if (data.isNotEmpty) {
          print('Sample data structure:');
          print(data.first);
          print('Available keys: ${data.first.keys.toList()}');
        }
        
        // Final check before setState
        if (_isDisposed || !mounted) return;
        
        setState(() {
          _posts = data;
          _filteredPosts = data;
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load stories');
      }
    } catch (e) {
      // Check before calling setState
      if (_isDisposed || !mounted) return;
      
      setState(() => _isLoading = false);
      
      // Check before showing SnackBar
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    }
  }

  // Add method to fetch user ID by name
  Future<int?> _fetchUserIdByName(String userName) async {
    try {
      final token = await _authService.getToken();
      print('Fetching user ID for name: $userName');
      
      final response = await http.get(
        Uri.parse('http://127.0.0.1:8000/api/user?name=${Uri.encodeComponent(userName)}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      print('User ID API response: ${response.statusCode}');
      print('User ID response body: ${response.body}');

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

  void _searchPosts() {
    // Check if widget is still mounted
    if (_isDisposed || !mounted) return;
    
    String query = _searchController.text.toLowerCase();

    setState(() {
      if (selectedFilterIndex == 0) {
        // Judul tab
        _filteredPosts = _posts.where((post) {
          final judul = (post['judul'] ?? '').toLowerCase();
          return judul.contains(query);
        }).toList();
      } else if (selectedFilterIndex == 1) {
        // Penulis tab - Show all matching authors (with duplicates removed manually)
        List<dynamic> matchingPosts = _posts.where((post) {
          final penulis = (post['user_name'] ?? '').toLowerCase();
          return penulis.contains(query);
        }).toList();
        
        // Remove duplicates based on user_name and user_id
        Map<String, dynamic> seenUsers = {};
        List<dynamic> uniqueUsers = [];
        
        for (var post in matchingPosts) {
          String userKey = '${post['user_id'] ?? 0}_${post['user_name'] ?? ''}';
          if (!seenUsers.containsKey(userKey)) {
            seenUsers[userKey] = true;
            uniqueUsers.add({
              'user_id': post['user_id'],
              'user_name': post['user_name'],
              'user_avatar': post['user_avatar'],
              'id': post['id'],
            });
          }
        }
        
        _filteredPosts = uniqueUsers;
        print('Found ${matchingPosts.length} matching posts, ${uniqueUsers.length} unique users');
      } else {
        // Genre tab
        if (selectedGenres.isEmpty) {
          _filteredPosts = _posts;
        } else {
          _filteredPosts = _posts.where((post) {
            final List<dynamic> postGenres = post['genres'] ?? [];
            return selectedGenres.any(
              (genre) => postGenres.contains(genre),
            );
          }).toList();
        }
      }
    });
  }

  void _toggleGenreSelection(String genre) {
    // Check if widget is still mounted
    if (_isDisposed || !mounted) return;
    
    setState(() {
      selectedGenres.contains(genre)
          ? selectedGenres.remove(genre)
          : selectedGenres.add(genre);
      _searchPosts();
    });
  }

  Widget _buildUserCard(dynamic post) {
    final avatar = (post['user_avatar'] != null && post['user_avatar'].isNotEmpty)
        ? NetworkImage(post['user_avatar'])
        : const AssetImage('assets/default_avatar.png') as ImageProvider;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: avatar,
          radius: 25,
        ),
        title: Text(
          post['user_name'] ?? 'Anonim',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Text('@${post['user_name'] ?? 'anonim'}'),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () async {
          // Check if widget is still mounted before navigation
          if (!mounted) return;
          
          final userName = post['user_name'] ?? 'Anonim';
          final userAvatar = post['user_avatar'] ?? '';
          int? userId = post['user_id'];
          
          // If user_id is 0 or null, fetch it using the name
          if (userId == null || userId == 0) {
            print('User ID is null or 0, fetching by name: $userName');
            
            // Show loading indicator
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => const Center(
                child: CircularProgressIndicator(),
              ),
            );
            
            userId = await _fetchUserIdByName(userName);
            
            // Hide loading indicator
            if (mounted) {
              Navigator.of(context).pop();
            }
            
            if (userId == null) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Tidak dapat menemukan data user'),
                  ),
                );
              }
              return;
            }
          }
          
          print('Navigating to UserPage with:');
          print('- userId: $userId');
          print('- userName: $userName');
          print('- userAvatar: $userAvatar');
          
          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => UserPage(
                  userId: userId!,
                  userName: userName,
                  userAvatar: userAvatar,
                ),
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildStoryCard(dynamic post) {
    final avatar = (post['user_avatar'] != null && post['user_avatar'].isNotEmpty)
        ? NetworkImage(post['user_avatar'])
        : const AssetImage('assets/default_avatar.png') as ImageProvider;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        leading: CircleAvatar(backgroundImage: avatar),
        title: Text(
          post['judul'] ?? 'Tanpa Judul',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Penulis: ${post['user_name'] ?? 'Anonim'}'),
            Text(
              'Genre: ${(post['genres'] as List<dynamic>? ?? []).join(', ')}',
            ),
          ],
        ),
        isThreeLine: true,
        onTap: () {
          // Check if widget is still mounted before navigation
          if (!mounted) return;
          
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => FullStoryPage(
                title: post['judul'] ?? 'Tanpa Judul',
                genre: (post['genres'] as List<dynamic>? ?? []).join(', '),
                synopsis: post['sinopsis'] ?? 'Tidak ada sinopsis',
                fullStory: post['isi'] ?? 'Tidak ada konten',
                user: post['user_name'] ?? 'Anonim',
                avatar: post['user_avatar'] ?? '',
                kisahId: post['id'] ?? 0,
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    // Mark as disposed to prevent setState calls
    _isDisposed = true;
    
    // Remove listener before disposing controller
    _searchController.removeListener(_searchPosts);
    
    // Dispose the controller
    _searchController.dispose();
    
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<String> filters = ['Judul', 'Penulis', 'Genre'];

    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: selectedFilterIndex == 0
                    ? 'Cari berdasarkan judul...'
                    : selectedFilterIndex == 1
                        ? 'Cari penulis...'
                        : 'Pilih genre...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          _searchController.clear();
                          _searchPosts();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(filters.length, (index) {
                bool isSelected = selectedFilterIndex == index;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: GestureDetector(
                    onTap: () {
                      // Check if widget is still mounted
                      if (!mounted) return;
                      
                      setState(() {
                        selectedFilterIndex = index;
                        if (index != 2) selectedGenres.clear();
                        _searchPosts();
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.blueAccent : Colors.grey[200],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        filters[index],
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : Colors.black,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 20),
          if (selectedFilterIndex == 2)
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: genres.map((genre) {
                  bool isSelected = selectedGenres.contains(genre);
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => _toggleGenreSelection(genre),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.blueAccent
                              : Colors.grey[200],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          genre,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          const SizedBox(height: 10),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredPosts.isEmpty
                    ? Center(
                        child: Text(
                          selectedFilterIndex == 1
                              ? 'Penulis tidak ditemukan.'
                              : 'Cerita tidak ditemukan.',
                          style: const TextStyle(fontSize: 16),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _filteredPosts.length,
                        itemBuilder: (context, index) {
                          final post = _filteredPosts[index];
                          
                          // Show user card for author search, story card for others
                          return selectedFilterIndex == 1
                              ? _buildUserCard(post)
                              : _buildStoryCard(post);
                        },
                      ),
          ),
        ],
      ),
    );
  }
}