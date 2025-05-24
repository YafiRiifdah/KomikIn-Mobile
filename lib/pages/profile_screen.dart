import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 40),
                
                // Profile Image with Plus Icon
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundImage: AssetImage('assets/images/profile.png'),
                      backgroundColor: Colors.grey[200],
                    ),
                    Positioned(
                      bottom: 2,
                      right: 2,
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.blue,
                        ),
                        child: const Icon(
                          Icons.add,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 20),
                
                // Name
                const Text(
                  'Alvany',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                
                const SizedBox(height: 12),
                
                // Bio Description
                const Text(
                  'I`m student from Ukraine. I have been a resident of\nAtom Space for 4 years now...',
                  textAlign: TextAlign.center,
                  style: TextStyle(
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
                
                // Account Buttons
                _buildAccountButton('History'),
                const SizedBox(height: 16),
                _buildAccountButton('Bookmark'),
                const SizedBox(height: 24),
                _buildAccountButton(
                  'Log Out',
                  textColor: Colors.red,
                  centerText: true,
                ),
                
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAccountButton(String text, {Color textColor = Colors.black, bool centerText = false}) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: () {},
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          side: const BorderSide(
            color: Colors.black,
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