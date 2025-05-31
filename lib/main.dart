// lib/main.dart - Integrated dengan struktur existing Anda
import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Tambahkan ini
import 'package:komik_in/providers/auth_provider.dart'; // Tambahkan ini
import 'package:komik_in/pages/signup_screen.dart';
import 'pages/splash_screen.dart';
import 'pages/login_screen.dart';
import 'pages/main_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider( // Wrap dengan MultiProvider
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        // Tambahkan provider lainnya di sini jika ada
      ],
      child: MaterialApp(
        title: 'KomikIn',
        theme: ThemeData(
          fontFamily: 'Poppins',
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        debugShowCheckedModeBanner: false,
        initialRoute: '/', 
        routes: {
          '/': (context) => const SplashScreen(),
          '/login': (context) => const LoginScreen(),
          '/main': (context) => const AuthProtectedMainScreen(), // Wrap MainScreen dengan protection
          '/signup': (context) => const SignUpScreen(),
        },
      ),
    );
  }
}

// Auth-protected wrapper untuk MainScreen
class AuthProtectedMainScreen extends StatelessWidget {
  const AuthProtectedMainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        // Jika belum authenticated, redirect ke login
        if (!authProvider.isAuthenticated) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.pushReplacementNamed(context, '/login');
          });
          // Show loading sementara redirect
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        
        // Jika sudah authenticated, tampilkan MainScreen
        return const MainScreen();
      },
    );
  }
}