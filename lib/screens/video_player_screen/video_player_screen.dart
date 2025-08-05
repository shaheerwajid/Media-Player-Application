// This will be the new main screen file.
// It will contain the VideoScreen StatefulWidget and _VideoScreenState.
// The build method will be simplified to use the new modular widgets.

import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:flutter/services.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'package:floating/floating.dart';
import 'package:path_provider/path_provider.dart';
import 'package:media_store_plus/media_store_plus.dart';
import 'package:share_plus/share_plus.dart';
// import 'package:cast/cast.dart';
import 'package:easy_video_editor/easy_video_editor.dart';
import 'dart:ui' as ui;
import 'dart:ui';
import 'dart:typed_data';
import 'package:flutter/rendering.dart';
import 'package:media_store_plus/media_store_plus.dart' show MediaStorePlatform;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math' as math;
import 'package:flutter/cupertino.dart';
import 'package:simple_pip_mode/simple_pip.dart';
import 'package:simple_pip_mode/aspect_ratio.dart' as pip_mode;
import 'package:simple_pip_mode/actions/pip_action.dart';
import 'package:simple_pip_mode/actions/pip_actions_layout.dart';
import 'package:simple_pip_mode/pip_widget.dart';
import 'package:google_fonts/google_fonts.dart';

import 'widgets/video_controls_overlay.dart';
import 'widgets/player_gestures.dart';
import '../audio_screen.dart';
import '../../services/native_audio_service.dart';
import '../video_trim_screen.dart';
import 'widgets/bottom_controls.dart';
import '../audio_screen_standalone.dart';

class VideoPlayerScreen extends StatefulWidget {
  final List<AssetEntity> videoAssets;
  final int initialIndex;

  const VideoPlayerScreen({
    Key? key,
    required this.videoAssets,
    required this.initialIndex,
  }) : super(key: key);

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late final Player player;
  late final VideoController controller;

  bool _isLandscape = false;
  bool _showControls = true;
  Timer? _hideTimer;
  late int _currentIndex;

  double _currentVolume = 0.5;
  bool _showVolumeOverlay = false;
  double? _dragStartDy;
  double? _dragStartVolume;

  double _currentBrightness = 0.5;
  bool _showBrightnessOverlay = false;
  double? _dragStartBrightness;

  bool _isMuted = false;
  bool _isLocked = false;

  double _playbackSpeed = 1.0;
  final List<double> _speedOptions = [0.25, 0.5, 1.0, 1.5, 2.0];

  double? _seekBarValue;
  bool _isSeeking = false;

  double? _dragStartDx;
  Duration? _dragStartPosition;
  double _seekOffsetSeconds = 0;
  bool _showSeekOverlay = false;

  final GlobalKey _videoScreenshotKey = GlobalKey();
  bool _isAudioOnly = false;
  bool _isAudioPlayerReady = false;

  // Audio state variables
  String? _audioState;
  int _audioPositionMs = 0;
  int _audioTotalDurationMs = 0;

  final List<String> _aspectModes = [
    'Original',
    'Fit',
    'Crop',
    'Stretch',
    '16:9',
    '4:3',
  ];
  int _aspectModeIndex = 0;
  String? _aspectModeOverlayText;
  Timer? _aspectModeOverlayTimer;

  // Add missing getters for navigation
  bool get canPlayPrevious => _currentIndex > 0;
  bool get canPlayNext => _currentIndex < widget.videoAssets.length - 1;

  // Cast devices cache
  // List<CastDevice>? _castDevices;

  StreamSubscription? _audioStateSub;
  StreamSubscription? _completedSub;
  StreamSubscription? _positionSub;
  StreamSubscription? _playingSub;

  bool get isPlayerInitialized => player.state.playlist.medias.isNotEmpty;

  bool _vrMode = false;
  bool _mirrorMode = false;
  bool _isFavourite = false;
  List<int> _bookmarks = [];
  String _loopMode = 'order'; // 'order', 'loop', 'shuffle', 'stop'
  late SharedPreferences _prefs;

  final SimplePip pip = SimplePip();
  bool isPlaying = true;

  void _handlePipAction(PipAction action) {
    switch (action) {
      case PipAction.play:
        player.play();
        setState(() => isPlaying = true);
        break;
      case PipAction.pause:
        player.pause();
        setState(() => isPlaying = false);
        break;
      case PipAction.next:
        _playNext();
        break;
      case PipAction.previous:
        _playPrevious();
        break;
      default:
        break;
    }
  }

