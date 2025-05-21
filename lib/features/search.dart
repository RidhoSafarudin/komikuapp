import 'package:flutter/material.dart';
import 'full_story_page.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  int selectedFilterIndex = 0;
  List<String> selectedGenres = [];

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

  final List<Map<String, String>> posts = [
    {
      'user': 'ZFAR',
      'title': 'KISAH JEKY',
      'genre': 'Petualangan',
      'synopsis': 'Ini adalah kisah tentang Jeky yang penuh petualangan.',
      'fullStory': 'Ini kisah lengkap Jeky...',
      'time': '1 jam yang lalu',
      'avatar': 'assets/avatar1.png',
    },
    {
      'user': 'Inra',
      'title': 'KISAH Inra',
      'genre': 'Romance',
      'synopsis': 'Perjalanan cinta Inra yang penuh tantangan.',
      'fullStory': 'Kisah lengkap Inra...',
      'time': '3 jam yang lalu',
      'avatar': 'assets/avatar2.png',
    },
    {
      'user': 'This is Loli',
      'title': 'KISAH Ridho',
      'genre': 'Misteri',
      'synopsis': 'Kisah misterius tentang Ridho.',
      'fullStory': 'Kisah lengkap Ridho...',
      'time': '5 jam yang lalu',
      'avatar': 'assets/avatar3.png',
    },
  ];

  List<Map<String, String>> filteredPosts = [];

  @override
  void initState() {
    super.initState();
    filteredPosts = posts;
    _searchController.addListener(_searchPosts);
  }

  void _searchPosts() {
    String query = _searchController.text.toLowerCase();

    setState(() {
      if (selectedFilterIndex == 0) {
        // Search by Title
        filteredPosts =
            posts.where((post) {
              return post['title']!.toLowerCase().contains(query);
            }).toList();
      } else if (selectedFilterIndex == 1) {
        // Search by Author
        filteredPosts =
            posts.where((post) {
              return post['user']!.toLowerCase().contains(query);
            }).toList();
      } else {
        // Filter by Genre
        if (selectedGenres.isEmpty) {
          filteredPosts = posts;
        } else {
          filteredPosts =
              posts.where((post) {
                return selectedGenres.contains(post['genre']);
              }).toList();
        }
      }
    });
  }

  void _toggleGenreSelection(String genre) {
    setState(() {
      if (selectedGenres.contains(genre)) {
        selectedGenres.remove(genre);
      } else {
        selectedGenres.add(genre);
      }
      _searchPosts();
    });
  }

  @override
  void dispose() {
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
                hintText: 'Cari cerita...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
    ? IconButton(
        icon: const Icon(Icons.close),
        onPressed: () {
          _searchController.clear();
          _searchPosts(); // Optional: langsung update hasil
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
                      setState(() {
                        selectedFilterIndex = index;
                        if (index != 2) {
                          selectedGenres.clear();
                        }
                        _searchPosts();
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color:
                            isSelected ? Colors.blueAccent : Colors.grey[200],
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
          const SizedBox(height: 20), // Tambahkan jarak antar filter dan genre
          if (selectedFilterIndex == 2)
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children:
                    genres.map((genre) {
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
                              color:
                                  isSelected
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
            child:
                filteredPosts.isEmpty
                    ? const Center(
                      child: Text(
                        'Cerita tidak ditemukan.',
                        style: TextStyle(fontSize: 16),
                      ),
                    )
                    : ListView.builder(
                      itemCount: filteredPosts.length,
                      itemBuilder: (context, index) {
                        final post = filteredPosts[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundImage: AssetImage(post['avatar']!),
                            ),
                            title: Text(post['title']!),
                            subtitle: Text('Genre: ${post['genre']}'),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (_) => FullStoryPage(
                                        title: post['title']!,
                                        genre: post['genre']!,
                                        synopsis: post['synopsis']!,
                                        fullStory: post['fullStory']!,
                                        user: post['user']!,
                                        avatar: post['avatar']!,
                                      ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }
}
