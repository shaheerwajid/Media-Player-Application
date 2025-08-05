import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:easy_video_editor/easy_video_editor.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:path_provider/path_provider.dart';
import 'package:media_store_plus/media_store_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:google_fonts/google_fonts.dart';

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
    // Wait tiny bit for metadata
    await Future.delayed(const Duration(milliseconds: 200));
    if (mounted) {
      setState(() {
        _duration = _player.state.duration;
        _start = 0.0;
        _end = _duration.inMilliseconds.toDouble();
      });
    }
  }

  @override
  void dispose() {
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Trim saved to gallery')));
      }
      // Dispose preview now that we're done and before leaving
      Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Trim failed: $e')));
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
      appBar: AppBar(title: const Text('Trim Video')),
      body: _duration == Duration.zero
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
                      // Trim range selector
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 4,
                          thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 8,
                          ),
                          overlayShape: const RoundSliderOverlayShape(
                            overlayRadius: 14,
                          ),
                          activeTrackColor: Theme.of(
                            context,
                          ).colorScheme.secondary,
                          inactiveTrackColor: Colors.grey.shade600,
                        ),
                        child: RangeSlider(
                          values: RangeValues(_start, _end),
                          min: 0.0,
                          max: totalMs,
                          divisions: (_duration.inSeconds).clamp(10, 120),
                          onChanged: (values) {
                            setState(() {
                              _start = values.start;
                              _end = values.end;
                            });
                          },
                        ),
                      ),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(_formatMs(_start)),
                          Text(_formatMs(_end)),
                        ],
                      ),

                      const SizedBox(height: 12),
                      // Preview playback controls
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            iconSize: 48,
                            icon: Icon(
                              _isPlaying
                                  ? Icons.pause_circle
                                  : Icons.play_circle,
                            ),
                            onPressed: _exporting
                                ? null
                                : () async {
                                    if (_isPlaying) {
                                      await _player.pause();
                                      if (mounted)
                                        setState(() => _isPlaying = false);
                                    } else {
                                      await _player.seek(
                                        Duration(milliseconds: _start.round()),
                                      );
                                      await _player.play();
                                      if (mounted)
                                        setState(() => _isPlaying = true);
                                    }
                                  },
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),
                      if (_exporting)
                        LinearProgressIndicator(value: _exportProgress),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: _exporting ? null : _exportTrim,
                        icon: const Icon(Icons.save),
                        label: const Text('Save Trim'),
                      ),
                    ],
                  ),
                ),
              ],
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
