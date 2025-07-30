import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'home_screen.dart';
import 'audio_home_screen.dart';
import 'dart:ui';
import 'settings_screen.dart';

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
        title: Text(
          'Media Player',
          style: Theme.of(context).textTheme.titleLarge,
        ),
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
            children: List.generate(3, (index) {
              final delay = Duration(milliseconds: 80 * index);
              return TweenAnimationBuilder(
                tween: Tween<Offset>(
                  begin: const Offset(0, 0.12),
                  end: Offset.zero,
                ),
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeOut,
                builder: (context, offset, child) => AnimatedOpacity(
                  opacity: 1.0,
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeOut,
                  child: AnimatedSlide(
                    offset: offset,
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeOut,
                    child: child,
                  ),
                ),
                child: _FeatureTile(
                  icon: index == 0
                      ? Icons.play_circle_outline_rounded
                      : index == 1
                      ? Icons.library_music_outlined
                      : Icons.settings_outlined,
                  label: index == 0
                      ? 'Video'
                      : index == 1
                      ? 'Audio'
                      : 'Settings',
                  iconSize: iconSize,
                  overlayColor: index == 0
                      ? const Color(0xFF4A5C6A)
                      : index == 1
                      ? const Color(0xFF9BA8AB)
                      : Color(0xFF3C5A99),
                  onTap: () {
                    if (index == 0) {
                      Navigator.push(
                        context,
                        FadePageRoute(page: HomeScreen()),
                      );
                    } else if (index == 1) {
                      Navigator.push(
                        context,
                        FadePageRoute(page: AudioHomeScreen()),
                      );
                    } else {
                      Navigator.push(
                        context,
                        FadePageRoute(page: SettingsScreen()),
                      );
                    }
                  },
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class FadePageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  FadePageRoute({required this.page})
    : super(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      );
}

class _FeatureTile extends StatefulWidget {
  final IconData icon;
  final String label;
  final double iconSize;
  final Color overlayColor;
  final VoidCallback onTap;
  const _FeatureTile({
    required this.icon,
    required this.label,
    required this.iconSize,
    required this.overlayColor,
    required this.onTap,
    Key? key,
  }) : super(key: key);
  @override
  State<_FeatureTile> createState() => _FeatureTileState();
}

class _FeatureTileState extends State<_FeatureTile> {
  bool _isPressed = false;
  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _isPressed ? 0.96 : 1.0,
      duration: const Duration(milliseconds: 120),
      child: InkWell(
        borderRadius: BorderRadius.circular(32),
        onTap: widget.onTap,
        onHighlightChanged: (v) => setState(() => _isPressed = v),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: widget.iconSize + 20,
              height: widget.iconSize + 20,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF06141B).withOpacity(0.35),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
                color: widget.overlayColor.withOpacity(0.45),
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
                      widget.icon,
                      size: widget.iconSize,
                      color: Color(0xFFCCD0CF),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              widget.label,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