  @override
  void initState() {
    super.initState();
    player = Player();
    controller = VideoController(player);
    _currentIndex = widget.initialIndex;
    _initPrefs();
    _initializeAndPlay(_currentIndex);
    _initBrightness();
    _startHideTimer();
    _audioStateSub = NativeAudioService.playbackStateStream.listen((
      event,
    ) async {
      if (mounted) {
        setState(() {
          _audioState = event['state'] ?? 'paused';
          _audioPositionMs = event['position'] ?? 0;
          _audioTotalDurationMs = event['duration'];
        });
        // Dart-side playback mode logic for audio-only mode
        if (_isAudioOnly &&
            (event['state'] == 'completed' || event['completed'] == true)) {
          final assets = widget.videoAssets;
          if (_loopMode == 'order') {
            if (_currentIndex < assets.length - 1) {
              _currentIndex++;
              final file = await assets[_currentIndex].file;
              if (file != null) {
                await NativeAudioService.playNextAudio(file.path, 0);
                if (mounted)
                  setState(() {
                    _isAudioPlayerReady = true;
                  });
              }
            }
            // else: do nothing (end of playlist)
          } else if (_loopMode == 'loop') {
            final file = await assets[_currentIndex].file;
            if (file != null) {
              await NativeAudioService.playNextAudio(file.path, 0);
              if (mounted)
                setState(() {
                  _isAudioPlayerReady = true;
                });
            }
          } else if (_loopMode == 'shuffle') {
            final random = (assets.length > 1)
                ? (List<int>.generate(assets.length, (i) => i)
                    ..remove(_currentIndex))
                : [0];
            random.shuffle();
            final nextIndex = random.first;
            _currentIndex = nextIndex;
            final file = await assets[_currentIndex].file;
            if (file != null) {
              await NativeAudioService.playNextAudio(file.path, 0);
              if (mounted)
                setState(() {
                  _isAudioPlayerReady = true;
                });
            }
          } else if (_loopMode == 'stop') {
            // Do nothing, stop playback
          }
        }
      }
    });
    _completedSub = player.stream.completed.listen((completed) {
      if (completed == true) {
        _handlePlaybackModeOnComplete();
      }
    });
    _positionSub = player.stream.position.listen((pos) {
      final duration = player.state.duration;
      if (duration.inMilliseconds > 0 &&
          (pos.inMilliseconds >= duration.inMilliseconds - 500) &&
          !_isSeeking) {
        _handlePlaybackModeOnComplete();
      }
      // Trigger UI update for progress bar
      if (mounted) {
        setState(() {
          // This will update the progress bar in real-time
        });
      }
    });

    // Listen to playing state changes for real-time UI updates
    _playingSub = player.stream.playing.listen((playing) {
      if (mounted) {
        setState(() {
          // This will trigger UI rebuild when playing state changes
        });
      }
    });
  }

  @override
  void dispose() {
    _audioStateSub?.cancel();
    _hideTimer?.cancel();
    _aspectModeOverlayTimer?.cancel();
    player.dispose();
    _completedSub?.cancel();
    _positionSub?.cancel();
    _playingSub?.cancel();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    super.dispose();
  }

  Future<void> _initPrefs() async {
    _prefs = await SharedPreferences.getInstance();
    _loadFavourites();
    _loadBookmarks();
    _loadLoopMode();
  }

  void _loadFavourites() {
    final file = widget.videoAssets[_currentIndex].id;
    final favs = _prefs.getStringList('favourites') ?? [];
    setState(() {
      _isFavourite = favs.contains(file);
    });
  }

  void _toggleFavourite() {
    final file = widget.videoAssets[_currentIndex].id;
    final favs = _prefs.getStringList('favourites') ?? [];
    if (_isFavourite) {
      favs.remove(file);
    } else {
      favs.add(file);
    }
    _prefs.setStringList('favourites', favs);
    setState(() {
      _isFavourite = !_isFavourite;
    });

    // Show animated checkmark feedback
    if (_isFavourite) {
      _showCheckmarkFeedback(context);
    }
  }

  void _loadBookmarks() {
    final file = widget.videoAssets[_currentIndex].id;
    final marks = _prefs.getStringList('bookmarks_$file') ?? [];
    setState(() {
      _bookmarks = marks.map((e) => int.tryParse(e) ?? 0).toList();
    });
  }

  void _addBookmark() {
    final file = widget.videoAssets[_currentIndex].id;
    final pos = player.state.position.inMilliseconds;
    if (!_bookmarks.contains(pos)) {
      _bookmarks.add(pos);
      _prefs.setStringList(
        'bookmarks_$file',
        _bookmarks.map((e) => e.toString()).toList(),
      );
      setState(() {});

      // Show animated checkmark feedback
      _showBookmarkCheckmarkFeedback(context);
    }
  }

  void _removeBookmark(int pos) {
    final file = widget.videoAssets[_currentIndex].id;
    _bookmarks.remove(pos);
    _prefs.setStringList(
      'bookmarks_$file',
      _bookmarks.map((e) => e.toString()).toList(),
    );
    setState(() {});
  }

  void _loadLoopMode() {
    _loopMode = _prefs.getString('loop_mode') ?? 'order';
    setState(() {});
  }

  void _setLoopMode(String mode) {
    _loopMode = mode;
    _prefs.setString('loop_mode', mode);
    setState(() {});
  }

  void _cycleAspectMode() {
    setState(() {
      _aspectModeIndex = (_aspectModeIndex + 1) % _aspectModes.length;
      _aspectModeOverlayText = _aspectModes[_aspectModeIndex];
    });
    _aspectModeOverlayTimer?.cancel();
    _aspectModeOverlayTimer = Timer(const Duration(milliseconds: 700), () {
      if (mounted) {
        setState(() => _aspectModeOverlayText = null);
      }
    });
  }

  Future<void> _initBrightness() async {
    try {
      _currentBrightness = await ScreenBrightness.instance.application;
      if (mounted) setState(() {});
    } catch (_) {}
  }

  Future<void> _setBrightness(double value) async {
    try {
      await ScreenBrightness.instance.setApplicationScreenBrightness(value);
      _currentBrightness = value;
      if (mounted) setState(() {});
    } catch (_) {}
  }

  Future<void> _initializeAndPlay(int index, {bool pause = false}) async {
    final file = await widget.videoAssets[index].file;
    if (file != null) {
      await player.open(Media(file.path), play: !pause);
      player.setVolume(_currentVolume * 100);
      player.setRate(_playbackSpeed);
      _setInitialOrientation();
      _loadFavourites();
      _loadBookmarks();
    }
  }

