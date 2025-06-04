import 'package:flutter/material.dart';
import 'package:komik_in/services/auth_service.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController codeController = TextEditingController();
  final TextEditingController newPasswordController = TextEditingController();
  final AuthService _authService = AuthService();
  
  bool isCodeSent = false;
  bool _obscurePassword = true;
  bool isLoading = false;
  String? resetToken; // Token untuk reset password
  String? errorMessage;

  @override
  void dispose() {
    emailController.dispose();
    codeController.dispose();
    newPasswordController.dispose();
    super.dispose();
  }

  Future<void> sendResetCode() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      print('[ChangePasswordScreen] Sending OTP to: ${emailController.text.trim()}');
      
      final result = await _authService.sendResetPasswordOTP(
        email: emailController.text.trim(),
      );
      
      print('[ChangePasswordScreen] Send OTP result: $result');
      
      setState(() {
        isCodeSent = true;
        isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']?.toString() ?? 'Kode OTP telah dikirim ke email Anda'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      print('[ChangePasswordScreen] Send OTP error: $e');
      setState(() {
        isLoading = false;
        errorMessage = _extractErrorMessage(e);
      });
    }
  }

  Future<void> verifyCodeAndReset() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      print('[ChangePasswordScreen] Step 1: Verifying OTP...');
      
      // Step 1: Verify OTP and get token
      final verifyResult = await _authService.verifyResetPasswordOTP(
        email: emailController.text.trim(),
        otp: codeController.text.trim(),
      );
      
      print('[ChangePasswordScreen] Verify result: $verifyResult');
      
      // Extract token safely
      if (verifyResult['token'] != null) {
        resetToken = verifyResult['token'].toString();
      } else {
        throw Exception('Token tidak diterima dari server');
      }
      
      print('[ChangePasswordScreen] Step 2: Resetting password with token: $resetToken');
      
      // Step 2: Reset password with token
      final resetResult = await _authService.resetPasswordWithOTP(
        email: emailController.text.trim(),
        token: resetToken!,
        newPassword: newPasswordController.text,
      );
      
      print('[ChangePasswordScreen] Reset result: $resetResult');
      
      setState(() {
        isLoading = false;
      });

      if (mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(resetResult['message']?.toString() ?? 'Password berhasil direset!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
        
        // Wait a moment then navigate to login
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            Navigator.pushNamedAndRemoveUntil(
              context, 
              '/login', 
              (route) => false, // Remove all previous routes
            );
          }
        });
      }
    } catch (e) {
      print('[ChangePasswordScreen] Reset password error: $e');
      setState(() {
        isLoading = false;
        errorMessage = _extractErrorMessage(e);
      });
    }
  }

  // Helper method to extract clean error message
  String _extractErrorMessage(dynamic error) {
    String errorStr = error.toString();
    
    // Remove "Exception: " prefix
    if (errorStr.startsWith('Exception: ')) {
      errorStr = errorStr.substring(11);
    }
    
    // Handle common network errors
    if (errorStr.contains('SocketException') || errorStr.contains('TimeoutException')) {
      return 'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.';
    }
    
    if (errorStr.contains('FormatException') || errorStr.contains('not a subtype')) {
      return 'Terjadi kesalahan dalam memproses data. Silakan coba lagi.';
    }
    
    return errorStr;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email tidak boleh kosong';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Format email tidak valid';
    }
    return null;
  }

  String? _validateCode(String? value) {
    if (value == null || value.isEmpty) {
      return 'Kode OTP tidak boleh kosong';
    }
    if (value.length < 6) {
      return 'Kode OTP harus 6 digit';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password tidak boleh kosong';
    }
    if (value.length < 6) {
      return 'Password minimal 6 karakter';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Gelombang atas
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Image.asset(
              'assets/images/gelombang1.png',
              fit: BoxFit.cover,
            ),
          ),
          // Gelombang bawah
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Image.asset(
              'assets/images/gelombang2.png',
              fit: BoxFit.cover,
            ),
          ),
          // Konten
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.blue.shade100,
                        borderRadius: BorderRadius.circular(40),
                      ),
                      child: Icon(
                        Icons.menu_book,
                        size: 40,
                        color: Colors.blue.shade600,
                      ),
                    ),
                    const SizedBox(height: 16),

                    const Text(
                      'Reset Password',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),

                    Text(
                      isCodeSent 
                          ? 'Enter the code and new password'
                          : 'Enter your email to receive reset code',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Error message
                    if (errorMessage != null)
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.error_outline, color: Colors.red.shade600, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                errorMessage!,
                                style: TextStyle(color: Colors.red.shade600, fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Email field
                    TextFormField(
                      controller: emailController,
                      enabled: !isCodeSent && !isLoading,
                      keyboardType: TextInputType.emailAddress,
                      validator: _validateEmail,
                      decoration: InputDecoration(
                        hintText: 'Email',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        prefixIcon: const Icon(Icons.email_outlined),
                      ),
                    ),
                    const SizedBox(height: 20),

                    if (isCodeSent) ...[
                      // OTP Code field
                      TextFormField(
                        controller: codeController,
                        enabled: !isLoading,
                        keyboardType: TextInputType.number,
                        validator: _validateCode,
                        decoration: InputDecoration(
                          hintText: 'Kode OTP (6 digit)',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          prefixIcon: const Icon(Icons.sms_outlined),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // New Password field
                      TextFormField(
                        controller: newPasswordController,
                        enabled: !isLoading,
                        obscureText: _obscurePassword,
                        validator: _validatePassword,
                        decoration: InputDecoration(
                          hintText: 'Password Baru',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Reset Password button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : verifyCodeAndReset,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'Reset Password',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                    ] else ...[
                      // Send Code button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : sendResetCode,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'Kirim Kode Verifikasi',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 20),

                    // Back to login link
                    Wrap(
                      alignment: WrapAlignment.center,
                      children: [
                        const Text("Remember your password? "),
                        GestureDetector(
                          onTap: isLoading ? null : () {
                            Navigator.pushReplacementNamed(context, '/login');
                          },
                          child: Text(
                            'Sign in!',
                            style: TextStyle(
                              color: isLoading ? Colors.grey : Colors.blue,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
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
    );
  }
}