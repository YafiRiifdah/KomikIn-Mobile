// lib/pages/splash_screen.dart - Auto-login implementation
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _minimumSplashTimer;
  bool _isMinimumTimeElapsed = false;
  bool _isAuthCheckComplete = false;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Start minimum splash duration timer
    _minimumSplashTimer = Timer(const Duration(seconds: 2), () {
      _isMinimumTimeElapsed = true;
      _checkAndNavigate();
    });

    // Initialize authentication
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    try {
      print('[SplashScreen] Initializing authentication...');
      await authProvider.initializeAuth();
      print('[SplashScreen] Auth initialization complete');
    } catch (e) {
      print('[SplashScreen] Auth initialization error: $e');
    }
    
    _isAuthCheckComplete = true;
    _checkAndNavigate();
  }

  void _checkAndNavigate() {
    // Only navigate when both conditions are met:
    // 1. Minimum splash time has elapsed
    // 2. Auth check is complete
    if (!_isMinimumTimeElapsed || !_isAuthCheckComplete) {
      return;
    }

    if (!mounted) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    print('[SplashScreen] Auth status: ${authProvider.status}');
    print('[SplashScreen] Is authenticated: ${authProvider.isAuthenticated}');
    
    // Navigate based on authentication status
    if (authProvider.isAuthenticated) {
      print('[SplashScreen] User is authenticated, navigating to main screen');
      Navigator.of(context).pushReplacementNamed('/main');
    } else {
      print('[SplashScreen] User not authenticated, navigating to login');
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  @override
  void dispose() {
    _minimumSplashTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF5086F1),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo/App Name
                RichText(
                  text: TextSpan(
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 40,
                      fontWeight: FontWeight.w900,
                      shadows: [
                        Shadow(
                          offset: Offset(2, 2),
                          blurRadius: 4,
                          color: Colors.black26,
                        ),
                      ],
                    ),
                    children: const [
                      TextSpan(text: 'Komik', style: TextStyle(color: Colors.white)),
                      TextSpan(text: 'In!', style: TextStyle(color: Colors.orange)),
                    ],
                  ),
                ),
                
                const SizedBox(height: 40),
                
                // Loading indicator with status text
                Column(
                  children: [
                    const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      strokeWidth: 3,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      authProvider.authStatusMessage,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}