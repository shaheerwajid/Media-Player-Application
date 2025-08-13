import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:io';
import 'dart:typed_data';
import 'package:photo_manager/photo_manager.dart';
import '../services/video_service.dart';
import 'video_player_screen/video_player_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/skeleton_media_card.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme_data.dart';
import '../widgets/unified_card.dart';

class VideoScreen extends StatefulWidget {
  const VideoScreen({Key? key}) : super(key: key);

  @override
  State<VideoScreen> createState() => _VideoScreenState();
}

class _VideoScreenState extends State<VideoScreen> {
  int _selectedTabIndex = 0; // Default to Videos tab
  List<AssetEntity> _videoAssets = [];
  bool _loading = true;
  Set<String> _favourites = {};
  late SharedPreferences _prefs;
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  List<AssetEntity> _filteredVideos = [];
  List<AssetEntity> _historyVideos = [];
  bool _showFolders = false;
  bool _isGridView = false;
  Map<String, List<AssetEntity>> _folderMap = {};
  List<String> _folderList = [];
  String? _selectedFolder;
  List<String> _playlists = [];
  String? _selectedPlaylist;
  String? _sortBy = 'date';
  bool _sortAscending = false;
  List<AssetEntity> _sortedVideos = [];
  bool _isSorting = false;
  bool _folderMapBuilt = false; // Track if folder map is built
  bool _videosLoaded = false; // Track if videos are already loaded

  @override
  void initState() {
    super.initState();
    _initPrefs();
    if (!_videosLoaded) {
      _fetchAllVideos();
    }
    _searchController.addListener(_filterVideos);
  }

  Future<void> _initPrefs() async {
    _prefs = await SharedPreferences.getInstance();

    if (!mounted) return; // Early return if widget is disposed

    _loadFavourites();
    _loadHistory();
    _loadPlaylists();
  }

  void _loadFavourites() {
    if (!mounted) return; // Early return if widget is disposed

    // Load both video_favourites and favourites for compatibility
    final videoFavs = _prefs.getStringList('video_favourites') ?? [];
    final favs = _prefs.getStringList('favourites') ?? [];
    final allFavs = {...videoFavs, ...favs};

    if (mounted) {
      setState(() {
        _favourites = allFavs.toSet();
      });
    }
  }

  void _loadHistory() {
    if (!mounted) return; // Early return if widget is disposed

    final historyIds = _prefs.getStringList('video_history') ?? [];
    if (historyIds.isNotEmpty) {
      if (mounted) {
        setState(() {
          // Use a Map to ensure unique entries by ID
          final Map<String, AssetEntity> uniqueVideos = {};
          for (final asset in _videoAssets) {
            if (historyIds.contains(asset.id)) {
              uniqueVideos[asset.id] = asset;
            }
          }
          // Convert back to list and maintain history order
          _historyVideos = historyIds
              .map((id) => uniqueVideos[id])
              .where((asset) => asset != null)
              .cast<AssetEntity>()
              .toList();
        });
      }
    }
  }

  void _loadPlaylists() {
    if (!mounted) return; // Early return if widget is disposed

    final keys = _prefs.getStringList('video_playlists') ?? [];
    if (mounted) {
      setState(() {
        _playlists = keys;
        // Add default "Favourite Videos" playlist if it doesn't exist
        if (!_playlists.contains('Favourite Videos')) {
          _playlists.add('Favourite Videos');
          _prefs.setStringList('video_playlists', _playlists);
        }
      });
    }
  }

  List<AssetEntity> _getPlaylistVideos(String playlist) {
    if (playlist == 'Favourite Videos') {
      // For Favourite Videos playlist, use the favorites list
      final Set<String> seenIds = <String>{};
      final List<AssetEntity> favoriteVideos = [];
      for (final asset in _videoAssets) {
        if (_favourites.contains(asset.id) && !seenIds.contains(asset.id)) {
          seenIds.add(asset.id);
          favoriteVideos.add(asset);
        }
      }
      return favoriteVideos;
    }

    final ids = _prefs.getStringList('playlist_$playlist') ?? [];
    final List<AssetEntity> playlistVideos = [];

    // Ensure unique IDs
    final uniqueIds = ids.toSet().toList();
    _prefs.setStringList('playlist_$playlist', uniqueIds);

    final Set<String> seenIds = <String>{};
    for (final asset in _videoAssets) {
      if (uniqueIds.contains(asset.id) && !seenIds.contains(asset.id)) {
        seenIds.add(asset.id);
        playlistVideos.add(asset);
      }
    }
    return playlistVideos;
  }

  void _createPlaylist(String name) {
    if (!_playlists.contains(name)) {
      _playlists.add(name);
      _prefs.setStringList('video_playlists', _playlists);
      _prefs.setStringList('playlist_$name', []);
      setState(() {});
      _loadPlaylists();
    }
  }

