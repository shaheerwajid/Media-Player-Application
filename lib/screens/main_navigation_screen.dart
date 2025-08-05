import 'package:flutter/material.dart';
import 'dart:ui';
import 'video_screen.dart';
import 'audio_home_screen.dart';
import 'settings_screen.dart';

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
        child: _screens[_selectedIndex],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF4A5C6A).withOpacity(0.15),
          border: Border(
            top: BorderSide(
              color: const Color(0xFF4A5C6A).withOpacity(0.3),
              width: 1,
            ),
          ),
        ),
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: BottomNavigationBar(
              currentIndex: _selectedIndex,
              onTap: (index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
              backgroundColor: Colors.transparent,
              elevation: 0,
              selectedItemColor: const Color(0xFF4A5C6A),
              unselectedItemColor: const Color(0xFF9BA8AB),
              type: BottomNavigationBarType.fixed,
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.play_circle_outline),
                  activeIcon: Icon(Icons.play_circle_filled),
                  label: 'Video',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.music_note_outlined),
                  activeIcon: Icon(Icons.music_note),
                  label: 'Music',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person_outline),
                  activeIcon: Icon(Icons.person),
                  label: 'Me',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
