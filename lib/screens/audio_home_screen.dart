import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import '../services/audio_service.dart';
import '../services/audio_cache_service.dart';
import '../services/background_audio_processor.dart';
import 'audio_player_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../main.dart';
import 'dart:ui';
import '../widgets/skeleton_media_card.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme_data.dart';
import '../services/current_audio_context.dart';
import '../services/native_audio_service.dart';

class MediaFileCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final bool isFavourite;
  final VoidCallback onTap;
  final Color overlayColor;
  final String? duration;
  const MediaFileCard({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    required this.isFavourite,
    required this.onTap,
    required this.overlayColor,
    this.duration,
  });

  @override
  State<MediaFileCard> createState() => _MediaFileCardState();
}

class _MediaFileCardState extends State<MediaFileCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 0),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            color: Colors.white.withOpacity(0.13),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF06141B).withOpacity(0.18),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
            border: Border.all(
              width: 1.2,
              style: BorderStyle.solid,
              color: Colors.white.withOpacity(0.18),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Thumbnail/icon
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.white.withOpacity(0.18),
                ),
                child: Icon(
                  widget.icon,
                  size: 32,
                  color: const Color(0xFFCCD0CF),
                ),
              ),
              const SizedBox(width: 16),
              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      widget.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (widget.subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        widget.subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ],
                ),
              ),
              // Favourite icon (top right)
              Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    transitionBuilder: (child, animation) =>
                        ScaleTransition(scale: animation, child: child),
                    child: widget.isFavourite
                        ? Icon(
                            Icons.star_outlined,
                            key: const ValueKey('favorite'),
                            color: const Color(0xFFCCD0CF),
                            size: 24,
                          )
                        : const SizedBox(
                            width: 24,
                            height: 24,
                            key: ValueKey('not_favorite'),
                          ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// For MediaFileCard and ListTile, create a _AnimatedMediaFileCard StatefulWidget:
class _AnimatedMediaFileCard extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final double borderRadius;
  const _AnimatedMediaFileCard({
    required this.child,
    required this.onTap,
    this.borderRadius = 28,
    Key? key,
  }) : super(key: key);
  @override
  State<_AnimatedMediaFileCard> createState() => _AnimatedMediaFileCardState();
}

class _AnimatedMediaFileCardState extends State<_AnimatedMediaFileCard> {
  bool _isPressed = false;
  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _isPressed ? 0.96 : 1.0,
      duration: const Duration(milliseconds: 120),
      child: InkWell(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        onTap: widget.onTap,
        onHighlightChanged: (v) => setState(() => _isPressed = v),
        child: widget.child,
      ),
    );
  }
}

class AudioHomeScreen extends StatefulWidget {
  const AudioHomeScreen({Key? key}) : super(key: key);

  @override
  State<AudioHomeScreen> createState() => _AudioHomeScreenState();
}

class _AudioHomeScreenState extends State<AudioHomeScreen> with RouteAware {
  List<AssetEntity> _audioAssets = [];
  bool _loading = true;
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  bool _showFolders = false;
  Map<String, List<AssetEntity>> _folderMap = {};
  List<String> _folderList = [];
  String? _selectedFolder;
  Set<String> _favourites = {};
  List<String> _playlists = [];
  String? _selectedPlaylist;
  late SharedPreferences _prefs;

  // Filter tabs state
  int _selectedTabIndex =
      0; // 0: All Songs, 1: Playlists, 2: Folder, 3: Album, 4: Artist
  Map<String, List<AssetEntity>> _albumMap = {};
  Map<String, List<AssetEntity>> _artistMap = {};
  List<String> _albumList = [];
  List<String> _artistList = [];
  String? _selectedAlbum;
  String? _selectedArtist;

  // Pagination support
  int _currentPage = 0;
  bool _hasMore = true;
  bool _isLoadingMore = false;
  static const int _pageSize = 50;

  @override
  void initState() {
    super.initState();
    _initPrefs();
    _initializeServices();
    _fetchAllAudios();
    _searchController.addListener(_onSearchChanged);
    // Listen for playback changes to refresh UI indicators if needed
    NativeAudioService.playbackStateStream.listen((event) {
      if (!mounted) return;
      setState(() {});
    });
  }

  Future<void> _initializeServices() async {
    await AudioCacheService.loadPersistedCacheKeys();
    await BackgroundAudioProcessor.initialize();
  }

  void _onSearchChanged() {
    if (mounted) setState(() {});
  }

  void _deduplicateAllPlaylists() {
    for (final playlist in _playlists) {
      final ids = _prefs.getStringList('playlist_$playlist') ?? [];
      final uniqueIds = ids.toSet().toList();
      if (ids.length != uniqueIds.length) {
        _prefs.setStringList('playlist_$playlist', uniqueIds);
      }
    }
  }