  void _showPlaylistSelectDialog() {
    showModalBottomSheet(
      context: context,
      builder: (c) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.clear_outlined),
                title: const Text('All Videos'),
                onTap: () {
                  setState(() => _selectedPlaylist = null);
                  Navigator.pop(c);
                },
              ),
              for (final playlist in _playlists)
                ListTile(
                  leading: Image.asset(
                    'assets/favourite.png',
                    width: 24,
                    height: 24,
                    color: const Color(0xFFCCD0CF),
                  ),
                  title: Text(playlist),
                  onTap: () {
                    setState(() => _selectedPlaylist = playlist);
                    Navigator.pop(c);
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  void _addToPlaylist(AssetEntity video, String playlist) {
    final list = _prefs.getStringList('playlist_$playlist') ?? [];
    // Ensure no duplicates by using a Set
    final uniqueIds = list.toSet();
    if (!uniqueIds.contains(video.id)) {
      uniqueIds.add(video.id);
      _prefs.setStringList('playlist_$playlist', uniqueIds.toList());
    }
  }

  void _removeFromPlaylist(AssetEntity video, String playlist) {
    final list = _prefs.getStringList('playlist_$playlist') ?? [];
    // Ensure no duplicates by using a Set
    final uniqueIds = list.toSet();
    if (uniqueIds.contains(video.id)) {
      uniqueIds.remove(video.id);
      _prefs.setStringList('playlist_$playlist', uniqueIds.toList());
    }
  }

  void _showAddToPlaylistDialog(AssetEntity video) {
    final TextEditingController playlistController = TextEditingController();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (c) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.6,
                ),
                decoration: BoxDecoration(
                  gradient: AppThemes.currentMainGradient,
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
                                      Icons.playlist_add_outlined,
                                      color: Color(0xFFCCD0CF),
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Text(
                                      'Add to Playlist',
                                      style: GoogleFonts.poppins(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFFCCD0CF),
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () => Navigator.pop(c),
                                    icon: const Icon(
                                      Icons.close,
                                      color: Color(0xFFCCD0CF),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            // Create new playlist section
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.2),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: playlistController,
                                        style: GoogleFonts.poppins(
                                          color: const Color(0xFFCCD0CF),
                                        ),
                                        decoration: InputDecoration(
                                          hintText: 'New playlist name',
                                          hintStyle: GoogleFonts.poppins(
                                            color: Colors.white.withOpacity(
                                              0.7,
                                            ),
                                          ),
                                          border: const OutlineInputBorder(),
                                          enabledBorder:
                                              const OutlineInputBorder(
                                                borderSide: BorderSide(
                                                  color: Color(0xFF253745),
                                                ),
                                              ),
                                          focusedBorder:
                                              const OutlineInputBorder(
                                                borderSide: BorderSide(
                                                  color: Color(0xFF4A5C6A),
                                                ),
                                              ),
                                          isDense: true,
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                vertical: 12,
                                                horizontal: 16,
                                              ),
                                        ),
                                        onSubmitted: (value) {
                                          if (value.isNotEmpty) {
                                            _createPlaylist(value);
                                            _addToPlaylist(video, value);
                                            playlistController.clear();
                                            Navigator.pop(c);
                                          }
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Container(
                                      decoration: BoxDecoration(
                                        color: const Color(
                                          0xFF4A5C6A,
                                        ).withOpacity(0.3),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: IconButton(
                                        icon: const Icon(
                                          Icons.check,
                                          color: Color(0xFFCCD0CF),
                                        ),
                                        onPressed: () {
                                          final newPlaylist = playlistController
                                              .text
                                              .trim();
                                          if (newPlaylist.isNotEmpty) {
                                            _createPlaylist(newPlaylist);
                                            _addToPlaylist(video, newPlaylist);
                                            playlistController.clear();
                                            Navigator.pop(c);
                                          }
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            if (_playlists.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    'Existing Playlists:',
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFFCCD0CF),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              ...(_playlists.map((playlist) {
                                final inPlaylist =
                                    (_prefs.getStringList(
                                              'playlist_$playlist',
                                            ) ??
                                            [])
                                        .contains(video.id);
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                  child: Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.2),
                                      ),
                                    ),
                                    child: ListTile(
                                      leading: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: const Color(
                                            0xFF4A5C6A,
                                          ).withOpacity(0.3),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Icon(
                                          inPlaylist
                                              ? Icons.check_circle
                                              : Icons.queue_music_outlined,
                                          color: const Color(0xFFCCD0CF),
                                          size: 20,
                                        ),
                                      ),
                                      title: Text(
                                        playlist,
                                        style: GoogleFonts.poppins(
                                          color: const Color(0xFFCCD0CF),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      subtitle: Text(
                                        inPlaylist
                                            ? 'Remove from playlist'
                                            : 'Add to playlist',
                                        style: GoogleFonts.poppins(
                                          color: Colors.white.withOpacity(0.7),
                                          fontSize: 12,
                                        ),
                                      ),
                                      onTap: () {
                                        if (inPlaylist) {
                                          _removeFromPlaylist(video, playlist);
                                        } else {
                                          _addToPlaylist(video, playlist);
                                        }
                                        setModalState(() {});
                                      },
                                    ),
                                  ),
                                );
                              })),
                            ],
                            const SizedBox(height: 16),
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
      },
    );
  }

  void _showCreatePlaylistDialog() {
    final TextEditingController playlistController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF11212D),
          title: Text(
            'Create New Playlist',
            style: GoogleFonts.poppins(
              color: const Color(0xFFCCD0CF),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: TextField(
            controller: playlistController,
            autofocus: true,
            style: GoogleFonts.poppins(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Enter playlist name',
              hintStyle: GoogleFonts.poppins(
                color: Colors.white.withOpacity(0.7),
              ),
              border: const OutlineInputBorder(),
              enabledBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: Color(0xFF253745)),
              ),
              focusedBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: Color(0xFF4A5C6A)),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                final playlistName = playlistController.text.trim();
                if (playlistName.isNotEmpty) {
                  _createPlaylist(playlistName);
                  Navigator.of(context).pop();
                }
              },
              child: Text(
                'Create',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _addToHistory(AssetEntity video) async {
    if (!mounted) return;

    final historyIds = _prefs.getStringList('video_history') ?? [];

    // Remove if already exists (to move to top)
    historyIds.remove(video.id);

    // Add to beginning
    historyIds.insert(0, video.id);

    // Keep only last 10 videos
    if (historyIds.length > 10) {
      historyIds.removeRange(10, historyIds.length);
    }

    await _prefs.setStringList('video_history', historyIds);

    if (mounted) {
      setState(() {
        // Use a Map to ensure unique entries by ID
        final Map<String, AssetEntity> uniqueVideos = {};
        for (final asset in _videoAssets) {
          if (historyIds.contains(asset.id)) {
            uniqueVideos[asset.id] = asset;
          }
        }
        // Convert back to list and maintain history order
        _historyVideos = historyIds
            .map((id) => uniqueVideos[id])
            .where((asset) => asset != null)
            .cast<AssetEntity>()
            .toList();
      });
    }
  }

  void _clearHistory() async {
    if (!mounted) return;

    // Show confirm dialog before clearing history
    final shouldClear = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppThemes.currentSurfaceColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(Icons.delete_forever, color: Colors.white, size: 28),
              const SizedBox(width: 12),
              Text(
                'Clear History',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ],
          ),
          content: Text(
            'Are you sure you want to clear all video history? This action cannot be undone.',
            style: TextStyle(color: Colors.white, fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: AppThemes.currentMainGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(
                  'Clear History',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
          actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        );
      },
    );

    // Only clear if user confirmed
    if (shouldClear != true) return;

    await _prefs.remove('video_history');
    if (mounted) {
      setState(() {
        _historyVideos.clear();
      });
    }
  }

