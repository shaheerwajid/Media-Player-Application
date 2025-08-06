import 'package:flutter/material.dart';
import 'dart:ui';
import 'video_screen.dart';
import 'audio_home_screen.dart';
import 'settings_screen.dart';
import '../widgets/animated_nav_bar.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({Key? key}) : super(key: key);

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0; // Default to Video tab

  final List<Widget> _screens = [
    const VideoScreen(),
    const AudioHomeScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomLeft,
            end: Alignment.topRight,
            colors: [
              Color(0xFF06151C),
              Color(0xFF0C1A24),
              Color(0xFF172734),
              Color(0xFF2F404D),
              Color(0xFF64727A),
              Color(0xFFCCD1CF),
            ],
            stops: [0.0, 0.2, 0.43, 0.54, 0.78, 1.0],
          ),
        ),
        child: IndexedStack(index: _selectedIndex, children: _screens),
      ),
      bottomNavigationBar: AnimatedNavBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: [
          NavBarItem(label: 'Video', assetPath: 'assets/video.png'),
          NavBarItem(label: 'Music', assetPath: 'assets/music.png'),
          NavBarItem(label: 'Me', assetPath: 'assets/settings.png'),
        ],
      ),
    );
  }
}
