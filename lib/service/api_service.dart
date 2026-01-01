import 'dart:typed_data';
import 'dart:convert';
import 'dart:io' show File;

import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:apotek/model/obat.dart';
import 'package:apotek/model/user.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  final String _baseUrl = 'http://127.0.0.1:8000';

  // TOKEN MANAGEMENT
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
  }

  Future<void> _removeToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('role');
  }

  // ROLE MANAGEMENT
  Future<void> _saveRole(String role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('role', role);
  }

  Future<String> getCurrentUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    String? role = prefs.getString('role');
    
    // Jika role belum tersimpan, coba ambil dari profile
    if (role == null || role.isEmpty) {
      final profile = await getUserProfile();
      if (profile != null) {
        role = profile.role;
        await _saveRole(role);
      }
    }
    
    return role ?? 'user';
  }

  Future<bool> isAdmin() async {
    final role = await getCurrentUserRole();
    return role == 'admin';
  }

  Future<void> refreshUserRole() async {
    final profile = await getUserProfile();
    if (profile != null) {
      await _saveRole(profile.role);
    }
  }

  Future<List<Obat>> fetchData() async {
    final uri = Uri.parse('$_baseUrl/api/obat/');
    final token = await _getToken();
    if (token == null) return [];

    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> body = json.decode(response.body);
      final List list = body['data'] ?? [];
      return list.map((json) => Obat.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load items: ${response.statusCode}');
    }
  }

  /// Create a new Obat.
  /// Supports web by sending bytes and mobile by sending file from path.
  Future<bool> createObat({
    required String name,
    required String description,
    required int price,
    required int stock,
    XFile? image,
    Uint8List? imageBytes,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/api/obat/');
      final token = await _getToken();

      final request = http.MultipartRequest('POST', uri);
      request.headers.addAll({
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      });
      request.fields['name'] = name;
      request.fields['description'] = description;
      request.fields['price'] = price.toString();
      request.fields['stock'] = stock.toString();

      // Attach image: prefer bytes (web) else file (mobile)
      if (imageBytes != null) {
        final filename = image?.name ?? 'upload.jpg';
        // send bytes without explicit contentType (server will infer)
        request.files.add(
          http.MultipartFile.fromBytes('image', imageBytes, filename: filename),
        );
      } else if (image != null && !kIsWeb) {
        final file = File(image.path);
        final filename =
            image.name.isNotEmpty ? image.name : image.path.split('/').last;
        // send file from path without explicit contentType
        request.files.add(
          await http.MultipartFile.fromPath(
            'image',
            file.path,
            filename: filename,
          ),
        );
      }

      final streamed = await request.send();
      final resp = await http.Response.fromStream(streamed);

      return resp.statusCode == 201 || resp.statusCode == 200;
    } catch (e) {
      // print('Error creating Obat: $e');
      return false;
    }
  }

  Future<bool> deleteObat(int id) async {
    final uri = Uri.parse('$_baseUrl/api/obat/$id/');
    final token = await _getToken();

    final response = await http.delete(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    return response.statusCode == 204 || response.statusCode == 200;
  }

  Future<bool> updateObat({
    required int id,
    required String name,
    required String description,
    required int price,
    required int stock,
    XFile? image,
    Uint8List? imageBytes,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/api/obat/$id/');
      final token = await _getToken();
      // Gunakan POST dengan _method=PUT untuk support multipart di Laravel
      final request = http.MultipartRequest('POST', uri);

      request.headers.addAll({
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      });

      request.fields['_method'] = 'PUT';
      request.fields['name'] = name;
      request.fields['description'] = description;
      request.fields['price'] = price.toString();
      request.fields['stock'] = stock.toString();

      if (imageBytes != null) {
        final filename = image?.name ?? 'update.jpg';
        request.files.add(
          http.MultipartFile.fromBytes('image', imageBytes, filename: filename),
        );
      } else if (image != null && !kIsWeb) {
        final file = File(image.path);
        final filename =
            image.name.isNotEmpty ? image.name : image.path.split('/').last;
        request.files.add(
          await http.MultipartFile.fromPath(
            'image',
            file.path,
            filename: filename,
          ),
        );
      }

      final streamed = await request.send();
      final resp = await http.Response.fromStream(streamed);
      return resp.statusCode == 200;
    } catch (e) {
      print('Error updating Obat: $e');
      return false;
    }
  }

  // ---------------------------------------------------------------
  // USER LOGIN
  // ---------------------------------------------------------------
  Future<bool> registerUser(User user) async {
    final url = Uri.parse('$_baseUrl/api/register');
    try {
      final resp = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(user.toJson()),
      );

      if (resp.statusCode == 201 || resp.statusCode == 200) {
        final Map<String, dynamic> body = json.decode(resp.body);
        final token = body['data']['token'];
        if (token != null) {
          await _saveToken(token);
        }
        return true;
      } else {
        return false;
      }
    } catch (e) {
      print('Error registering user: $e');
      return false;
    }
  }

  Future<bool> loginUser(String email, String password) async {
    final url = Uri.parse('$_baseUrl/api/login');
    try {
      final resp = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (resp.statusCode == 200) {
        final Map<String, dynamic> body = json.decode(resp.body);
        print('Login response body: $body');
        final token = body['data']['token'];
        print('Received token: $token');
        if (token != null) {
          await _saveToken(token);
          
          // Coba ambil role dari response login
          final role = body['data']['role'];
          if (role != null && role.toString().isNotEmpty) {
            await _saveRole(role);
            print('Role from login: $role');
          } else {
            // Jika tidak ada role di response login, ambil dari profile
            await refreshUserRole();
            print('Role fetched from profile');
          }
        }
        return true;
      } else {
        return false;
      }
    } catch (e) {
      print('Error logging in user: $e');
      return false;
    }
  }

  Future<bool> logoutUser() async {
    final url = Uri.parse('$_baseUrl/api/logout');
    try {
      final token = await _getToken();
      if (token == null) return false;

      final resp = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (resp.statusCode == 200) {
        await _removeToken();
        return true;
      } else {
        return false;
      }
    } catch (e) {
      print('Error logging out user: $e');
      return false;
    }
  }

  // User Get Profile
  Future<UserProfile?> getUserProfile() async {
    final url = Uri.parse('$_baseUrl/api/profile');
    try {
      final token = await _getToken();
      if (token == null) return null;

      final resp = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (resp.statusCode == 200) {
        final Map<String, dynamic> body = json.decode(resp.body);
        print('User profile response body: $body');
        return UserProfile.fromJson(body['data']);
      } else {
        return null;
      }
    } catch (e) {
      print('Error fetching user profile: $e');
      return null;
    }
  }
}
