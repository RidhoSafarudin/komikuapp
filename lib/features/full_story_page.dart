import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:test_komikuapp/services/auth_service.dart';
import 'user_page.dart';

class FullStoryPage extends StatefulWidget {
  final String title;
  final String genre;
  final String synopsis;
  final String fullStory;
  final String user;
  final String avatar;
  final int kisahId;
  
  // Add optional parameter to indicate if we need to fetch full data
  final bool needsFullData;

  const FullStoryPage({
    super.key,
    required this.title,
    required this.genre,
    required this.synopsis,
    required this.fullStory,
    required this.user,
    required this.avatar,
    required this.kisahId,
    this.needsFullData = false, // Default false for backward compatibility
  });

  @override
  State<FullStoryPage> createState() => _FullStoryPageState();
}

class _FullStoryPageState extends State<FullStoryPage> {
  final AuthService _authService = AuthService();
  bool _isBookmarked = false;
  bool _isLoading = false;
  bool _isLoadingStoryData = false;
  bool _isCheckingBookmark = true; // Track bookmark checking status
  
  // Variables to hold the actual story data
  late String _actualTitle;
  late String _actualGenre;
  late String _actualSynopsis;
  late String _actualFullStory;
  late String _actualUser;
  late String _actualAvatar;
  
  // Variable untuk menyimpan user ID yang sebenarnya
  int? _actualUserId;

  // HTTP client untuk cancel requests
  http.Client? _httpClient;

  // Add a GlobalKey for ScaffoldMessenger to avoid context issues
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

  @override
  void initState() {
    super.initState();
    
    // Initialize HTTP client
    _httpClient = http.Client();
    
    // Initialize with passed data
    _actualTitle = widget.title;
    _actualGenre = widget.genre;
    _actualSynopsis = widget.synopsis;
    _actualFullStory = widget.fullStory;
    _actualUser = widget.user;
    _actualAvatar = widget.avatar;
    
    // Call these methods but don't await them to avoid blocking UI
    _initializeData();
  }

  // Method to initialize all data
  void _initializeData() async {
    try {
      // Start both operations concurrently
      final futures = <Future>[
        _checkBookmarkStatus(),
      ];
      
      // If data seems incomplete or needsFullData is true, fetch full data
      if (widget.needsFullData || 
          widget.synopsis.isEmpty || 
          widget.fullStory.isEmpty ||
          widget.synopsis == 'Tidak ada sinopsis' ||
          widget.fullStory == 'Tidak ada konten') {
        futures.add(_fetchFullStoryData());
      }
      
      // Wait for all operations to complete
      await Future.wait(futures);
    } catch (e) {
      // Silently handle initialization errors
      print('Error during initialization: $e');
    }
  }

  @override
  void dispose() {
    // Cancel any ongoing HTTP requests before disposing
    _httpClient?.close();
    _httpClient = null;
    super.dispose();
  }

