import 'package:flutter/material.dart';
import 'edit_cerita_page.dart'; // jangan lupa buat file ini

class TulisanPage extends StatefulWidget {
  const TulisanPage({super.key});

  @override
  State<TulisanPage> createState() => _TulisanPageState();
}

class _TulisanPageState extends State<TulisanPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final TextEditingController _judulController = TextEditingController();
  final TextEditingController _sinopsisController = TextEditingController();
  final TextEditingController _ceritaController = TextEditingController();

  List<String> genres = [
    'Romance',
    'Fantasi',
    'Horor',
    'Misteri',
    'Action',
    'Sejarah',
    'Fiksi Ilmiah',
    'Petualangan',
  ];

  List<String> selectedGenres = [];

  List<Map<String, String>> stories = [
    {
      'title': 'KISAH Saya',
      'time': '20 menit yang lalu',
      'sinopsis': 'Ini sinopsis pertama',
      'fullStory': 'Ini cerita lengkap pertama',
      'genres': 'Romance, Action'
    },
    {
      'title': 'KISAH Adik Saya',
      'time': '30 menit yang lalu',
      'sinopsis': 'Ini sinopsis kedua',
      'fullStory': 'Ini cerita lengkap kedua',
      'genres': 'Fantasi, Misteri'
    },
    {
      'title': 'KISAH Jeky',
      'time': '1 jam yang lalu',
      'sinopsis': 'Ini sinopsis ketiga',
      'fullStory': 'Ini cerita lengkap ketiga',
      'genres': 'Petualangan'
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _judulController.dispose();
    _sinopsisController.dispose();
    _ceritaController.dispose();
    super.dispose();
  }

  void toggleGenre(String genre) {
    setState(() {
      if (selectedGenres.contains(genre)) {
        selectedGenres.remove(genre);
      } else {
        selectedGenres.add(genre);
      }
    });
  }

  void _showDeleteConfirmation(BuildContext context, int index) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Konfirmasi Hapus'),
          content: const Text('Apakah Anda yakin ingin menghapus cerita ini?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('No'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  stories.removeAt(index);
                });
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              child: const Text('Yes'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.black,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: 'Terbaru'),
            Tab(text: 'Terlama'),
            Tab(text: 'Tulis Baru'),
          ],
        ),
        title: const Text('', style: TextStyle(color: Colors.black)),
        centerTitle: true,
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildListView(isTerbaru: true),
          _buildListView(isTerbaru: false),
          _buildFormTulisBaru(),
        ],
      ),
    );
  }

  Widget _buildListView({required bool isTerbaru}) {
    List<Map<String, String>> sortedStories = List.from(stories);
    if (!isTerbaru) {
      sortedStories = List.from(stories.reversed);
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(icon: const Icon(Icons.close), onPressed: () {}),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: sortedStories.length,
            itemBuilder: (context, index) {
              final story = sortedStories[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                                  story['title'] ?? '',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  story['time'] ?? '',
                                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                          PopupMenuButton<String>(
                            onSelected: (value) {
                              if (value == 'edit') {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => EditCeritaPage(
                                      story: story,
                                      onSave: (editedStory) {
                                        setState(() {
                                          stories[index] = editedStory;
                                        });
                                      },
                                    ),
                                  ),
                                );
                              } else if (value == 'hapus') {
                                _showDeleteConfirmation(context, index);
                              }
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'edit',
                                child: Text('Edit'),
                              ),
                              const PopupMenuItem(
                                value: 'hapus',
                                child: Text('Hapus'),
                              ),
                            ],
                            icon: const Icon(Icons.more_vert),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        children: (story['genres'] ?? '')
                            .split(', ')
                            .map((genre) => Chip(label: Text(genre)))
                            .toList(),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Sinopsis:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(story['sinopsis'] ?? 'Tidak ada sinopsis.'),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Icon(Icons.thumb_up_alt_outlined),
                          Icon(Icons.thumb_down_alt_outlined),
                          Icon(Icons.comment_outlined),
                          Icon(Icons.share),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFormTulisBaru() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _judulController,
            decoration: const InputDecoration(
              hintText: 'Judul',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: genres.map((genre) {
              final isSelected = selectedGenres.contains(genre);
              return ChoiceChip(
                label: Text(genre),
                selected: isSelected,
                selectedColor: Colors.blue.shade100,
                onSelected: (_) => toggleGenre(genre),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _sinopsisController,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Tulis sinopsis cerita...',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.add),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _ceritaController,
            maxLines: 10,
            decoration: const InputDecoration(
              hintText: 'Tulis cerita lengkap...',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.add),
            ),
          ),
          const SizedBox(height: 20),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade100,
              ),
              onPressed: () {
                // Dummy save
                print('Judul: ${_judulController.text}');
                print('Genres: $selectedGenres');
                print('Sinopsis: ${_sinopsisController.text}');
                print('Cerita: ${_ceritaController.text}');
              },
              child: const Text('Publish'),
            ),
          ),
        ],
      ),
    );
  }
}