  Future<void> _initPrefs() async {
    _prefs = await SharedPreferences.getInstance();

    if (!mounted) return; // Early return if widget is disposed

    _loadFavourites();
    _loadPlaylists();
    _deduplicateAllPlaylists();
  }

  void _loadFavourites() {
    if (!mounted) return; // Early return if widget is disposed

    final favs = _prefs.getStringList('audio_favourites') ?? [];
    if (mounted) {
      setState(() {
        _favourites = favs.toSet();
      });
    }
  }

  void _loadPlaylists() {
    if (!mounted) return; // Early return if widget is disposed

    final keys = _prefs.getStringList('audio_playlists') ?? [];
    if (mounted) {
      setState(() {
        _playlists = keys;
      });
    }
  }

  void _buildAlbumMap(List<AssetEntity> audios) {
    if (!mounted) return; // Early return if widget is disposed

    final Map<String, List<AssetEntity>> albumMap = {};
    for (final audio in audios) {
      // For now, use a placeholder since AssetEntity doesn't have album property
      final album = 'Unknown Album';
      if (!albumMap.containsKey(album)) {
        albumMap[album] = [];
      }
      albumMap[album]!.add(audio);
    }
    if (mounted) {
      setState(() {
        _albumMap = albumMap;
        _albumList = albumMap.keys.toList()..sort();
      });
    }
  }

  void _buildArtistMap(List<AssetEntity> audios) {
    if (!mounted) return; // Early return if widget is disposed

    final Map<String, List<AssetEntity>> artistMap = {};
    for (final audio in audios) {
      // For now, use a placeholder since AssetEntity doesn't have artist property
      final artist = 'Unknown Artist';
      if (!artistMap.containsKey(artist)) {
        artistMap[artist] = [];
      }
      artistMap[artist]!.add(audio);
    }
    if (mounted) {
      setState(() {
        _artistMap = artistMap;
        _artistList = artistMap.keys.toList()..sort();
      });
    }
  }

  List<AssetEntity> _getPlaylistAudios(String playlist) {
    final ids = _prefs.getStringList('playlist_$playlist') ?? [];
    final uniqueIds = ids.toSet().toList();
    // Clean up duplicates in storage
    if (ids.length != uniqueIds.length) {
      _prefs.setStringList('playlist_$playlist', uniqueIds);
    }
    // Only show each audio once
    final seen = <String>{};
    final uniqueAudios = <AssetEntity>[];
    for (final a in _audioAssets) {
      if (uniqueIds.contains(a.id) && !seen.contains(a.id)) {
        seen.add(a.id);
        uniqueAudios.add(a);
      }
    }
    return uniqueAudios;
  }

  List<AssetEntity> _getFilteredAudios() {
    switch (_selectedTabIndex) {
      case 0: // All Songs
        return _audioAssets;
      case 1: // Playlists
        if (_selectedPlaylist != null) {
          return _getPlaylistAudios(_selectedPlaylist!);
        }
        return [];
      case 2: // Folder
        if (_selectedFolder != null && _folderMap[_selectedFolder!] != null) {
          return _folderMap[_selectedFolder!]!;
        }
        return [];
      case 3: // Album
        if (_selectedAlbum != null && _albumMap[_selectedAlbum!] != null) {
          return _albumMap[_selectedAlbum!]!;
        }
        return [];
      case 4: // Artist
        if (_selectedArtist != null && _artistMap[_selectedArtist!] != null) {
          return _artistMap[_selectedArtist!]!;
        }
        return [];
      default:
        return _audioAssets;
    }
  }

