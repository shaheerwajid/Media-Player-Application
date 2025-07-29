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
      builder: (c) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.repeat),
                title: const Text('Playback Mode'),
                subtitle: Text(
                  _loopMode == 'order'
                      ? 'Play in Order'
                      : _loopMode == 'loop'
                      ? 'Loop Current'
                      : _loopMode == 'shuffle'
                      ? 'Shuffle'
                      : 'Stop After Current',
                ),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Playback Mode'),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          RadioListTile<String>(
                            value: 'order',
                            groupValue: _loopMode,
                            title: const Text('Play in Order'),
                            onChanged: (v) {
                              _setLoopMode('order');
                              Navigator.pop(context);
                            },
                          ),
                          RadioListTile<String>(
                            value: 'loop',
                            groupValue: _loopMode,
                            title: const Text('Loop Current'),
                            onChanged: (v) {
                              _setLoopMode('loop');
                              Navigator.pop(context);
                            },
                          ),
                          RadioListTile<String>(
                            value: 'shuffle',
                            groupValue: _loopMode,
                            title: const Text('Shuffle'),
                            onChanged: (v) {
                              _setLoopMode('shuffle');
                              Navigator.pop(context);
                            },
                          ),
                          RadioListTile<String>(
                            value: 'stop',
                            groupValue: _loopMode,
                            title: const Text('Stop After Current'),
                            onChanged: (v) {
                              _setLoopMode('stop');
                              Navigator.pop(context);
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.speed),
                title: const Text('Playback speed'),
                subtitle: Text('${_playbackSpeed}x'),
                onTap: () {
                  Navigator.pop(c);
                  _showSpeedSelect();
                },
              ),
              ListTile(
                leading: const Icon(Icons.phone),
                title: const Text('Set as ringtone'),
                onTap: () async {
                  Navigator.pop(c);
                  final file = await widget.audios[_currentIndex].file;
                  if (file != null) {
                    final success = await NativeAudioService.setAsRingtone(
                      file.path,
                    );
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            success ? 'Ringtone set' : 'Failed to set ringtone',
                          ),
                        ),
                      );
                    }
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.share, color: Colors.blue),
                title: const Text('Share'),
                onTap: () async {
                  Navigator.pop(c);
                  final file = await widget.audios[_currentIndex].file;
                  if (file == null) return;
                  await Share.shareXFiles([
                    XFile(file.path),
                  ], text: 'Check out this audio!');
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showSpeedSelect() {
    showModalBottomSheet(
      context: context,
      builder: (c) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var s in [0.5, 0.75, 1.0, 1.25, 1.5, 2.0])
                ListTile(
                  title: Text('${s}x'),
                  onTap: () async {
                    await NativeAudioService.setPlaybackSpeed(s);
                    setState(() {
                      _playbackSpeed = s;
                    });
                    Navigator.pop(c);
                  },
                ),
            ],
          ),
        );
      },
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
