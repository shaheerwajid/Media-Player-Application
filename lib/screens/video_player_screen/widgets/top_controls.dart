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
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withOpacity(0.9),
              Colors.black.withOpacity(0.8),
              Colors.black.withOpacity(0.7),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 15,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            IconButton(
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.arrow_back,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
            const Spacer(),
            IconButton(
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.lock_open,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              onPressed: toggleLock,
              tooltip: 'Lock',
            ),
            IconButton(
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.aspect_ratio,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              onPressed: cycleAspectMode,
              tooltip: 'Resize',
            ),
            IconButton(
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.more_vert,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              onPressed: onMoreOptions,
              tooltip: 'More',
            ),
            IconButton(
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  isLandscape
                      ? Icons.screen_lock_portrait
                      : Icons.screen_lock_landscape,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              onPressed: toggleOrientation,
              tooltip: 'Orientation',
            ),
            IconButton(
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Image.asset(
                  'assets/pip.png',
                  width: 20,
                  height: 20,
                  color: Colors.white,
                ),
              ),
              onPressed: onEnablePiP,
              tooltip: 'PiP',
            ),
            IconButton(
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Image.asset(
                  'assets/headphone.png',
                  width: 20,
                  height: 20,
                  color: Colors.white,
                ),
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
