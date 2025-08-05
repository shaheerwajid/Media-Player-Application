import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import '../services/native_audio_service.dart';
import 'audio_screen_standalone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/native_album_art.dart';
import 'dart:typed_data';
import 'package:share_plus/share_plus.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';

class AudioPlayerScreen extends StatefulWidget {
  final List<AssetEntity> audios;
  final int initialIndex;
  const AudioPlayerScreen({
    Key? key,
    required this.audios,
    required this.initialIndex,
  }) : super(key: key);

  @override
  State<AudioPlayerScreen> createState() => _AudioPlayerScreenState();
}

class _AudioPlayerScreenState extends State<AudioPlayerScreen> {
  late int _currentIndex;
  bool _isAudioPlayerReady = false;
  String _playbackState = 'paused';
  int _positionMs = 0;
  int? _durationMs;
  late final Stream<Map<String, dynamic>> _stateStream;
  late final StreamSubscription _sub;
  double _playbackSpeed = 1.0;
  bool _isFavourite = false;
  Set<String> _favourites = {};
  late SharedPreferences _prefs;
  List<String> _playlists = [];
  String? _currentPlaylist;
  final TextEditingController _playlistController = TextEditingController();
  String _loopMode = 'order'; // 'order', 'loop', 'shuffle', 'stop'

  // Cache for album art future
  Future<Uint8List?>? _albumArtFuture;
  File? _albumArtFile;

  @override
  void initState() {
    super.initState();
    _initPrefs();
    _currentIndex = widget.initialIndex;
    _stateStream = NativeAudioService.playbackStateStream;
    _sub = _stateStream.listen((event) async {
      if (!mounted) return;
      // Handle native next/previous actions
      if (event.containsKey('action')) {
        if (event['action'] == 'next') {
          _playNext();
        } else if (event['action'] == 'previous') {
          _playPrevious();
        }
        return;
      }
      // Auto-play next track on completion
      if (event['state'] == 'completed') {
        _handlePlaybackModeOnComplete();
        return;
      }
      setState(() {
        _playbackState = event['state'] ?? 'paused';
        _positionMs = event['position'] ?? 0;
        _durationMs = event['duration'];
      });
    });
    _startCurrent();
  }

  Future<void> _initPrefs() async {
    _prefs = await SharedPreferences.getInstance();
    _loadFavourites();
    _loadPlaylists();
  }

  void _loadFavourites() {
    final favs = _prefs.getStringList('audio_favourites') ?? [];
    setState(() {
      _favourites = favs.toSet();
      _isFavourite = _favourites.contains(widget.audios[_currentIndex].id);
    });
  }

