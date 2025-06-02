import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/auth_service.dart';

class EditCeritaPage extends StatefulWidget {
  final Map<String, dynamic> story; // Changed to dynamic to handle all data types
  final Function(Map<String, dynamic>) onSave;

  const EditCeritaPage({super.key, required this.story, required this.onSave});

  @override
  State<EditCeritaPage> createState() => _EditCeritaPageState();
}

class _EditCeritaPageState extends State<EditCeritaPage> {
  late TextEditingController _judulController;
  late TextEditingController _sinopsisController;
  late TextEditingController _ceritaController;
  final AuthService _authService = AuthService();
  
  bool _isLoading = false;
  
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
    _judulController = TextEditingController(text: widget.story['title']?.toString() ?? '');
    _sinopsisController = TextEditingController(text: widget.story['sinopsis']?.toString() ?? '');
    _ceritaController = TextEditingController(text: widget.story['fullStory']?.toString() ?? '');
    
    // Parse genres from string to list
    String genresString = widget.story['genres']?.toString() ?? '';
    if (genresString.isNotEmpty) {
      selectedGenres = genresString.split(', ').where((genre) => genre.isNotEmpty).toList();
    }
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

  Future<void> _saveEditedStory() async {
    // Validate required fields
    if (_judulController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Judul tidak boleh kosong'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_sinopsisController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sinopsis tidak boleh kosong'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final token = await _authService.getToken();
      
      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Token tidak ditemukan. Silakan login kembali.'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final kisahId = widget.story['id'];
      
      // Prepare request body
      final requestBody = {
        'judul': _judulController.text.trim(),
        'sinopsis': _sinopsisController.text.trim(),
        'isi': _ceritaController.text.trim(),
        'genres': selectedGenres,
      };

      print('DEBUG: Updating kisah with ID: $kisahId');
      print('DEBUG: Request body: $requestBody');

      final response = await http.patch(
        Uri.parse('http://127.0.0.1:8000/api/kisah/update/$kisahId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: json.encode(requestBody),
      );

      print('DEBUG: Update response status: ${response.statusCode}');
      print('DEBUG: Update response body: ${response.body}');

      if (response.statusCode == 200) {
        // Successfully updated on server
        final responseData = json.decode(response.body);
        
        // Prepare updated story data for callback
        final editedStory = {
          'id': kisahId,
          'title': _judulController.text.trim(),
          'sinopsis': _sinopsisController.text.trim(),
          'fullStory': _ceritaController.text.trim(),
          'genres': selectedGenres.join(', '),
          'time': widget.story['time'] ?? 'Baru saja',
          'created_at': widget.story['created_at'], // Keep original timestamp
        };

        // Call the callback function to update parent widget
        widget.onSave(editedStory);
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kisah berhasil diperbarui'),
            backgroundColor: Colors.green,
          ),
        );
        
        Navigator.pop(context, editedStory); // Return the updated story
      } else {
        // Handle error response
        final responseData = json.decode(response.body);
        String errorMessage = 'Gagal memperbarui kisah';
        
        if (responseData is Map && responseData.containsKey('message')) {
          errorMessage = responseData['message'];
        } else if (responseData is Map && responseData.containsKey('errors')) {
          // Handle validation errors
          final errors = responseData['errors'] as Map;
          errorMessage = errors.values.first[0]; // Get first error message
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('DEBUG: Update error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Cerita'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Judul Field
                const Text(
                  'Judul Cerita *',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _judulController,
                  decoration: const InputDecoration(
                    hintText: 'Masukkan judul cerita',
                    border: OutlineInputBorder(),
                  ),
                  enabled: !_isLoading,
                ),
                const SizedBox(height: 16),
                
                // Genres Selection
                const Text(
                  'Genre',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: genres.map((genre) {
                    final isSelected = selectedGenres.contains(genre);
                    return ChoiceChip(
                      label: Text(genre),
                      selected: isSelected,
                      selectedColor: Colors.blue.shade100,
                      onSelected: _isLoading ? null : (_) => toggleGenre(genre),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                
                // Sinopsis Field
                const Text(
                  'Sinopsis *',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _sinopsisController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    hintText: 'Tulis sinopsis cerita...',
                    border: OutlineInputBorder(),
                  ),
                  enabled: !_isLoading,
                ),
                const SizedBox(height: 16),
                
                // Cerita Field
                const Text(
                  'Cerita Lengkap',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _ceritaController,
                  maxLines: 10,
                  decoration: const InputDecoration(
                    hintText: 'Tulis cerita lengkap...',
                    border: OutlineInputBorder(),
                  ),
                  enabled: !_isLoading,
                ),
                const SizedBox(height: 24),
                
                // Save Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveEditedStory,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'Simpan Perubahan',
                            style: TextStyle(fontSize: 16),
                          ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Required fields note
                const Text(
                  '* Field wajib diisi',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
          
          // Loading overlay
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}