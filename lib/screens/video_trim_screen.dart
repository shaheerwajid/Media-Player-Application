import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:easy_video_editor/easy_video_editor.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:path_provider/path_provider.dart';
import 'package:media_store_plus/media_store_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme_data.dart';

class VideoTrimScreen extends StatefulWidget {
  final File originalFile;
  const VideoTrimScreen({Key? key, required this.originalFile})
    : super(key: key);

  @override
  State<VideoTrimScreen> createState() => _VideoTrimScreenState();
}

class _VideoTrimScreenState extends State<VideoTrimScreen> {
  late final Player _player;
  late final VideoController _controller;
  Duration _duration = Duration.zero;
  double _start = 0.0;
  double _end = 1.0; // fraction of duration (0-1)
  double _exportProgress = 0.0;
  bool _exporting = false;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _setupPlayer();
  }

  Future<void> _setupPlayer() async {
    _player = Player();
    _controller = VideoController(_player);
    await _player.open(Media(widget.originalFile.path), play: false);
    // Robustly wait for duration to become available (handles reopen cases)
    Duration dur = Duration.zero;
    try {
      dur = await _player.stream.duration
          .firstWhere((d) => d > Duration.zero)
          .timeout(const Duration(seconds: 3));
    } catch (_) {
      // Fallback to current state if stream did not emit in time
      dur = _player.state.duration;
    }
    if (!mounted) return;
    setState(() {
      _duration = dur;
      _start = 0.0;
      _end = _duration.inMilliseconds.toDouble();
    });
  }

  @override
  void dispose() {
    try {
      _player.pause();
    } catch (_) {}
    _player.dispose();
    super.dispose();
  }

  Future<void> _exportTrim() async {
    // Pause the preview to unlock file, dispose later after UI no longer needs it
    try {
      await _player.pause();
    } catch (_) {}
    if (!await Permission.videos.request().isGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Storage permission is required')),
      );
      return;
    }
    final startMs = _start.round();
    final endMs = _end.round();
    if (endMs <= startMs) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('End time must be greater than start time'),
        ),
      );
      return;
    }
    setState(() {
      _exporting = true;
      _exportProgress = 0.0;
    });
    try {
      final tempDir = await getTemporaryDirectory();
      final outPath =
          '${tempDir.path}/trim_${DateTime.now().millisecondsSinceEpoch}.mp4';
      final builder = VideoEditorBuilder(
        videoPath: widget.originalFile.path,
      ).trim(startTimeMs: startMs, endTimeMs: endMs);
      final output = await builder.export(
        outputPath: outPath,
        onProgress: (p) {
          debugPrint('export progress: $p');
          if (mounted) {
            setState(() => _exportProgress = p);
          }
        },
      );
      final exportedPath = output ?? outPath;
      // Save to gallery (Android)
      await MediaStore.ensureInitialized();
      final mediaStore = MediaStore();
      await mediaStore.saveFile(
        tempFilePath: exportedPath,
        dirType: DirType.video,
        dirName: DirName.movies,
        relativePath: '',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Trim saved to gallery',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        );
      }
      // Dispose preview now that we're done and before leaving
      Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Trim failed: $e',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _exporting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalMs = _duration.inMilliseconds.toDouble();
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        title: Text(
          'Trim Video',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(gradient: AppThemes.currentMainGradient),
        ),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(gradient: AppThemes.currentMainGradient),
        child: _duration == Duration.zero
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  Expanded(
                    child: Center(
                      child: AspectRatio(
                        aspectRatio: 16 / 9,
                        child: Video(
                          controller: _controller,
                          controls: NoVideoControls,
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        // Combined controls card
                        ClipRRect(
                          borderRadius: BorderRadius.circular(28),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                            child: Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.13),
                                borderRadius: BorderRadius.circular(28),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.18),
                                  width: 1.2,
                                ),
                              ),
                              child: Column(
                                children: [
                                  // Trim range slider
                                  SliderTheme(
                                    data: SliderTheme.of(context).copyWith(
                                      trackHeight: 4,
                                      thumbShape: const RoundSliderThumbShape(
                                        enabledThumbRadius: 8,
                                      ),
                                      overlayShape:
                                          const RoundSliderOverlayShape(
                                            overlayRadius: 14,
                                          ),
                                      activeTrackColor: Colors.white,
                                      inactiveTrackColor: Colors.white
                                          .withOpacity(0.3),
                                    ),
                                    child: RangeSlider(
                                      values: RangeValues(_start, _end),
                                      min: 0.0,
                                      max: totalMs,
                                      divisions: (_duration.inSeconds).clamp(
                                        10,
                                        120,
                                      ),
                                      onChanged: (values) {
                                        setState(() {
                                          _start = values.start;
                                          _end = values.end;
                                        });
                                      },
                                    ),
                                  ),

                                  // Time display
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 8,
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          _formatMs(_start),
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.w500,
                                              ),
                                        ),
                                        Text(
                                          _formatMs(_end),
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.w500,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  const SizedBox(height: 16),

                                  // Play/Pause button
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(28),
                                    child: Container(
                                      width: 56,
                                      height: 56,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [
                                            Colors.white.withOpacity(0.25),
                                            Colors.grey.withOpacity(0.15),
                                            Colors.white.withOpacity(0.20),
                                          ],
                                        ),
                                        border: Border.all(
                                          color: Colors.white.withOpacity(0.25),
                                          width: 1.5,
                                        ),
                                        shape: BoxShape.circle,
                                      ),
                                      child: IconButton(
                                        iconSize: 32,
                                        icon: Icon(
                                          _isPlaying
                                              ? Icons.pause_circle
                                              : Icons.play_circle,
                                          color: Colors.white,
                                        ),
                                        onPressed: _exporting
                                            ? null
                                            : () async {
                                                if (_isPlaying) {
                                                  await _player.pause();
                                                  if (mounted)
                                                    setState(
                                                      () => _isPlaying = false,
                                                    );
                                                } else {
                                                  await _player.seek(
                                                    Duration(
                                                      milliseconds: _start
                                                          .round(),
                                                    ),
                                                  );
                                                  await _player.play();
                                                  if (mounted)
                                                    setState(
                                                      () => _isPlaying = true,
                                                    );
                                                }
                                              },
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 16),

                                  // Progress indicator
                                  if (_exporting)
                                    Column(
                                      children: [
                                        LinearProgressIndicator(
                                          value: _exportProgress,
                                          backgroundColor: Colors.white
                                              .withOpacity(0.2),
                                          valueColor:
                                              const AlwaysStoppedAnimation<
                                                Color
                                              >(Colors.white),
                                        ),
                                        const SizedBox(height: 8),
                                      ],
                                    ),

                                  // Save button
                                  Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(12),
                                      onTap: _exporting ? null : _exportTrim,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 24,
                                          vertical: 12,
                                        ),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                            colors: [
                                              Colors.white.withOpacity(0.25),
                                              Colors.grey.withOpacity(0.15),
                                              Colors.white.withOpacity(0.20),
                                            ],
                                          ),
                                          border: Border.all(
                                            color: Colors.white.withOpacity(
                                              0.25,
                                            ),
                                            width: 1.5,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.save,
                                              color: Colors.white,
                                              size: 20,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              'Save Trim',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodyLarge
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  String _formatMs(double ms) {
    final d = Duration(milliseconds: ms.round());
    String two(int n) => n.toString().padLeft(2, '0');
    final mins = two(d.inMinutes.remainder(60));
    final secs = two(d.inSeconds.remainder(60));
    return '${d.inHours > 0 ? '${two(d.inHours)}:' : ''}$mins:$secs';
  }
}
