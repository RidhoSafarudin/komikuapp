import 'package:flutter/material.dart';

class TulisanPage extends StatefulWidget {
  const TulisanPage({super.key});

  @override
  State<TulisanPage> createState() => _TulisanPageState();
}

class _TulisanPageState extends State<TulisanPage> {
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
  void dispose() {
    _judulController.dispose();
    _sinopsisController.dispose();
    _ceritaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
  title: const Text('Tulis Cerita Baru'),
  centerTitle: true,
  backgroundColor: Colors.white,
  elevation: 1,
  foregroundColor: Colors.black,
  automaticallyImplyLeading: false, // Tambahkan ini
),

      body: _buildFormTulisBaru(),
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
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white
              ),
              onPressed: () {
                // Simpan cerita baru (dummy)
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
