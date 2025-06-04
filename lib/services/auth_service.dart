// lib/services/auth_service.dart - Update Base URL
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class AuthService {
  // Menggunakan URL yang sama dengan ApiService
  static const String _baseUrl = 'https://api.tascaid.space/api';

  // ========================================
  // CORE AUTHENTICATION METHODS
  // ========================================

  // Login User
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

  // Register User
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

  // Logout User
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

  // Validate Token
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

  // ========================================
  // RESET PASSWORD METHODS
  // ========================================

  // 1. Send Reset Password OTP
  Future<Map<String, dynamic>> sendResetPasswordOTP({
    required String email,
  }) async {
    final uri = Uri.parse('$_baseUrl/user/send-reset-otp');
    print('[AuthService] Sending reset OTP to: $uri with email: $email');
    
    try {
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode({
          'email': email,
        }),
      ).timeout(const Duration(seconds: 15));

      final responseBody = jsonDecode(response.body);
      print('[AuthService] Response: ${response.statusCode} Body: $responseBody');
      
      if (response.statusCode == 200) {
        return responseBody;
      } else {
        throw Exception(responseBody['message'] ?? 'Gagal mengirim kode OTP (${response.statusCode})');
      }
    } catch (e) {
      print('[AuthService] Send reset OTP error: $e');
      if (e is Exception && (e.toString().contains('Failed') || e.toString().contains('Gagal'))) {
        rethrow;
      }
      throw Exception('Tidak dapat terhubung ke server atau terjadi kesalahan jaringan.');
    }
  }

  // 2. Verify Reset Password OTP
  Future<Map<String, dynamic>> verifyResetPasswordOTP({
    required String email,
    required String otp,
  }) async {
    final uri = Uri.parse('$_baseUrl/user/verify-reset-otp');
    print('[AuthService] Verifying reset OTP: $uri with email: $email, otp: $otp');
    
    try {
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode({
          'email': email,
          'otp': otp,
        }),
      ).timeout(const Duration(seconds: 15));

      final responseBody = jsonDecode(response.body);
      print('[AuthService] Response: ${response.statusCode} Body: $responseBody');
      
      if (response.statusCode == 200) {
        // Response akan berisi token untuk reset password
        if (responseBody['token'] != null) {
          return responseBody;
        } else {
          throw Exception('Token tidak diterima dari server.');
        }
      } else {
        throw Exception(responseBody['message'] ?? 'Gagal memverifikasi kode OTP (${response.statusCode})');
      }
    } catch (e) {
      print('[AuthService] Verify reset OTP error: $e');
      if (e is Exception && (e.toString().contains('Failed') || e.toString().contains('Gagal') || e.toString().contains('Token tidak diterima'))) {
        rethrow;
      }
      throw Exception('Tidak dapat terhubung ke server atau terjadi kesalahan jaringan.');
    }
  }

  // 3. Reset Password with Token
  Future<Map<String, dynamic>> resetPasswordWithOTP({
    required String email,
    required String token,
    required String newPassword,
  }) async {
    final uri = Uri.parse('$_baseUrl/user/reset-password');
    print('[AuthService] Resetting password: $uri with email: $email');
    
    try {
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode({
          'email': email,
          'token': token,
          'newPassword': newPassword,
        }),
      ).timeout(const Duration(seconds: 15));

      final responseBody = jsonDecode(response.body);
      print('[AuthService] Response: ${response.statusCode} Body: $responseBody');
      
      if (response.statusCode == 200) {
        return responseBody;
      } else {
        throw Exception(responseBody['message'] ?? 'Gagal mereset password (${response.statusCode})');
      }
    } catch (e) {
      print('[AuthService] Reset password error: $e');
      if (e is Exception && (e.toString().contains('Failed') || e.toString().contains('Gagal'))) {
        rethrow;
      }
      throw Exception('Tidak dapat terhubung ke server atau terjadi kesalahan jaringan.');
    }
  }
}