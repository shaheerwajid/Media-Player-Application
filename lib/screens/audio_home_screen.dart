import 'dart:io';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import '../services/audio_service.dart';
import 'audio_player_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../main.dart';
import 'dart:ui';
import '../widgets/skeleton_media_card.dart';

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
                leading: const Icon(Icons.clear_outlined),
                title: const Text('All Audio'),
                onTap: () {
                  setState(() => _selectedPlaylist = null);
                  Navigator.pop(c);
                },
              ),
              for (final playlist in _playlists)
                ListTile(
                  leading: const Icon(Icons.queue_music_outlined),
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
                style: Theme.of(context).textTheme.bodyLarge,
                decoration: InputDecoration(
                  hintText: 'Search audio...',
                  border: InputBorder.none,
                  hintStyle: Theme.of(context).textTheme.bodyMedium,
                  filled: true,
                  fillColor: const Color(0xFF4A5C6A).withOpacity(0.18),
                  prefixIcon: const Icon(
                    Icons.search_outlined,
                    color: Color(0xFF4A5C6A),
                  ),
                ),
              )
            : Text(
                'Audio Browser',
                style: Theme.of(context).textTheme.titleLarge,
              ),
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
              icon: const Icon(Icons.close_outlined, color: Color(0xFF9BA8AB)),
              onPressed: _stopSearch,
            )
          else ...[
            IconButton(
              icon: const Icon(Icons.search_outlined, color: Color(0xFF4A5C6A)),
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
              ? const SkeletonList(itemCount: 8)
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
                              Icons.queue_music_outlined,
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
                              _showFolders
                                  ? Icons.list_outlined
                                  : Icons.folder_outlined,
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
                                      return _AnimatedMediaFileCard(
                                        child: MediaFileCard(
                                          icon: Icons.folder_outlined,
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
                                        ),
                                        onTap: () {
                                          setState(() {
                                            _selectedFolder = folder;
                                          });
                                        },
                                      );
                                    },
                                  )
                                : Column(
                                    children: [
                                      ListTile(
                                        leading: const Icon(
                                          Icons.arrow_back_outlined,
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
                                            return _AnimatedMediaFileCard(
                                              child: FutureBuilder<File?>(
                                                future: asset.file,
                                                builder: (context, snap) {
                                                  if (!snap.hasData) {
                                                    return MediaFileCard(
                                                      icon: Icons
                                                          .music_note_outlined,
                                                      title: 'Loading...',
                                                      isFavourite: false,
                                                      onTap: () {},
                                                      overlayColor:
                                                          overlayColor,
                                                    );
                                                  }
                                                  final file = snap.data!;
                                                  return MediaFileCard(
                                                    icon: Icons
                                                        .music_note_outlined,
                                                    title:
                                                        asset.title ??
                                                        file.path
                                                            .split('/')
                                                            .last,
                                                    isFavourite: _favourites
                                                        .contains(asset.id),
                                                    onTap: () {
                                                      final fullList =
                                                          folderAudios;
                                                      final initialIndex =
                                                          fullList.indexWhere(
                                                            (a) =>
                                                                a.id ==
                                                                asset.id,
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
                                              ),
                                              onTap: () {
                                                final fullList = folderAudios;
                                                final initialIndex = fullList
                                                    .indexWhere(
                                                      (a) => a.id == asset.id,
                                                    );
                                                if (initialIndex != -1) {
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (_) =>
                                                          AudioPlayerScreen(
                                                            audios: fullList,
                                                            initialIndex:
                                                                initialIndex,
                                                          ),
                                                    ),
                                                  );
                                                }
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
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              itemCount: audiosToShow.length,
                              itemBuilder: (context, index) {
                                final asset = audiosToShow[index];
                                final overlayColor = index % 2 == 0
                                    ? const Color(0xFF4A5C6A)
                                    : const Color(0xFF9BA8AB);
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 6,
                                  ),
                                  child: _AnimatedMediaFileCard(
                                    child: FutureBuilder<File?>(
                                      future: asset.file,
                                      builder: (context, snapshot) {
                                        String title = asset.title ?? 'Unknown';
                                        if (snapshot.hasData &&
                                            snapshot.data != null) {
                                          title =
                                              asset.title ??
                                              snapshot.data!.path
                                                  .split('/')
                                                  .last;
                                        }
                                        return MediaFileCard(
                                          icon: Icons.music_note_outlined,
                                          title: title,
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
                                                  builder: (_) =>
                                                      AudioPlayerScreen(
                                                        audios: fullList,
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
                                    ),
                                    onTap: () {
                                      final fullList = audiosToShow;
                                      final initialIndex = fullList.indexWhere(
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
                                  ),
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
