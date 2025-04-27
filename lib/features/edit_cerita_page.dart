import 'package:flutter/material.dart';

class EditCeritaPage extends StatefulWidget {
  final Map<String, String> story;
  final Function(Map<String, String>) onSave;

  const EditCeritaPage({
    super.key,
    required this.story,
    required this.onSave,
  });

  @override
  State<EditCeritaPage> createState() => _EditCeritaPageState();
}

class _EditCeritaPageState extends State<EditCeritaPage> {
  late TextEditingController _judulController;
  late TextEditingController _sinopsisController;
  late TextEditingController _ceritaController;
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
    _judulController = TextEditingController(text: widget.story['title']);
    _sinopsisController = TextEditingController(text: widget.story['sinopsis']);
    _ceritaController = TextEditingController(text: widget.story['fullStory']);
    selectedGenres = widget.story['genres']?.split(', ') ?? [];
  }

  @override
  void dispose() {
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

  void _saveEditedStory() {
    final editedStory = {
      'title': _judulController.text,
      'sinopsis': _sinopsisController.text,
      'fullStory': _ceritaController.text,
      'genres': selectedGenres.join(', '),
      'time': widget.story['time'] ?? 'Baru saja',
    };
    widget.onSave(editedStory);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Cerita'),
        backgroundColor: Colors.blueAccent,
      ),
      body: SingleChildScrollView(
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
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _ceritaController,
              maxLines: 10,
              decoration: const InputDecoration(
                hintText: 'Tulis cerita lengkap...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: _saveEditedStory,
                child: const Text('Simpan Perubahan'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
