import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import '../services/auth_service.dart'; // Import AuthService

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({Key? key}) : super(key: key);

  @override
  _EditProfilePageState createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  String nama = '';
  bool isEditingNama = false;
  TextEditingController _controller = TextEditingController();
  String? avatarUrl;
  String? avatarBase64;
  bool isUploadingAvatar = false;
  bool isUpdatingNama = false;
  bool isLoading = true;
  final AuthService _authService = AuthService();

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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Token tidak ditemukan. Silakan login kembali.')),
        );
        return;
      }

      final response = await http.get(
        Uri.parse('http://127.0.0.1:8000/api/me'),
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
          avatarUrl = userData['avatar_url'];
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
        
        final errorData = json.decode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memuat data user: ${errorData['message'] ?? 'Unknown error'}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
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
    setState(() {
      isUpdatingNama = true;
    });

    try {
      final token = await _authService.getToken();
      
      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Token tidak ditemukan. Silakan login kembali.')),
        );
        return;
      }

      final response = await http.post(
        Uri.parse('http://127.0.0.1:8000/api/user/update'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'name': _controller.text, // Changed from 'nama' to 'name' to match API
        }),
      );

      if (response.statusCode == 200) {
        setState(() {
          nama = _controller.text;
          isEditingNama = false;
          _controller.clear();
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Nama berhasil diupdate')),
        );

        // Kirim data balik ke ProfilePage
        Navigator.pop(context, {'nama': nama});
      } else {
        final errorData = json.decode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengupdate nama: ${errorData['message'] ?? 'Unknown error'}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
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
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          isUploadingAvatar = true;
        });

        final token = await _authService.getToken();
        
        if (token == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Token tidak ditemukan. Silakan login kembali.')),
          );
          return;
        }

        // Read file as bytes
        final bytes = await image.readAsBytes();
        final base64String = base64Encode(bytes);

        // Get file extension
        final extension = image.path.split('.').last.toLowerCase();
        final mimeType = _getMimeType(extension);

        // Upload to API
        final response = await http.post(
          Uri.parse('http://127.0.0.1:8000/api/user/uploadAvatar'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: json.encode({
            'avatar': 'data:$mimeType;base64,$base64String',
          }),
        );

        if (response.statusCode == 200) {
          final responseData = json.decode(response.body);
          
          setState(() {
            // Update both base64 and URL based on API response
            avatarBase64 = 'data:$mimeType;base64,$base64String';
            avatarUrl = responseData['avatar_url'] ?? avatarUrl; // Update if API returns new URL
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Avatar berhasil diupload')),
          );
        } else {
          final errorData = json.decode(response.body);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal mengupload avatar: ${errorData['message'] ?? 'Unknown error'}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        isUploadingAvatar = false;
      });
    }
  }

  String _getMimeType(String extension) {
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      default:
        return 'image/jpeg';
    }
  }

  Widget _buildAvatar() {
    // Priority: 1. Recently uploaded base64, 2. Avatar URL from server, 3. Default
    if (avatarBase64 != null && avatarBase64!.isNotEmpty) {
      try {
        // Extract base64 part from data URL
        final base64Data = avatarBase64!.split(',')[1];
        return CircleAvatar(
          radius: 40,
          backgroundImage: MemoryImage(base64Decode(base64Data)),
        );
      } catch (e) {
        // Fall back to server URL if base64 fails
      }
    }
    
    if (avatarUrl != null && avatarUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: 40,
        backgroundImage: NetworkImage(avatarUrl!),
        onBackgroundImageError: (_, __) {
          // If network image fails, we'll show default
        },
        child: null,
      );
    }
    
    // Default avatar with first letter of name
    return CircleAvatar(
      radius: 40,
      child: Text(
        nama.isNotEmpty ? nama[0].toUpperCase() : 'U',
        style: TextStyle(fontSize: 24, color: Colors.white),
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
      body: Column(
        children: [
          SizedBox(height: 20),
          Stack(
            children: [
              _buildAvatar(),
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
          SizedBox(height: 10),
          ElevatedButton(
            onPressed: isUploadingAvatar ? null : _pickAndUploadAvatar,
            child: Text(isUploadingAvatar ? 'Uploading...' : 'Ganti Avatar'),
          ),
          SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.person),
                  title: Text(nama.isNotEmpty ? nama : 'Nama tidak tersedia'),
                  trailing: IconButton(
                    icon: Icon(Icons.edit),
                    onPressed: () => _startEditing('nama'),
                  ),
                ),
              ],
            ),
          ),
          if (isEditingNama)
            Container(
              color: Colors.blue.shade100,
              padding: EdgeInsets.all(16),
              margin: EdgeInsets.only(top: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Ubah Nama'),
                  TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'Masukkan nama baru',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: _cancelEditing,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.close),
                            Text(' Batal'),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: isUpdatingNama ? null : _saveNamaChanges,
                        child: isUpdatingNama
                            ? SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Text('Simpan'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}