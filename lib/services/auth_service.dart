import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class AuthService {
  static const String _baseUrl = 'http://127.0.0.1:8000/api';
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final http.Client _client = http.Client();

  Future<String?> getToken() async {
    return await _storage.read(key: 'auth_token');
  }

  Future<void> saveToken(String token) async {
    await _storage.write(key: 'auth_token', value: token);
  }

  Future<void> deleteToken() async {
    await _storage.delete(key: 'auth_token');
    await _storage.delete(key: 'user_id'); // Also delete user ID
  }

  // New methods for user ID
  Future<String?> getUserId() async {
    return await _storage.read(key: 'user_id');
  }

  Future<void> saveUserId(String userId) async {
    await _storage.write(key: 'user_id', value: userId);
  }

  Future<Map<String, dynamic>> login(
    String email,
    String password,
    String deviceName,
  ) async {
    try {
      final response = await _client.post(
        Uri.parse('$_baseUrl/sanctum/token'),
        headers: {'Accept': 'application/json'},
        body: {'email': email, 'password': password, 'device_name': deviceName},
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        final token = responseData['token'] ?? responseData['access_token'];
        await saveToken(token);
        
        // If the response includes user data, save the user ID
        if (responseData['user'] != null) {
          await saveUserId(responseData['user']['id'].toString());
        }
        
        return {'success': true, 'token': token, 'user': responseData['user']};
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Login failed',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  Future<Map<String, dynamic>> register(
    String name,
    String email,
    String password,
  ) async {
    try {
      final response = await _client.post(
        Uri.parse('$_baseUrl/register'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'name': name,
          'email': email,
          'password': password,
          'password_confirmation': password,
        }),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final token = responseData['access_token'];
        await saveToken(token);
        
        // If the response includes user data, save the user ID
        if (responseData['user'] != null) {
          await saveUserId(responseData['user']['id'].toString());
        }
        
        return {'success': true, 'token': token, 'user': responseData['user']};
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Registration failed',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  Future<void> logout() async {
    final token = await getToken();
    if (token != null) {
      try {
        await _client.post(
          Uri.parse('$_baseUrl/logout'),
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        );
      } catch (e) {
        print('Error during logout: $e');
      }
    }
    await deleteToken();
  }

  // New method to get current user data
  Future<Map<String, dynamic>> getCurrentUser() async {
    try {
      final token = await getToken();
      final userId = await getUserId();
      
      if (token == null) {
        return {'success': false, 'message': 'No token found'};
      }

      if (userId != null) {
        // Use stored user ID
        final response = await _client.get(
          Uri.parse('$_baseUrl/user/$userId'),
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        );

        if (response.statusCode == 200) {
          final userData = json.decode(response.body);
          return {'success': true, 'user': userData};
        }
      }

      // Fallback: try /api/me endpoint
      final response = await _client.get(
        Uri.parse('$_baseUrl/me'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final userData = json.decode(response.body);
        // Save user ID for future use
        await saveUserId(userData['id'].toString());
        return {'success': true, 'user': userData};
      }

      return {'success': false, 'message': 'Failed to get user data'};
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }
}