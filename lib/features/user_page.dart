import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:test_komikuapp/services/auth_service.dart';
import 'full_story_page.dart';
import 'package:share_plus/share_plus.dart';

class UserPage extends StatefulWidget {
  final int userId;
  final String userName;
  final String userAvatar;

  const UserPage({
    super.key,
    required this.userId,
    required this.userName,
    required this.userAvatar,
  });

  @override
  State<UserPage> createState() => _UserPageState();
}

class _UserPageState extends State<UserPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  bool _isFollowing = false;
  int _followersCount = 0;
  int _followingCount = 0;
  List<dynamic> _userStories = [];
  String _displayUserName = '';
  bool _commentsLoading = false;
  List<dynamic> _comments = [];
  final TextEditingController _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    print('UserPage initialized with userId: ${widget.userId}, userName: ${widget.userName}');
    _tabController = TabController(length: 2, vsync: this);
    _fetchUserData();
    _fetchUserStories();
    _checkFollowingStatus();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _fetchUserData() async {
    try {
      final token = await _authService.getToken();
      print('Fetching user data for ID: ${widget.userId}');
      final response = await http.get(
        Uri.parse('http://127.0.0.1:8000/api/user/${widget.userId}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      print('User data API response: ${response.statusCode}');
      print('User data response body: ${response.body}');

      if (response.statusCode == 200) {
        final userData = json.decode(response.body);
        setState(() {
          _displayUserName = userData['name'] ?? widget.userName;
        });
        print('Display user name set to: $_displayUserName');
      }
    } catch (e) {
      print('Error fetching user data: $e');
      setState(() {
        _displayUserName = widget.userName;
      });
    }
  }

  Future<void> _fetchFollowersCount() async {
    try {
      final token = await _authService.getToken();
      print('Fetching followers for user ID: ${widget.userId}');
      final response = await http.get(
        Uri.parse('http://127.0.0.1:8000/api/user/${widget.userId}/followers'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      print('Followers API response: ${response.statusCode}');
      print('Followers data: ${response.body}');

      if (response.statusCode == 200) {
        final followers = json.decode(response.body);
        setState(() {
          _followersCount = followers is List ? followers.length : 0;
        });
        print('Followers count: $_followersCount');
      }
    } catch (e) {
      print('Error fetching followers count: $e');
    }
  }

  Future<void> _fetchFollowingCount() async {
    try {
      final token = await _authService.getToken();
      print('Fetching following for user ID: ${widget.userId}');
      final response = await http.get(
        Uri.parse('http://127.0.0.1:8000/api/user/${widget.userId}/followings'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      print('Following API response: ${response.statusCode}');
      print('Following data: ${response.body}');

      if (response.statusCode == 200) {
        final followings = json.decode(response.body);
        setState(() {
          _followingCount = followings is List ? followings.length : 0;
        });
        print('Following count: $_followingCount');
      }
    } catch (e) {
      print('Error fetching following count: $e');
    }
  }

  Future<void> _fetchUserStories() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final token = await _authService.getToken();
      print('Fetching stories for user ID: ${widget.userId}');
      final response = await http.get(
        Uri.parse('http://127.0.0.1:8000/api/kisah/user/${widget.userId}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      print('Stories API response: ${response.statusCode}');
      print('Stories data: ${response.body}');

      if (response.statusCode == 200) {
        setState(() {
          _userStories = json.decode(response.body);
          _isLoading = false;
        });
        print('Stories count: ${_userStories.length}');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('Error loading stories: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading stories: ${e.toString()}')),
      );
    }
  }

  Future<void> _checkFollowingStatus() async {
    try {
      final token = await _authService.getToken();
      final response = await http.get(
        Uri.parse('http://127.0.0.1:8000/api/followings'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      print('Following status API response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final followingList = json.decode(response.body);
        setState(() {
          _isFollowing = followingList.any(
            (user) => user['id'] == widget.userId,
          );
        });
        print('Is following: $_isFollowing');
      }
    } catch (e) {
      print('Error checking follow status: $e');
    }
    
    await _fetchFollowersCount();
    await _fetchFollowingCount();
  }

  Future<void> _toggleFollow() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final token = await _authService.getToken();
      if (_isFollowing) {
        final response = await http.delete(
          Uri.parse('http://127.0.0.1:8000/api/unfollow/${widget.userId}'),
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        );

        if (response.statusCode == 200) {
          setState(() {
            _isFollowing = false;
            _followersCount--;
          });
        }
      } else {
        final response = await http.post(
          Uri.parse('http://127.0.0.1:8000/api/follow/${widget.userId}'),
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        );

        if (response.statusCode == 200) {
          setState(() {
            _isFollowing = true;
            _followersCount++;
          });
        }
      }
      
      await _fetchFollowersCount();
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshUserData() async {
    print('Refreshing user data for ID: ${widget.userId}');
    await _checkFollowingStatus();
    await _fetchFollowersCount();
    await _fetchFollowingCount();
    await _fetchUserStories();
  }

  List<dynamic> _getSortedStories(bool newestFirst) {
    List<dynamic> stories = List.from(_userStories);
    stories.sort((a, b) {
      DateTime dateA = DateTime.parse(a['created_at']);
      DateTime dateB = DateTime.parse(b['created_at']);
      return newestFirst ? dateB.compareTo(dateA) : dateA.compareTo(dateB);
    });
    return stories;
  }

  Future<void> _handleReaction(int kisahId, int value, int postIndex) async {
    try {
      final token = await _authService.getToken();
      final currentPost = _userStories[postIndex];
      final currentUserReaction = currentPost['user_reaction'];
      
      if (currentUserReaction == value) {
        final deleteResponse = await http.delete(
          Uri.parse('http://127.0.0.1:8000/api/kisah/$kisahId/reaction'),
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        );
        
        if (deleteResponse.statusCode == 200) {
          final responseData = json.decode(deleteResponse.body);
          setState(() {
            _userStories[postIndex]['user_reaction'] = null;
            _userStories[postIndex]['like_count'] = int.parse(responseData['like_count'] ?? '0');
            _userStories[postIndex]['dislike_count'] = int.parse(responseData['dislike_count'] ?? '0');
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

        if (response.statusCode == 200) {
          final responseData = json.decode(response.body);
          setState(() {
            _userStories[postIndex]['user_reaction'] = value;
            _userStories[postIndex]['like_count'] = int.parse(responseData['like_count'] ?? '0');
            _userStories[postIndex]['dislike_count'] = int.parse(responseData['dislike_count'] ?? '0');
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating reaction: ${e.toString()}')),
      );
    }
  }

  Future<void> _handleBookmark(int kisahId, int postIndex) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Anda harus login untuk menambahkan bookmark')),
        );
        return;
      }

      final currentPost = _userStories[postIndex];
      final isBookmarked = currentPost['is_bookmarked'] ?? false;

      if (isBookmarked) {
        final response = await http.delete(
          Uri.parse('http://127.0.0.1:8000/api/bookmarks/$kisahId'),
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        );

        if (response.statusCode == 200) {
          setState(() {
            _userStories[postIndex]['is_bookmarked'] = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Bookmark dihapus')),
          );
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

        if (response.statusCode == 200) {
          setState(() {
            _userStories[postIndex]['is_bookmarked'] = true;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ditambahkan ke bookmark')),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
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

  void _showComments(BuildContext context, int kisahId) async {
    setState(() {
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

      if (response.statusCode == 200) {
        final List<dynamic> responseData = json.decode(response.body);
        setState(() {
          _comments = responseData;
        });
      } else {
        throw Exception('Failed to load comments');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading comments: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _commentsLoading = false;
      });
    }

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
                            child: _comments.isEmpty
                                ? const Center(child: Text('No comments yet'))
                                : ListView.builder(
                                    controller: scrollController,
                                    itemCount: _comments.length,
                                    itemBuilder: (context, index) {
                                      final comment = _comments[index];
                                      final user = comment['user'] ?? {};
                                      final avatar = user['avatar'] != null
                                          ? 'http://127.0.0.1:8000/${user['avatar']}'
                                          : null;
                                      final userName = user['name'] ?? 'Unknown User';
                                      final createdAt = comment['created_at'] ?? '';

                                      return ListTile(
                                        leading: CircleAvatar(
                                          backgroundImage: avatar != null
                                              ? NetworkImage(avatar)
                                              : null,
                                          child: avatar == null
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
                                      final updatedComments = await _fetchCommentsReturnList(kisahId);
                                      setModalState(() {
                                        _comments = updatedComments;
                                      });
                                    }
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Failed to post comment: ${e.toString()}',
                                        ),
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
  }

  Widget _buildPostCard(dynamic post, int index) {
    final user = post['user'] ?? {};
    final avatarPath = user['avatar'] ?? '';
    final userName = user['name'] ?? 'Unknown';
    final avatarUrl = avatarPath.isNotEmpty
        ? 'http://127.0.0.1:8000/$avatarPath'
        : '';
    final int likeCount = post['like_count'] ?? 0;
    final int dislikeCount = post['dislike_count'] ?? 0;
    final int? userReaction = post['user_reaction'];
    final bool isBookmarked = post['is_bookmarked'] ?? false;

    return GestureDetector(
      onTap: () {
        final postUserId = post['user']?['id'] ?? post['user_id'] ?? post['userId'] ?? widget.userId;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => FullStoryPage(
              title: post['judul'] ?? 'No Title',
              genre: (post['genres'] != null && post['genres'].isNotEmpty) 
                  ? post['genres'][0]['genre'] ?? 'Unknown'
                  : 'Unknown',
              synopsis: post['sinopsis'] ?? 'No Synopsis',
              fullStory: post['isi'] ?? 'No Content',
              user: userName,
              avatar: avatarUrl,
              kisahId: post['id'] ?? 0,
              needsFullData: true,
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
                    backgroundImage: avatarUrl.isNotEmpty 
                        ? NetworkImage(avatarUrl) 
                        : null,
                    child: avatarUrl.isEmpty ? const Icon(Icons.person) : null,
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
                    onPressed: () => _handleBookmark(post['id'] ?? 0, index),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                post['judul'] ?? 'No Title',
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
              Text(post['sinopsis'] ?? 'No Synopsis'),
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
                        onPressed: () => _handleReaction(post['id'] ?? 0, 1, index),
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
                        onPressed: () => _handleReaction(post['id'] ?? 0, -1, index),
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
                    onPressed: () => _showComments(context, post['id'] ?? 0),
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_displayUserName.isNotEmpty ? _displayUserName : widget.userName),
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
          tabs: const [Tab(text: 'Terbaru'), Tab(text: 'Terlama')],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshUserData,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshUserData,
        child: Column(
          children: [
            const SizedBox(height: 16),
            CircleAvatar(
              radius: 40,
              backgroundImage: NetworkImage(widget.userAvatar),
            ),
            const SizedBox(height: 8),
            Text(
              '@${_displayUserName.isNotEmpty ? _displayUserName : widget.userName}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Text(
              'User ID: ${widget.userId}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: _isLoading ? null : _toggleFollow,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isFollowing ? Colors.grey[400] : Colors.blueAccent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 8,
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(_isFollowing ? 'Following' : 'Follow'),
                ),
                const SizedBox(width: 16),
                Row(
                  children: [
                    const Icon(Icons.group, size: 18, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      '$_followersCount Followers',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                Row(
                  children: [
                    const Icon(Icons.person_add, size: 18, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      '$_followingCount Following',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ],
            ),
            const Divider(height: 32, thickness: 1),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : ListView.builder(
                          itemCount: _getSortedStories(true).length,
                          itemBuilder: (context, index) {
                            return _buildPostCard(_getSortedStories(true)[index], index);
                          },
                        ),
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : ListView.builder(
                          itemCount: _getSortedStories(false).length,
                          itemBuilder: (context, index) {
                            return _buildPostCard(_getSortedStories(false)[index], index);
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
}