// lib/widgets/auth_wrapper.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:komik_in/providers/auth_provider.dart';
import 'package:komik_in/pages/login_screen.dart';

class AuthWrapper extends StatelessWidget {
  final Widget child;
  final bool requireAuth;

  const AuthWrapper({
    super.key,
    required this.child,
    this.requireAuth = false,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        // Show splash screen saat initialize
        if (authProvider.status == AuthStatus.uninitialized) {
          return const SplashScreen();
        }

        // Jika butuh auth tapi user belum login
        if (requireAuth && !authProvider.isAuthenticated) {
          return const LoginScreen();
        }

        // Jika tidak butuh auth atau user sudah login
        return child;
      },
    );
  }
}

// Splash Screen
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo atau icon app
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.blue.shade100,
                borderRadius: BorderRadius.circular(60),
              ),
              child: Icon(
                Icons.menu_book,
                size: 60,
                color: Colors.blue.shade600,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Komik In',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade600,
              ),
            ),
            const SizedBox(height: 16),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}

// Auth Guard untuk melindungi halaman tertentu
class AuthGuard extends StatelessWidget {
  final Widget child;
  final String? redirectTo;

  const AuthGuard({
    super.key,
    required this.child,
    this.redirectTo,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        if (authProvider.status == AuthStatus.uninitialized) {
          return const SplashScreen();
        }

        if (!authProvider.isAuthenticated) {
          // Redirect ke login atau halaman yang ditentukan
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.pushReplacementNamed(
              context, 
              redirectTo ?? '/login',
            );
          });
          return const SplashScreen();
        }

        return child;
      },
    );
  }
}

// Widget untuk menampilkan info user yang sedang login
class UserInfoWidget extends StatelessWidget {
  const UserInfoWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        if (!authProvider.isAuthenticated) {
          return const SizedBox.shrink();
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.blue.shade100,
                child: Text(
                  authProvider.username?.substring(0, 1).toUpperCase() ?? 
                  authProvider.userEmail?.substring(0, 1).toUpperCase() ?? 
                  'U',
                  style: TextStyle(
                    color: Colors.blue.shade600,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      authProvider.username ?? 'User',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      authProvider.userEmail ?? '',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// Logout Button Widget
class LogoutButton extends StatelessWidget {
  final VoidCallback? onLogoutSuccess;

  const LogoutButton({super.key, this.onLogoutSuccess});

  Future<void> _handleLogout(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    // Tampilkan dialog konfirmasi
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Apakah Anda yakin ingin keluar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      await authProvider.logout();
      if (onLogoutSuccess != null) {
        onLogoutSuccess!();
      } else {
        // Default: navigate ke login
        if (context.mounted) {
          Navigator.pushNamedAndRemoveUntil(
            context, 
            '/login', 
            (route) => false,
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        if (!authProvider.isAuthenticated) {
          return const SizedBox.shrink();
        }

        return IconButton(
          onPressed: authProvider.isLoading 
              ? null 
              : () => _handleLogout(context),
          icon: authProvider.isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.logout),
          tooltip: 'Logout',
        );
      },
    );
  }
}