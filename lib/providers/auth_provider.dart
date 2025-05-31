// lib/providers/auth_provider.dart - Navigate ke main_screen
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';

enum AuthStatus { 
  uninitialized, 
  authenticated, 
  unauthenticated, 
  loading 
}

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  
  AuthStatus _status = AuthStatus.uninitialized;
  String? _token;
  String? _userEmail;
  String? _username;
  String? _userId;
  String? _errorMessage;

  // Getters
  AuthStatus get status => _status;
  String? get token => _token;
  String? get userEmail => _userEmail;
  String? get username => _username;
  String? get userId => _userId;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _status == AuthStatus.authenticated && _token != null;
  bool get isLoading => _status == AuthStatus.loading;

  // Auth status message for UI
  String get authStatusMessage {
    switch (_status) {
      case AuthStatus.uninitialized:
        return 'Initializing...';
      case AuthStatus.authenticated:
        return 'Logged in as ${_username ?? _userEmail ?? 'User'}';
      case AuthStatus.unauthenticated:
        return 'Not logged in';
      case AuthStatus.loading:
        return 'Processing...';
    }
  }

  // Initialize auth state dari storage
  Future<void> initializeAuth() async {
    try {
      print('[AuthProvider] Initializing authentication...');
      
      final prefs = await SharedPreferences.getInstance();
      final savedToken = prefs.getString('auth_token');
      final savedEmail = prefs.getString('user_email');
      final savedUsername = prefs.getString('username');
      final savedUserId = prefs.getString('user_id');

      if (savedToken != null && savedToken.isNotEmpty) {
        _token = savedToken;
        _userEmail = savedEmail;
        _username = savedUsername;
        _userId = savedUserId;
        _status = AuthStatus.authenticated;
        print('[AuthProvider] User restored from storage: $_userEmail');
      } else {
        _status = AuthStatus.unauthenticated;
        print('[AuthProvider] No saved session found');
      }
    } catch (e) {
      print('[AuthProvider] Error initializing auth: $e');
      _setError('Gagal memuat data autentikasi');
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  // Login function with detailed error handling
  Future<bool> login(String email, String password) async {
    try {
      _setLoading(true);
      _clearError();

      // Client-side validation
      final validationError = _validateLoginInput(email, password);
      if (validationError != null) {
        _setError(validationError);
        return false;
      }

      print('[AuthProvider] Attempting login for: $email');

      // API call
      final response = await _authService.loginUser(
        email: email,
        password: password,
      );

      // Process successful response (sesuai backend existing Anda)
      if (response['token'] != null && response['user'] != null) {
        _token = response['token'];
        _userEmail = response['user']['email'] ?? email;
        _username = response['user']['username'] ?? email.split('@')[0];
        _userId = response['user']['id']?.toString();

        // Simpan ke storage
        await _saveToStorage();

        _status = AuthStatus.authenticated;
        print('[AuthProvider] Login successful for: $_userEmail');
        notifyListeners();
        return true;
      } else {
        _setError('Server tidak mengirim data login yang valid');
        return false;
      }
    } catch (e) {
      print('[AuthProvider] Login error: $e');
      _handleLoginError(e, email);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Register function with detailed error handling
  Future<bool> register(String email, String password, {String? username}) async {
    try {
      _setLoading(true);
      _clearError();

      // Client-side validation
      final validationError = _validateRegisterInput(email, password, username);
      if (validationError != null) {
        _setError(validationError);
        return false;
      }

      print('[AuthProvider] Attempting registration for: $email');

      // API call
      final response = await _authService.registerUser(
        email: email,
        password: password,
        username: username,
      );

      // Process successful registration (sesuai backend existing Anda)
      if (response['message'] != null && 
          (response['message'].toString().contains('berhasil') || response['user'] != null)) {
        print('[AuthProvider] Registration successful, attempting auto-login...');
        
        // Auto-login after successful registration
        final loginSuccess = await login(email, password);
        if (loginSuccess) {
          return true;
        } else {
          _setError('Registrasi berhasil, namun auto-login gagal. Silakan login manual');
          return false;
        }
      } else {
        _setError('Registrasi gagal. Server tidak memberikan konfirmasi yang valid');
        return false;
      }
    } catch (e) {
      print('[AuthProvider] Register error: $e');
      _handleRegisterError(e, email, username);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Logout function
  Future<void> logout() async {
    try {
      _setLoading(true);
      
      if (_token != null) {
        print('[AuthProvider] Logging out user: $_userEmail');
        
        try {
          await _authService.logoutUser(_token!);
          print('[AuthProvider] Server logout successful');
        } catch (e) {
          print('[AuthProvider] Server logout failed, continuing local logout: $e');
        }
      }
    } catch (e) {
      print('[AuthProvider] Logout error: $e');
    }

    // Clear local data
    await _clearStorage();
    _clearUserData();
    _status = AuthStatus.unauthenticated;
    _clearError();
    
    print('[AuthProvider] User logged out successfully');
    notifyListeners();
  }

  // VALIDATION METHODS

  String? _validateLoginInput(String email, String password) {
    if (email.trim().isEmpty && password.isEmpty) {
      return 'Email dan password tidak boleh kosong';
    }
    
    if (email.trim().isEmpty) {
      return 'Email tidak boleh kosong';
    }
    
    if (password.isEmpty) {
      return 'Password tidak boleh kosong';
    }

    if (!_isValidEmail(email.trim())) {
      return 'Format email tidak valid. Contoh: user@example.com';
    }

    if (password.length < 6) {
      return 'Password minimal 6 karakter';
    }

    return null;
  }

  String? _validateRegisterInput(String email, String password, String? username) {
    if (email.trim().isEmpty && password.isEmpty) {
      return 'Email dan password wajib diisi';
    }
    
    if (email.trim().isEmpty) {
      return 'Email wajib diisi';
    }
    
    if (password.isEmpty) {
      return 'Password wajib diisi';
    }

    if (!_isValidEmail(email.trim())) {
      return 'Format email tidak valid. Gunakan format: nama@domain.com';
    }

    if (password.length < 6) {
      return 'Password minimal 6 karakter';
    }
    if (password.length > 50) {
      return 'Password maksimal 50 karakter';
    }

    if (username != null && username.trim().isNotEmpty) {
      if (username.trim().length < 3) {
        return 'Username minimal 3 karakter';
      }
      if (username.trim().length > 20) {
        return 'Username maksimal 20 karakter';
      }
      if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(username.trim())) {
        return 'Username hanya boleh mengandung huruf, angka, dan underscore (_)';
      }
    }

    return null;
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  // ERROR HANDLING METHODS - Sesuai backend existing Anda

  void _handleLoginError(dynamic error, String email) {
    String errorString = error.toString().toLowerCase();
    
    // Network related errors
    if (errorString.contains('timeoutexception') || errorString.contains('timeout')) {
      _setError('Koneksi timeout. Periksa koneksi internet Anda dan coba lagi');
      return;
    }
    
    if (errorString.contains('socketexception') || 
        errorString.contains('network') ||
        errorString.contains('tidak dapat terhubung')) {
      _setError('Tidak dapat terhubung ke server. Periksa koneksi internet Anda');
      return;
    }

    // Backend response errors (sesuai backend existing Anda)
    if (errorString.contains('email dan password dibutuhkan')) {
      _setError('Email dan password tidak boleh kosong');
      return;
    }

    if (errorString.contains('kombinasi email/password salah') || 
        errorString.contains('401') || 
        errorString.contains('unauthorized')) {
      _setError('Email atau password yang Anda masukkan salah. Periksa kembali kredensial Anda');
      return;
    }

    // Server related errors
    if (errorString.contains('500') || errorString.contains('kesalahan konfigurasi server')) {
      _setError('Server sedang mengalami gangguan. Coba lagi dalam beberapa menit');
      return;
    }

    // Generic error
    _setError('Login gagal. Periksa email dan password Anda, atau coba lagi nanti');
  }

  void _handleRegisterError(dynamic error, String email, String? username) {
    String errorString = error.toString().toLowerCase();
    
    // Network related errors
    if (errorString.contains('timeoutexception') || errorString.contains('timeout')) {
      _setError('Koneksi timeout. Periksa koneksi internet Anda dan coba lagi');
      return;
    }
    
    if (errorString.contains('socketexception') || 
        errorString.contains('network') ||
        errorString.contains('tidak dapat terhubung')) {
      _setError('Tidak dapat terhubung ke server. Periksa koneksi internet Anda');
      return;
    }

    // Backend response errors (sesuai backend existing Anda)
    if (errorString.contains('email dan password dibutuhkan')) {
      _setError('Email dan password tidak boleh kosong');
      return;
    }

    if (errorString.contains('password minimal 6 karakter')) {
      _setError('Password minimal 6 karakter');
      return;
    }

    if (errorString.contains('email sudah terdaftar') ||
        errorString.contains('409') ||
        errorString.contains('conflict')) {
      _setError('Email "$email" sudah terdaftar. Gunakan email lain atau login dengan akun yang ada');
      return;
    }

    if (errorString.contains('400') || errorString.contains('bad request')) {
      _setError('Data yang dikirim tidak valid. Periksa kembali isian Anda');
      return;
    }

    if (errorString.contains('gagal mendaftarkan pengguna')) {
      _setError('Gagal mendaftarkan pengguna. Coba lagi nanti');
      return;
    }

    // Server related errors
    if (errorString.contains('500')) {
      _setError('Server sedang mengalami gangguan. Coba lagi dalam beberapa menit');
      return;
    }

    // Generic error
    _setError('Registrasi gagal. Periksa data Anda dan coba lagi');
  }

  // Helper methods
  void _setLoading(bool loading) {
    _status = loading ? AuthStatus.loading : 
              (_token != null ? AuthStatus.authenticated : AuthStatus.unauthenticated);
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    _status = AuthStatus.unauthenticated;
    print('[AuthProvider] Error: $error');
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void _clearUserData() {
    _token = null;
    _userEmail = null;
    _username = null;
    _userId = null;
  }

  Future<void> _saveToStorage() async {
    final prefs = await SharedPreferences.getInstance();
    if (_token != null) await prefs.setString('auth_token', _token!);
    if (_userEmail != null) await prefs.setString('user_email', _userEmail!);
    if (_username != null) await prefs.setString('username', _username!);
    if (_userId != null) await prefs.setString('user_id', _userId!);
  }

  Future<void> _clearStorage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_email');
    await prefs.remove('username');
    await prefs.remove('user_id');
  }

  // Debug method
  void debugPrintAuthState() {
    print('[AuthProvider] === AUTH STATE ===');
    print('[AuthProvider] Status: $_status');
    print('[AuthProvider] Is Authenticated: $isAuthenticated');
    print('[AuthProvider] Email: $_userEmail');
    print('[AuthProvider] Username: $_username');
    print('[AuthProvider] Error: $_errorMessage');
    print('[AuthProvider] ==================');
  }
}