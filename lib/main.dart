// lib/main.dart - Fixed dengan auth status handling yang lebih robust
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:komik_in/providers/auth_provider.dart';
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
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
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
          '/main': (context) => const AuthProtectedMainScreen(),
          '/signup': (context) => const SignUpScreen(),
        },
      ),
    );
  }
}

// FIXED: Auth-protected wrapper untuk MainScreen dengan debugging
class AuthProtectedMainScreen extends StatefulWidget {
  const AuthProtectedMainScreen({super.key});

  @override
  State<AuthProtectedMainScreen> createState() => _AuthProtectedMainScreenState();
}

class _AuthProtectedMainScreenState extends State<AuthProtectedMainScreen> {
  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        
        // DEBUGGING: Print auth status
        print('[AuthProtectedMainScreen] Auth Status: ${authProvider.status}');
        print('[AuthProtectedMainScreen] Is Authenticated: ${authProvider.isAuthenticated}');
        print('[AuthProtectedMainScreen] Token exists: ${authProvider.token != null}');
        print('[AuthProtectedMainScreen] Error message: ${authProvider.errorMessage}');

        // Jika sedang loading, tampilkan loading
        if (authProvider.isLoading) {
          print('[AuthProtectedMainScreen] Showing loading state');
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // HANYA redirect ke login jika BENAR-BENAR tidak authenticated
        // DAN bukan sedang loading
        if (!authProvider.isAuthenticated && 
            authProvider.status == AuthStatus.unauthenticated &&
            !authProvider.isLoading) {
          
          print('[AuthProtectedMainScreen] Redirecting to login - User not authenticated');
          
          // Gunakan addPostFrameCallback untuk menghindari rebuild during build
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              Navigator.pushReplacementNamed(context, '/login');
            }
          });
          
          // Show loading sementara redirect
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Redirecting to login...'),
                ],
              ),
            ),
          );
        }
        
        // Jika sudah authenticated, tampilkan MainScreen
        print('[AuthProtectedMainScreen] Showing MainScreen - User authenticated');
        return const MainScreen();
      },
    );
  }
}