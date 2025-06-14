import 'package:flutter/material.dart';
import 'package:komik_in/widgets/bottom_navbar.dart';
import 'home_screen.dart';
import 'profile_screen.dart';
import 'bookmark_screen.dart';
import 'history_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const BookmarkScreen(),
    const HistoryScreen(),
    const ProfileScreen(),
  ];

  void _onNavTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavbar(
        currentIndex: _selectedIndex,
        onTap: _onNavTapped,
      ),
    );
  }
}