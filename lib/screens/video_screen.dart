import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:io';
import 'dart:typed_data';
import 'package:photo_manager/photo_manager.dart';
import '../services/video_service.dart';
import 'video_player_screen/video_player_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/skeleton_media_card.dart';

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

  @override
  void initState() {
    super.initState();
    _initPrefs();
    _fetchAllVideos();
    _searchController.addListener(_filterVideos);
  }

  Future<void> _initPrefs() async {
    _prefs = await SharedPreferences.getInstance();
    _loadFavourites();
    _loadHistory();
  }

  void _loadFavourites() {
    final favs = _prefs.getStringList('favourites') ?? [];
    setState(() {
      _favourites = favs.toSet();
    });
  }

  void _loadHistory() {
    final historyIds = _prefs.getStringList('video_history') ?? [];
    if (historyIds.isNotEmpty) {
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

    await _prefs.remove('video_history');
    if (mounted) {
      setState(() {
        _historyVideos.clear();
      });
    }
  }

  void _buildFolderMap(List<AssetEntity> assets) async {
    if (!mounted) return;

    print('Building folder map for ${assets.length} videos');
    final Map<String, List<AssetEntity>> folderMap = {};
    for (final asset in assets) {
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
      });
    }
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
      });
    } else {
      final query = _searchController.text.toLowerCase();
      setState(() {
        _filteredVideos = _videoAssets.where((asset) {
          final title = asset.title?.toLowerCase() ?? '';
          return title.contains(query);
        }).toList();
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
    if (result.permissionState == PermissionState.authorized ||
        result.permissionState == PermissionState.limited) {
      if (mounted) {
        setState(() {
          _videoAssets = result.videos;
          _filteredVideos = result.videos;
          _loading = false;
        });
      }
      _loadFavourites();
      _loadHistory();
      _buildFolderMap(result.videos);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text(
          'Media Player',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xFFCCD0CF),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.cleaning_services_outlined,
              color: Color(0xFF9BA8AB),
            ),
            onPressed: () {
              // TODO: Implement clean functionality
            },
          ),
          IconButton(
            icon: Icon(
              _isSearching ? Icons.close : Icons.search,
              color: const Color(0xFF9BA8AB),
            ),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                  _filteredVideos = _videoAssets;
                }
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Color(0xFF9BA8AB)),
            onPressed: () {
              // TODO: Implement delete functionality
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // History Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'History',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFCCD0CF),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.delete_outline,
                      color: Color(0xFF9BA8AB),
                      size: 20,
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
                child: _historyVideos.isEmpty
                    ? const Center(
                        child: Text(
                          'No recent videos',
                          style: TextStyle(
                            color: Color(0xFF9BA8AB),
                            fontSize: 14,
                          ),
                        ),
                      )
                    : ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _historyVideos.length,
                        itemBuilder: (context, index) {
                          final asset = _historyVideos[index];
                          return _buildHistoryCard(asset, index);
                        },
                      ),
              ),
              const SizedBox(height: 24),

              // Search Field (when searching)
              if (_isSearching) ...[
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF253745).withOpacity(0.6),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF4A5C6A).withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: TextField(
                    controller: _searchController,
                    autofocus: true,
                    style: const TextStyle(
                      color: Color(0xFFCCD0CF),
                      fontSize: 16,
                    ),
                    decoration: const InputDecoration(
                      hintText: 'Search videos...',
                      hintStyle: TextStyle(
                        color: Color(0xFF9BA8AB),
                        fontSize: 16,
                      ),
                      border: InputBorder.none,
                      prefixIcon: Icon(Icons.search, color: Color(0xFF9BA8AB)),
                    ),
                  ),
                ),
              ],

              // Filter Tabs
              Row(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildFilterTab('Videos', 0),
                          const SizedBox(width: 12),
                          _buildFilterTab('Folder', 1),
                        ],
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.shuffle, color: Color(0xFF9BA8AB)),
                    onPressed: () {
                      // TODO: Implement shuffle functionality
                    },
                  ),
                  IconButton(
                    icon: Icon(
                      _isGridView ? Icons.view_list : Icons.grid_view,
                      color: const Color(0xFF9BA8AB),
                    ),
                    onPressed: () {
                      setState(() {
                        _isGridView = !_isGridView;
                      });
                    },
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
                                ? Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Text(
                                          'No folders found.',
                                          style: TextStyle(
                                            color: Color(0xFF9BA8AB),
                                            fontSize: 16,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Debug: _showFolders=$_showFolders, _folderList.length=${_folderList.length}',
                                          style: const TextStyle(
                                            color: Color(0xFF9BA8AB),
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
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
                                          childAspectRatio: 1.2,
                                        ),
                                    itemCount: _folderList.length,
                                    itemBuilder: (context, index) {
                                      final folder = _folderList[index];
                                      final count =
                                          _folderMap[folder]?.length ?? 0;
                                      return _buildFolderCard(
                                        folder,
                                        count,
                                        index,
                                      );
                                    },
                                  )
                          : Column(
                              children: [
                                _buildBackToFoldersCard(),
                                Expanded(child: _buildFolderVideosList()),
                              ],
                            )
                    : _filteredVideos.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _isSearching
                                  ? Icons.search_off
                                  : Icons.video_library_outlined,
                              color: const Color(0xFF9BA8AB),
                              size: 48,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _isSearching
                                  ? 'No videos found matching your search.'
                                  : 'No videos found.',
                              style: const TextStyle(
                                color: Color(0xFF9BA8AB),
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
                        itemCount: _filteredVideos.length,
                        itemBuilder: (context, index) {
                          final asset = _filteredVideos[index];
                          return _buildGridVideoCard(asset, index);
                        },
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: _filteredVideos.length,
                        itemBuilder: (context, index) {
                          final asset = _filteredVideos[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: _buildVideoCard(asset, index),
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

  Widget _buildFilterTab(String label, int index) {
    final isSelected = _selectedTabIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTabIndex = index;
          if (label == 'Folder') {
            _showFolders = true;
            _selectedFolder = null;
          } else {
            _showFolders = false;
            _selectedFolder = null;
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF4A5C6A) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF4A5C6A)
                : const Color(0xFF253745),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? const Color(0xFFCCD0CF)
                : const Color(0xFF9BA8AB),
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
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
              style: const TextStyle(
                color: Color(0xFFCCD0CF),
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
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: const Color(0xFF11212D).withOpacity(0.4),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF06141B).withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(
            width: 1,
            style: BorderStyle.solid,
            color: const Color(0xFF4A5C6A).withOpacity(0.3),
          ),
        ),
        child: Container(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Thumbnail
              FutureBuilder<Uint8List?>(
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
                        width: 80,
                        height: 80,
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
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: const Color(0xFF253745),
                    ),
                    child: thumbWidget,
                  );
                },
              ),
              const SizedBox(width: 12),
              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      asset.title ?? 'Unknown',
                      style: const TextStyle(
                        color: Color(0xFFCCD0CF),
                        fontSize: 16,
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
                                fontSize: 14,
                              ),
                            );
                          } catch (e) {
                            return const Text(
                              'Unknown',
                              style: TextStyle(
                                color: Color(0xFF9BA8AB),
                                fontSize: 14,
                              ),
                            );
                          }
                        } else {
                          return const Text(
                            'Unknown',
                            style: TextStyle(
                              color: Color(0xFF9BA8AB),
                              fontSize: 14,
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
              // Favourite icon and more options
              Column(
                children: [
                  Icon(
                    _favourites.contains(asset.id)
                        ? Icons.star
                        : Icons.star_border,
                    color: _favourites.contains(asset.id)
                        ? Colors.amber
                        : const Color(0xFF9BA8AB),
                    size: 20,
                  ),
                  const SizedBox(height: 8),
                  const Icon(
                    Icons.more_vert,
                    color: Color(0xFF9BA8AB),
                    size: 20,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
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
          color: overlayColor.withOpacity(0.28),
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
                    Icons.folder_outlined,
                    size: 28,
                    color: const Color(0xFFCCD0CF),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    folder.split(Platform.pathSeparator).last,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFFCCD0CF),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$count video${count == 1 ? '' : 's'}',
                    style: const TextStyle(
                      color: Color(0xFF9BA8AB),
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
            const Text(
              'Back to Folders',
              style: TextStyle(
                color: Color(0xFFCCD0CF),
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
      return const Center(
        child: Text(
          'No videos in this folder.',
          style: TextStyle(color: Color(0xFF9BA8AB), fontSize: 16),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: folderVideos.length,
      itemBuilder: (context, index) {
        final asset = folderVideos[index];
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: _buildVideoCard(asset, index),
        );
      },
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
          color: const Color(0xFF11212D).withOpacity(0.4),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF06141B).withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(
            width: 1,
            style: BorderStyle.solid,
            color: const Color(0xFF4A5C6A).withOpacity(0.3),
          ),
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
                          decoration: const BoxDecoration(
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(16),
                              topRight: Radius.circular(16),
                            ),
                            color: Color(0xFF253745),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.movie_outlined,
                              color: Color(0xFF9BA8AB),
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
              child: Icon(
                _favourites.contains(asset.id) ? Icons.star : Icons.star_border,
                color: _favourites.contains(asset.id)
                    ? Colors.amber
                    : const Color(0xFF9BA8AB),
                size: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