  void _toggleFavourite() {
    final id = widget.audios[_currentIndex].id;
    final favs = _prefs.getStringList('audio_favourites') ?? [];
    if (_favourites.contains(id)) {
      favs.remove(id);
    } else {
      favs.add(id);
    }
    _prefs.setStringList('audio_favourites', favs);
    setState(() {
      _favourites = favs.toSet();
      _isFavourite = _favourites.contains(id);
    });

    // Show animated checkmark feedback when adding to favorites
    if (_favourites.contains(id)) {
      _showCheckmarkFeedback(context);
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
            key: const ValueKey('audio_favorite_checkmark'),
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

  void _loadPlaylists() {
    final keys = _prefs.getStringList('audio_playlists') ?? [];
    setState(() {
      _playlists = keys;
    });
  }

  void _addToPlaylist(String playlist) {
    final id = widget.audios[_currentIndex].id;
    final list = _prefs.getStringList('playlist_$playlist') ?? [];
    if (!list.contains(id)) {
      list.add(id);
      _prefs.setStringList('playlist_$playlist', list);

      // Show animated checkmark feedback
      _showPlaylistCheckmarkFeedback(context);
    }
  }

  void _removeFromPlaylist(String playlist) {
    final id = widget.audios[_currentIndex].id;
    final list = _prefs.getStringList('playlist_$playlist') ?? [];
    if (list.contains(id)) {
      list.remove(id);
      _prefs.setStringList('playlist_$playlist', list);
    }
  }

  void _createPlaylist(String name) {
    if (!_playlists.contains(name)) {
      _playlists.add(name);
      _prefs.setStringList('audio_playlists', _playlists);
      _prefs.setStringList('playlist_$name', []);
      setState(() {});
      _loadPlaylists();
    }
  }

  void _showPlaylistDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (c) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _playlistController,
                                decoration: const InputDecoration(
                                  hintText: 'New playlist name',
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(
                                    vertical: 8,
                                    horizontal: 12,
                                  ),
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.check),
                              onPressed: () {
                                final newPlaylist = _playlistController.text
                                    .trim();
                                if (newPlaylist.isNotEmpty) {
                                  _createPlaylist(newPlaylist);
                                  _playlistController.clear();
                                  Navigator.pop(c);
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                      for (final playlist in _playlists)
                        ListTile(
                          leading: const Icon(Icons.queue_music),
                          title: Text(playlist),
                          trailing: IconButton(
                            icon: Icon(
                              (_prefs.getStringList('playlist_$playlist') ?? [])
                                      .contains(widget.audios[_currentIndex].id)
                                  ? Icons.check_box
                                  : Icons.check_box_outline_blank,
                            ),
                            onPressed: () {
                              final inPlaylist =
                                  (_prefs.getStringList('playlist_$playlist') ??
                                          [])
                                      .contains(
                                        widget.audios[_currentIndex].id,
                                      );
                              if (inPlaylist) {
                                _removeFromPlaylist(playlist);
                              } else {
                                _addToPlaylist(playlist);
                              }
                              setModalState(() {});
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _startCurrent() async {
    final file = await widget.audios[_currentIndex].file;
    if (file != null) {
      await NativeAudioService.startAudio(file.path, 0);
      setState(() {
        _isAudioPlayerReady = true;
      });
      _playbackSpeed = await NativeAudioService.getPlaybackSpeed();
    }
  }

  Future<void> _playNext() async {
    if (_currentIndex < widget.audios.length - 1) {
      _currentIndex++;
      await _startCurrent();
    }
  }

  Future<void> _playPrevious() async {
    if (_currentIndex > 0) {
      _currentIndex--;
      await _startCurrent();
    }
  }

  void _setLoopMode(String mode) {
    setState(() {
      _loopMode = mode;
    });
  }

  Future<void> _handlePlaybackModeOnComplete() async {
    final audios = widget.audios;
    if (_loopMode == 'order') {
      if (_currentIndex < audios.length - 1) {
        _currentIndex++;
        final file = await audios[_currentIndex].file;
        if (file != null) {
          await NativeAudioService.playNextAudio(file.path, 0);
          setState(() {
            _isAudioPlayerReady = true;
          });
          _playbackSpeed = await NativeAudioService.getPlaybackSpeed();
        }
      }
      // else: do nothing (end of playlist)
    } else if (_loopMode == 'loop') {
      final file = await audios[_currentIndex].file;
      if (file != null) {
        await NativeAudioService.playNextAudio(file.path, 0);
        setState(() {
          _isAudioPlayerReady = true;
        });
        _playbackSpeed = await NativeAudioService.getPlaybackSpeed();
      }
    } else if (_loopMode == 'shuffle') {
      final random = (audios.length > 1)
          ? (List<int>.generate(audios.length, (i) => i)..remove(_currentIndex))
          : [0];
      random.shuffle();
      final nextIndex = random.first;
      _currentIndex = nextIndex;
      final file = await audios[_currentIndex].file;
      if (file != null) {
        await NativeAudioService.playNextAudio(file.path, 0);
        setState(() {
          _isAudioPlayerReady = true;
        });
        _playbackSpeed = await NativeAudioService.getPlaybackSpeed();
      }
    } else if (_loopMode == 'stop') {
      // Do nothing, stop playback
    }
  }

  void _showOptions() {
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
                              _buildOptionItem(
                                c,
                                Icons.repeat,
                                'Playback Mode',
                                _loopMode == 'order'
                                    ? 'Play in Order'
                                    : _loopMode == 'loop'
                                    ? 'Loop Current'
                                    : _loopMode == 'shuffle'
                                    ? 'Shuffle'
                                    : 'Stop After Current',
                                () {
                                  Navigator.pop(c);
                                  _showPlaybackModeDialog();
                                },
                              ),
                              _buildOptionItem(
                                c,
                                Icons.speed,
                                'Playback Speed',
                                '${_playbackSpeed}x',
                                () {
                                  Navigator.pop(c);
                                  _showSpeedSelect();
                                },
                              ),
                              _buildOptionItem(
                                c,
                                Icons.phone,
                                'Set as Ringtone',
                                'Set current audio as ringtone',
                                () async {
                                  Navigator.pop(c);
                                  final file =
                                      await widget.audios[_currentIndex].file;
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
                                              ? Colors.green
                                              : Colors.red,
                                        ),
                                      );
                                    }
                                  }
                                },
                              ),
                              _buildOptionItem(
                                c,
                                Icons.share,
                                'Share Audio',
                                'Share this audio file',
                                () async {
                                  Navigator.pop(c);
                                  final file =
                                      await widget.audios[_currentIndex].file;
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

  Widget _buildOptionItem(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap, [
    Color? iconColor,
  ]) {
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
                  child: Icon(
                    icon,
                    color: iconColor ?? const Color(0xFF9BA8AB),
                    size: 20,
                  ),
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
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: const Color(0xFF9BA8AB),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  color: Color(0xFF9BA8AB),
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRadioOption(String value, String title, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: _loopMode == value
            ? const Color(0xFF4A5C6A).withOpacity(0.4)
            : Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _loopMode == value
              ? const Color(0xFFCCD0CF).withOpacity(0.3)
              : Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            _setLoopMode(value);
            Navigator.pop(context);
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _loopMode == value
                        ? const Color(0xFFCCD0CF).withOpacity(0.2)
                        : Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: _loopMode == value
                        ? const Color(0xFFCCD0CF)
                        : const Color(0xFF9BA8AB),
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFFCCD0CF),
                    ),
                  ),
                ),
                if (_loopMode == value)
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFCCD0CF).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Color(0xFFCCD0CF),
                      size: 14,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showPlaybackModeDialog() {
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
                                  Icons.repeat,
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
                              _buildRadioOption(
                                'order',
                                'Play in Order',
                                Icons.playlist_play,
                              ),
                              _buildRadioOption(
                                'loop',
                                'Loop Current',
                                Icons.repeat_one,
                              ),
                              _buildRadioOption(
                                'shuffle',
                                'Shuffle',
                                Icons.shuffle,
                              ),
                              _buildRadioOption(
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

  void _showSpeedSelect() {
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
                                  Icons.speed,
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
                              for (var s in [0.5, 0.75, 1.0, 1.25, 1.5, 2.0])
                                _buildSpeedOption(c, s),
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
          onTap: () async {
            await NativeAudioService.setPlaybackSpeed(speed);
            setState(() {
              _playbackSpeed = speed;
            });
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
                    Icons.speed,
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

  void _updateAlbumArtFuture(File? file) {
    if (_albumArtFile?.path != file?.path) {
      _albumArtFile = file;
      _albumArtFuture = file != null
          ? NativeAlbumArt.getAlbumArt(file.path)
          : Future.value(null);
    }
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    final minutes = two(d.inMinutes.remainder(60));
    final seconds = two(d.inSeconds.remainder(60));
    return d.inHours > 0
        ? '${two(d.inHours)}:$minutes:$seconds'
        : '$minutes:$seconds';
  }

  void _showPlaylistCheckmarkFeedback(BuildContext context) {
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
            Icons.playlist_add_check,
            key: const ValueKey('playlist_checkmark'),
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

  @override
  Widget build(BuildContext context) {
    final currentAudio = widget.audios[_currentIndex];
    String? lyrics =
        'Sample lyrics for this audio.\nMore lines...\n(Integrate real lyrics here)';
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.audios[_currentIndex].title ?? 'Audio'),
        actions: [
          IconButton(
            icon: Icon(
              _isFavourite ? Icons.star : Icons.star_border,
              color: Colors.amber,
            ),
            tooltip: _isFavourite ? 'Remove Favourite' : 'Add Favourite',
            onPressed: _toggleFavourite,
          ),
          IconButton(
            icon: const Icon(Icons.playlist_add),
            tooltip: 'Add to Playlist',
            onPressed: _showPlaylistDialog,
          ),
        ],
      ),
      body: Container(
        color: Colors.black,
        child: FutureBuilder<File?>(
          future: currentAudio.file,
          builder: (context, fileSnapshot) {
            if (!fileSnapshot.hasData || fileSnapshot.data == null) {
              return AudioScreenStandalone(
                isAudioPlayerReady: _isAudioPlayerReady,
                formatDuration: _formatDuration,
                playbackState: _playbackState,
                playbackPositionMs: _positionMs,
                totalDurationMs: _durationMs,
                onNext: _playNext,
                onPrevious: _playPrevious,
                onMoreOptions: _showOptions,
                onPlayPause: () async {
                  if (_playbackState == 'playing') {
                    await NativeAudioService.pauseAudio();
                  } else {
                    await NativeAudioService.playAudio();
                  }
                },
                onSeek: (ms) async {
                  await NativeAudioService.seekTo(ms);
                },
                albumArt: null,
                lyrics: lyrics,
              );
            }
            final file = fileSnapshot.data;
            final filePath = file?.path;
            print(
              'AudioPlayerScreen: filePath for album art: '
              ' [33m [1m$filePath [0m',
            );
            _updateAlbumArtFuture(file);
            return FutureBuilder<Uint8List?>(
              future: _albumArtFuture,
              builder: (context, artSnapshot) {
                ImageProvider? albumArt;
                if (artSnapshot.connectionState == ConnectionState.done) {
                  if (artSnapshot.hasData && artSnapshot.data != null) {
                    print(
                      'AudioPlayerScreen: Album art fetched for $filePath, bytes: '
                      ' [32m [1m${artSnapshot.data!.length} [0m',
                    );
                    albumArt = MemoryImage(artSnapshot.data!);
                  } else {
                    print(
                      'AudioPlayerScreen: No album art found for $filePath',
                    );
                  }
                }
                return AudioScreenStandalone(
                  isAudioPlayerReady: _isAudioPlayerReady,
                  formatDuration: _formatDuration,
                  playbackState: _playbackState,
                  playbackPositionMs: _positionMs,
                  totalDurationMs: _durationMs,
                  onNext: _playNext,
                  onPrevious: _playPrevious,
                  onMoreOptions: _showOptions,
                  onPlayPause: () async {
                    if (_playbackState == 'playing') {
                      await NativeAudioService.pauseAudio();
                    } else {
                      await NativeAudioService.playAudio();
                    }
                  },
                  onSeek: (ms) async {
                    await NativeAudioService.seekTo(ms);
                  },
                  albumArt: albumArt,
                  lyrics: lyrics,
                );
              },
            );
          },
        ),
      ),
    );
  }
}
