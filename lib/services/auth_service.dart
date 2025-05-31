// lib/services/auth_service.dart - Dedicated Auth Service
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class AuthService {
  // Copy getBaseUrl logic from ApiService
  static String getBaseUrl() {
    const String port = "8081";
    if (kIsWeb) {
      return 'http://localhost:$port/api';
    } else {
      try {
        if (Platform.isAndroid) {
          return 'http://10.0.2.2:$port/api';
        } else if (Platform.isIOS) {
          return 'http://localhost:$port/api';
        }
      } catch (e) {
        print("Platform check error: $e");
      }
      return 'https://api.tascaid.space/api';
    }
  }

  static final String _baseUrl = getBaseUrl();

  // Auth methods - same as ApiService but in dedicated class
  Future<Map<String, dynamic>> loginUser({
    required String email,
    required String password,
  }) async {
    final uri = Uri.parse('$_baseUrl/auth/login');
    print('[AuthService] Logging in to: $uri with email: $email');
    
    try {
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      ).timeout(const Duration(seconds: 15));

      final responseBody = jsonDecode(response.body);
      print('[AuthService] Response: ${response.statusCode} Body: $responseBody');
      
      if (response.statusCode == 200) {
        if (responseBody['token'] != null) {
          return responseBody;
        } else {
          throw Exception('Token tidak diterima dari server.');
        }
      } else {
        throw Exception(responseBody['message'] ?? 'Gagal melakukan login (${response.statusCode})');
      }
    } catch (e) {
      print('[AuthService] Login error: $e');
      if (e is Exception && (e.toString().contains('Failed') || e.toString().contains('Gagal') || e.toString().contains('Token tidak diterima'))) {
        rethrow;
      }
      throw Exception('Tidak dapat terhubung ke server atau terjadi kesalahan jaringan.');
    }
  }

  Future<Map<String, dynamic>> registerUser({
    required String email,
    required String password,
    String? username,
  }) async {
    final uri = Uri.parse('$_baseUrl/auth/register');
    print('[AuthService] Registering to: $uri with email: $email');
    
    try {
      final Map<String, String?> body = {
        'email': email,
        'password': password,
      };
      if (username != null && username.isNotEmpty) {
        body['username'] = username;
      }

      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 15));

      final responseBody = jsonDecode(response.body);
      print('[AuthService] Response: ${response.statusCode} Body: $responseBody');

      if (response.statusCode == 201) {
        return responseBody; 
      } else {
        throw Exception(responseBody['message'] ?? 'Gagal melakukan registrasi (${response.statusCode})');
      }
    } catch (e) {
      print('[AuthService] Register error: $e');
      if (e is Exception && (e.toString().contains('Failed') || e.toString().contains('Gagal'))) {
        rethrow;
      }
      throw Exception('Tidak dapat terhubung ke server atau terjadi kesalahan jaringan.');
    }
  }

  Future<Map<String, dynamic>> logoutUser(String token) async {
    final uri = Uri.parse('$_baseUrl/auth/logout');
    print('[AuthService] Logging out from: $uri');
    
    try {
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 15));

      final responseBody = jsonDecode(response.body);
      print('[AuthService] Response: ${response.statusCode} Body: $responseBody');

      if (response.statusCode == 200) {
        return responseBody;
      } else {
        throw Exception(responseBody['message'] ?? 'Gagal melakukan logout (${response.statusCode})');
      }
    } catch (e) {
      print('[AuthService] Logout error: $e');
      if (e is Exception && (e.toString().contains('Failed') || e.toString().contains('Gagal'))) {
        rethrow;
      }
      throw Exception('Tidak dapat terhubung ke server atau terjadi kesalahan jaringan.');
    }
  }

  // Optional: Method untuk validate token
  Future<Map<String, dynamic>> validateToken(String token) async {
    final uri = Uri.parse('$_baseUrl/auth/validate');
    
    try {
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      final responseBody = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return responseBody;
      } else {
        throw Exception('Token tidak valid');
      }
    } catch (e) {
      print('[AuthService] Token validation error: $e');
      throw Exception('Gagal memvalidasi token');
    }
  }
}