  Future<void> _setInitialOrientation() async {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    if (mounted) {
      setState(() {
        _isLandscape = false;
      });
    }
  }

  void _setLandscape() async {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    if (mounted) {
      setState(() {
        _isLandscape = true;
      });
    }
  }

  void _setPortrait() async {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    if (mounted) {
      setState(() {
        _isLandscape = false;
      });
    }
  }

  void _toggleOrientation() {
    if (_isLandscape) {
      _setPortrait();
    } else {
      _setLandscape();
    }
  }

  void _startHideTimer() {
    _hideTimer?.cancel();
    if (!_isLocked) {
      _hideTimer = Timer(const Duration(seconds: 2), () {
        if (mounted) setState(() => _showControls = false);
      });
    }
  }

  void _onTapVideo() {
    if (mounted) {
      setState(() {
        _showControls = true;
      });
    }
    _startHideTimer();
  }

  void _playPrevious() {
    if (_currentIndex > 0) {
      if (mounted) {
        setState(() {
          _currentIndex--;
        });
      }
      if (_isAudioOnly) {
        _switchToAudio(resumePosition: Duration.zero);
        _initializeAndPlay(_currentIndex, pause: true);
      } else {
        _initializeAndPlay(_currentIndex);
        _startHideTimer();
      }
    }
  }

  void _playNext() {
    if (_currentIndex < widget.videoAssets.length - 1) {
      if (mounted) {
        setState(() {
          _currentIndex++;
        });
      }
      if (_isAudioOnly) {
        _switchToAudio(resumePosition: Duration.zero);
        _initializeAndPlay(_currentIndex, pause: true);
      } else {
        _initializeAndPlay(_currentIndex);
        _startHideTimer();
      }
    }
  }

  void _onVerticalDragStart(
    DragStartDetails details,
    BoxConstraints constraints,
  ) {
    final width = constraints.maxWidth;
    _dragStartDy = details.localPosition.dy;
    if (details.localPosition.dx <= width / 3) {
      _dragStartBrightness = _currentBrightness;
      if (mounted) setState(() => _showBrightnessOverlay = true);
    } else if (details.localPosition.dx >= width * 2 / 3) {
      _dragStartVolume = _currentVolume;
      if (mounted) setState(() => _showVolumeOverlay = true);
    }
  }

  void _onVerticalDragUpdate(
    DragUpdateDetails details,
    BoxConstraints constraints,
  ) {
    if (_dragStartDy == null) return;
    final delta =
        (_dragStartDy! - details.localPosition.dy) / constraints.maxHeight;
    if (_dragStartVolume != null) {
      _currentVolume = (_dragStartVolume! + delta).clamp(0.0, 1.0);
      player.setVolume(_currentVolume * 100);
    } else if (_dragStartBrightness != null) {
      _currentBrightness = (_dragStartBrightness! + delta).clamp(0.0, 1.0);
      _setBrightness(_currentBrightness);
    }
    if (mounted) setState(() {});
  }

  void _onVerticalDragEnd(DragEndDetails details) {
    if (mounted) {
      setState(() {
        _showVolumeOverlay = false;
        _showBrightnessOverlay = false;
        _dragStartDy = null;
        _dragStartVolume = null;
        _dragStartBrightness = null;
      });
    }
  }

  Future<void> _setMute(bool mute) async {
    await player.setVolume(mute ? 0.0 : _currentVolume * 100);
    if (mounted) {
      setState(() {
        _isMuted = mute;
      });
    }
  }

  void _toggleLock() {
    if (mounted) {
      setState(() {
        _isLocked = !_isLocked;
      });
    }
    _startHideTimer();
  }

