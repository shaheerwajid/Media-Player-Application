import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

class NativeAudioService {
  static const MethodChannel _channel = MethodChannel(
    'com.example.video_player/audio_controls',
  );
  static const EventChannel _eventChannel = EventChannel(
    'com.example.video_player/audio_events',
  );

  // Global now playing notifier
  static final ValueNotifier<Map<String, dynamic>?> nowPlayingNotifier =
      ValueNotifier<Map<String, dynamic>?>(null);
  static bool _bridgeInitialized = false;

  static Future<void> ensurePlaybackBridgeInitialized() async {
    if (_bridgeInitialized) return;
    _bridgeInitialized = true;
    // Seed current state
    try {
      final info = await getCurrentPlaybackInfo();
      if (info != null) nowPlayingNotifier.value = info;
    } catch (_) {}
    // Subscribe to stream
    playbackStateStream.listen((event) {
      try {
        if (event is Map && event['state'] != null) {
          nowPlayingNotifier.value = Map<String, dynamic>.from(event);
        }
      } catch (_) {}
    });
  }

  static Future<void> startAudio(String filePath, int positionMs) async {
    await _channel.invokeMethod('startAudio', {
      'filePath': filePath,
      'position': positionMs,
    });
  }

  static Future<void> pauseAudio() async => _channel.invokeMethod('pauseAudio');
  static Future<void> playAudio() async => _channel.invokeMethod('playAudio');
  static Future<void> nextAudio() async => _channel.invokeMethod('nextAudio');
  static Future<void> previousAudio() async =>
      _channel.invokeMethod('previousAudio');
  static Future<void> seekTo(int positionMs) async =>
      _channel.invokeMethod('seekTo', {'position': positionMs});

  static Future<void> playNextAudio(String filePath, int positionMs) async {
    await _channel.invokeMethod('playNextAudio', {
      'filePath': filePath,
      'position': positionMs,
    });
  }

  // Equalizer & audio effects helpers
  static Future<int> getEqualizerBands() async =>
      (await _channel.invokeMethod<int>('getEqualizerBands')) ?? 0;

  static Future<List<int>> getEqualizerBandLevelRange() async {
    final result = await _channel.invokeMethod<List<dynamic>>(
      'getEqualizerBandLevelRange',
    );
    return result?.map((e) => e as int).toList() ?? [0, 0];
  }

  static Future<int> getEqualizerBandLevel(int band) async =>
      (await _channel.invokeMethod<int>('getEqualizerBandLevel', {
        'band': band,
      })) ??
      0;

  static Future<void> setEqualizerBandLevel(int band, int level) async =>
      _channel.invokeMethod('setEqualizerBandLevel', {
        'band': band,
        'level': level,
      });

  static Future<void> setEqualizerEnabled(bool enabled) async =>
      _channel.invokeMethod('setEqualizerEnabled', {'enabled': enabled});

  static Future<bool> getEqualizerEnabled() async =>
      (await _channel.invokeMethod<bool>('getEqualizerEnabled')) ?? true;

  static Future<void> setEqualizerPreset(int preset) async =>
      _channel.invokeMethod('setEqualizerPreset', {'preset': preset});

  static Future<int> getEqualizerPreset() async =>
      (await _channel.invokeMethod<int>('getEqualizerPreset')) ?? 0;

  static Future<void> setReverbPreset(int preset) async =>
      _channel.invokeMethod('setReverbPreset', {'preset': preset});

  static Future<int> getReverbPreset() async =>
      (await _channel.invokeMethod<int>('getReverbPreset')) ?? 0;

  static Future<void> setBassBoostStrength(int strength) async =>
      _channel.invokeMethod('setBassBoostStrength', {'strength': strength});

  static Future<int> getBassBoostStrength() async =>
      (await _channel.invokeMethod<int>('getBassBoostStrength')) ?? 0;

  static Future<void> setVirtualizerStrength(int strength) async =>
      _channel.invokeMethod('setVirtualizerStrength', {'strength': strength});

  static Future<int> getVirtualizerStrength() async =>
      (await _channel.invokeMethod<int>('getVirtualizerStrength')) ?? 0;

  static Future<List<int>> getBandLevelsForPreset(int preset) async {
    final result = await _channel.invokeMethod<List<dynamic>>(
      'getBandLevelsForPreset',
      {'preset': preset},
    );
    return result?.map((e) => e as int).toList() ?? [];
  }

  // Playback speed
  static Future<void> setPlaybackSpeed(double speed) async =>
      _channel.invokeMethod('setPlaybackSpeed', {'speed': speed});

  static Future<double> getPlaybackSpeed() async =>
      (await _channel.invokeMethod<double>('getPlaybackSpeed')) ?? 1.0;

  // Set as ringtone (Android)
  static Future<bool> setAsRingtone(String filePath) async =>
      (await _channel.invokeMethod<bool>('setAsRingtone', {
        'filePath': filePath,
      })) ??
      false;

  // Listen to playback state changes from native
  static Stream<Map<String, dynamic>> get playbackStateStream => _eventChannel
      .receiveBroadcastStream()
      .map((event) => Map<String, dynamic>.from(event));

  static Future<Map<String, dynamic>?> getCurrentPlaybackInfo() async {
    final result = await _channel.invokeMethod<Map<dynamic, dynamic>>(
      'getCurrentPlaybackInfo',
    );
    if (result == null) return null;
    return result.map((key, value) => MapEntry(key.toString(), value));
  }
}