  void _showPlaylistSelectDialog() {
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
            decoration: BoxDecoration(gradient: AppThemes.currentMainGradient),
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
                                  Icons.queue_music,
                                  color: Color(0xFFCCD0CF),
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  'Select Playlist',
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
                              _buildPlaylistOption(
                                c,
                                Icons.clear_outlined,
                                'All Audio',
                                'Show all audio files',
                                () {
                                  setState(() => _selectedPlaylist = null);
                                  Navigator.pop(c);
                                },
                              ),
                              for (final playlist in _playlists)
                                _buildPlaylistOption(
                                  c,
                                  Icons.queue_music_outlined,
                                  playlist,
                                  'Playlist',
                                  () {
                                    setState(
                                      () => _selectedPlaylist = playlist,
                                    );
                                    Navigator.pop(c);
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

  Widget _buildPlaylistOption(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
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
                  child: Icon(icon, color: const Color(0xFF9BA8AB), size: 20),
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

  void _showCreatePlaylistDialog() {
    final TextEditingController playlistNameController =
        TextEditingController();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return SafeArea(
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.6,
            ),
            decoration: BoxDecoration(gradient: AppThemes.currentMainGradient),
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
                                  Icons.playlist_add,
                                  color: Color(0xFFCCD0CF),
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  'Create New Playlist',
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
                        const SizedBox(height: 16),
                        // Input field
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: TextField(
                            controller: playlistNameController,
                            autofocus: true,
                            style: GoogleFonts.poppins(
                              color: const Color(0xFFCCD0CF),
                              fontSize: 16,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Enter playlist name',
                              hintStyle: GoogleFonts.poppins(
                                color: const Color(0xFF9BA8AB),
                                fontSize: 16,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Color(0xFF4A5C6A),
                                  width: 1,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Color(0xFF4A5C6A),
                                  width: 1,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Color(0xFFCCD0CF),
                                  width: 2,
                                ),
                              ),
                              filled: true,
                              fillColor: const Color(
                                0xFF1A2A3A,
                              ).withOpacity(0.5),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Buttons
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Row(
                            children: [
                              Expanded(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.1),
                                      width: 1,
                                    ),
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(12),
                                      onTap: () {
                                        Navigator.of(context).pop();
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 16,
                                        ),
                                        child: Center(
                                          child: Text(
                                            'Cancel',
                                            style: GoogleFonts.poppins(
                                              color: const Color(0xFF9BA8AB),
                                              fontSize: 16,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFF4A5C6A,
                                    ).withOpacity(0.3),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: const Color(
                                        0xFFCCD0CF,
                                      ).withOpacity(0.2),
                                      width: 1,
                                    ),
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(12),
                                      onTap: () {
                                        final playlistName =
                                            playlistNameController.text.trim();
                                        if (playlistName.isNotEmpty) {
                                          _createPlaylist(playlistName);
                                          Navigator.of(context).pop();
                                        }
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 16,
                                        ),
                                        child: Center(
                                          child: Text(
                                            'Create',
                                            style: GoogleFonts.poppins(
                                              color: const Color(0xFFCCD0CF),
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
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

  void _createPlaylist(String name) {
    if (!_playlists.contains(name)) {
      setState(() {
        _playlists.add(name);
      });
      _prefs.setStringList('audio_playlists', _playlists);

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Playlist "$name" created successfully!',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
          backgroundColor: const Color(0xFF4A5C6A),
          duration: const Duration(seconds: 2),
        ),
      );
    } else {
      // Show error if playlist already exists
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Playlist "$name" already exists!',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
          backgroundColor: Colors.red.withOpacity(0.8),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Widget _buildFilterTab(String label, int index) {
    final isSelected = _selectedTabIndex == index;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () {
          setState(() {
            _selectedTabIndex = index;
            // Reset selections when switching tabs
            if (label == 'Folder') {
              _selectedFolder = null;
            } else if (label == 'Playlists') {
              _selectedPlaylist = null;
            } else if (label == 'Album') {
              _selectedAlbum = null;
            } else if (label == 'Artist') {
              _selectedArtist = null;
            }
          });
        },
        child: Container(
          width: double.infinity,
          child: Center(
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              style: GoogleFonts.poppins(
                color: isSelected
                    ? const Color(0xFFCCD0CF)
                    : const Color(0xFF9BA8AB),
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                fontSize: 10,
              ),
              child: Text(label),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlaylistCard(String playlist, int count, int index) {
    final overlayColor = index % 2 == 0
        ? const Color(0xFF4A5C6A)
        : const Color(0xFF9BA8AB);

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPlaylist = playlist;
        });
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          color: Colors.white.withOpacity(0.13),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF06141B).withOpacity(0.18),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
          border: Border.all(
            width: 1.2,
            style: BorderStyle.solid,
            color: Colors.white.withOpacity(0.10),
          ),
        ),
        clipBehavior: Clip.hardEdge,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                children: [
                  // Icon
                  Image.asset(
                    playlist == 'Favourite Songs'
                        ? 'assets/favourite_playlist.png'
                        : 'assets/playlist.png',
                    width: 32,
                    height: 32,
                    color: playlist == 'Favourite Songs'
                        ? null
                        : const Color(0xFFCCD0CF),
                  ),
                  const SizedBox(width: 16),
                  // Text content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          playlist == 'Favourite Songs' ? 'Favorite' : playlist,
                          style: GoogleFonts.poppins(
                            color: const Color(0xFFCCD0CF),
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$count Song${count == 1 ? '' : 's'}',
                          style: GoogleFonts.poppins(
                            color: const Color(0xFF9BA8AB),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAlbumCard(String album, int count, int index) {
    final overlayColor = index % 2 == 0
        ? const Color(0xFF4A5C6A)
        : const Color(0xFF9BA8AB);

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedAlbum = album;
        });
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          color: Colors.white.withOpacity(0.13),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF06141B).withOpacity(0.18),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
          border: Border.all(
            width: 1.2,
            style: BorderStyle.solid,
            color: Colors.white.withOpacity(0.10),
          ),
        ),
        clipBehavior: Clip.hardEdge,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.album_outlined,
                    size: 28,
                    color: const Color(0xFFCCD0CF),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    album,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      color: const Color(0xFFCCD0CF),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$count song${count == 1 ? '' : 's'}',
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF9BA8AB),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildArtistCard(String artist, int count, int index) {
    final overlayColor = index % 2 == 0
        ? const Color(0xFF4A5C6A)
        : const Color(0xFF9BA8AB);

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedArtist = artist;
        });
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          color: Colors.white.withOpacity(0.13),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF06141B).withOpacity(0.18),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
          border: Border.all(
            width: 1.2,
            style: BorderStyle.solid,
            color: Colors.white.withOpacity(0.10),
          ),
        ),
        clipBehavior: Clip.hardEdge,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.person_outline,
                    size: 28,
                    color: const Color(0xFFCCD0CF),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    artist,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      color: const Color(0xFFCCD0CF),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$count song${count == 1 ? '' : 's'}',
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF9BA8AB),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_selectedTabIndex) {
      case 0: // All Songs
        return _buildAudioList(_getFilteredAudios());
      case 1: // Playlists
        if (_selectedPlaylist == null) {
          return _buildPlaylistGrid();
        } else {
          return _buildPlaylistSongsList();
        }
      case 2: // Folder
        if (_selectedFolder == null) {
          return _buildFolderGrid();
        } else {
          return _buildFolderSongsList();
        }
      case 3: // Album
        if (_selectedAlbum == null) {
          return _buildAlbumGrid();
        } else {
          return _buildAlbumSongsList();
        }
      case 4: // Artist
        if (_selectedArtist == null) {
          return _buildArtistGrid();
        } else {
          return _buildArtistSongsList();
        }
      default:
        return _buildAudioList(_getFilteredAudios());
    }
  }

  Widget _buildAudioList(List<AssetEntity> audios) {
    if (audios.isEmpty) {
      return Center(
        child: Text(
          'No songs found.',
          style: GoogleFonts.poppins(color: Colors.white),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: audios.length + (_hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == audios.length) {
          // Load more button
          return _buildLoadMoreButton();
        }

        final asset = audios[index];
        return _buildAnimatedAudioCard(asset, index);
      },
    );
  }

  Widget _buildAnimatedAudioCard(AssetEntity asset, int index) {
    return AnimatedOpacity(
      duration: Duration(milliseconds: 200 + (index * 20)),
      opacity: 1.0,
      child: AnimatedSlide(
        duration: Duration(milliseconds: 300 + (index * 30)),
        offset: Offset.zero,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: _buildAudioListCard(asset, index),
        ),
      ),
    );
  }

  Widget _buildLoadMoreButton() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: _isLoadingMore
            ? const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              )
            : ElevatedButton(
                onPressed: _hasMore ? _loadMoreAudios : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4A5C6A).withOpacity(0.3),
                  foregroundColor: const Color(0xFFCCD0CF),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: Text(
                  'Load More',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildAudioListCard(AssetEntity asset, int index) {
    return GestureDetector(
      onTap: () {
        final audios = _getFilteredAudios();
        final initial = audios.indexWhere((a) => a.id == asset.id);
        if (initial >= 0) {
          CurrentAudioContext.setSelection(audios, initial);
        }
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) =>
                AudioPlayerScreen(audios: audios, initialIndex: initial),
          ),
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 0),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              color: Colors.white.withOpacity(0.13),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF06141B).withOpacity(0.18),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
              border: Border.all(
                width: 1.2,
                style: BorderStyle.solid,
                color: Colors.white.withOpacity(0.18),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Thumbnail
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: Colors.white.withOpacity(0.18),
                  ),
                  child: Icon(
                    Icons.music_note_outlined,
                    size: 32,
                    color: const Color(0xFFCCD0CF),
                  ),
                ),
                const SizedBox(width: 16),
                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        asset.title ?? 'Unknown',
                        style: GoogleFonts.poppins(
                          color: const Color(0xFFCCD0CF),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Audio File',
                        style: GoogleFonts.poppins(
                          color: const Color(0xFF9BA8AB),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                // Favourite icon
                Image.asset(
                  'assets/favourite.png',
                  width: 24,
                  height: 24,
                  color: _favourites.contains(asset.id)
                      ? Colors.amber
                      : const Color(0xFF9BA8AB),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlaylistGrid() {
    // Create a list that includes "Favourite Songs" plus user playlists
    final allPlaylists = ['Favourite Songs', ..._playlists];

    return Column(
      children: [
        // Header with title and plus icon
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Playlist(${allPlaylists.length})',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                onPressed: () {
                  _showCreatePlaylistDialog();
                },
                icon: const Icon(Icons.add, color: Colors.white, size: 24),
              ),
            ],
          ),
        ),
        // Playlist list
        Expanded(
          child: allPlaylists.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'No playlists found.',
                        style: GoogleFonts.poppins(
                          color: const Color(0xFF9BA8AB),
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Create playlists to organize your songs.',
                        style: GoogleFonts.poppins(
                          color: const Color(0xFF9BA8AB),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  itemCount: allPlaylists.length,
                  itemBuilder: (context, index) {
                    final playlist = allPlaylists[index];
                    int count;
                    if (playlist == 'Favourite Songs') {
                      count = _favourites.length;
                    } else {
                      count = _getPlaylistAudios(playlist).length;
                    }
                    return TweenAnimationBuilder<double>(
                      duration: Duration(milliseconds: 600 + (index * 50)),
                      curve: Curves.easeOutCubic,
                      tween: Tween<double>(begin: 0.0, end: 1.0),
                      builder: (context, value, child) {
                        return Transform.translate(
                          offset: Offset(0, 20 * (1 - value)),
                          child: Opacity(
                            opacity: value,
                            child: Transform.scale(
                              scale: 0.8 + (0.2 * value),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 6,
                                ),
                                child: _buildPlaylistCard(
                                  playlist,
                                  count,
                                  index,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildPlaylistSongsList() {
    List<AssetEntity> playlistAudios;

    if (_selectedPlaylist == 'Favourite Songs') {
      playlistAudios = _audioAssets
          .where((audio) => _favourites.contains(audio.id))
          .toList();
    } else {
      playlistAudios = _selectedPlaylist != null
          ? _getPlaylistAudios(_selectedPlaylist!)
          : <AssetEntity>[];
    }

    if (playlistAudios.isEmpty) {
      return Center(
        child: Text(
          'No songs in this playlist.',
          style: GoogleFonts.poppins(
            color: const Color(0xFF9BA8AB),
            fontSize: 16,
          ),
        ),
      );
    }

    return Column(
      children: [
        _buildBackToPlaylistsCard(),
        Expanded(child: _buildAudioList(playlistAudios)),
      ],
    );
  }

  Widget _buildBackToPlaylistsCard() {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPlaylist = null;
        });
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF11212D).withOpacity(0.6),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFF253745).withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.arrow_back_outlined,
              color: Color(0xFFCCD0CF),
              size: 24,
            ),
            const SizedBox(width: 12),
            Text(
              'Back to Playlists',
              style: GoogleFonts.poppins(
                color: const Color(0xFFCCD0CF),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFolderGrid() {
    if (_folderList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'No folders found.',
              style: GoogleFonts.poppins(
                color: const Color(0xFF9BA8AB),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Debug: _showFolders=$_showFolders, _folderList.length=${_folderList.length}',
              style: GoogleFonts.poppins(
                color: const Color(0xFF9BA8AB),
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.2,
      ),
      itemCount: _folderList.length,
      itemBuilder: (context, index) {
        final folder = _folderList[index];
        final count = _folderMap[folder]?.length ?? 0;
        return TweenAnimationBuilder<double>(
          duration: Duration(milliseconds: 600 + (index * 50)),
          curve: Curves.easeOutCubic,
          tween: Tween<double>(begin: 0.0, end: 1.0),
          builder: (context, value, child) {
            return Transform.translate(
              offset: Offset(0, 20 * (1 - value)),
              child: Opacity(
                opacity: value,
                child: Transform.scale(
                  scale: 0.8 + (0.2 * value),
                  child: _buildFolderCard(folder, count, index),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFolderCard(String folder, int count, int index) {
    final overlayColor = index % 2 == 0
        ? const Color(0xFF4A5C6A)
        : const Color(0xFF9BA8AB);

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFolder = folder;
        });
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          color: Colors.white.withOpacity(0.13),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF06141B).withOpacity(0.18),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
          border: Border.all(
            width: 1.2,
            style: BorderStyle.solid,
            color: Colors.white.withOpacity(0.10),
          ),
        ),
        clipBehavior: Clip.hardEdge,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/folder.png',
                    width: 28,
                    height: 28,
                    color: const Color(0xFFCCD0CF),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    folder.split(Platform.pathSeparator).last,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      color: const Color(0xFFCCD0CF),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$count song${count == 1 ? '' : 's'}',
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF9BA8AB),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFolderSongsList() {
    final folderAudios =
        _selectedFolder != null && _folderMap[_selectedFolder!] != null
        ? _folderMap[_selectedFolder!]!
        : <AssetEntity>[];

    if (folderAudios.isEmpty) {
      return Center(
        child: Text(
          'No songs in this folder.',
          style: GoogleFonts.poppins(
            color: const Color(0xFF9BA8AB),
            fontSize: 16,
          ),
        ),
      );
    }

    return Column(
      children: [
        _buildBackToFoldersCard(),
        Expanded(child: _buildAudioList(folderAudios)),
      ],
    );
  }

  Widget _buildBackToFoldersCard() {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFolder = null;
        });
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF11212D).withOpacity(0.6),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFF253745).withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.arrow_back_outlined,
              color: Color(0xFFCCD0CF),
              size: 24,
            ),
            const SizedBox(width: 12),
            Text(
              'Back to Folders',
              style: GoogleFonts.poppins(
                color: const Color(0xFFCCD0CF),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlbumGrid() {
    if (_albumList.isEmpty) {
      return Center(
        child: Text(
          'No albums found.',
          style: GoogleFonts.poppins(
            color: const Color(0xFF9BA8AB),
            fontSize: 16,
          ),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.2,
      ),
      itemCount: _albumList.length,
      itemBuilder: (context, index) {
        final album = _albumList[index];
        final count = _albumMap[album]?.length ?? 0;
        return TweenAnimationBuilder<double>(
          duration: Duration(milliseconds: 600 + (index * 50)),
          curve: Curves.easeOutCubic,
          tween: Tween<double>(begin: 0.0, end: 1.0),
          builder: (context, value, child) {
            return Transform.translate(
              offset: Offset(0, 20 * (1 - value)),
              child: Opacity(
                opacity: value,
                child: Transform.scale(
                  scale: 0.8 + (0.2 * value),
                  child: _buildAlbumCard(album, count, index),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildAlbumSongsList() {
    final albumAudios =
        _selectedAlbum != null && _albumMap[_selectedAlbum!] != null
        ? _albumMap[_selectedAlbum!]!
        : <AssetEntity>[];

    if (albumAudios.isEmpty) {
      return Center(
        child: Text(
          'No songs in this album.',
          style: GoogleFonts.poppins(
            color: const Color(0xFF9BA8AB),
            fontSize: 16,
          ),
        ),
      );
    }

    return Column(
      children: [
        _buildBackToAlbumsCard(),
        Expanded(child: _buildAudioList(albumAudios)),
      ],
    );
  }

  Widget _buildBackToAlbumsCard() {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedAlbum = null;
        });
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF11212D).withOpacity(0.6),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFF253745).withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.arrow_back_outlined,
              color: Color(0xFFCCD0CF),
              size: 24,
            ),
            const SizedBox(width: 12),
            Text(
              'Back to Albums',
              style: GoogleFonts.poppins(
                color: const Color(0xFFCCD0CF),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArtistGrid() {
    if (_artistList.isEmpty) {
      return Center(
        child: Text(
          'No artists found.',
          style: GoogleFonts.poppins(
            color: const Color(0xFF9BA8AB),
            fontSize: 16,
          ),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.2,
      ),
      itemCount: _artistList.length,
      itemBuilder: (context, index) {
        final artist = _artistList[index];
        final count = _artistMap[artist]?.length ?? 0;
        return TweenAnimationBuilder<double>(
          duration: Duration(milliseconds: 600 + (index * 50)),
          curve: Curves.easeOutCubic,
          tween: Tween<double>(begin: 0.0, end: 1.0),
          builder: (context, value, child) {
            return Transform.translate(
              offset: Offset(0, 20 * (1 - value)),
              child: Opacity(
                opacity: value,
                child: Transform.scale(
                  scale: 0.8 + (0.2 * value),
                  child: _buildArtistCard(artist, count, index),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildArtistSongsList() {
    final artistAudios =
        _selectedArtist != null && _artistMap[_selectedArtist!] != null
        ? _artistMap[_selectedArtist!]!
        : <AssetEntity>[];

    if (artistAudios.isEmpty) {
      return Center(
        child: Text(
          'No songs by this artist.',
          style: GoogleFonts.poppins(
            color: const Color(0xFF9BA8AB),
            fontSize: 16,
          ),
        ),
      );
    }

    return Column(
      children: [
        _buildBackToArtistsCard(),
        Expanded(child: _buildAudioList(artistAudios)),
      ],
    );
  }

  Widget _buildBackToArtistsCard() {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedArtist = null;
        });
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF11212D).withOpacity(0.6),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFF253745).withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.arrow_back_outlined,
              color: Color(0xFFCCD0CF),
              size: 24,
            ),
            const SizedBox(width: 12),
            Text(
              'Back to Artists',
              style: GoogleFonts.poppins(
                color: const Color(0xFFCCD0CF),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _fetchAllAudios() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _currentPage = 0;
        _hasMore = true;
      });
    }

    final result = await AudioService.fetchAudiosPaginated(
      page: _currentPage,
      pageSize: _pageSize,
    );

    if (!mounted) return; // Early return if widget is disposed

    if (result.permissionState == PermissionState.authorized ||
        result.permissionState == PermissionState.limited) {
      // Ensure unique audio IDs
      final seen = <String>{};
      final uniqueAudios = <AssetEntity>[];
      for (final a in result.audios) {
        if (!seen.contains(a.id)) {
          seen.add(a.id);
          uniqueAudios.add(a);
        }
      }

      if (mounted) {
        setState(() {
          _audioAssets = uniqueAudios;
          _loading = false;
          _hasMore = result.hasMore;
        });
      }

      if (mounted) {
        _buildFolderMap(result.audios);
        _buildAlbumMap(result.audios);
        _buildArtistMap(result.audios);
      }

      // Process metadata in background
      if (uniqueAudios.isNotEmpty) {
        _processMetadataInBackground(uniqueAudios);
      }
    } else {
      if (mounted) {
        setState(() => _loading = false);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Storage permission required.',
              style: GoogleFonts.poppins(),
            ),
          ),
        );
      }
      if (result.permissionState == PermissionState.denied) {
        PhotoManager.openSetting();
      }
    }
  }

  Future<void> _loadMoreAudios() async {
    if (_isLoadingMore || !_hasMore) return;

    if (mounted) {
      setState(() {
        _isLoadingMore = true;
      });
    }

    try {
      final nextPage = _currentPage + 1;
      final result = await AudioService.fetchAudiosPaginated(
        page: nextPage,
        pageSize: _pageSize,
      );

      if (!mounted) return;

      if (result.audios.isNotEmpty) {
        final newAudios = <AssetEntity>[];
        final existingIds = _audioAssets.map((a) => a.id).toSet();

        for (final audio in result.audios) {
          if (!existingIds.contains(audio.id)) {
            newAudios.add(audio);
            existingIds.add(audio.id);
          }
        }

        if (mounted) {
          setState(() {
            _audioAssets.addAll(newAudios);
            _currentPage = nextPage;
            _hasMore = result.hasMore;
            _isLoadingMore = false;
          });
        }

        // Process new metadata in background
        if (newAudios.isNotEmpty) {
          _processMetadataInBackground(newAudios);
        }
      } else {
        if (mounted) {
          setState(() {
            _hasMore = false;
            _isLoadingMore = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
      }
    }
  }

  void _processMetadataInBackground(List<AssetEntity> audios) {
    // Process metadata in background without blocking UI
    BackgroundAudioProcessor.processMultipleAudios(audios).catchError((e) {
      print('Background metadata processing error: $e');
    });
  }

  // Cache management methods
  void _clearCache() {
    AudioCacheService.clearCache();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Cache cleared successfully',
          style: GoogleFonts.poppins(color: Colors.white),
        ),
        backgroundColor: Colors.green,
      ),
    );
  }

  Map<String, dynamic> _getCacheStats() {
    return AudioCacheService.getCacheStats();
  }

  void _showCacheStats() {
    final stats = _getCacheStats();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Cache Statistics'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('File Cache: ${stats['fileCacheSize']} items'),
            Text('Album Art Cache: ${stats['albumArtCacheSize']} items'),
            Text('Metadata Cache: ${stats['metadataCacheSize']} items'),
            Text('Max Cache Size: ${stats['maxCacheSize']} items'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  void _buildFolderMap(List<AssetEntity> assets) async {
    final Map<String, List<AssetEntity>> folderMap = {};

    for (final asset in assets) {
      if (!mounted) return; // Early return if widget is disposed

      final file = await asset.file;
      if (file != null) {
        final dir = file.parent.path;
        folderMap.putIfAbsent(dir, () => []).add(asset);
      }
    }

    if (mounted) {
      setState(() {
        _folderMap = folderMap;
        _folderList = folderMap.keys.toList();
      });
    }
  }

  void _startSearch() {
    if (mounted) {
      setState(() => _isSearching = true);
    }
  }

  void _stopSearch() {
    if (mounted) {
      setState(() {
        _isSearching = false;
        _searchController.clear();
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)! as PageRoute);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    // Only unsubscribe if actually subscribed
    try {
      routeObserver.unsubscribe(this);
    } catch (_) {}
    // Cleanup background processor
    BackgroundAudioProcessor.dispose();
    super.dispose();
  }

  @override
  void didPopNext() {
    // Called when coming back to this screen
    if (mounted) {
      _loadFavourites();
      _loadPlaylists();
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    List<AssetEntity> audiosToShow = _isSearching
        ? _audioAssets.where((asset) {
            final title = asset.title?.toLowerCase() ?? '';
            final q = _searchController.text.toLowerCase();
            return title.contains(q);
          }).toList()
        : _audioAssets;
    if (_selectedPlaylist != null) {
      audiosToShow = _getPlaylistAudios(_selectedPlaylist!);
    }
    final List<AssetEntity> folderAudios =
        _selectedFolder != null && _folderMap[_selectedFolder!] != null
        ? List<AssetEntity>.from(_folderMap[_selectedFolder!]!)
        : <AssetEntity>[];
    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: Theme.of(context).textTheme.bodyLarge,
                decoration: InputDecoration(
                  hintText: 'Search audio...',
                  border: InputBorder.none,
                  hintStyle: Theme.of(context).textTheme.bodyMedium,
                  filled: true,
                  fillColor: Theme.of(
                    context,
                  ).colorScheme.primary.withOpacity(0.18),
                  prefixIcon: Icon(Icons.search_outlined, color: Colors.white),
                ),
              )
            : Text(
                'Audio Browser',
                style: Theme.of(context).textTheme.titleLarge,
              ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: BoxDecoration(gradient: AppThemes.currentMainGradient),
        ),
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        centerTitle: false,
        titleTextStyle: Theme.of(context).textTheme.titleLarge,
        actions: [
          if (_isSearching)
            IconButton(
              icon: Icon(Icons.close_outlined, color: Colors.white),
              onPressed: _stopSearch,
            )
          else ...[
            IconButton(
              icon: Image.asset(
                'assets/search.png',
                width: 24,
                height: 24,
                color: Colors.white,
              ),
              onPressed: _startSearch,
            ),
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert, color: Colors.white),
              onSelected: (value) {
                switch (value) {
                  case 'cache_stats':
                    _showCacheStats();
                    break;
                  case 'clear_cache':
                    _clearCache();
                    break;
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'cache_stats',
                  child: Row(
                    children: [
                      Icon(Icons.info_outline),
                      const SizedBox(width: 8),
                      Text('Cache Info'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'clear_cache',
                  child: Row(
                    children: [
                      Icon(Icons.clear_all),
                      const SizedBox(width: 8),
                      Text('Clear Cache'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(gradient: AppThemes.currentMainGradient),
        child: Padding(
          padding: EdgeInsets.only(
            top: kToolbarHeight + MediaQuery.of(context).padding.top,
          ),
          child: _loading
              ? const SkeletonList(itemCount: 8)
              : Column(
                  children: [
                    // Filter Tabs
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.1),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final tabWidth = constraints.maxWidth / 5;
                            return Stack(
                              children: [
                                // Sliding indicator
                                AnimatedPositioned(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                  left: _selectedTabIndex * tabWidth,
                                  top: 0,
                                  bottom: 0,
                                  child: Container(
                                    width: tabWidth,
                                    decoration: BoxDecoration(
                                      color: const Color(
                                        0xFF4A5C6A,
                                      ).withOpacity(0.4),
                                      borderRadius: BorderRadius.circular(24),
                                      border: Border.all(
                                        color: const Color(
                                          0xFFCCD0CF,
                                        ).withOpacity(0.3),
                                        width: 1,
                                      ),
                                    ),
                                  ),
                                ),
                                // Tab buttons
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildFilterTab('All Songs', 0),
                                    ),
                                    Expanded(
                                      child: _buildFilterTab('Playlists', 1),
                                    ),
                                    Expanded(
                                      child: _buildFilterTab('Folder', 2),
                                    ),
                                    Expanded(
                                      child: _buildFilterTab('Album', 3),
                                    ),
                                    Expanded(
                                      child: _buildFilterTab('Artist', 4),
                                    ),
                                  ],
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                    // Content based on selected tab
                    Expanded(child: _buildTabContent()),
                  ],
                ),
        ),
      ),
    );
  }
}