  Future<void> _fetchFullStoryData() async {
    if (!mounted) return;
    
    setState(() {
      _isLoadingStoryData = true;
    });

    try {
      final token = await _authService.getToken();
      if (token == null) {
        if (mounted) {
          print('No token available for fetching story data');
        }
        return;
      }

      final response = await _httpClient!.get(
        Uri.parse('http://127.0.0.1:8000/api/kisah/${widget.kisahId}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (!mounted) return; // Check mounted before setState

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (mounted) {
          setState(() {
            _actualTitle = data['judul'] ?? widget.title;
            _actualSynopsis = data['sinopsis'] ?? widget.synopsis;
            _actualFullStory = data['isi'] ?? widget.fullStory;
            
            // Handle genre - might be array or string
            if (data['genres'] != null) {
              if (data['genres'] is List) {
                _actualGenre = (data['genres'] as List).map((g) => g['genre'] ?? g.toString()).join(', ');
              } else {
                _actualGenre = data['genres'].toString();
              }
            } else {
              _actualGenre = widget.genre;
            }
            
            // Handle user data
            final user = data['user'] ?? {};
            _actualUser = user['name'] ?? widget.user;
            
            // Ambil user ID dengan berbagai kemungkinan field name
            _actualUserId = user['id'] ?? user['user_id'] ?? user['userId'];
            
            print('Fetched user data: ID=${_actualUserId}, Name=${_actualUser}'); // Debug log
            
            final avatarPath = user['avatar'] ?? '';
            _actualAvatar = avatarPath.isNotEmpty 
                ? 'http://127.0.0.1:8000/$avatarPath' 
                : widget.avatar;
          });
        }
      } else {
        print('Failed to fetch story data: ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        print('Error fetching full story data: $e');
      }
      // Keep original data if fetch fails
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingStoryData = false;
        });
      }
    }
  }

  Future<void> _checkBookmarkStatus() async {
    if (!mounted) return;
    
    try {
      final token = await _authService.getToken();
      if (token == null) {
        if (mounted) {
          setState(() {
            _isCheckingBookmark = false;
            _isBookmarked = false;
          });
        }
        return;
      }

      final response = await _httpClient!.get(
        Uri.parse('http://127.0.0.1:8000/api/user/getBookmarks'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (!mounted) return; // Check mounted before setState

      if (response.statusCode == 200) {
        final List<dynamic> bookmarks = json.decode(response.body);
        final isBookmarked = bookmarks.any((bookmark) => 
          bookmark['kisah_id'] == widget.kisahId || 
          bookmark['id'] == widget.kisahId
        );
        
        if (mounted) {
          setState(() {
            _isBookmarked = isBookmarked;
            _isCheckingBookmark = false;
          });
        }
        
        print('Bookmark status checked: $_isBookmarked for kisah ${widget.kisahId}');
      } else {
        print('Failed to check bookmark status: ${response.statusCode}');
        if (mounted) {
          setState(() {
            _isCheckingBookmark = false;
            _isBookmarked = false; // Default to false on error
          });
        }
      }
    } catch (e) {
      print('Error checking bookmark status: $e');
      if (mounted) {
        setState(() {
          _isCheckingBookmark = false;
          _isBookmarked = false; // Default to false on error
        });
      }
    }
  }

  Future<void> _toggleBookmark() async {
    if (!mounted || _isLoading || _isCheckingBookmark) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      final token = await _authService.getToken();
      if (token == null) {
        _showSnackBar('Anda harus login untuk menambahkan bookmark');
        return;
      }

      if (_isBookmarked) {
        // Remove bookmark
        final response = await _httpClient!.delete(
          Uri.parse('http://127.0.0.1:8000/api/bookmarks/${widget.kisahId}'),
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        );

        if (!mounted) return;

        if (response.statusCode == 200) {
          setState(() {
            _isBookmarked = false;
          });
          _showSnackBar('Bookmark dihapus');
        } else {
          print('Failed to remove bookmark: ${response.statusCode}');
          _showSnackBar('Gagal menghapus bookmark');
        }
      } else {
        // Add bookmark
        final response = await _httpClient!.post(
          Uri.parse('http://127.0.0.1:8000/api/user/addBookmark'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: json.encode({
            'kisah_id': widget.kisahId,
          }),
        );

        if (!mounted) return;

        if (response.statusCode == 200) {
          setState(() {
            _isBookmarked = true;
          });
          _showSnackBar('Ditambahkan ke bookmark');
        } else {
          print('Failed to add bookmark: ${response.statusCode}');
          _showSnackBar('Gagal menambahkan bookmark');
        }
      }
    } catch (e) {
      print('Error toggling bookmark: $e');
      _showSnackBar('Error: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Safe method to show SnackBar that checks if widget is mounted
  void _showSnackBar(String message) {
    if (mounted) {
      // Use a post-frame callback to ensure the context is safe
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message)),
          );
        }
      });
    }
  }

  // Method untuk mencari user ID berdasarkan nama
  Future<int?> _findUserIdByName(String userName) async {
    // Skip search API karena tidak tersedia
    print('Skipping user search API (not available)');
    return null;
  }

  // Method alternatif - coba beberapa ID yang mungkin
  Future<int?> _findUserIdFromCommonIds(String userName) async {
    try {
      final token = await _authService.getToken();
      if (token == null) return null;
      
      // Coba beberapa ID user yang mungkin (1-10 sebagai contoh)
      for (int userId = 1; userId <= 20; userId++) {
        if (!mounted) break; // Stop if widget is disposed
        
        try {
          final response = await _httpClient!.get(
            Uri.parse('http://127.0.0.1:8000/api/user/$userId'),
            headers: {
              'Authorization': 'Bearer $token',
              'Accept': 'application/json',
            },
          );

          if (response.statusCode == 200) {
            final userData = json.decode(response.body);
            if (userData['name'] == userName) {
              print('Found user $userName with ID: $userId');
              return userId;
            }
          }
        } catch (e) {
          // Continue to next ID if this one fails
          continue;
        }
      }
    } catch (e) {
      print('Error searching user IDs: $e');
    }
    return null;
  }

  void _navigateToUserPage(BuildContext context) async {
    // Jangan gunakan default userIdToUse = 1
    int? userIdToUse = _actualUserId;
    
    // Jika tidak ada _actualUserId, coba cari berdasarkan nama
    if (_actualUserId == null) {
      print('No user ID found, searching by name: $_actualUser');
      
      // Coba method pencarian dengan iterasi ID (workaround)
      userIdToUse = await _findUserIdFromCommonIds(_actualUser);
    }
    
    // Jika masih tidak ditemukan, tampilkan pesan error
    if (userIdToUse == null) {
      print('Unable to find user ID for: $_actualUser');
      _showSnackBarWithAction(
        'User "$_actualUser" not found. Try refreshing the story.',
        'Refresh',
        () => _fetchFullStoryData(),
      );
      return; // Don't navigate if no user ID found
    }
    
    print('Navigating to user page with ID: $userIdToUse, Name: $_actualUser'); // Debug log
    
    if (mounted && context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => UserPage(
            userId: userIdToUse!,
            userName: _actualUser,
            userAvatar: _actualAvatar,
          ),
        ),
      );
    }
  }

  // Safe method to show SnackBar with action
  void _showSnackBarWithAction(String message, String actionLabel, VoidCallback onPressed) {
    if (mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: Colors.orange,
              action: SnackBarAction(
                label: actionLabel,
                textColor: Colors.white,
                onPressed: onPressed,
              ),
            ),
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldMessengerKey,
      appBar: AppBar(
        title: Text(_actualTitle),
        backgroundColor: const Color(0xFFB2CEF8),
        actions: [
          IconButton(
            icon: _isLoading || _isCheckingBookmark
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Icon(
                    _isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                    color: _isBookmarked ? Colors.yellow : Colors.white,
                  ),
            onPressed: (_isLoading || _isCheckingBookmark) ? null : _toggleBookmark,
          ),
          IconButton(
            icon: const Icon(Icons.warning_amber_outlined, color: Colors.white),
            onPressed: () {
              if (!mounted) return;
              
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
                        _showSnackBar('Postingan telah dilaporkan.');
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
      body: _isLoadingStoryData
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: () => _navigateToUserPage(context),
                    child: CircleAvatar(
                      radius: 50,
                      backgroundImage: (_actualAvatar.isNotEmpty)
                          ? NetworkImage(_actualAvatar)
                          : const AssetImage('assets/default_avatar.png')
                              as ImageProvider,
                    ),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => _navigateToUserPage(context),
                    child: Text(
                      _actualUser,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueAccent,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Text(
                      _actualTitle,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_actualGenre.isNotEmpty)
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blueAccent,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _actualGenre,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 20),
                  const Text(
                    'Sinopsis:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _actualSynopsis.isNotEmpty ? _actualSynopsis : 'Tidak ada sinopsis',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Cerita Lengkap:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _actualFullStory.isNotEmpty ? _actualFullStory : 'Tidak ada konten',
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
    );
  }
}