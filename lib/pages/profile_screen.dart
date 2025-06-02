import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:komik_in/providers/auth_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ImagePicker _picker = ImagePicker();
  bool _isUpdatingProfile = false;

  // Helper method untuk mendapatkan display name user
  String _getUserDisplayName(AuthProvider authProvider) {
    if (authProvider.username != null && authProvider.username!.isNotEmpty) {
      return authProvider.username!;
    }
    
    if (authProvider.userEmail != null && authProvider.userEmail!.isNotEmpty) {
      final emailParts = authProvider.userEmail!.split('@');
      return emailParts.isNotEmpty ? emailParts[0] : 'User';
    }
    
    return 'User';
  }

  // Helper method untuk mendapatkan bio/deskripsi user
  String _getUserBio(AuthProvider authProvider) {
    if (authProvider.userEmail != null && authProvider.userEmail!.isNotEmpty) {
      return 'Welcome to KomikIn!\nEmail: ${authProvider.userEmail}\nEnjoy reading your favorite comics!';
    }
    
    return 'Welcome to KomikIn!\nEnjoy reading your favorite comics!';
  }

  // Method untuk handle profile image update
  Future<void> _updateProfileImage() async {
    try {
      // Show loading
      setState(() {
        _isUpdatingProfile = true;
      });

      // Pick image from gallery
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image == null) {
        setState(() {
          _isUpdatingProfile = false;
        });
        return;
      }

      // Convert image to base64
      final bytes = await image.readAsBytes();
      final base64String = 'data:image/jpeg;base64,${base64Encode(bytes)}';

      // Update profile through AuthProvider
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = await authProvider.updateProfile(
        profileImageUrl: base64String,
      );

      if (success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile image berhasil diperbarui!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else if (context.mounted) {
        final errorMessage = authProvider.errorMessage ?? 'Gagal memperbarui gambar profil';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red[600],
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red[600],
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUpdatingProfile = false;
        });
      }
    }
  }

  // Method untuk edit username
  Future<void> _editUsername(AuthProvider authProvider) async {
    final TextEditingController controller = TextEditingController(
      text: authProvider.username ?? '',
    );

    final newUsername = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Username'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Username',
            hintText: 'Masukkan username baru...',
            border: OutlineInputBorder(),
          ),
          maxLength: 20,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              final username = controller.text.trim();
              if (username.isNotEmpty && username != authProvider.username) {
                Navigator.of(context).pop(username);
              } else {
                Navigator.of(context).pop();
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );

    if (newUsername != null && newUsername.isNotEmpty && mounted) {
      setState(() {
        _isUpdatingProfile = true;
      });

      try {
        print('[ProfileScreen] Starting username update...');
        print('[ProfileScreen] Auth status before update: ${authProvider.isAuthenticated}');
        
        final success = await authProvider.updateProfile(username: newUsername);

        print('[ProfileScreen] Update result: $success');
        print('[ProfileScreen] Auth status after update: ${authProvider.isAuthenticated}');
        
        if (mounted) {
          setState(() {
            _isUpdatingProfile = false;
          });

          if (success) {
            print('[ProfileScreen] Username update successful, showing success message');
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Username berhasil diperbarui!'),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
              ),
            );
          } else {
            print('[ProfileScreen] Username update failed');
            final errorMessage = authProvider.errorMessage ?? 'Gagal memperbarui username';
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(errorMessage),
                backgroundColor: Colors.red[600],
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
      } catch (e) {
        print('[ProfileScreen] Exception during username update: $e');
        if (mounted) {
          setState(() {
            _isUpdatingProfile = false;
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: Colors.red[600],
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  // Method untuk handle logout dengan konfirmasi
  Future<void> _handleLogout(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    // Tampilkan dialog konfirmasi dengan layout yang responsive
    final shouldLogout = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          contentPadding: const EdgeInsets.all(24),
          title: Row(
            children: [
              Icon(Icons.logout, color: Colors.red[600]),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Konfirmasi Logout',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Apakah Anda yakin ingin keluar dari akun?',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 12),
              Text(
                'Anda harus login kembali untuk mengakses aplikasi.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          actions: [
            // UPDATED: Button dengan ukuran yang sama dan font yang lebih kecil
            Row(
              children: [
                // Tombol Batal
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.grey[600],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(color: Colors.grey[300]!),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                      child: const Text(
                        'Batal',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Tombol Logout
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[600],
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                      child: const Text(
                        'Logout',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );

    // Jika user mengkonfirmasi logout
    if (shouldLogout == true) {
      try {
        // Tampilkan loading dialog yang responsive
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const AlertDialog(
            content: IntrinsicHeight(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Logging out...'),
                ],
              ),
            ),
          ),
        );

        // Lakukan logout
        await authProvider.logout();

        // Tutup loading dialog
        if (context.mounted) {
          Navigator.of(context).pop();
        }

        // Navigate ke login screen dan hapus semua route sebelumnya
        if (context.mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil(
            '/login',
            (route) => false,
          );
          
          // Tampilkan snackbar sukses
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Berhasil logout. Sampai jumpa!'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        // Tutup loading dialog jika error
        if (context.mounted) {
          Navigator.of(context).pop();
        }
        
        // Tampilkan error message
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal logout: ${e.toString()}'),
              backgroundColor: Colors.red[600],
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  // Widget untuk menampilkan profile image
  Widget _buildProfileImage(AuthProvider authProvider) {
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        CircleAvatar(
          radius: 50,
          backgroundColor: Colors.grey[200],
          backgroundImage: authProvider.profileImageUrl != null && 
                          authProvider.profileImageUrl!.isNotEmpty
              ? MemoryImage(
                  base64Decode(
                    authProvider.profileImageUrl!.split(',')[1], // Remove data:image/jpeg;base64,
                  ),
                )
              : const AssetImage('assets/images/profile.png') as ImageProvider,
        ),
        Positioned(
          bottom: 2,
          right: 2,
          child: GestureDetector(
            onTap: _isUpdatingProfile ? null : _updateProfileImage,
            child: Container(
              width: 28,
              height: 28,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.blue,
              ),
              child: _isUpdatingProfile
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(
                      Icons.camera_alt,
                      color: Colors.white,
                      size: 16,
                    ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Consumer<AuthProvider>(
          builder: (context, authProvider, child) {
            final displayName = _getUserDisplayName(authProvider);
            final userBio = _getUserBio(authProvider);
            
            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 40),
                    
                    // Profile Image with Camera Icon (Updated)
                    _buildProfileImage(authProvider),
                    
                    const SizedBox(height: 20),
                    
                    // Name with Edit Button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          displayName,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: _isUpdatingProfile ? null : () => _editUsername(authProvider),
                          child: Icon(
                            Icons.edit,
                            size: 20,
                            color: _isUpdatingProfile ? Colors.grey : Colors.blue,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Bio Description - Dynamic from AuthProvider
                    Text(
                      userBio,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                        height: 1.4,
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Divider
                    Divider(
                      thickness: 0.5,
                      color: Colors.grey[300],
                      indent: 20,
                      endIndent: 20,
                    ),
                    
                    const SizedBox(height: 32),

                    // Read Comics & Reviews Containers
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(25),
                              border: Border.all(
                                color: Colors.black,
                                width: 1.5,
                              ),
                            ),
                            child: const Text(
                              'Read Comics',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(25),
                              border: Border.all(
                                color: Colors.black,
                                width: 1.5,
                              ),
                            ),
                            child: const Text(
                              'Reviews',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 40),

                    // Account Section Title
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Account',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 18,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Account Info Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue[200]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Account Info',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: Colors.blue[700],
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (authProvider.userEmail != null) ...[
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.email, size: 16, color: Colors.grey[600]),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    authProvider.userEmail!,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey[700],
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 2,
                                  ),
                                ),
                              ],
                            ),
                          ],
                          if (authProvider.userId != null) ...[
                            const SizedBox(height: 8),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.badge, size: 16, color: Colors.grey[600]),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'ID: ${authProvider.userId}',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey[700],
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    
                    // Account Buttons
                    _buildAccountButton('History'),
                    const SizedBox(height: 16),
                    _buildAccountButton('Bookmark'),
                    const SizedBox(height: 24),
                    _buildAccountButton(
                      'Log Out',
                      textColor: Colors.red,
                      centerText: true,
                      onTap: () => _handleLogout(context),
                    ),
                    
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildAccountButton(
    String text, {
    Color textColor = Colors.black,
    bool centerText = false,
    VoidCallback? onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onTap ?? () {
          // TODO: Implement other button actions
        },
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          side: BorderSide(
            color: text == 'Log Out' ? Colors.red : Colors.black,
            width: 1.5,
          ),
          alignment: centerText ? Alignment.center : Alignment.centerLeft,
        ),
        child: Text(
          text,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: textColor,
          ),
        ),
      ),
    );
  }
}