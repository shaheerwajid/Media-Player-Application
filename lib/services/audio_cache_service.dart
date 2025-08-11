import 'dart:io';
import 'dart:typed_data';
import 'package:shared_preferences/shared_preferences.dart';

class AudioCacheService {
  static final Map<String, File> _fileCache = {};
  static final Map<String, Uint8List?> _albumArtCache = {};
  static final Map<String, Map<String, dynamic>> _metadataCache = {};
  static const int _maxCacheSize = 100;
  static const String _cacheKey = 'audio_cache_keys';

  // Cache audio file
  static Future<File?> getCachedFile(String audioId) async {
    if (_fileCache.containsKey(audioId)) {
      return _fileCache[audioId];
    }
    return null;
  }

  static void cacheFile(String audioId, File file) {
    _evictIfNeeded();
    _fileCache[audioId] = file;
    _persistCacheKeys();
  }

  // Cache album art
  static Uint8List? getCachedAlbumArt(String audioId) {
    return _albumArtCache[audioId];
  }

  static void cacheAlbumArt(String audioId, Uint8List? albumArt) {
    _evictIfNeeded();
    _albumArtCache[audioId] = albumArt;
    _persistCacheKeys();
  }

  // Cache metadata
  static Map<String, dynamic>? getCachedMetadata(String audioId) {
    return _metadataCache[audioId];
  }

  static void cacheMetadata(String audioId, Map<String, dynamic> metadata) {
    _evictIfNeeded();
    _metadataCache[audioId] = metadata;
    _persistCacheKeys();
  }

  // Cache management
  static void _evictIfNeeded() {
    if (_fileCache.length >= _maxCacheSize) {
      final oldestKey = _fileCache.keys.first;
      _fileCache.remove(oldestKey);
      _albumArtCache.remove(oldestKey);
      _metadataCache.remove(oldestKey);
    }
  }

  static void clearCache() {
    _fileCache.clear();
    _albumArtCache.clear();
    _metadataCache.clear();
    _clearPersistedCacheKeys();
  }

  static int get cacheSize => _fileCache.length;

  // Persist cache keys for app restarts
  static Future<void> _persistCacheKeys() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = _fileCache.keys.toList();
      await prefs.setStringList(_cacheKey, keys);
    } catch (e) {
      // Ignore errors in cache persistence
    }
  }

  static Future<void> _clearPersistedCacheKeys() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cacheKey);
    } catch (e) {
      // Ignore errors in cache persistence
    }
  }

  // Load cache keys on app start
  static Future<void> loadPersistedCacheKeys() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getStringList(_cacheKey) ?? [];

      // Clear expired cache entries
      for (final key in keys) {
        if (_fileCache.containsKey(key)) {
          final file = _fileCache[key];
          if (file != null && !await file.exists()) {
            _fileCache.remove(key);
            _albumArtCache.remove(key);
            _metadataCache.remove(key);
          }
        }
      }
    } catch (e) {
      // Ignore errors in cache loading
    }
  }

  // Get cache statistics
  static Map<String, dynamic> getCacheStats() {
    return {
      'fileCacheSize': _fileCache.length,
      'albumArtCacheSize': _albumArtCache.length,
      'metadataCacheSize': _metadataCache.length,
      'maxCacheSize': _maxCacheSize,
    };
  }
}
