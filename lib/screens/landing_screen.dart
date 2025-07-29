import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'home_screen.dart';
import 'audio_home_screen.dart';
import 'dart:ui';

class LandingScreen extends StatefulWidget {
  const LandingScreen({Key? key}) : super(key: key);

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  @override
  void initState() {
    super.initState();
    _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    // Request media permissions where necessary
    await [
      Permission.videos,
      Permission.audio,
      Permission.storage, // for Android < 13
    ].request();
  }

  @override
  Widget build(BuildContext context) {
    final iconSize = 80.0;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Media Player'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Theme.of(context).colorScheme.onBackground,
        centerTitle: true,
        titleTextStyle: const TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF06141B),
              Color(0xFF11212D),
              Color(0xFF253745),
              Color(0xFF4A5C6A),
              Color(0xFF9BA8AB),
            ],
            stops: [0.0, 0.25, 0.5, 0.75, 1.0],
          ),
        ),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _FeatureTile(
                icon: Icons.play_circle_fill,
                label: 'Video',
                iconSize: iconSize,
                overlayColor: const Color(0xFF4A5C6A),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    settings: const RouteSettings(name: '/home'),
                    builder: (_) => const HomeScreen(),
                  ),
                ),
              ),
              _FeatureTile(
                icon: Icons.library_music,
                label: 'Audio',
                iconSize: iconSize,
                overlayColor: const Color(0xFF9BA8AB),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    settings: const RouteSettings(name: '/audio_home'),
                    builder: (_) => const AudioHomeScreen(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final double iconSize;
  final VoidCallback onTap;
  final Color overlayColor;
  const _FeatureTile({
    required this.icon,
    required this.label,
    required this.iconSize,
    required this.onTap,
    required this.overlayColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: iconSize + 20,
            height: iconSize + 20,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF06141B).withOpacity(0.35),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
              color: overlayColor.withOpacity(0.45),
              backgroundBlendMode: BlendMode.overlay,
              border: Border.all(
                color: const Color(0xFF253745).withOpacity(0.18),
                width: 1.5,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(32),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                child: Center(
                  child: Icon(
                    icon,
                    size: iconSize,
                    color: const Color(0xFFCCD0CF),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFFCCD0CF),
              letterSpacing: 1.1,
              shadows: [
                Shadow(
                  color: Color(0xFF06141B),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            overlayColor == const Color(0xFF4A5C6A)
                ? 'Explore videos'
                : 'Listen to music',
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF9BA8AB),
              fontWeight: FontWeight.w400,
              letterSpacing: 0.7,
            ),
          ),
        ],
      ),
    );
  }
}