  void _buildFolderMap(List<AssetEntity> assets) async {
    if (!mounted || _folderMapBuilt) return; // Skip if already built

    print('Building folder map for ${assets.length} videos');
    final Map<String, List<AssetEntity>> folderMap = {};

    for (final asset in assets) {
      if (!mounted) return; // Early return if widget is disposed

      try {
        final file = await asset.file;
        if (file != null) {
          final dir = file.parent.path;
          folderMap.putIfAbsent(dir, () => []).add(asset);
          print('Added video to folder: $dir');
        }
      } catch (e) {
        print('Error getting file for asset: $e');
      }
    }

    print('Folder map built with ${folderMap.length} folders');
    print('Folders: ${folderMap.keys.toList()}');

    if (mounted) {
      setState(() {
        _folderMap = folderMap;
        _folderList = folderMap.keys.toList();
        _folderMapBuilt = true; // Mark as built
      });
    }
  }

  void _resetFolderMap() {
    setState(() {
      _folderMap.clear();
      _folderList.clear();
      _folderMapBuilt = false;
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterVideos);
    _searchController.dispose();
    super.dispose();
  }

  void _filterVideos() {
    if (!mounted) return;

    if (_searchController.text.isEmpty) {
      setState(() {
        _filteredVideos = _videoAssets;
        _sortedVideos.clear(); // Clear cached sorted videos
      });
    } else {
      final query = _searchController.text.toLowerCase();
      setState(() {
        _filteredVideos = _videoAssets.where((asset) {
          final title = asset.title?.toLowerCase() ?? '';
          return title.contains(query);
        }).toList();
        _sortedVideos.clear(); // Clear cached sorted videos
      });
    }
  }

  Future<void> _fetchAllVideos() async {
    if (mounted) {
      setState(() {
        _loading = true;
      });
    }

    final result = await VideoService.fetchAllVideos();

    if (!mounted) return; // Early return if widget is disposed

    if (result.permissionState == PermissionState.authorized ||
        result.permissionState == PermissionState.limited) {
      // Check if videos actually changed
      bool videosChanged = _videoAssets.length != result.videos.length;
      if (!videosChanged) {
        // Check if any video IDs changed
        final currentIds = _videoAssets.map((v) => v.id).toSet();
        final newIds = result.videos.map((v) => v.id).toSet();
        videosChanged =
            !currentIds.containsAll(newIds) || !newIds.containsAll(currentIds);
      }

      if (mounted) {
        setState(() {
          _videoAssets = result.videos;
          _filteredVideos = result.videos;
          _loading = false;
          _sortedVideos.clear(); // Clear cached sorted videos
          _videosLoaded = true; // Mark videos as loaded
        });
      }

      if (mounted) {
        _loadFavourites();
        _loadHistory();

        // Build folder map if videos changed OR if folder map hasn't been built yet
        if (videosChanged) {
          _resetFolderMap();
          _buildFolderMap(result.videos);
        } else if (!_folderMapBuilt) {
          // If videos haven't changed but folder map isn't built yet, build it
          _buildFolderMap(result.videos);
        }

        // Apply default sort (date, descending)
        if (_sortBy == 'date') {
          _performAsyncSort(result.videos);
        }
      }
    } else {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Storage permission is required to access videos.',
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: Theme.of(context).textTheme.bodyLarge,
                decoration: InputDecoration(
                  hintText: 'Search videos...',
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
                'Video Browser',
                style: Theme.of(context).textTheme.titleLarge,
              ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: BoxDecoration(gradient: AppThemes.currentMainGradient),
        ),
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        centerTitle: false,
        actions: [
          if (_isSearching)
            IconButton(
              icon: Icon(Icons.close_outlined, color: Colors.white),
              onPressed: () {
                setState(() {
                  _isSearching = false;
                  _searchController.clear();
                  _filteredVideos = _videoAssets;
                  _sortedVideos.clear(); // Clear cached sorted videos
                });
              },
            )
          else ...[
            IconButton(
              icon: Image.asset(
                'assets/search.png',
                width: 24,
                height: 24,
                color: Colors.white,
              ),
              onPressed: () {
                setState(() {
                  _isSearching = true;
                });
              },
            ),
            IconButton(
              icon: Icon(Icons.refresh, color: Colors.white),
              tooltip: 'Refresh',
              onPressed: _fetchAllVideos,
              iconSize: 30,
            ),
          ],
        ],
      ),
      body: Container(
        decoration: BoxDecoration(gradient: AppThemes.currentMainGradient),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // History Section - Only show if there are videos in history
                if (_historyVideos.isNotEmpty) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'History',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: Image.asset(
                          'assets/delete.png',
                          width: 20,
                          height: 20,
                        ),
                        onPressed: () {
                          _clearHistory();
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 110,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _historyVideos.length,
                      itemBuilder: (context, index) {
                        final asset = _historyVideos[index];
                        return _buildHistoryCard(asset, index);
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Add padding above filter tabs when history is empty
                if (_historyVideos.isEmpty) const SizedBox(height: 24),

                // Filter Tabs
                Row(
                  children: [
                    Expanded(
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
                            final tabWidth = constraints.maxWidth / 3;
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
                                      child: _buildFilterTab('Videos', 0),
                                    ),
                                    Expanded(
                                      child: _buildFilterTab('Folder', 1),
                                    ),
                                    Expanded(
                                      child: _buildFilterTab('Playlist', 2),
                                    ),
                                  ],
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Always reserve space for sort button to prevent layout shift
                    SizedBox(
                      width: 48,
                      child: _selectedTabIndex == 0 && !_showFolders
                          ? Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.1),
                                  width: 1,
                                ),
                              ),
                              child: IconButton(
                                icon: Image.asset(
                                  'assets/sort.png',
                                  width: 22,
                                  height: 22,
                                ),
                                onPressed: () {
                                  _showSortDialog();
                                },
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 4), // 1px padding between buttons
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.1),
                          width: 1,
                        ),
                      ),
                      child: IconButton(
                        icon: Image.asset(
                          _isGridView
                              ? 'assets/view.png'
                              : 'assets/list_view.png',
                          width: 22,
                          height: 22,
                        ),
                        onPressed: () {
                          setState(() {
                            _isGridView = !_isGridView;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Video List
                Expanded(
                  child: _loading
                      ? const SkeletonList(itemCount: 8)
                      : (_showFolders ||
                            _selectedTabIndex == 1) // 1 is the Folder tab index
                      ? _selectedFolder == null
                            ? _folderList.isEmpty
                                  ? const SkeletonList(itemCount: 6)
                                  : _isGridView
                                  ? GridView.builder(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 8,
                                      ),
                                      gridDelegate:
                                          const SliverGridDelegateWithFixedCrossAxisCount(
                                            crossAxisCount: 2,
                                            childAspectRatio: 1.2,
                                            crossAxisSpacing: 16,
                                            mainAxisSpacing: 16,
                                          ),
                                      itemCount: _folderList.length,
                                      itemBuilder: (context, index) {
                                        final folder = _folderList[index];
                                        final count =
                                            _folderMap[folder]?.length ?? 0;
                                        return TweenAnimationBuilder<double>(
                                          duration: Duration(
                                            milliseconds: 600 + (index * 50),
                                          ),
                                          curve: Curves.easeOutCubic,
                                          tween: Tween<double>(
                                            begin: 0.0,
                                            end: 1.0,
                                          ),
                                          builder: (context, value, child) {
                                            return Transform.translate(
                                              offset: Offset(
                                                0,
                                                20 * (1 - value),
                                              ),
                                              child: Opacity(
                                                opacity: value,
                                                child: Transform.scale(
                                                  scale: 0.8 + (0.2 * value),
                                                  child: _buildFolderCard(
                                                    folder,
                                                    count,
                                                    index,
                                                  ),
                                                ),
                                              ),
                                            );
                                          },
                                        );
                                      },
                                    )
                                  : ListView.builder(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 8,
                                      ),
                                      itemCount: _folderList.length,
                                      itemBuilder: (context, index) {
                                        final folder = _folderList[index];
                                        final count =
                                            _folderMap[folder]?.length ?? 0;
                                        return TweenAnimationBuilder<double>(
                                          duration: Duration(
                                            milliseconds: 600 + (index * 50),
                                          ),
                                          curve: Curves.easeOutCubic,
                                          tween: Tween<double>(
                                            begin: 0.0,
                                            end: 1.0,
                                          ),
                                          builder: (context, value, child) {
                                            return Transform.translate(
                                              offset: Offset(
                                                0,
                                                20 * (1 - value),
                                              ),
                                              child: Opacity(
                                                opacity: value,
                                                child: Transform.scale(
                                                  scale: 0.8 + (0.2 * value),
                                                  child: Padding(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          vertical: 6,
                                                        ),
                                                    child: _buildFolderListCard(
                                                      folder,
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
                                    )
                            : Column(
                                children: [
                                  _buildBackToFoldersCard(),
                                  Expanded(child: _buildFolderVideosList()),
                                ],
                              )
                      : _selectedTabIndex ==
                            2 // 2 is the Playlist tab index
                      ? _selectedPlaylist == null
                            ? _playlists.isEmpty
                                  ? Center(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
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
                                            'Create playlists to organize your videos.',
                                            style: GoogleFonts.poppins(
                                              color: const Color(0xFF9BA8AB),
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  : _isGridView
                                  ? Column(
                                      children: [
                                        // Header with title and plus icon
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 12,
                                          ),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                'Playlists(${_playlists.length})',
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
                                                icon: const Icon(
                                                  Icons.add,
                                                  color: Colors.white,
                                                  size: 24,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        // Playlist grid
                                        Expanded(
                                          child: GridView.builder(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 8,
                                            ),
                                            gridDelegate:
                                                const SliverGridDelegateWithFixedCrossAxisCount(
                                                  crossAxisCount: 2,
                                                  childAspectRatio: 1.2,
                                                ),
                                            itemCount: _playlists.length,
                                            itemBuilder: (context, index) {
                                              final playlist =
                                                  _playlists[index];
                                              final count = _getPlaylistVideos(
                                                playlist,
                                              ).length;
                                              return TweenAnimationBuilder<
                                                double
                                              >(
                                                duration: Duration(
                                                  milliseconds:
                                                      600 + (index * 50),
                                                ),
                                                curve: Curves.easeOutCubic,
                                                tween: Tween<double>(
                                                  begin: 0.0,
                                                  end: 1.0,
                                                ),
                                                builder: (context, value, child) {
                                                  return Transform.translate(
                                                    offset: Offset(
                                                      0,
                                                      20 * (1 - value),
                                                    ),
                                                    child: Opacity(
                                                      opacity: value,
                                                      child: Transform.scale(
                                                        scale:
                                                            0.8 + (0.2 * value),
                                                        child:
                                                            _buildPlaylistCard(
                                                              playlist,
                                                              count,
                                                              index,
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
                                    )
                                  : Column(
                                      children: [
                                        // Header with title and plus icon
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 12,
                                          ),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                'Playlists(${_playlists.length})',
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
                                                icon: const Icon(
                                                  Icons.add,
                                                  color: Colors.white,
                                                  size: 24,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        // Playlist list
                                        Expanded(
                                          child: ListView.builder(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 8,
                                            ),
                                            itemCount: _playlists.length,
                                            itemBuilder: (context, index) {
                                              final playlist =
                                                  _playlists[index];
                                              final count = _getPlaylistVideos(
                                                playlist,
                                              ).length;
                                              return TweenAnimationBuilder<
                                                double
                                              >(
                                                duration: Duration(
                                                  milliseconds:
                                                      600 + (index * 50),
                                                ),
                                                curve: Curves.easeOutCubic,
                                                tween: Tween<double>(
                                                  begin: 0.0,
                                                  end: 1.0,
                                                ),
                                                builder: (context, value, child) {
                                                  return Transform.translate(
                                                    offset: Offset(
                                                      0,
                                                      20 * (1 - value),
                                                    ),
                                                    child: Opacity(
                                                      opacity: value,
                                                      child: Transform.scale(
                                                        scale:
                                                            0.8 + (0.2 * value),
                                                        child: Padding(
                                                          padding:
                                                              const EdgeInsets.symmetric(
                                                                vertical: 6,
                                                              ),
                                                          child:
                                                              _buildPlaylistListCard(
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
                                    )
                            : Column(
                                children: [
                                  _buildBackToPlaylistsCard(),
                                  Expanded(child: _buildPlaylistVideosList()),
                                ],
                              )
                      : _getVideosToShow().isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _isSearching
                                  ? Icon(
                                      Icons.search_off,
                                      color: const Color(0xFF9BA8AB),
                                      size: 48,
                                    )
                                  : _selectedPlaylist != null
                                  ? Image.asset(
                                      'assets/favourite.png',
                                      width: 48,
                                      height: 48,
                                      color: const Color(0xFF9BA8AB),
                                    )
                                  : Icon(
                                      Icons.video_library_outlined,
                                      color: const Color(0xFF9BA8AB),
                                      size: 48,
                                    ),
                              const SizedBox(height: 16),
                              Text(
                                _isSearching
                                    ? 'No videos found matching your search.'
                                    : _selectedPlaylist != null
                                    ? 'No videos in this playlist.'
                                    : 'No videos found.',
                                style: GoogleFonts.poppins(
                                  color: const Color(0xFF9BA8AB),
                                  fontSize: 16,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        )
                      : _isGridView
                      ? GridView.builder(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 8,
                          ),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                childAspectRatio: 0.8,
                              ),
                          itemCount: _getVideosToShow().length,
                          itemBuilder: (context, index) {
                            final asset = _getVideosToShow()[index];
                            return TweenAnimationBuilder<double>(
                              duration: Duration(
                                milliseconds: 600 + (index * 50),
                              ),
                              curve: Curves.easeOutCubic,
                              tween: Tween<double>(begin: 0.0, end: 1.0),
                              builder: (context, value, child) {
                                return Transform.translate(
                                  offset: Offset(0, 20 * (1 - value)),
                                  child: Opacity(
                                    opacity: value,
                                    child: Transform.scale(
                                      scale: 0.8 + (0.2 * value),
                                      child: _buildGridVideoCard(asset, index),
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: _getVideosToShow().length,
                          itemBuilder: (context, index) {
                            final asset = _getVideosToShow()[index];
                            return TweenAnimationBuilder<double>(
                              duration: Duration(
                                milliseconds: 600 + (index * 50),
                              ),
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
                                        child: _buildVideoCard(asset, index),
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
            ),
          ),
        ),
      ),
    );
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
            if (label == 'Folder') {
              _showFolders = true;
              _selectedFolder = null;
            } else if (label == 'Playlist') {
              _showFolders = false;
              _selectedFolder = null;
              _selectedPlaylist = null;
            } else {
              _showFolders = false;
              _selectedFolder = null;
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
                fontSize: 14,
              ),
              child: Text(label),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryCard(AssetEntity asset, int index) {
    return GestureDetector(
      onTap: () async {
        final fullList = _videoAssets;
        final initialIndex = fullList.indexWhere((a) => a.id == asset.id);
        if (initialIndex != -1) {
          final result = await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => VideoPlayerScreen(
                videoAssets: fullList,
                initialIndex: initialIndex,
                onFavouritesChanged: () {
                  _loadFavourites();
                  setState(() {});
                },
                onPlaylistsChanged: () {
                  _loadPlaylists();
                  setState(() {});
                },
              ),
            ),
          );
          if (result == true) {
            _loadFavourites();
            setState(() {});
          }
        }
      },
      child: Container(
        width: 100,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            FutureBuilder<Uint8List?>(
              future: asset.thumbnailDataWithSize(ThumbnailSize(80, 70)),
              builder: (context, snapshot) {
                Widget thumbWidget;
                if (snapshot.connectionState == ConnectionState.done &&
                    snapshot.hasData &&
                    snapshot.data != null) {
                  thumbWidget = ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.memory(
                      snapshot.data!,
                      width: 100,
                      height: 70,
                      fit: BoxFit.cover,
                    ),
                  );
                } else {
                  thumbWidget = Container(
                    width: 100,
                    height: 70,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: const Color(0xFF253745),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.movie_outlined,
                        color: Color(0xFF9BA8AB),
                        size: 24,
                      ),
                    ),
                  );
                }
                return thumbWidget;
              },
            ),
            const SizedBox(height: 6),
            Text(
              asset.title ?? 'Unknown',
              style: GoogleFonts.poppins(
                color: const Color(0xFFCCD0CF),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoCard(AssetEntity asset, int index) {
    return FutureBuilder<File?>(
      future: asset.file,
      builder: (context, snapshot) {
        String dateText = 'Unknown';
        if (snapshot.hasData && snapshot.data != null) {
          try {
            final file = snapshot.data!;
            final stat = file.statSync();
            final now = DateTime.now();
            final fileDate = stat.modified;
            final difference = now.difference(fileDate);
            if (difference.inDays == 0) {
              dateText = 'Today';
            } else if (difference.inDays == 1) {
              dateText = 'Yesterday';
            } else if (difference.inDays < 7) {
              dateText = '${difference.inDays} days ago';
            } else if (difference.inDays < 30) {
              final weeks = (difference.inDays / 7).floor();
              dateText = '${weeks} week${weeks == 1 ? '' : 's'} ago';
            } else if (difference.inDays < 365) {
              final months = (difference.inDays / 30).floor();
              dateText = '${months} month${months == 1 ? '' : 's'} ago';
            } else {
              final years = (difference.inDays / 365).floor();
              dateText = '${years} year${years == 1 ? '' : 's'} ago';
            }
          } catch (e) {
            dateText = 'Unknown';
          }
        }
        return GestureDetector(
          onTap: () async {
            final fullList = _videoAssets;
            final initialIndex = fullList.indexWhere((a) => a.id == asset.id);
            if (initialIndex != -1) {
              _addToHistory(asset);
              final result = await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => VideoPlayerScreen(
                    videoAssets: fullList,
                    initialIndex: initialIndex,
                    onFavouritesChanged: () {
                      _loadFavourites();
                      setState(() {});
                    },
                    onPlaylistsChanged: () {
                      _loadPlaylists();
                      setState(() {});
                    },
                  ),
                ),
              );
              if (result == true) {
                _loadFavourites();
                setState(() {});
              }
            }
          },
          child: UnifiedCard(
            leading: FutureBuilder<Uint8List?>(
              future: asset.thumbnailDataWithSize(ThumbnailSize(80, 80)),
              builder: (context, snapshot) {
                Widget thumbWidget;
                if (snapshot.connectionState == ConnectionState.done &&
                    snapshot.hasData &&
                    snapshot.data != null) {
                  thumbWidget = ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.memory(
                      snapshot.data!,
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                    ),
                  );
                } else {
                  thumbWidget = Icon(
                    Icons.movie_outlined,
                    size: 32,
                    color: const Color(0xFFCCD0CF),
                  );
                }
                return Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withOpacity(0.22),
                        Colors.white.withOpacity(0.10),
                      ],
                    ),
                  ),
                  child: thumbWidget,
                );
              },
            ),
            title: asset.title ?? 'Unknown',
            subtitle: dateText,
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/favourite.png',
                  width: 20,
                  height: 20,
                  color: _favourites.contains(asset.id)
                      ? Colors.amber
                      : const Color(0xFF9BA8AB),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () {
                    _showAddToPlaylistDialog(asset);
                  },
                  child: const Icon(
                    Icons.playlist_add,
                    color: Color(0xFF9BA8AB),
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
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
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$count video${count == 1 ? '' : 's'}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
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

  Widget _buildFolderVideosList() {
    final folderVideos =
        _selectedFolder != null && _folderMap[_selectedFolder!] != null
        ? List<AssetEntity>.from(_folderMap[_selectedFolder!]!)
        : <AssetEntity>[];

    if (folderVideos.isEmpty) {
      return Center(
        child: Text(
          'No videos in this folder.',
          style: GoogleFonts.poppins(
            color: const Color(0xFF9BA8AB),
            fontSize: 16,
          ),
        ),
      );
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 600),
      transitionBuilder: (Widget child, Animation<double> animation) {
        return SlideTransition(
          position: Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
              .animate(
                CurvedAnimation(parent: animation, curve: Curves.elasticOut),
              ),
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.8, end: 1.0).animate(
              CurvedAnimation(parent: animation, curve: Curves.elasticOut),
            ),
            child: FadeTransition(opacity: animation, child: child),
          ),
        );
      },
      child: _isGridView
          ? GridView.builder(
              key: const ValueKey('folder_videos_grid'),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.8,
              ),
              itemCount: folderVideos.length,
              itemBuilder: (context, index) {
                final asset = folderVideos[index];
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeInOutCubic,
                  child: _buildGridVideoCard(asset, index),
                );
              },
            )
          : ListView.builder(
              key: const ValueKey('folder_videos_list'),
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: folderVideos.length,
              itemBuilder: (context, index) {
                final asset = folderVideos[index];
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeInOutCubic,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: _buildVideoCard(asset, index),
                  ),
                );
              },
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
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    playlist == 'Favourite Videos'
                        ? 'assets/favourite_playlist.png'
                        : 'assets/playlist.png',
                    width: 28,
                    height: 28,
                    color: playlist == 'Favourite Videos'
                        ? null
                        : const Color(0xFFCCD0CF),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    playlist,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$count video${count == 1 ? '' : 's'}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white.withOpacity(0.7),
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

  Widget _buildPlaylistVideosList() {
    final playlistVideos =
        _selectedPlaylist != null &&
            _getPlaylistVideos(_selectedPlaylist!).isNotEmpty
        ? List<AssetEntity>.from(_getPlaylistVideos(_selectedPlaylist!))
        : <AssetEntity>[];

    if (playlistVideos.isEmpty) {
      return Center(
        child: Text(
          'No videos in this playlist.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOutCubic,
      child: _isGridView
          ? GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.8,
              ),
              itemCount: playlistVideos.length,
              itemBuilder: (context, index) {
                final asset = playlistVideos[index];
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeInOutCubic,
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.001)
                    ..rotateY(_isGridView ? 0 : 0.1),
                  child: _buildGridVideoCard(asset, index),
                );
              },
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: playlistVideos.length,
              itemBuilder: (context, index) {
                final asset = playlistVideos[index];
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeInOutCubic,
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.001)
                    ..rotateY(_isGridView ? 0.1 : 0),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: _buildVideoCard(asset, index),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildFolderListCard(String folder, int count, int index) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFolder = folder;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white.withOpacity(0.13),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF06141B).withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(color: Colors.white.withOpacity(0.13), width: 1),
        ),
        child: Container(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Folder icon
              Container(
                width: 32,
                height: 32,

                child: Image.asset(
                  'assets/folder.png',
                  width: 18,
                  height: 18,
                  color: const Color(0xFF0E1A22),
                ),
              ),
              const SizedBox(width: 12),
              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      folder.split(Platform.pathSeparator).last,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$count video${count == 1 ? '' : 's'}',
                      style: const TextStyle(
                        color: Color(0xFF9BA8AB),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              // Arrow icon
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.white.withOpacity(0.7),
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaylistListCard(String playlist, int count, int index) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPlaylist = playlist;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white.withOpacity(0.13),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF06141B).withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(color: Colors.white.withOpacity(0.13), width: 1),
        ),
        child: Container(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Playlist icon
              Image.asset(
                playlist == 'Favourite Videos'
                    ? 'assets/favourite_playlist.png'
                    : 'assets/playlist.png',
                width: 32,
                height: 32,
                color: playlist == 'Favourite Videos'
                    ? null
                    : const Color(0xFFCCD0CF),
              ),
              const SizedBox(width: 12),
              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      playlist,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$count video${count == 1 ? '' : 's'}',
                      style: const TextStyle(
                        color: Color(0xFF9BA8AB),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              // Arrow icon
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.white.withOpacity(0.7),
                size: 16,
              ),
            ],
          ),
        ),
      ),
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
              color: Colors.white,
              size: 24,
            ),
            const SizedBox(width: 12),
            const Text(
              'Back to Playlists',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGridVideoCard(AssetEntity asset, int index) {
    return GestureDetector(
      onTap: () async {
        final fullList = _videoAssets;
        final initialIndex = fullList.indexWhere((a) => a.id == asset.id);
        if (initialIndex != -1) {
          _addToHistory(asset);
          final result = await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => VideoPlayerScreen(
                videoAssets: fullList,
                initialIndex: initialIndex,
                onFavouritesChanged: () {
                  _loadFavourites();
                  setState(() {});
                },
                onPlaylistsChanged: () {
                  _loadPlaylists();
                  setState(() {});
                },
              ),
            ),
          );
          if (result == true) {
            _loadFavourites();
            setState(() {});
          }
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white.withOpacity(0.13),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF06141B).withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(color: Colors.white.withOpacity(0.13), width: 1),
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Thumbnail
                Expanded(
                  child: FutureBuilder<Uint8List?>(
                    future: asset.thumbnailDataWithSize(
                      ThumbnailSize(120, 120),
                    ),
                    builder: (context, snapshot) {
                      Widget thumbWidget;
                      if (snapshot.connectionState == ConnectionState.done &&
                          snapshot.hasData &&
                          snapshot.data != null) {
                        thumbWidget = ClipRRect(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(16),
                            topRight: Radius.circular(16),
                          ),
                          child: Image.memory(
                            snapshot.data!,
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        );
                      } else {
                        thumbWidget = Container(
                          width: double.infinity,
                          height: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(16),
                              topRight: Radius.circular(16),
                            ),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.white.withOpacity(0.22),
                                Colors.white.withOpacity(0.10),
                              ],
                            ),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.movie_outlined,
                              color: Color(0xFF0E1A22),
                              size: 32,
                            ),
                          ),
                        );
                      }
                      return thumbWidget;
                    },
                  ),
                ),
                // Details
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        asset.title ?? 'Unknown',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFFCCD0CF),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      FutureBuilder<File?>(
                        future: asset.file,
                        builder: (context, snapshot) {
                          if (!mounted) {
                            return const SizedBox.shrink();
                          }

                          if (snapshot.hasData && snapshot.data != null) {
                            try {
                              final file = snapshot.data!;
                              final stat = file.statSync();
                              final now = DateTime.now();
                              final fileDate = stat.modified;
                              final difference = now.difference(fileDate);

                              String dateText;
                              if (difference.inDays == 0) {
                                dateText = 'Today';
                              } else if (difference.inDays == 1) {
                                dateText = 'Yesterday';
                              } else if (difference.inDays < 7) {
                                dateText = '${difference.inDays} days ago';
                              } else if (difference.inDays < 30) {
                                final weeks = (difference.inDays / 7).floor();
                                dateText =
                                    '${weeks} week${weeks == 1 ? '' : 's'} ago';
                              } else if (difference.inDays < 365) {
                                final months = (difference.inDays / 30).floor();
                                dateText =
                                    '${months} month${months == 1 ? '' : 's'} ago';
                              } else {
                                final years = (difference.inDays / 365).floor();
                                dateText =
                                    '${years} year${years == 1 ? '' : 's'} ago';
                              }

                              return Text(
                                dateText,
                                style: const TextStyle(
                                  color: Color(0xFF9BA8AB),
                                  fontSize: 10,
                                ),
                              );
                            } catch (e) {
                              return const Text(
                                'Unknown',
                                style: TextStyle(
                                  color: Color(0xFF9BA8AB),
                                  fontSize: 10,
                                ),
                              );
                            }
                          } else {
                            return const Text(
                              'Unknown',
                              style: TextStyle(
                                color: Color(0xFF9BA8AB),
                                fontSize: 10,
                              ),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            // Favourite icon overlay
            Positioned(
              top: 8,
              right: 8,
              child: Image.asset(
                'assets/favourite.png',
                width: 16,
                height: 16,
                color: _favourites.contains(asset.id)
                    ? Colors.amber
                    : const Color(0xFF9BA8AB),
              ),
            ),
            // Playlist button overlay
            Positioned(
              top: 8,
              right: 32,
              child: GestureDetector(
                onTap: () {
                  _showAddToPlaylistDialog(asset);
                },
                child: const Icon(
                  Icons.playlist_add,
                  color: Color(0xFF9BA8AB),
                  size: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<AssetEntity> _getVideosToShow() {
    List<AssetEntity> videosToShow;
    if (_selectedPlaylist != null) {
      videosToShow = _getPlaylistVideos(_selectedPlaylist!);
    } else if (_isSearching) {
      videosToShow = _filteredVideos;
    } else {
      videosToShow = _videoAssets;
    }

    // Ensure no duplicates by ID
    videosToShow = _removeDuplicates(videosToShow);

    // For name and length sorting, use synchronous sorting
    if (_sortBy == 'name' || _sortBy == 'length') {
      return _sortVideos(videosToShow);
    } else {
      // For date and size sorting, only return sorted results if available
      if (_sortedVideos.isNotEmpty && !_isSorting) {
        return _removeDuplicates(_sortedVideos);
      } else {
        // If no sorted results available, trigger async sort and return original list
        if (!_isSorting) {
          _performAsyncSort(videosToShow);
        }
        return videosToShow;
      }
    }
  }

  List<AssetEntity> _removeDuplicates(List<AssetEntity> videos) {
    final seen = <String>{};
    final uniqueVideos = <AssetEntity>[];

    for (final video in videos) {
      if (!seen.contains(video.id)) {
        seen.add(video.id);
        uniqueVideos.add(video);
      }
    }

    return uniqueVideos;
  }

  void _performAsyncSort(List<AssetEntity> videos) async {
    if (_isSorting || !mounted) return;

    if (mounted) {
      setState(() {
        _isSorting = true;
      });
    }

    try {
      List<AssetEntity> sortedVideos = List<AssetEntity>.from(videos);

      if (_sortBy == 'date') {
        // Sort by date
        final List<MapEntry<AssetEntity, DateTime>> videosWithDates = [];

        for (final video in sortedVideos) {
          if (!mounted) return; // Early return if widget is disposed

          try {
            final file = await video.file;
            if (file != null) {
              final stat = file.statSync();
              videosWithDates.add(MapEntry(video, stat.modified));
            }
          } catch (e) {
            // Skip videos with errors
          }
        }

        videosWithDates.sort((a, b) {
          return _sortAscending
              ? a.value.compareTo(b.value)
              : b.value.compareTo(a.value);
        });

        sortedVideos = videosWithDates.map((entry) => entry.key).toList();
      } else if (_sortBy == 'size') {
        // Sort by file size
        final List<MapEntry<AssetEntity, int>> videosWithSizes = [];

        for (final video in sortedVideos) {
          if (!mounted) return; // Early return if widget is disposed

          try {
            final file = await video.file;
            if (file != null) {
              final size = file.lengthSync();
              videosWithSizes.add(MapEntry(video, size));
            }
          } catch (e) {
            // Skip videos with errors
          }
        }

        videosWithSizes.sort((a, b) {
          return _sortAscending
              ? a.value.compareTo(b.value)
              : b.value.compareTo(a.value);
        });

        sortedVideos = videosWithSizes.map((entry) => entry.key).toList();
      }

      if (mounted) {
        setState(() {
          _sortedVideos = sortedVideos;
          _isSorting = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSorting = false;
        });
      }
    }
  }

  List<AssetEntity> _sortVideos(List<AssetEntity> videos) {
    final sortedVideos = List<AssetEntity>.from(videos);

    switch (_sortBy) {
      case 'name':
        sortedVideos.sort((a, b) {
          final nameA = (a.title ?? '').toLowerCase();
          final nameB = (b.title ?? '').toLowerCase();
          return _sortAscending
              ? nameA.compareTo(nameB)
              : nameB.compareTo(nameA);
        });
        break;
      case 'length':
        sortedVideos.sort((a, b) {
          final durationA = a.duration ?? 0;
          final durationB = b.duration ?? 0;
          return _sortAscending
              ? durationA.compareTo(durationB)
              : durationB.compareTo(durationA);
        });
        break;
      case 'date':
      case 'size':
        // These are handled by async sorting
        break;
    }

    return sortedVideos;
  }

  void _showSortDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (c) {
        return SafeArea(
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.7,
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
                                  color: Colors.white.withOpacity(0.18),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.sort,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  'Sort Videos',
                                  style: GoogleFonts.poppins(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFFCCD0CF),
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.18),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                                onPressed: () => Navigator.pop(c),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Sort options
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            children: [
                              _buildSortOption(
                                c,
                                'name',
                                Icons.sort_by_alpha,
                                'Name',
                                _sortBy == 'name' ? 'A to Z' : 'Z to A',
                                _sortBy == 'name',
                              ),
                              _buildSortOption(
                                c,
                                'date',
                                Icons.calendar_today,
                                'Date',
                                _sortBy == 'date'
                                    ? 'Oldest first'
                                    : 'Newest first',
                                _sortBy == 'date',
                              ),
                              _buildSortOption(
                                c,
                                'length',
                                Icons.timer,
                                'Duration',
                                _sortBy == 'length'
                                    ? 'Shortest first'
                                    : 'Longest first',
                                _sortBy == 'length',
                              ),
                              const SizedBox(height: 16),
                              // Divider
                              Container(
                                height: 1,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.transparent,
                                      Colors.white.withOpacity(0.2),
                                      Colors.transparent,
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              // Order options
                              _buildOrderOption(
                                c,
                                true,
                                Icons.arrow_upward,
                                'Ascending',
                                _sortAscending,
                              ),
                              _buildOrderOption(
                                c,
                                false,
                                Icons.arrow_downward,
                                'Descending',
                                !_sortAscending,
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

  Widget _buildSortOption(
    BuildContext context,
    String sortType,
    IconData icon,
    String title,
    String subtitle,
    bool isSelected,
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
          onTap: () {
            setState(() {
              _sortBy = sortType;
              _sortedVideos.clear();
            });
            if (sortType == 'date' || sortType == 'size') {
              _performAsyncSort(_videoAssets);
            } else {
              setState(() {
                _sortedVideos = _sortVideos(_videoAssets);
              });
            }
            Navigator.pop(context);
          },
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

  Widget _buildOrderOption(
    BuildContext context,
    bool ascending,
    IconData icon,
    String title,
    bool isSelected,
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
          onTap: () {
            setState(() {
              _sortAscending = ascending;
              _sortedVideos.clear();
            });
            if (_sortBy == 'date' || _sortBy == 'size') {
              _performAsyncSort(_videoAssets);
            } else {
              setState(() {
                _sortedVideos = _sortVideos(_videoAssets);
              });
            }
            Navigator.pop(context);
          },
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
}
