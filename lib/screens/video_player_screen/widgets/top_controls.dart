import 'package:flutter/material.dart';

class TopControls extends StatelessWidget {
  final VoidCallback onMoreOptions;
  final VoidCallback toggleOrientation;
  final bool isLandscape;
  final VoidCallback onEnablePiP;
  final VoidCallback onSwitchToAudio;
  final VoidCallback toggleLock;
  final VoidCallback cycleAspectMode;

  const TopControls({
    Key? key,
    required this.onMoreOptions,
    required this.toggleOrientation,
    required this.isLandscape,
    required this.onEnablePiP,
    required this.onSwitchToAudio,
    required this.toggleLock,
    required this.cycleAspectMode,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      top: 0,
      child: Container(
        padding: const EdgeInsets.only(top: 16.0),
        height: 75,
        color: Colors.black.withOpacity(0.35),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.lock_open, color: Colors.white),
              onPressed: toggleLock,
              tooltip: 'Lock',
            ),
            IconButton(
              icon: const Icon(Icons.aspect_ratio, color: Colors.white),
              onPressed: cycleAspectMode,
              tooltip: 'Resize',
            ),
            IconButton(
              icon: const Icon(Icons.more_vert, color: Colors.white),
              onPressed: onMoreOptions,
              tooltip: 'More',
            ),
            IconButton(
              icon: Icon(
                isLandscape
                    ? Icons.screen_lock_portrait
                    : Icons.screen_lock_landscape,
                color: Colors.white,
              ),
              onPressed: toggleOrientation,
              tooltip: 'Orientation',
            ),
            IconButton(
              icon: Image.asset(
                'assets/pip.png',
                width: 24,
                height: 24,
                color: Colors.white,
              ),
              onPressed: onEnablePiP,
              tooltip: 'PiP',
            ),
            IconButton(
              icon: Image.asset(
                'assets/headphone.png',
                width: 24,
                height: 24,
                color: Colors.white,
              ),
              onPressed: onSwitchToAudio,
              tooltip: 'Audio Only',
            ),
          ],
        ),
      ),
    );
  }
}
