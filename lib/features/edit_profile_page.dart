import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import '../services/auth_service.dart';
import 'dart:html' as html; // Hanya untuk web
import 'package:flutter/foundation.dart' show kIsWeb;

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({Key? key}) : super(key: key);

  @override
  _EditProfilePageState createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  String nama = '';
  String email = '';
  bool isEditingNama = false;
  TextEditingController _controller = TextEditingController();
  String? avatarUrl;
  File? selectedAvatarFile;
  bool isUploadingAvatar = false;
  bool isUpdatingNama = false;
  bool isLoading = true;
  final AuthService _authService = AuthService();
  final String baseUrl = 'http://127.0.0.1:8000/api';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() {
      isLoading = true;
    });

    try {
      final token = await _authService.getToken();
      
      if (token == null) {
        setState(() {
          isLoading = false;
        });
        _showErrorSnackBar('Token tidak ditemukan. Silakan login kembali.');
        return;
      }

      final response = await http.get(
        Uri.parse('$baseUrl/me'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final userData = responseData['user'];
        
        setState(() {
          nama = userData['name'] ?? '';
          email = userData['email'] ?? '';
          // Perbaikan: Gunakan format URL yang sama seperti di profile.dart
          if (userData['avatar_url'] != null && userData['avatar_url'].toString().isNotEmpty) {
            avatarUrl = 'http://127.0.0.1:8000/avatar/${Uri.encodeComponent(userData['avatar_url'].toString().split('/').last)}';
          }
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
        
        final errorData = json.decode(response.body);
        _showErrorSnackBar('Gagal memuat data user: ${errorData['message'] ?? 'Unknown error'}');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      
      _showErrorSnackBar('Error: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _startEditing(String field) {
    setState(() {
      if (field == 'nama') {
        isEditingNama = true;
        _controller.text = nama;
      }
    });
  }

  Future<void> _saveNamaChanges() async {
    if (_controller.text.trim().isEmpty) {
      _showErrorSnackBar('Nama tidak boleh kosong');
      return;
    }

    setState(() {
      isUpdatingNama = true;
    });

    try {
      final token = await _authService.getToken();
      
      if (token == null) {
        _showErrorSnackBar('Token tidak ditemukan. Silakan login kembali.');
        return;
      }

      final response = await http.post(
        Uri.parse('$baseUrl/user/update'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'name': _controller.text.trim(),
          'email': email,
        }),
      );

      if (response.statusCode == 200) {
        setState(() {
          nama = _controller.text.trim();
          isEditingNama = false;
          _controller.clear();
        });

        _showSuccessSnackBar('Nama berhasil diupdate');
        Navigator.pop(context, {'nama': nama});
      } else {
        final errorData = json.decode(response.body);
        _showErrorSnackBar('Gagal mengupdate nama: ${errorData['message'] ?? 'Unknown error'}');
      }
    } catch (e) {
      _showErrorSnackBar('Error: $e');
    } finally {
      setState(() {
        isUpdatingNama = false;
      });
    }
  }

  void _cancelEditing() {
    setState(() {
      isEditingNama = false;
      _controller.clear();
    });
  }

  Future<void> _pickAndUploadAvatar() async {
  final ImagePicker picker = ImagePicker();
  
  try {
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1500,
      maxHeight: 1500,
      imageQuality: 85,
    );

    if (image != null) {
      setState(() {
        isUploadingAvatar = true;
        if (!kIsWeb) {
          selectedAvatarFile = File(image.path);
        }
      });

      final token = await _authService.getToken();
      
      if (token == null) {
        setState(() {
          isUploadingAvatar = false;
          selectedAvatarFile = null;
        });
        _showErrorSnackBar('Token tidak ditemukan. Silakan login kembali.');
        return;
      }

      var request = http.MultipartRequest(
        'POST', 
        Uri.parse('$baseUrl/user/uploadAvatar')
      );

      request.headers.addAll({
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      });

      if (kIsWeb) {
        // Handle untuk web
        final bytes = await image.readAsBytes();
        final blob = html.Blob([bytes]);
        request.files.add(
          http.MultipartFile.fromBytes(
            'avatar', 
            bytes,
            filename: image.name,
          )
        );
      } else {
        // Handle untuk mobile/desktop
        request.files.add(
          await http.MultipartFile.fromPath('avatar', image.path)
        );
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        
        String newAvatarUrl;
        if (responseData['url'] != null) {
          newAvatarUrl = 'http://127.0.0.1:8000/avatar/${Uri.encodeComponent(responseData['url'].toString().split('/').last)}';
        } else if (responseData['path'] != null) {
          newAvatarUrl = 'http://127.0.0.1:8000/avatar/${Uri.encodeComponent(responseData['path'].toString().split('/').last)}';
        } else {
          newAvatarUrl = '$baseUrl/user/getAvatar?token=$token&t=${DateTime.now().millisecondsSinceEpoch}';
        }

        setState(() {
          avatarUrl = newAvatarUrl;
          selectedAvatarFile = null;
        });

        _showSuccessSnackBar('Avatar berhasil diupload');
        
        Navigator.pop(context, {
          'nama': nama,
          'avatarUrl': avatarUrl,
        });
        
      } else {
        final errorData = json.decode(response.body);
        _showErrorSnackBar('Gagal mengupload avatar: ${errorData['message'] ?? 'Unknown error'}');
        
        setState(() {
          selectedAvatarFile = null;
        });
      }
    }
  } catch (e) {
    _showErrorSnackBar('Error saat upload avatar: $e');
    setState(() {
      selectedAvatarFile = null;
    });
  } finally {
    setState(() {
      isUploadingAvatar = false;
    });
  }
}

  Widget _buildAvatar() {
  return Container(
    width: 80,
    height: 80,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: Colors.grey[300],
    ),
    child: Stack(
      children: [
        if (selectedAvatarFile != null && !kIsWeb)
          ClipOval(
            child: Image.file(
              selectedAvatarFile!,
              width: 80,
              height: 80,
              fit: BoxFit.cover,
            ),
          )
        else if (avatarUrl != null && avatarUrl!.isNotEmpty)
          ClipOval(
            child: Image.network(
              avatarUrl!,
              width: 80,
              height: 80,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      nama.isNotEmpty ? nama[0].toUpperCase() : 'U',
                      style: const TextStyle(
                        fontSize: 24,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              },
            ),
          )
        else
          Center(
            child: Text(
              nama.isNotEmpty ? nama[0].toUpperCase() : 'U',
              style: const TextStyle(
                fontSize: 24,
                color: Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        if (isUploadingAvatar)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              ),
            ),
          ),
      ],
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Edit Profile'),
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Profile'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(height: 20),
            
            // Avatar Section
            Center(
              child: _buildAvatar(),
            ),
            
            SizedBox(height: 10),
            
            // Upload Avatar Button
            ElevatedButton(
              onPressed: isUploadingAvatar ? null : _pickAndUploadAvatar,
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: Text(isUploadingAvatar ? 'Uploading...' : 'Upload Avatar'),
            ),
            
            SizedBox(height: 30),
            
            // Profile Information
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: Icon(Icons.person, color: Colors.blue),
                      title: Text(
                        'Nama',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      subtitle: Text(nama.isNotEmpty ? nama : 'Nama tidak tersedia'),
                      trailing: IconButton(
                        icon: Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _startEditing('nama'),
                      ),
                    ),
                    ListTile(
                      leading: Icon(Icons.email, color: Colors.blue),
                      title: Text(
                        'Email',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      subtitle: Text(email.isNotEmpty ? email : 'Email tidak tersedia'),
                    ),
                  ],
                ),
              ),
            ),
            
            // Edit Name Section
            if (isEditingNama)
              Container(
                margin: EdgeInsets.all(16),
                child: Card(
                  color: Colors.blue.shade50,
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ubah Nama',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 12),
                        TextField(
                          controller: _controller,
                          decoration: InputDecoration(
                            hintText: 'Masukkan nama baru',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                        ),
                        SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            TextButton(
                              onPressed: _cancelEditing,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.close, size: 20),
                                  SizedBox(width: 4),
                                  Text('Batal'),
                                ],
                              ),
                            ),
                            ElevatedButton(
                              onPressed: isUpdatingNama ? null : _saveNamaChanges,
                              child: isUpdatingNama
                                  ? SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Text('Simpan'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}