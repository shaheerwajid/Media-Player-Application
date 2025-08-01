import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:photo_manager/photo_manager.dart';
import '../services/video_service.dart';
import 'video_player_screen/video_player_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../main.dart';
import 'dart:ui';
import '../widgets/skeleton_media_card.dart';

class MediaFileCard extends StatefulWidget {
  final Widget? thumbnail;
  final IconData? icon;
  final String title;
  final String? subtitle;
  final bool isFavourite;
  final VoidCallback onTap;
  final Color overlayColor;
  final String? duration;
  const MediaFileCard({
    super.key,
    this.thumbnail,
    this.icon,
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
          color: widget.overlayColor.withOpacity(0.28), // more transparent
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
                        widget.thumbnail ??
                            (widget.icon != null
                                ? Icon(
                                    widget.icon,
                                    size: 32,
                                    color: const Color(0xFFCCD0CF),
                                  )
                                : const SizedBox()),
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
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (widget.subtitle != null) ...[
                      const SizedBox(height: 1),
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
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
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

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with RouteAware {
  List<AssetEntity> _videoAssets = [];
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  late final Player player;
  late final VideoController videoController;
  String? _currentVideoName;
  bool _loading = true;
  bool _showFolders = false;
  Map<String, List<AssetEntity>> _folderMap = {};
  List<String> _folderList = [];
  String? _selectedFolder;
  Set<String> _favourites = {};
  late SharedPreferences _prefs;

  @override
  void initState() {
    super.initState();
    player = Player();
    videoController = VideoController(player);
    _initPrefs();
    _fetchAllVideos();
    // The listener just triggers a rebuild.
    _searchController.addListener(() {
      setState(() {});
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)! as PageRoute);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didPopNext() {
    // Called when coming back to this screen
    _fetchAllVideos();
  }

  Future<void> _initPrefs() async {
    _prefs = await SharedPreferences.getInstance();
    _loadFavourites();
  }

  void _loadFavourites() {
    final favs = _prefs.getStringList('favourites') ?? [];
    setState(() {
      _favourites = favs.toSet();
    });
  }

  Future<void> _fetchAllVideos() async {
    if (mounted) {
      setState(() {
        _loading = true;
      });
    }
    final result = await VideoService.fetchAllVideos();
    if (result.permissionState == PermissionState.authorized ||
        result.permissionState == PermissionState.limited) {
      if (mounted) {
        setState(() {
          _videoAssets = result.videos;
          _loading = false;
        });
      }
      _buildFolderMap(result.videos);
      _loadFavourites();
    } else {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Storage permission is required to access videos.'),
          ),
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
    if (mounted) {
      setState(() {
        _folderMap = folderMap;
        _folderList = folderMap.keys.toList();
      });
    }
  }

  void _startSearch() {
    setState(() {
      _isSearching = true;
    });
  }

  void _stopSearch() {
    setState(() {
      _isSearching = false;
      _searchController.clear();
    });
  }

  void _playVideo(AssetEntity asset) async {
    final file = await asset.file;
    if (file != null) {
      await player.open(Media(file.path), play: true);
      setState(() {
        _currentVideoName =
            asset.title ?? file.path.split(Platform.pathSeparator).last;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Filter the list directly inside the build method.
    final videosToShow = _isSearching
        ? _videoAssets.where((asset) {
            final title = asset.title?.toLowerCase() ?? '';
            final query = _searchController.text.toLowerCase();
            return title.contains(query);
          }).toList()
        : _videoAssets;
    final List<AssetEntity> folderVideos =
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
                  hintText: 'Search videos...',
                  border: InputBorder.none,
                  hintStyle: Theme.of(context).textTheme.bodyMedium,
                  filled: true,
                  fillColor: const Color(0xFF4A5C6A).withOpacity(0.18),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: Color(0xFF4A5C6A),
                  ),
                ),
              )
            : Text('Videos', style: Theme.of(context).textTheme.titleLarge),
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
        foregroundColor: Theme.of(context).colorScheme.onBackground,
        centerTitle: true,
        titleTextStyle: const TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.1,
        ),
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
                    if (_showFolders)
                      if (_selectedFolder == null)
                        // Folders grid
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
                            itemCount: _folderList.length,
                            itemBuilder: (context, index) {
                              final folder = _folderList[index];
                              final count = _folderMap[folder]?.length ?? 0;
                              final overlayColor = index % 2 == 0
                                  ? const Color(0xFF4A5C6A)
                                  : const Color(0xFF9BA8AB);
                              return TweenAnimationBuilder(
                                tween: Tween<Offset>(
                                  begin: const Offset(0, 0.12),
                                  end: Offset.zero,
                                ),
                                duration: const Duration(milliseconds: 400),
                                curve: Curves.easeOut,
                                builder: (context, offset, child) =>
                                    AnimatedOpacity(
                                      opacity: 1.0,
                                      duration: const Duration(
                                        milliseconds: 400,
                                      ),
                                      curve: Curves.easeOut,
                                      child: AnimatedSlide(
                                        offset: offset,
                                        duration: const Duration(
                                          milliseconds: 400,
                                        ),
                                        curve: Curves.easeOut,
                                        child: _AnimatedMediaFileCard(
                                          child: MediaFileCard(
                                            icon: Icons.folder_outlined,
                                            title: folder
                                                .split(Platform.pathSeparator)
                                                .last,
                                            subtitle:
                                                '$count video${count == 1 ? '' : 's'}',
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
                                        ),
                                      ),
                                    ),
                              );
                            },
                          ),
                        )
                      else ...[
                        TweenAnimationBuilder(
                          tween: Tween<Offset>(
                            begin: const Offset(0, 0.12),
                            end: Offset.zero,
                          ),
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeOut,
                          builder: (context, offset, child) => AnimatedOpacity(
                            opacity: 1.0,
                            duration: const Duration(milliseconds: 400),
                            curve: Curves.easeOut,
                            child: AnimatedSlide(
                              offset: offset,
                              duration: const Duration(milliseconds: 400),
                              curve: Curves.easeOut,
                              child: _AnimatedMediaFileCard(
                                child: ListTile(
                                  leading: const Icon(
                                    Icons.arrow_back_outlined,
                                    color: Colors.white,
                                  ),
                                  title: Text(
                                    'Back to Folders',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodyLarge,
                                  ),
                                  onTap: () {
                                    setState(() {
                                      _selectedFolder = null;
                                    });
                                  },
                                ),
                                onTap: () {
                                  setState(() {
                                    _selectedFolder = null;
                                  });
                                },
                              ),
                            ),
                          ),
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
                            itemCount: folderVideos.length,
                            itemBuilder: (context, index) {
                              final asset = folderVideos[index];
                              final overlayColor = index % 2 == 0
                                  ? const Color(0xFF4A5C6A)
                                  : const Color(0xFF9BA8AB);
                              return TweenAnimationBuilder(
                                tween: Tween<Offset>(
                                  begin: const Offset(0, 0.12),
                                  end: Offset.zero,
                                ),
                                duration: const Duration(milliseconds: 400),
                                curve: Curves.easeOut,
                                builder: (context, offset, child) => AnimatedOpacity(
                                  opacity: 1.0,
                                  duration: const Duration(milliseconds: 400),
                                  curve: Curves.easeOut,
                                  child: AnimatedSlide(
                                    offset: offset,
                                    duration: const Duration(milliseconds: 400),
                                    curve: Curves.easeOut,
                                    child: _AnimatedMediaFileCard(
                                      child: FutureBuilder<File?>(
                                        future: asset.file,
                                        builder: (context, snapshot) {
                                          if (!snapshot.hasData) {
                                            return MediaFileCard(
                                              icon: Icons.movie_outlined,
                                              title: 'Loading...',
                                              isFavourite: false,
                                              onTap: () {},
                                              overlayColor: overlayColor,
                                            );
                                          }
                                          final file = snapshot.data!;
                                          return FutureBuilder<Uint8List?>(
                                            future: asset.thumbnailDataWithSize(
                                              ThumbnailSize(80, 80),
                                            ),
                                            builder: (context, thumbSnapshot) {
                                              Widget? thumbWidget;
                                              if (thumbSnapshot
                                                          .connectionState ==
                                                      ConnectionState.done &&
                                                  thumbSnapshot.hasData &&
                                                  thumbSnapshot.data != null) {
                                                thumbWidget = ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                  child: Image.memory(
                                                    thumbSnapshot.data!,
                                                    width: 44,
                                                    height: 44,
                                                    fit: BoxFit.cover,
                                                  ),
                                                );
                                              }
                                              return MediaFileCard(
                                                thumbnail: thumbWidget,
                                                title:
                                                    asset.title ??
                                                    file.path
                                                        .split(
                                                          Platform
                                                              .pathSeparator,
                                                        )
                                                        .last,
                                                isFavourite: _favourites
                                                    .contains(asset.id),
                                                onTap: () async {
                                                  final fullList = folderVideos;
                                                  final initialIndex = fullList
                                                      .indexWhere(
                                                        (a) => a.id == asset.id,
                                                      );
                                                  if (initialIndex != -1) {
                                                    final result =
                                                        await Navigator.of(
                                                          context,
                                                        ).push(
                                                          MaterialPageRoute(
                                                            builder: (_) =>
                                                                VideoPlayerScreen(
                                                                  videoAssets:
                                                                      fullList,
                                                                  initialIndex:
                                                                      initialIndex,
                                                                ),
                                                          ),
                                                        );
                                                    if (result == true) {
                                                      _loadFavourites();
                                                      setState(() {});
                                                    }
                                                  }
                                                },
                                                overlayColor: overlayColor,
                                              );
                                            },
                                          );
                                        },
                                      ),
                                      onTap: () async {
                                        final fullList = folderVideos;
                                        final initialIndex = fullList
                                            .indexWhere(
                                              (a) => a.id == asset.id,
                                            );
                                        if (initialIndex != -1) {
                                          final result =
                                              await Navigator.of(context).push(
                                                MaterialPageRoute(
                                                  builder: (_) =>
                                                      VideoPlayerScreen(
                                                        videoAssets: fullList,
                                                        initialIndex:
                                                            initialIndex,
                                                      ),
                                                ),
                                              );
                                          if (result == true) {
                                            _loadFavourites();
                                            setState(() {});
                                          }
                                        }
                                      },
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ]
                    else if (videosToShow.isEmpty)
                      const Expanded(
                        child: Center(
                          child: Text(
                            'No videos found.',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      )
                    else
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          itemCount: videosToShow.length,
                          itemBuilder: (context, index) {
                            final asset = videosToShow[index];
                            final overlayColor = index % 2 == 0
                                ? const Color(0xFF4A5C6A)
                                : const Color(0xFF9BA8AB);
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: _AnimatedMediaFileCard(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(28),
                                  child: BackdropFilter(
                                    filter: ImageFilter.blur(
                                      sigmaX: 18,
                                      sigmaY: 18,
                                    ),
                                    child: Container(
                                      margin: const EdgeInsets.symmetric(
                                        vertical: 0,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 18,
                                      ),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(28),
                                        color: Colors.white.withOpacity(0.13),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(
                                              0xFF06141B,
                                            ).withOpacity(0.18),
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
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          // Thumbnail
                                          FutureBuilder<Uint8List?>(
                                            future: asset.thumbnailDataWithSize(
                                              ThumbnailSize(64, 64),
                                            ),
                                            builder: (context, snapshot) {
                                              Widget thumbWidget;
                                              if (snapshot.connectionState ==
                                                      ConnectionState.done &&
                                                  snapshot.hasData &&
                                                  snapshot.data != null) {
                                                thumbWidget = ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                  child: Image.memory(
                                                    snapshot.data!,
                                                    width: 64,
                                                    height: 64,
                                                    fit: BoxFit.cover,
                                                  ),
                                                );
                                              } else {
                                                thumbWidget = Icon(
                                                  Icons.movie_outlined,
                                                  size: 32,
                                                  color: const Color(
                                                    0xFFCCD0CF,
                                                  ),
                                                );
                                              }
                                              return Container(
                                                width: 64,
                                                height: 64,
                                                decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(16),
                                                  color: Colors.white
                                                      .withOpacity(0.18),
                                                ),
                                                child: thumbWidget,
                                              );
                                            },
                                          ),
                                          const SizedBox(width: 16),
                                          // Details
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Text(
                                                  asset.title ?? 'Unknown',
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodyLarge
                                                      ?.copyWith(
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                ),
                                                // Optionally add subtitle or other details here
                                              ],
                                            ),
                                          ),
                                          // Favourite icon (top right)
                                          Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.start,
                                            children: [
                                              AnimatedSwitcher(
                                                duration: const Duration(
                                                  milliseconds: 200,
                                                ),
                                                transitionBuilder:
                                                    (child, animation) =>
                                                        ScaleTransition(
                                                          scale: animation,
                                                          child: child,
                                                        ),
                                                child:
                                                    _favourites.contains(
                                                      asset.id,
                                                    )
                                                    ? Icon(
                                                        Icons.star_outlined,
                                                        key: const ValueKey(
                                                          'favorite',
                                                        ),
                                                        color: const Color(
                                                          0xFFCCD0CF,
                                                        ),
                                                        size: 24,
                                                      )
                                                    : const SizedBox(
                                                        width: 24,
                                                        height: 24,
                                                        key: ValueKey(
                                                          'not_favorite',
                                                        ),
                                                      ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                onTap: () async {
                                  final fullList = _videoAssets;
                                  final initialIndex = fullList.indexWhere(
                                    (a) => a.id == asset.id,
                                  );
                                  if (initialIndex != -1) {
                                    final result = await Navigator.of(context)
                                        .push(
                                          MaterialPageRoute(
                                            builder: (_) => VideoPlayerScreen(
                                              videoAssets: fullList,
                                              initialIndex: initialIndex,
                                            ),
                                          ),
                                        );
                                    if (result == true) {
                                      _loadFavourites();
                                      setState(() {});
                                    }
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
