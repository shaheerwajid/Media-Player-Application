import 'dart:io';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import '../services/audio_service.dart';
import 'audio_player_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../main.dart';
import 'dart:ui';

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
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          color: widget.overlayColor.withOpacity(0.28),
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
          child: Stack(
            children: [
              // Liquid glass blur
              BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                child: const SizedBox.expand(),
              ),
              // Animated wavy highlight
              AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  final double anim = _controller.value;
                  return Positioned(
                    top: 0,
                    left: -40 + 80 * anim,
                    child: Opacity(
                      opacity: 0.18 + 0.12 * (1 - (anim - 0.5).abs() * 2),
                      child: Container(
                        width: 120,
                        height: 60,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(40),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.white.withOpacity(0.45),
                              Colors.white.withOpacity(0.0),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              // Top radial highlight
              Positioned(
                top: -30,
                left: -30,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Colors.white.withOpacity(0.18),
                        Colors.transparent,
                      ],
                      radius: 0.8,
                    ),
                  ),
                ),
              ),
              // Card content
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Icon(
                          widget.icon,
                          size: 32,
                          color: const Color(0xFFCCD0CF),
                        ),
                        if (widget.isFavourite)
                          Icon(
                            Icons.star,
                            color: const Color(0xFFCCD0CF),
                            size: 20,
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFFCCD0CF),
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    if (widget.subtitle != null) ...[
                      const SizedBox(height: 1),
                      Text(
                        widget.subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF9BA8AB),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (widget.duration != null)
                Positioned(
                  right: 10,
                  bottom: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF06141B).withOpacity(0.7),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      widget.duration!,
                      style: const TextStyle(
                        color: Color(0xFFCCD0CF),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
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

  @override
  void initState() {
    super.initState();
    _initPrefs();
    _fetchAllAudios();
    _searchController.addListener(_onSearchChanged);
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
    _loadFavourites();
    _loadPlaylists();
    _deduplicateAllPlaylists();
  }

  void _loadFavourites() {
    final favs = _prefs.getStringList('audio_favourites') ?? [];
    setState(() {
      _favourites = favs.toSet();
    });
  }

  void _loadPlaylists() {
    final keys = _prefs.getStringList('audio_playlists') ?? [];
    setState(() {
      _playlists = keys;
    });
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

  void _showPlaylistSelectDialog() {
    showModalBottomSheet(
      context: context,
      builder: (c) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.clear),
                title: const Text('All Audio'),
                onTap: () {
                  setState(() => _selectedPlaylist = null);
                  Navigator.pop(c);
                },
              ),
              for (final playlist in _playlists)
                ListTile(
                  leading: const Icon(Icons.queue_music),
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

  Future<void> _fetchAllAudios() async {
    if (mounted)
      setState(() {
        _loading = true;
      });
    final result = await AudioService.fetchAllAudios();
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
      if (mounted)
        setState(() {
          _audioAssets = uniqueAudios;
          _loading = false;
        });
      _buildFolderMap(result.audios);
    } else {
      if (mounted) setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Storage permission required.')),
        );
      }
      if (result.permissionState == PermissionState.denied) {
        PhotoManager.openSetting();
      }
    }
  }

  void _buildFolderMap(List<AssetEntity> assets) async {
    final Map<String, List<AssetEntity>> folderMap = {};
    for (final asset in assets) {
      final file = await asset.file;
      if (file != null) {
        final dir = file.parent.path;
        folderMap.putIfAbsent(dir, () => []).add(asset);
      }
    }
    if (mounted)
      setState(() {
        _folderMap = folderMap;
        _folderList = folderMap.keys.toList();
      });
  }

  void _startSearch() {
    if (mounted) setState(() => _isSearching = true);
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
    super.dispose();
  }

  @override
  void didPopNext() {
    // Called when coming back to this screen
    _loadFavourites();
    _loadPlaylists();
    setState(() {});
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
                style: const TextStyle(color: Color(0xFFCCD0CF)),
                decoration: InputDecoration(
                  hintText: 'Search audio...',
                  border: InputBorder.none,
                  hintStyle: const TextStyle(color: Color(0xFF9BA8AB)),
                  filled: true,
                  fillColor: const Color(0xFF4A5C6A).withOpacity(0.18),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: Color(0xFF4A5C6A),
                  ),
                ),
              )
            : const Text('Audio Browser'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF06141B), Color(0xFF11212D), Color(0xFF4A5C6A)],
              stops: [0.0, 0.5, 1.0],
            ),
          ),
        ),
        foregroundColor: const Color(0xFFCCD0CF),
        centerTitle: true,
        titleTextStyle: const TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.1,
        ),
        actions: [
          if (_isSearching)
            IconButton(
              icon: const Icon(Icons.close, color: Color(0xFF9BA8AB)),
              onPressed: _stopSearch,
            )
          else ...[
            IconButton(
              icon: const Icon(Icons.search, color: Color(0xFF4A5C6A)),
              onPressed: _startSearch,
            ),
          ],
        ],
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF06141B),
              Color(0xFF11212D),
              Color(0xFF253745),
              Color(0xFF4A5C6A),
              Color(0xFF9BA8AB),
            ],
            stops: [0.0, 0.2, 0.45, 0.75, 1.0],
          ),
        ),
        child: Padding(
          padding: EdgeInsets.only(
            top: kToolbarHeight + MediaQuery.of(context).padding.top,
          ),
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 8,
                      ),
                      child: Row(
                        children: [
                          ElevatedButton.icon(
                            icon: const Icon(
                              Icons.queue_music,
                              color: Color(0xFF4A5C6A),
                            ),
                            label: const Text('Playlist'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(
                                0xFF9BA8AB,
                              ).withOpacity(0.85),
                              foregroundColor: const Color(0xFF06141B),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              textStyle: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                              shadowColor: const Color(
                                0xFF06141B,
                              ).withOpacity(0.18),
                              elevation: 4,
                            ),
                            onPressed: _showPlaylistSelectDialog,
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            icon: Icon(
                              _showFolders ? Icons.list : Icons.folder,
                              color: const Color(0xFF4A5C6A),
                            ),
                            label: Text(_showFolders ? 'All Audio' : 'Folders'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(
                                0xFF4A5C6A,
                              ).withOpacity(0.85),
                              foregroundColor: const Color(0xFFCCD0CF),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              textStyle: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                              shadowColor: const Color(
                                0xFF06141B,
                              ).withOpacity(0.18),
                              elevation: 4,
                            ),
                            onPressed: () {
                              setState(() {
                                _showFolders = !_showFolders;
                                _selectedFolder = null;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: _showFolders
                          ? _selectedFolder == null
                                ? GridView.builder(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 8,
                                    ),
                                    gridDelegate:
                                        const SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: 2,
                                          childAspectRatio: 1.05,
                                        ),
                                    itemCount: _folderList.length,
                                    itemBuilder: (context, index) {
                                      final folder = _folderList[index];
                                      final count =
                                          _folderMap[folder]?.length ?? 0;
                                      final overlayColor = index % 2 == 0
                                          ? const Color(0xFF4A5C6A)
                                          : const Color(0xFF9BA8AB);
                                      return MediaFileCard(
                                        icon: Icons.folder,
                                        title: folder
                                            .split(Platform.pathSeparator)
                                            .last,
                                        subtitle:
                                            '$count audio file${count == 1 ? '' : 's'}',
                                        isFavourite: false,
                                        onTap: () {
                                          setState(() {
                                            _selectedFolder = folder;
                                          });
                                        },
                                        overlayColor: overlayColor,
                                      );
                                    },
                                  )
                                : Column(
                                    children: [
                                      ListTile(
                                        leading: const Icon(
                                          Icons.arrow_back,
                                          color: Colors.white,
                                        ),
                                        title: const Text(
                                          'Back to Folders',
                                          style: TextStyle(color: Colors.white),
                                        ),
                                        onTap: () {
                                          setState(() {
                                            _selectedFolder = null;
                                          });
                                        },
                                      ),
                                      Expanded(
                                        child: GridView.builder(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 8,
                                          ),
                                          gridDelegate:
                                              const SliverGridDelegateWithFixedCrossAxisCount(
                                                crossAxisCount: 2,
                                                childAspectRatio: 1.05,
                                              ),
                                          itemCount: folderAudios.length,
                                          itemBuilder: (context, index) {
                                            final asset = folderAudios[index];
                                            final overlayColor = index % 2 == 0
                                                ? const Color(0xFF4A5C6A)
                                                : const Color(0xFF9BA8AB);
                                            return FutureBuilder<File?>(
                                              future: asset.file,
                                              builder: (context, snap) {
                                                if (!snap.hasData) {
                                                  return MediaFileCard(
                                                    icon: Icons.music_note,
                                                    title: 'Loading...',
                                                    isFavourite: false,
                                                    onTap: () {},
                                                    overlayColor: overlayColor,
                                                  );
                                                }
                                                final file = snap.data!;
                                                return MediaFileCard(
                                                  icon: Icons.music_note,
                                                  title:
                                                      asset.title ??
                                                      file.path.split('/').last,
                                                  isFavourite: _favourites
                                                      .contains(asset.id),
                                                  onTap: () {
                                                    final fullList =
                                                        folderAudios;
                                                    final initialIndex =
                                                        fullList.indexWhere(
                                                          (a) =>
                                                              a.id == asset.id,
                                                        );
                                                    if (initialIndex != -1) {
                                                      Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                          builder: (_) =>
                                                              AudioPlayerScreen(
                                                                audios:
                                                                    fullList,
                                                                initialIndex:
                                                                    initialIndex,
                                                              ),
                                                        ),
                                                      );
                                                    }
                                                  },
                                                  overlayColor: overlayColor,
                                                );
                                              },
                                            );
                                          },
                                        ),
                                      ),
                                    ],
                                  )
                          : audiosToShow.isEmpty
                          ? Center(
                              child: Text(
                                _isSearching
                                    ? 'No results.'
                                    : 'No audio found.',
                                style: const TextStyle(
                                  color: Color(0xFF9BA8AB),
                                ),
                              ),
                            )
                          : GridView.builder(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 8,
                              ),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    childAspectRatio: 1.05,
                                  ),
                              itemCount: audiosToShow.length,
                              itemBuilder: (context, index) {
                                final asset = audiosToShow[index];
                                final overlayColor = index % 2 == 0
                                    ? const Color(0xFF4A5C6A)
                                    : const Color(0xFF9BA8AB);
                                return FutureBuilder<File?>(
                                  future: asset.file,
                                  builder: (context, snap) {
                                    if (!snap.hasData) {
                                      return MediaFileCard(
                                        icon: Icons.music_note,
                                        title: 'Loading...',
                                        isFavourite: false,
                                        onTap: () {},
                                        overlayColor: overlayColor,
                                      );
                                    }
                                    final file = snap.data!;
                                    return MediaFileCard(
                                      icon: Icons.music_note,
                                      title:
                                          asset.title ??
                                          file.path.split('/').last,
                                      isFavourite: _favourites.contains(
                                        asset.id,
                                      ),
                                      onTap: () {
                                        final fullList = audiosToShow;
                                        final initialIndex = fullList
                                            .indexWhere(
                                              (a) => a.id == asset.id,
                                            );
                                        if (initialIndex != -1) {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => AudioPlayerScreen(
                                                audios: fullList,
                                                initialIndex: initialIndex,
                                              ),
                                            ),
                                          );
                                        }
                                      },
                                      overlayColor: overlayColor,
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
    );
  }
}
