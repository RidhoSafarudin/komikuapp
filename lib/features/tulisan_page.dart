import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../services/auth_service.dart';
import 'dart:convert';
import 'dart:async'; // For TimeoutException

class TulisanPage extends StatefulWidget {
  const TulisanPage({super.key});

  @override
  State<TulisanPage> createState() => _TulisanPageState();
}

class _TulisanPageState extends State<TulisanPage> {
  final TextEditingController _judulController = TextEditingController();
  final TextEditingController _sinopsisController = TextEditingController();
  final TextEditingController _isiController = TextEditingController();
  bool _isLoading = false;
  final AuthService _authService = AuthService();

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

  Future<void> _publishStory() async {
    if (_judulController.text.isEmpty) {
      _showError('Judul tidak boleh kosong');
      return;
    }

    if (selectedGenres.isEmpty) {
      _showError('Pilih minimal satu genre');
      return;
    }

    if (_sinopsisController.text.isEmpty) {
      _showError('Sinopsis tidak boleh kosong');
      return;
    }

    if (_isiController.text.isEmpty) {
      _showError('Isi cerita tidak boleh kosong');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final token = await _authService.getToken();
      if (token == null) {
        _showError('Anda belum login');
        return;
      }

      const url = 'http://127.0.0.1:8000/api/kisah/create';
      var request = http.MultipartRequest('POST', Uri.parse(url));

      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Accept'] = 'application/json';

      request.fields['judul'] = _judulController.text;
      request.fields['sinopsis'] = _sinopsisController.text;
      request.fields['isi'] = _isiController.text;

      for (int i = 0; i < selectedGenres.length; i++) {
        request.fields['genres[$i]'] = selectedGenres[i];
      }

      var response = await request.send().timeout(const Duration(seconds: 30));
      var responseData = await response.stream.bytesToString();
      var jsonResponse = jsonDecode(responseData);

      if (response.statusCode == 200 || response.statusCode == 201) {
        _showSuccess(
          jsonResponse['message'] ?? 'Kisah berhasil dipublikasikan!',
        );
        _clearForm();
      } else {
        _showError(jsonResponse['message'] ?? 'Gagal mempublikasikan kisah');
      }
    } on TimeoutException {
      _showError('Waktu permintaan habis, coba lagi');
    } on http.ClientException catch (e) {
      _showError('Koneksi gagal: ${e.message}');
    } catch (e) {
      _showError('Terjadi kesalahan: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _clearForm() {
    _judulController.clear();
    _sinopsisController.clear();
    _isiController.clear();
    setState(() {
      selectedGenres = [];
    });
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  void dispose() {
    _judulController.dispose();
    _sinopsisController.dispose();
    _isiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tulis Kisah Baru'),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 1,
        foregroundColor: Colors.black,
        automaticallyImplyLeading: false,
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
          const Text('Pilih Genre:'),
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
              hintText: 'Tulis sinopsis kisah...',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.add),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _isiController,
            maxLines: 10,
            decoration: const InputDecoration(
              hintText: 'Tulis kisah lengkap...',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.add),
            ),
          ),
          const SizedBox(height: 20),
          Align(
            alignment: Alignment.centerRight,
            child:
                _isLoading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: _publishStory,
                      child: const Text('Publish'),
                    ),
          ),
        ],
      ),
    );
  }
}
