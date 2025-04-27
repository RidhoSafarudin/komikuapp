import 'package:flutter/material.dart';

class TulisanPage extends StatefulWidget {
  const TulisanPage({super.key});

  @override
  State<TulisanPage> createState() => _TulisanPageState();
}

class _TulisanPageState extends State<TulisanPage>
    with SingleTickerProviderStateMixin {
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
          _buildListView(isTerbaru: true), // Terbaru
          _buildListView(isTerbaru: false), // Terlama
          _buildFormTulisBaru(), // Tulis Baru
        ],
      ),
    );
  }

  Widget _buildListView({required bool isTerbaru}) {
    List<Map<String, String>> stories = [
      {'title': 'KISAH Saya', 'time': '20 menit yang lalu'},
      {'title': 'KISAH Adit Saya', 'time': '30 menit yang lalu'},
      {'title': 'KISAH Jeky', 'time': '1 jam yang lalu'},
    ];

    if (!isTerbaru) {
      stories = List.from(stories.reversed);
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search',
              prefixIcon: Icon(Icons.search),
              suffixIcon: IconButton(icon: Icon(Icons.close), onPressed: () {}),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: stories.length,
            itemBuilder: (context, index) {
              final story = stories[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            story['title']!,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            story['time']!,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: const [
                          Chip(label: Text('Genre')),
                          SizedBox(width: 5),
                          Chip(label: Text('Genre')),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Sinopsis:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const Text(
                        'Lorem ipsum dolor sit amet, consectetur adipiscing elit...',
                      ),
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
            children:
                genres.map((genre) {
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
              hintText: 'Tulis cerita...',
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
                // Dummy Logic
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
