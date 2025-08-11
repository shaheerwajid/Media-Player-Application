import 'dart:isolate';
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:photo_manager/photo_manager.dart';
import 'audio_cache_service.dart';

class AudioMetadata {
  final String title;
  final String? artist;
  final String? album;
  final int? duration;
  final Uint8List? albumArt;

  AudioMetadata({
    required this.title,
    this.artist,
    this.album,
    this.duration,
    this.albumArt,
  });
}

class BackgroundAudioProcessor {
  static const String _isolateName = 'AudioProcessor';
  static Isolate? _isolate;
  static ReceivePort? _receivePort;
  static SendPort? _sendPort;
  static bool _isInitialized = false;

  // Initialize the background isolate
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _receivePort = ReceivePort();
      _isolate = await Isolate.spawn(
        _processAudioInBackground,
        _receivePort!.sendPort,
        debugName: _isolateName,
      );

      _sendPort = await _receivePort!.first as SendPort;
      _isInitialized = true;
    } catch (e) {
      print('Failed to initialize background audio processor: $e');
    }
  }

  // Process audio metadata in background
  static Future<AudioMetadata?> getAudioMetadata(AssetEntity audio) async {
    if (!_isInitialized) {
      await initialize();
    }

    if (_sendPort == null) return null;

    try {
      // Check cache first
      final cachedMetadata = AudioCacheService.getCachedMetadata(audio.id);
      if (cachedMetadata != null) {
        return AudioMetadata(
          title: cachedMetadata['title'] ?? '',
          artist: cachedMetadata['artist'],
          album: cachedMetadata['album'],
          duration: cachedMetadata['duration'],
          albumArt: cachedMetadata['albumArt'] != null
              ? Uint8List.fromList(cachedMetadata['albumArt'])
              : null,
        );
      }

      // Process in background
      final completer = Completer<AudioMetadata?>();
      final requestId = DateTime.now().millisecondsSinceEpoch.toString();

      _receivePort!.listen((response) {
        if (response is Map && response['requestId'] == requestId) {
          if (response['success'] == true) {
            final metadata = response['metadata'] as Map<String, dynamic>;
            final audioMetadata = AudioMetadata(
              title: metadata['title'] ?? '',
              artist: metadata['artist'],
              album: metadata['album'],
              duration: metadata['duration'],
              albumArt: metadata['albumArt'] != null
                  ? Uint8List.fromList(metadata['albumArt'])
                  : null,
            );

            // Cache the metadata
            AudioCacheService.cacheMetadata(audio.id, metadata);
            completer.complete(audioMetadata);
          } else {
            completer.complete(null);
          }
        }
      });

      _sendPort!.send({
        'type': 'processMetadata',
        'requestId': requestId,
        'audioId': audio.id,
        'title': audio.title,
        'filePath': (await audio.file)?.path,
      });

      return await completer.future.timeout(
        const Duration(seconds: 10),
        onTimeout: () => null,
      );
    } catch (e) {
      print('Error processing audio metadata: $e');
      return null;
    }
  }

  // Process multiple audios in background
  static Future<List<AudioMetadata>> processMultipleAudios(
    List<AssetEntity> audios,
  ) async {
    if (!_isInitialized) {
      await initialize();
    }

    if (_sendPort == null) return [];

    try {
      final completer = Completer<List<AudioMetadata>>();
      final requestId = DateTime.now().millisecondsSinceEpoch.toString();
      final results = <AudioMetadata>[];
      int processedCount = 0;

      _receivePort!.listen((response) {
        if (response is Map && response['requestId'] == requestId) {
          if (response['success'] == true) {
            final metadata = response['metadata'] as Map<String, dynamic>;
            final audioMetadata = AudioMetadata(
              title: metadata['title'] ?? '',
              artist: metadata['artist'],
              album: metadata['album'],
              duration: metadata['duration'],
              albumArt: metadata['albumArt'] != null
                  ? Uint8List.fromList(metadata['albumArt'])
                  : null,
            );

            results.add(audioMetadata);
            processedCount++;

            // Cache the metadata
            AudioCacheService.cacheMetadata(metadata['audioId'], metadata);

            if (processedCount >= audios.length) {
              completer.complete(results);
            }
          }
        }
      });

      // Send batch request
      _sendPort!.send({
        'type': 'processBatch',
        'requestId': requestId,
        'audios': audios
            .map(
              (audio) => {
                'id': audio.id,
                'title': audio.title,
                'filePath': null, // Will be resolved in background
              },
            )
            .toList(),
      });

      return await completer.future.timeout(
        const Duration(seconds: 30),
        onTimeout: () => results,
      );
    } catch (e) {
      print('Error processing multiple audios: $e');
      return [];
    }
  }

  // Background isolate entry point
  static void _processAudioInBackground(SendPort sendPort) {
    final receivePort = ReceivePort();
    sendPort.send(receivePort.sendPort);

    receivePort.listen((message) async {
      try {
        if (message['type'] == 'processMetadata') {
          await _handleMetadataRequest(message, sendPort);
        } else if (message['type'] == 'processBatch') {
          await _handleBatchRequest(message, sendPort);
        }
      } catch (e) {
        sendPort.send({
          'requestId': message['requestId'],
          'success': false,
          'error': e.toString(),
        });
      }
    });
  }

  // Handle single metadata request
  static Future<void> _handleMetadataRequest(
    Map<String, dynamic> message,
    SendPort sendPort,
  ) async {
    final requestId = message['requestId'];
    final audioId = message['audioId'];
    final title = message['title'];
    final filePath = message['filePath'];

    try {
      // Simulate metadata extraction (replace with actual implementation)
      final metadata = {
        'audioId': audioId,
        'title': title ?? 'Unknown',
        'artist': 'Unknown Artist',
        'album': 'Unknown Album',
        'duration': 0,
        'albumArt': null,
      };

      sendPort.send({
        'requestId': requestId,
        'success': true,
        'metadata': metadata,
      });
    } catch (e) {
      sendPort.send({
        'requestId': requestId,
        'success': false,
        'error': e.toString(),
      });
    }
  }

  // Handle batch request
  static Future<void> _handleBatchRequest(
    Map<String, dynamic> message,
    SendPort sendPort,
  ) async {
    final requestId = message['requestId'];
    final audios = message['audios'] as List;

    try {
      for (final audio in audios) {
        final metadata = {
          'audioId': audio['id'],
          'title': audio['title'] ?? 'Unknown',
          'artist': 'Unknown Artist',
          'album': 'Unknown Album',
          'duration': 0,
          'albumArt': null,
        };

        sendPort.send({
          'requestId': requestId,
          'success': true,
          'metadata': metadata,
        });
      }
    } catch (e) {
      sendPort.send({
        'requestId': requestId,
        'success': false,
        'error': e.toString(),
      });
    }
  }

  // Cleanup
  static void dispose() {
    _isolate?.kill();
    _isolate = null;
    _receivePort?.close();
    _receivePort = null;
    _sendPort = null;
    _isInitialized = false;
  }
}
