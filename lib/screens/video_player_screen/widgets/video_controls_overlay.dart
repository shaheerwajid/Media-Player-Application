import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

import 'top_controls.dart';
import 'bottom_controls.dart';
import 'status_overlays.dart';

class VideoControlsOverlay extends StatelessWidget {
  final Player player;
  final bool isPlayerInitialized;
  final bool showControls;
  final bool isLocked;
  final VoidCallback toggleLock;
  final VoidCallback onMoreOptions;
  final VoidCallback toggleOrientation;
  final bool isLandscape;
  final VoidCallback onEnablePiP;
  final VoidCallback onSwitchToAudio;
  final VoidCallback onCaptureScreenshot;
  final VoidCallback onMute;
  final bool isMuted;
  final VoidCallback onPlayPrevious;
  final bool canPlayPrevious;
  final VoidCallback onPlayNext;
  final bool canPlayNext;
  final VoidCallback cycleAspectMode;
  final VoidCallback startHideTimer;

  final double seekOffsetSeconds;
  final double currentVolume;
  final double currentBrightness;
  final bool showSeekOverlay;
  final bool showVolumeOverlay;
  final bool showBrightnessOverlay;
  final String? aspectModeOverlayText;

  final String Function(Duration) formatDuration;
  final List<int> bookmarks;
  final void Function(int ms) onBookmarkTap;

  const VideoControlsOverlay({
    Key? key,
    required this.player,
    required this.isPlayerInitialized,
    required this.showControls,
    required this.isLocked,
    required this.toggleLock,
    required this.onMoreOptions,
    required this.toggleOrientation,
    required this.isLandscape,
    required this.onEnablePiP,
    required this.onSwitchToAudio,
    required this.onCaptureScreenshot,
    required this.onMute,
    required this.isMuted,
    required this.onPlayPrevious,
    required this.canPlayPrevious,
    required this.onPlayNext,
    required this.canPlayNext,
    required this.cycleAspectMode,
    required this.seekOffsetSeconds,
    required this.currentVolume,
    required this.currentBrightness,
    required this.showSeekOverlay,
    required this.showVolumeOverlay,
    required this.showBrightnessOverlay,
    required this.formatDuration,
    required this.startHideTimer,
    required this.bookmarks,
    required this.onBookmarkTap,
    this.aspectModeOverlayText,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!showControls && !isLocked) {
      return const SizedBox.shrink();
    }

    return Stack(
      children: [
        // Status overlays
        if (showSeekOverlay && isPlayerInitialized)
          StatusOverlays.seek(context: context, offset: seekOffsetSeconds),
        if (showVolumeOverlay)
          StatusOverlays.volume(context: context, volume: currentVolume),
        if (showBrightnessOverlay)
          StatusOverlays.brightness(context, currentBrightness),
        if (aspectModeOverlayText != null)
          StatusOverlays.aspectRatio(context, aspectModeOverlayText!),

        // Lock button - only show when locked
        if (isLocked)
          Positioned(
            top: 32,
            right: 16,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withOpacity(0.4),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.6),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: IconButton(
                icon: const Icon(Icons.lock, color: Colors.white, size: 28),
                onPressed: toggleLock,
                tooltip: 'Unlock',
                padding: const EdgeInsets.all(8),
              ),
            ),
          ),

        // Controls overlay - only show when not locked
        if (!isLocked) ...[
          // Top controls
          if (showControls)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: TopControls(
                onMoreOptions: onMoreOptions,
                toggleOrientation: toggleOrientation,
                isLandscape: isLandscape,
                onEnablePiP: onEnablePiP,
                onSwitchToAudio: onSwitchToAudio,
                toggleLock: toggleLock,
                cycleAspectMode: cycleAspectMode,
              ),
            ),
          // Bottom controls
          if (showControls)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: BottomControls(
                player: player,
                isPlayerInitialized: isPlayerInitialized,
                onCaptureScreenshot: onCaptureScreenshot,
                onMute: onMute,
                isMuted: isMuted,
                onPlayPrevious: onPlayPrevious,
                canPlayPrevious: canPlayPrevious,
                onPlayNext: onPlayNext,
                canPlayNext: canPlayNext,
                formatDuration: formatDuration,
                startHideTimer: startHideTimer,
                bookmarks: bookmarks,
                onBookmarkTap: onBookmarkTap,
              ),
            ),
        ],
      ],
    );
  }
}
