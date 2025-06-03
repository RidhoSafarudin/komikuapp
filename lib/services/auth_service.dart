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
    await _storage.delete(key: 'user_id');
  }

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
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'email': email,
          'password': password,
          'device_name': deviceName,
        }),
      ).timeout(const Duration(seconds: 10));

      print('Login Response Status: ${response.statusCode}');
      print('Login Response Body: ${response.body}');

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        final token = responseData['token'] ?? responseData['access_token'];
        await saveToken(token);
        
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
      print('Login Error: $e');
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  Future<Map<String, dynamic>> register(
    String name,
    String email,
    String password,
  ) async {
    try {
      // Prepare the request body
      final requestBody = {
        'name': name.trim(),
        'email': email.trim().toLowerCase(),
        'password': password,
        'password_confirmation': password,
      };

      print('Register Request Body: ${json.encode(requestBody)}');

      final response = await _client.post(
        Uri.parse('$_baseUrl/register'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'X-Requested-With': 'XMLHttpRequest', // Sometimes needed for Laravel
        },
        body: json.encode(requestBody),
      ).timeout(const Duration(seconds: 10));

      print('Register Response Status: ${response.statusCode}');
      print('Register Response Body: ${response.body}');

      // Handle different response formats
      Map<String, dynamic> responseData;
      try {
        responseData = json.decode(response.body);
      } catch (e) {
        print('Failed to decode JSON: $e');
        return {
          'success': false,
          'message': 'Invalid response format from server',
        };
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        final token = responseData['access_token'] ?? responseData['token'];
        
        if (token != null) {
          await saveToken(token);
          
          if (responseData['user'] != null) {
            await saveUserId(responseData['user']['id'].toString());
          }
          
          return {'success': true, 'token': token, 'user': responseData['user']};
        } else {
          return {
            'success': false,
            'message': 'Registration successful but no token received',
          };
        }
      } else if (response.statusCode == 422) {
        // Handle validation errors
        String errorMessage = 'Validation failed';
        
        if (responseData['message'] != null) {
          errorMessage = responseData['message'];
        } else if (responseData['errors'] != null) {
          // Extract validation error messages
          Map<String, dynamic> errors = responseData['errors'];
          List<String> errorMessages = [];
          
          errors.forEach((field, messages) {
            if (messages is List) {
              errorMessages.addAll(messages.cast<String>());
            } else if (messages is String) {
              errorMessages.add(messages);
            }
          });
          
          errorMessage = errorMessages.join(', ');
        }
        
        return {
          'success': false,
          'message': errorMessage,
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Registration failed',
        };
      }
    } catch (e) {
      print('Register Error: $e');
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
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

  Future<Map<String, dynamic>> getCurrentUser() async {
    try {
      final token = await getToken();
      final userId = await getUserId();
      
      if (token == null) {
        return {'success': false, 'message': 'No token found'};
      }

      if (userId != null) {
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

      final response = await _client.get(
        Uri.parse('$_baseUrl/me'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final userData = json.decode(response.body);
        await saveUserId(userData['id'].toString());
        return {'success': true, 'user': userData};
      }

      return {'success': false, 'message': 'Failed to get user data'};
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }
}