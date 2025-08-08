import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:media_kit/media_kit.dart';

class BottomControls extends StatefulWidget {
  final Player player;
  final bool isPlayerInitialized;
  final VoidCallback onCaptureScreenshot;
  final VoidCallback onMute;
  final bool isMuted;
  final VoidCallback onPlayPrevious;
  final bool canPlayPrevious;
  final VoidCallback onPlayNext;
  final bool canPlayNext;
  final String Function(Duration) formatDuration;
  final VoidCallback startHideTimer;
  final List<int> bookmarks;
  final void Function(int ms) onBookmarkTap;

  const BottomControls({
    Key? key,
    required this.player,
    required this.isPlayerInitialized,
    required this.onCaptureScreenshot,
    required this.onMute,
    required this.isMuted,
    required this.onPlayPrevious,
    required this.canPlayPrevious,
    required this.onPlayNext,
    required this.canPlayNext,
    required this.formatDuration,
    required this.startHideTimer,
    required this.bookmarks,
    required this.onBookmarkTap,
  }) : super(key: key);

  @override
  State<BottomControls> createState() => _BottomControlsState();
}

class _BottomControlsState extends State<BottomControls> {
  bool _isSeeking = false;
  double? _seekBarValue;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        padding: const EdgeInsets.only(bottom: 16.0),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
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
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
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
                    child: Image.asset(
                      'assets/screenshot.png',
                      width: 20,
                      height: 20,
                      color: Colors.white,
                    ),
                  ),
                  onPressed: widget.onCaptureScreenshot,
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
                      'assets/mute.png',
                      width: 20,
                      height: 20,
                      color: Colors.white,
                    ),
                  ),
                  onPressed: widget.onMute,
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
                      Icons.skip_previous,
                      color: widget.canPlayPrevious
                          ? Colors.white
                          : Colors.white.withOpacity(0.5),
                      size: 28,
                    ),
                  ),
                  onPressed: widget.onPlayPrevious,
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
                      Icons.replay_10,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  onPressed: () {
                    final newPosition =
                        widget.player.state.position -
                        const Duration(seconds: 10);
                    final clampedPosition = newPosition < Duration.zero
                        ? Duration.zero
                        : newPosition > widget.player.state.duration
                        ? widget.player.state.duration
                        : newPosition;
                    widget.player.seek(clampedPosition);
                  },
                ),
                StreamBuilder<bool>(
                  stream: widget.player.stream.playing,
                  initialData: widget.player.state.playing,
                  builder: (context, snapshot) {
                    final isPlaying = snapshot.data ?? false;
                    return AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      transitionBuilder: (child, animation) =>
                          FadeTransition(opacity: animation, child: child),
                      child: IconButton(
                        key: ValueKey(isPlaying ? 'pause' : 'play'),
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
                            isPlaying
                                ? Icons.pause_circle_filled
                                : Icons.play_circle_filled,
                            color: Colors.white,
                            size: 40,
                          ),
                        ),
                        onPressed: widget.player.playOrPause,
                      ),
                    );
                  },
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
                      Icons.forward_10,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  onPressed: () {
                    final newPosition =
                        widget.player.state.position +
                        const Duration(seconds: 10);
                    final clampedPosition = newPosition < Duration.zero
                        ? Duration.zero
                        : newPosition > widget.player.state.duration
                        ? widget.player.state.duration
                        : newPosition;
                    widget.player.seek(clampedPosition);
                  },
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
                      Icons.skip_next,
                      color: widget.canPlayNext
                          ? Colors.white
                          : Colors.white.withOpacity(0.5),
                      size: 28,
                    ),
                  ),
                  onPressed: widget.onPlayNext,
                ),
              ],
            ),
            if (widget.isPlayerInitialized) _buildSeekBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildSeekBar() {
    return StreamBuilder<Duration>(
      stream: widget.player.stream.position,
      builder: (context, snapshot) {
        final position = _isSeeking
            ? Duration(milliseconds: (_seekBarValue ?? 0).toInt())
            : (snapshot.data ?? Duration.zero);
        final duration = widget.player.state.duration;
        final durationMs = duration.inMilliseconds.toDouble();
        return Row(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(8),
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
                child: Text(
                  widget.formatDuration(position),
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            Expanded(
              child: Stack(
                alignment: Alignment.centerLeft,
                children: [
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 3.0,
                      activeTrackColor: Colors.white,
                      inactiveTrackColor: Colors.white.withOpacity(0.3),
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 8.0,
                      ),
                      thumbColor: Colors.white,
                      overlayColor: Colors.white.withOpacity(0.2),
                    ),
                    child: Slider(
                      value: position.inMilliseconds.toDouble().clamp(
                        0.0,
                        durationMs,
                      ),
                      max: durationMs,
                      onChanged: (value) {
                        setState(() {
                          _seekBarValue = value;
                        });
                      },
                      onChangeStart: (value) {
                        setState(() {
                          _isSeeking = true;
                        });
                      },
                      onChangeEnd: (value) {
                        widget.player.seek(
                          Duration(milliseconds: value.toInt()),
                        );
                        setState(() {
                          _isSeeking = false;
                          _seekBarValue = null;
                        });
                        widget.startHideTimer();
                      },
                    ),
                  ),
                  // Bookmark dots
                  if (widget.bookmarks.isNotEmpty && durationMs > 0)
                    Positioned.fill(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return Stack(
                            children: widget.bookmarks.map((ms) {
                              final frac = ms / durationMs;
                              return Positioned(
                                left: (constraints.maxWidth - 8) * frac,
                                top: 0,
                                bottom: 0,
                                child: GestureDetector(
                                  onTap: () => widget.onBookmarkTap(ms),
                                  child: Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: Colors.amber,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.black,
                                        width: 1,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(8),
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
                child: Text(
                  widget.formatDuration(duration),
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