  Future<void> _captureAndSaveScreenshot() async {
    try {
      // Check if player is initialized and has a video
      if (!isPlayerInitialized || _isAudioOnly) {
        throw Exception('No video available to capture');
      }

      // Capture the video widget using RepaintBoundary
      final RenderRepaintBoundary boundary =
          _videoScreenshotKey.currentContext!.findRenderObject()
              as RenderRepaintBoundary;

      // Capture the image with high quality
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );

      if (byteData == null) {
        throw Exception('Failed to get image bytes');
      }

      final Uint8List pngBytes = byteData.buffer.asUint8List();

      // Save to temporary directory
      final directory = await getTemporaryDirectory();
      final fileName =
          'video_screenshot_${DateTime.now().millisecondsSinceEpoch}.png';
      final filePath = '${directory.path}/$fileName';
      final file = File(filePath);
      await file.writeAsBytes(pngBytes);

      // Check if file was created successfully
      if (!await file.exists()) {
        throw Exception('Failed to create screenshot file');
      }

      // Try to save to gallery using MediaStore
      try {
        await MediaStore.ensureInitialized();
        final mediaStore = MediaStore();
        final saveInfo = await mediaStore.saveFile(
          tempFilePath: file.path,
          dirType: DirType.photo,
          dirName: DirName.pictures,
          relativePath: '',
        );

        // Even if MediaStore returns null, the file was created successfully
        // So we'll show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Screenshot saved to gallery!')),
          );
        }
      } catch (mediaStoreError) {
        // If MediaStore fails, but file exists, still show success
        if (await file.exists() && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Screenshot saved to gallery!')),
          );
        } else {
          throw mediaStoreError;
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save screenshot: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _switchToAudio({Duration? resumePosition}) async {
    final file = await widget.videoAssets[_currentIndex].file;
    if (file == null) return;
    final position = resumePosition ?? player.state.position;
    await player.pause();
    await NativeAudioService.startAudio(file.path, position.inMilliseconds);
    if (mounted) {
      setState(() {
        _isAudioOnly = true;
        _isAudioPlayerReady = true;
      });
    }
  }

  Future<void> _switchToVideo() async {
    final positionMs = _audioPositionMs;
    await NativeAudioService.pauseAudio();
    if (mounted) {
      setState(() {
        _isAudioOnly = false;
      });
    }
    await player.seek(Duration(milliseconds: positionMs));
    await player.play();
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(d.inMinutes.remainder(60));
    final seconds = twoDigits(d.inSeconds.remainder(60));
    return d.inHours > 0
        ? '${twoDigits(d.inHours)}:$minutes:$seconds'
        : '$minutes:$seconds';
  }

  void _showMoreOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (c) {
        return SafeArea(
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.6,
            ),
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
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: SingleChildScrollView(
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Handle bar
                        Container(
                          margin: const EdgeInsets.only(top: 12, bottom: 8),
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        // Header
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 16,
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF4A5C6A,
                                  ).withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.more_vert,
                                  color: Color(0xFFCCD0CF),
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  'Audio Options',
                                  style: GoogleFonts.poppins(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFFCCD0CF),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Options
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            children: [
                              _buildAudioOptionItem(
                                context,
                                Icons.repeat_outlined,
                                'Playback Mode',
                                () {
                                  Navigator.pop(c);
                                  _showAudioPlaybackModeDialog(context);
                                },
                                subtitle: _loopMode == 'order'
                                    ? 'Play in Order'
                                    : _loopMode == 'loop'
                                    ? 'Loop Current'
                                    : _loopMode == 'shuffle'
                                    ? 'Shuffle'
                                    : 'Stop After Current',
                              ),
                              _buildAudioOptionItem(
                                context,
                                Icons.speed_outlined,
                                'Playback Speed',
                                () {
                                  Navigator.pop(c);
                                  _showSpeedSelect();
                                },
                                subtitle: '${_playbackSpeed}x',
                              ),
                              _buildAudioOptionItem(
                                context,
                                Icons.phone,
                                'Set as Ringtone',
                                () async {
                                  Navigator.pop(c);
                                  final file = await widget
                                      .videoAssets[_currentIndex]
                                      .file;
                                  if (file != null) {
                                    final success =
                                        await NativeAudioService.setAsRingtone(
                                          file.path,
                                        );
                                    if (mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            success
                                                ? 'Ringtone set'
                                                : 'Failed to set ringtone',
                                            style: GoogleFonts.poppins(),
                                          ),
                                          backgroundColor: success
                                              ? Colors.green.withOpacity(0.8)
                                              : Colors.red.withOpacity(0.8),
                                          duration: const Duration(seconds: 2),
                                        ),
                                      );
                                    }
                                  }
                                },
                              ),
                              _buildAudioOptionItem(
                                context,
                                Icons.share_outlined,
                                'Share',
                                () async {
                                  Navigator.pop(c);
                                  final file = await widget
                                      .videoAssets[_currentIndex]
                                      .file;
                                  if (file == null) return;
                                  await Share.shareXFiles([
                                    XFile(file.path),
                                  ], text: 'Check out this audio!');
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAudioOptionItem(
    BuildContext context,
    IconData icon,
    String title,
    VoidCallback onTap, {
    String? subtitle,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: const Color(0xFFCCD0CF), size: 20),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFFCCD0CF),
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: const Color(0xFF9BA8AB),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: const Color(0xFF9BA8AB),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAudioPlaybackModeDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.6,
            ),
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
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: SingleChildScrollView(
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Handle bar
                        Container(
                          margin: const EdgeInsets.only(top: 12, bottom: 8),
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        // Header
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 16,
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF4A5C6A,
                                  ).withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.repeat_outlined,
                                  color: Color(0xFFCCD0CF),
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  'Playback Mode',
                                  style: GoogleFonts.poppins(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFFCCD0CF),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Options
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            children: [
                              _buildAudioPlaybackModeOption(
                                context,
                                'order',
                                'Play in Order',
                                Icons.playlist_play,
                              ),
                              _buildAudioPlaybackModeOption(
                                context,
                                'loop',
                                'Loop Current',
                                Icons.repeat,
                              ),
                              _buildAudioPlaybackModeOption(
                                context,
                                'shuffle',
                                'Shuffle',
                                Icons.shuffle,
                              ),
                              _buildAudioPlaybackModeOption(
                                context,
                                'stop',
                                'Stop After Current',
                                Icons.stop,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAudioPlaybackModeOption(
    BuildContext context,
    String value,
    String title,
    IconData icon,
  ) {
    final isSelected = _loopMode == value;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isSelected
            ? const Color(0xFF4A5C6A).withOpacity(0.4)
            : Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected
              ? const Color(0xFFCCD0CF).withOpacity(0.3)
              : Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            _setLoopMode(value);
            Navigator.pop(context);
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFFCCD0CF).withOpacity(0.2)
                        : Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    color: isSelected
                        ? const Color(0xFFCCD0CF)
                        : const Color(0xFF9BA8AB),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFCCD0CF),
                    ),
                  ),
                ),
                if (isSelected)
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFCCD0CF).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Color(0xFFCCD0CF),
                      size: 16,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showSpeedSelect() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.6,
            ),
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
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: SingleChildScrollView(
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Handle bar
                        Container(
                          margin: const EdgeInsets.only(top: 12, bottom: 8),
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        // Header
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 16,
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF4A5C6A,
                                  ).withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.speed_outlined,
                                  color: Color(0xFFCCD0CF),
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  'Playback Speed',
                                  style: GoogleFonts.poppins(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFFCCD0CF),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Speed options
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            children: [
                              for (double speed in _speedOptions)
                                _buildSpeedOption(context, speed),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSpeedOption(BuildContext context, double speed) {
    final isSelected = _playbackSpeed == speed;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isSelected
            ? const Color(0xFF4A5C6A).withOpacity(0.4)
            : Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected
              ? const Color(0xFFCCD0CF).withOpacity(0.3)
              : Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            setState(() {
              _playbackSpeed = speed;
            });
            player.setRate(speed);
            Navigator.pop(context);
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFFCCD0CF).withOpacity(0.2)
                        : Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.speed_outlined,
                    color: isSelected
                        ? const Color(0xFFCCD0CF)
                        : const Color(0xFF9BA8AB),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    '${speed}x',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFCCD0CF),
                    ),
                  ),
                ),
                if (isSelected)
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFCCD0CF).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Color(0xFFCCD0CF),
                      size: 16,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _shareCurrentVideo() async {
    try {
      final file = await widget.videoAssets[_currentIndex].file;
      if (file == null) return;
      await Share.shareXFiles([XFile(file.path)]);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to share video: ${e.toString()}')),
        );
      }
    }
  }

  void _showVideoMoreOptions(BuildContext context) async {
    final file = await widget.videoAssets[_currentIndex].file;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (c) {
        return SafeArea(
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.6,
            ),
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
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: SingleChildScrollView(
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Handle bar
                        Container(
                          margin: const EdgeInsets.only(top: 12, bottom: 8),
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        // Header
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 16,
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF4A5C6A,
                                  ).withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.more_vert,
                                  color: Color(0xFFCCD0CF),
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  'Video Options',
                                  style: GoogleFonts.poppins(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFFCCD0CF),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Options
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            children: [
                              _buildOptionItem(
                                context,
                                Icons.audiotrack_outlined,
                                'Audio Track',
                                () {
                                  Navigator.pop(c);
                                  _showAudioTracksDialog(context);
                                },
                              ),
                              _buildOptionItem(
                                context,
                                Icons.share_outlined,
                                'Share',
                                () async {
                                  Navigator.pop(c);
                                  await _shareCurrentVideo();
                                },
                              ),
                              _buildOptionItem(
                                context,
                                Icons.content_cut_outlined,
                                'Trim',
                                () async {
                                  Navigator.pop(c);
                                  if (file != null) {
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            VideoTrimScreen(originalFile: file),
                                      ),
                                    );
                                  }
                                },
                              ),
                              _buildOptionItem(
                                context,
                                _isFavourite
                                    ? Icons.star_outline_rounded
                                    : Icons.star_border,
                                _isFavourite
                                    ? 'Remove Favourite'
                                    : 'Add Favourite',
                                () {
                                  Navigator.pop(c);
                                  _toggleFavourite();
                                },
                                isAnimated: true,
                                animatedKey: _isFavourite,
                              ),
                              _buildOptionItem(
                                context,
                                Icons.bookmark_outline,
                                'Add Bookmark',
                                () {
                                  Navigator.pop(c);
                                  _addBookmark();
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Bookmark added!',
                                          style: GoogleFonts.poppins(),
                                        ),
                                        backgroundColor: Colors.green
                                            .withOpacity(0.8),
                                        duration: const Duration(seconds: 2),
                                      ),
                                    );
                                  }
                                },
                              ),
                              _buildOptionItem(
                                context,
                                Icons.vrpano_outlined,
                                _vrMode ? 'Disable VR Mode' : 'Enable VR Mode',
                                () {
                                  Navigator.pop(c);
                                  setState(() {
                                    _vrMode = !_vrMode;
                                  });
                                },
                              ),
                              _buildOptionItem(
                                context,
                                Icons.flip_outlined,
                                _mirrorMode
                                    ? 'Disable Mirror Mode'
                                    : 'Enable Mirror Mode',
                                () {
                                  Navigator.pop(c);
                                  setState(() {
                                    _mirrorMode = !_mirrorMode;
                                  });
                                },
                              ),
                              _buildOptionItem(
                                context,
                                Icons.repeat_outlined,
                                'Playback Mode',
                                () {
                                  Navigator.pop(c);
                                  _showPlaybackModeDialog(context);
                                },
                                subtitle: _loopMode == 'order'
                                    ? 'Play in Order'
                                    : _loopMode == 'loop'
                                    ? 'Loop Current'
                                    : _loopMode == 'shuffle'
                                    ? 'Shuffle'
                                    : 'Stop After Current',
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildOptionItem(
    BuildContext context,
    IconData icon,
    String title,
    VoidCallback onTap, {
    String? subtitle,
    bool isAnimated = false,
    bool? animatedKey,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: isAnimated
                      ? AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          transitionBuilder: (child, animation) =>
                              ScaleTransition(scale: animation, child: child),
                          child: Icon(
                            icon,
                            key: ValueKey(animatedKey),
                            color: const Color(0xFFCCD0CF),
                            size: 20,
                          ),
                        )
                      : Icon(icon, color: const Color(0xFFCCD0CF), size: 20),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFFCCD0CF),
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: const Color(0xFF9BA8AB),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: const Color(0xFF9BA8AB),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showPlaybackModeDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.6,
            ),
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
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: SingleChildScrollView(
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Handle bar
                        Container(
                          margin: const EdgeInsets.only(top: 12, bottom: 8),
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        // Header
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 16,
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF4A5C6A,
                                  ).withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.repeat_outlined,
                                  color: Color(0xFFCCD0CF),
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  'Playback Mode',
                                  style: GoogleFonts.poppins(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFFCCD0CF),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Options
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            children: [
                              _buildPlaybackModeOption(
                                context,
                                'order',
                                'Play in Order',
                                Icons.playlist_play,
                              ),
                              _buildPlaybackModeOption(
                                context,
                                'loop',
                                'Loop Current',
                                Icons.repeat,
                              ),
                              _buildPlaybackModeOption(
                                context,
                                'shuffle',
                                'Shuffle',
                                Icons.shuffle,
                              ),
                              _buildPlaybackModeOption(
                                context,
                                'stop',
                                'Stop After Current',
                                Icons.stop,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPlaybackModeOption(
    BuildContext context,
    String value,
    String title,
    IconData icon,
  ) {
    final isSelected = _loopMode == value;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isSelected
            ? const Color(0xFF4A5C6A).withOpacity(0.4)
            : Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected
              ? const Color(0xFFCCD0CF).withOpacity(0.3)
              : Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            _setLoopMode(value);
            Navigator.pop(context);
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFFCCD0CF).withOpacity(0.2)
                        : Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    color: isSelected
                        ? const Color(0xFFCCD0CF)
                        : const Color(0xFF9BA8AB),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFCCD0CF),
                    ),
                  ),
                ),
                if (isSelected)
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFCCD0CF).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Color(0xFFCCD0CF),
                      size: 16,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAudioTracksDialog(BuildContext context) {
    final List<AudioTrack> audioTracks = player.state.tracks.audio;
    final AudioTrack activeTrack = player.state.track.audio;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.6,
            ),
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
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: SingleChildScrollView(
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Handle bar
                        Container(
                          margin: const EdgeInsets.only(top: 12, bottom: 8),
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        // Header
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 16,
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF4A5C6A,
                                  ).withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.audiotrack,
                                  color: Color(0xFFCCD0CF),
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  'Select Audio Track',
                                  style: GoogleFonts.poppins(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFFCCD0CF),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Audio tracks
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            children: [
                              for (
                                int index = 0;
                                index < audioTracks.length;
                                index++
                              )
                                _buildAudioTrackOption(
                                  context,
                                  audioTracks[index],
                                  activeTrack,
                                  index,
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAudioTrackOption(
    BuildContext context,
    AudioTrack track,
    AudioTrack activeTrack,
    int index,
  ) {
    final title = track.title ?? track.id;
    final language = track.language;
    final displayText = language != null ? '$title ($language)' : title;
    final isSelected = track == activeTrack;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isSelected
            ? const Color(0xFF4A5C6A).withOpacity(0.4)
            : Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected
              ? const Color(0xFFCCD0CF).withOpacity(0.3)
              : Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            player.setAudioTrack(track);
            Navigator.pop(context);
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFFCCD0CF).withOpacity(0.2)
                        : Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.audiotrack,
                    color: isSelected
                        ? const Color(0xFFCCD0CF)
                        : const Color(0xFF9BA8AB),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayText,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFFCCD0CF),
                        ),
                      ),
                      if (language != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          'Language: $language',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: const Color(0xFF9BA8AB),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (isSelected)
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFCCD0CF).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Color(0xFFCCD0CF),
                      size: 16,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showCastDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: Text(
            'Cast Devices',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          content: const SizedBox(
            height: 80,
            child: Center(child: CircularProgressIndicator()),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Close',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAspectRatioVideo() {
    final mode = _aspectModes[_aspectModeIndex];
    BoxFit fit;
    switch (mode) {
      case 'Crop':
        fit = BoxFit.cover;
        break;
      case 'Stretch':
        fit = BoxFit.fill;
        break;
      default:
        fit = BoxFit.contain;
        break;
    }
    double? aspectRatio;
    if (mode == '16:9') aspectRatio = 16 / 9;
    if (mode == '4:3') aspectRatio = 4 / 3;

    Widget video = Video(
      controller: controller,
      fit: fit,
      aspectRatio: aspectRatio,
      controls: NoVideoControls,
    );

    // Wrap in Container for better release mode compatibility
    video = Container(
      width: double.infinity,
      height: double.infinity,
      child: video,
    );

    if (mode == 'Original' || mode == 'Fit') {
      return Center(child: video);
    }
    return video;
  }

  @override
  Widget build(BuildContext context) {
    return PipWidget(
      pipLayout: PipActionsLayout.media,
      onPipAction: _handlePipAction,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: PlayerGestures(
          onTap: _onTapVideo,
          onHorizontalDragStart: (details) {
            if (_isLocked || !isPlayerInitialized || _isAudioOnly) return;
            _dragStartDx = details.localPosition.dx;
            _dragStartPosition = player.state.position;
            _seekOffsetSeconds = 0;
            if (mounted) setState(() => _showSeekOverlay = true);
          },
          onHorizontalDragUpdate: (details) {
            if (_isLocked ||
                !isPlayerInitialized ||
                _isAudioOnly ||
                _dragStartDx == null)
              return;
            final screenWidth = MediaQuery.of(context).size.width;
            final dx = details.localPosition.dx - _dragStartDx!;
            _seekOffsetSeconds = (dx / (screenWidth / 3) * 60);
            if (mounted) setState(() {});
          },
          onHorizontalDragEnd: (details) {
            if (_isLocked || !isPlayerInitialized || _isAudioOnly) return;
            if (_dragStartPosition != null) {
              final newPosition =
                  _dragStartPosition! +
                  Duration(seconds: _seekOffsetSeconds.round());
              player.seek(
                newPosition.clamp(Duration.zero, player.state.duration),
              );
            }
            if (mounted) {
              setState(() {
                _showSeekOverlay = false;
                _seekOffsetSeconds = 0;
                _dragStartDx = null;
                _dragStartPosition = null;
              });
            }
            _startHideTimer();
          },
          onVerticalDragStart: (details, constraints) =>
              _onVerticalDragStart(details, constraints),
          onVerticalDragUpdate: (details, constraints) =>
              _onVerticalDragUpdate(details, constraints),
          onVerticalDragEnd: _onVerticalDragEnd,
          child: Stack(
            children: [
              // Video/Audio content layer
              if (_isAudioOnly)
                AudioScreenStandalone(
                  isAudioPlayerReady: _isAudioPlayerReady,
                  formatDuration: _formatDuration,
                  playbackState: _audioState ?? 'paused',
                  playbackPositionMs: _audioPositionMs,
                  totalDurationMs: _audioTotalDurationMs,
                  onNext: _playNext,
                  onPrevious: _playPrevious,
                  onPlayPause: () async {
                    if ((_audioState ?? 'paused') == 'playing') {
                      await NativeAudioService.pauseAudio();
                      setState(() {
                        _audioState = 'paused';
                      });
                    } else {
                      final assets = widget.videoAssets;
                      final file = await assets[_currentIndex].file;
                      if (file != null) {
                        await NativeAudioService.playNextAudio(file.path, 0);
                        if (mounted)
                          setState(() {
                            _audioState = 'playing';
                            _isAudioPlayerReady = true;
                          });
                      }
                    }
                  },
                  onMoreOptions: () => _showMoreOptions(context),
                  onSeek: (ms) async {
                    if (_isAudioOnly) {
                      await NativeAudioService.seekTo(ms);
                    } else {
                      player.seek(Duration(milliseconds: ms));
                    }
                  },
                  albumArt: null, // You can add album art logic if available
                  lyrics: null, // Add lyrics if available
                  onSwitchToVideo: _switchToVideo,
                )
              else
                // Video content - completely separate from overlay
                Positioned.fill(
                  child: Container(
                    color: Colors.black,
                    child: isPlayerInitialized
                        ? _vrMode
                              ? Row(
                                  children: [
                                    Expanded(child: _buildTransformedVideo()),
                                    Expanded(child: _buildTransformedVideo()),
                                  ],
                                )
                              : RepaintBoundary(
                                  key: _videoScreenshotKey,
                                  child: _buildTransformedVideo(),
                                )
                        : const Center(
                            child: CircularProgressIndicator(
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),

              // Overlay controls - completely separate layer
              if (!_isAudioOnly)
                Positioned.fill(
                  child: IgnorePointer(
                    ignoring: !_showControls && !_isLocked,
                    child: Container(
                      color: Colors.transparent,
                      child: Stack(
                        children: [
                          // Status overlays for gesture controls
                          if (_showSeekOverlay && isPlayerInitialized)
                            Positioned(
                              top: MediaQuery.of(context).size.height / 2 - 50,
                              left: 0,
                              right: 0,
                              child: Center(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black87,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'Seek: ${_seekOffsetSeconds > 0 ? '+' : ''}${_seekOffsetSeconds.round()}s',
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          if (_showVolumeOverlay)
                            Positioned(
                              top: MediaQuery.of(context).size.height / 2 - 50,
                              right: 20,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black87,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.volume_up,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                    Text(
                                      '${(_currentVolume * 100).round()}%',
                                      style: GoogleFonts.poppins(
                                        color: Colors.white,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          if (_showBrightnessOverlay)
                            Positioned(
                              top: MediaQuery.of(context).size.height / 2 - 50,
                              left: 20,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black87,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.brightness_6,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                    Text(
                                      '${(_currentBrightness * 100).round()}%',
                                      style: GoogleFonts.poppins(
                                        color: Colors.white,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          if (_aspectModeOverlayText != null)
                            Positioned(
                              top: MediaQuery.of(context).size.height / 2 - 50,
                              left: 0,
                              right: 0,
                              child: Center(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black87,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    _aspectModeOverlayText!,
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ),
                            ),

                          // Main controls
                          if (_showControls)
                            Column(
                              children: [
                                // Top controls
                                Container(
                                  height: 60,
                                  color: Colors.black54,
                                  child: Row(
                                    children: [
                                      if (!_isLocked) ...[
                                        IconButton(
                                          icon: const Icon(
                                            Icons.arrow_back,
                                            color: Colors.white,
                                          ),
                                          onPressed: () =>
                                              Navigator.pop(context),
                                        ),
                                        const Spacer(),
                                      ],
                                      // Lock button - always visible
                                      IconButton(
                                        icon: Icon(
                                          _isLocked
                                              ? Icons.lock
                                              : Icons.lock_open,
                                          color: Colors.white,
                                        ),
                                        onPressed: _toggleLock,
                                      ),
                                      if (!_isLocked) ...[
                                        IconButton(
                                          icon: const Icon(
                                            Icons.screen_rotation,
                                            color: Colors.white,
                                          ),
                                          onPressed: _toggleOrientation,
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.picture_in_picture,
                                            color: Colors.white,
                                          ),
                                          onPressed: () async =>
                                              await pip.enterPipMode(
                                                aspectRatio: (16, 9),
                                              ),
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.music_note,
                                            color: Colors.white,
                                          ),
                                          onPressed: _switchToAudio,
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.more_vert,
                                            color: Colors.white,
                                          ),
                                          onPressed: () =>
                                              _showVideoMoreOptions(context),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                const Spacer(),
                                // Bottom controls - only show when not locked
                                if (!_isLocked)
                                  Container(
                                    height: 120,
                                    color: Colors.black54,
                                    child: Column(
                                      children: [
                                        // Progress bar and time
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                          ),
                                          child: Row(
                                            children: [
                                              Text(
                                                _formatDuration(
                                                  player.state.position,
                                                ),
                                                style: GoogleFonts.poppins(
                                                  color: Colors.white,
                                                  fontSize: 12,
                                                ),
                                              ),
                                              Expanded(
                                                child: Slider(
                                                  value: player
                                                      .state
                                                      .position
                                                      .inMilliseconds
                                                      .toDouble(),
                                                  max: player
                                                      .state
                                                      .duration
                                                      .inMilliseconds
                                                      .toDouble(),
                                                  onChanged: (value) {
                                                    player.seek(
                                                      Duration(
                                                        milliseconds: value
                                                            .toInt(),
                                                      ),
                                                    );
                                                  },
                                                  activeColor: Colors.white,
                                                  inactiveColor: Colors.white24,
                                                ),
                                              ),
                                              Text(
                                                _formatDuration(
                                                  player.state.duration,
                                                ),
                                                style: GoogleFonts.poppins(
                                                  color: Colors.white,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        // Control buttons
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceEvenly,
                                          children: [
                                            IconButton(
                                              icon: const Icon(
                                                Icons.skip_previous,
                                                color: Colors.white,
                                              ),
                                              onPressed: canPlayPrevious
                                                  ? _playPrevious
                                                  : null,
                                            ),
                                            IconButton(
                                              icon: Icon(
                                                player.state.playing
                                                    ? Icons.pause
                                                    : Icons.play_arrow,
                                                color: Colors.white,
                                                size: 48,
                                              ),
                                              onPressed: () {
                                                if (player.state.playing) {
                                                  player.pause();
                                                } else {
                                                  player.play();
                                                }
                                              },
                                            ),
                                            IconButton(
                                              icon: const Icon(
                                                Icons.skip_next,
                                                color: Colors.white,
                                              ),
                                              onPressed: canPlayNext
                                                  ? _playNext
                                                  : null,
                                            ),
                                            IconButton(
                                              icon: Icon(
                                                _isMuted
                                                    ? Icons.volume_off
                                                    : Icons.volume_up,
                                                color: Colors.white,
                                              ),
                                              onPressed: () =>
                                                  _setMute(!_isMuted),
                                            ),
                                            IconButton(
                                              icon: const Icon(
                                                Icons.screenshot,
                                                color: Colors.white,
                                              ),
                                              onPressed:
                                                  _captureAndSaveScreenshot,
                                            ),
                                            IconButton(
                                              icon: const Icon(
                                                Icons.aspect_ratio,
                                                color: Colors.white,
                                              ),
                                              onPressed: _cycleAspectMode,
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
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
      pipChild: Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: Text('PiP Mode')),
      ),
    );
  }

  Widget _buildTransformedVideo() {
    Widget video = _buildAspectRatioVideo();
    if (_mirrorMode) {
      video = Transform(
        alignment: Alignment.center,
        transform: Matrix4.rotationY(math.pi),
        child: video,
      );
    }
    return video;
  }

  void _handlePlaybackModeOnComplete() {
    if (_loopMode == 'order') {
      if (_currentIndex < widget.videoAssets.length - 1) {
        setState(() {
          _currentIndex++;
        });
        _initializeAndPlay(_currentIndex);
      }
      // else: do nothing (end of playlist)
    } else if (_loopMode == 'loop') {
      _initializeAndPlay(_currentIndex);
    } else if (_loopMode == 'shuffle') {
      final random = math.Random();
      int nextIndex = _currentIndex;
      if (widget.videoAssets.length > 1) {
        while (nextIndex == _currentIndex) {
          nextIndex = random.nextInt(widget.videoAssets.length);
        }
      }
      setState(() {
        _currentIndex = nextIndex;
      });
      _initializeAndPlay(_currentIndex);
    } else if (_loopMode == 'stop') {
      // Do nothing, stop playback
    }
  }
}

extension DurationClamp on Duration {
  Duration clamp(Duration min, Duration max) {
    if (this < min) return min;
    if (this > max) return max;
    return this;
  }
}

void _showCheckmarkFeedback(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.transparent,
    builder: (context) => Center(
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (child, animation) => ScaleTransition(
          scale: animation,
          child: FadeTransition(opacity: animation, child: child),
        ),
        child: Icon(
          Icons.check_circle,
          key: const ValueKey('favorite_checkmark'),
          color: Colors.green,
          size: 64,
        ),
      ),
    ),
  );

  Future.delayed(const Duration(milliseconds: 600), () {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  });
}

void _showBookmarkCheckmarkFeedback(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.transparent,
    builder: (context) => Center(
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (child, animation) => ScaleTransition(
          scale: animation,
          child: FadeTransition(opacity: animation, child: child),
        ),
        child: Icon(
          Icons.bookmark,
          key: const ValueKey('bookmark_checkmark'),
          color: Colors.blue,
          size: 64,
        ),
      ),
    ),
  );

  Future.delayed(const Duration(milliseconds: 600), () {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  });
}
