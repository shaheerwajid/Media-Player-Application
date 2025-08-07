import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/scheduler.dart';
import '../services/native_audio_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import '../theme_data.dart';

class AudioScreen extends StatefulWidget {
  final bool isAudioPlayerReady;
  final String Function(Duration) formatDuration;
  final VoidCallback onSwitchToVideo;
  final String playbackState; // 'playing', 'paused', etc.
  final int playbackPositionMs;
  final int? totalDurationMs;
  final VoidCallback onNext;
  final VoidCallback onPrevious;
  final VoidCallback? onMoreOptions;
  final void Function(int ms)? onSeek;

  const AudioScreen({
    Key? key,
    required this.isAudioPlayerReady,
    required this.formatDuration,
    required this.onSwitchToVideo,
    required this.playbackState,
    required this.playbackPositionMs,
    this.totalDurationMs,
    required this.onNext,
    required this.onPrevious,
    this.onMoreOptions,
    this.onSeek,
  }) : super(key: key);

  @override
  State<AudioScreen> createState() => _AudioScreenState();
}

class _AudioScreenState extends State<AudioScreen>
    with SingleTickerProviderStateMixin {
  late double _sliderValue;
  late int _lastNativePosition;
  late int _lastNativeUpdateTime;
  Ticker? _ticker;
  bool _isUserSeeking = false;
  int? _seekTarget;
  Timer? _sleepTimer;
  int? _sleepMinutes;

  @override
  void initState() {
    super.initState();
    _sliderValue = widget.playbackPositionMs.toDouble();
    _lastNativePosition = widget.playbackPositionMs;
    _lastNativeUpdateTime = DateTime.now().millisecondsSinceEpoch;
    _ticker = createTicker(_onTick)..start();
  }

  @override
  void didUpdateWidget(AudioScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isUserSeeking && widget.playbackPositionMs != _lastNativePosition) {
      _sliderValue = widget.playbackPositionMs.toDouble();
      _lastNativePosition = widget.playbackPositionMs;
      _lastNativeUpdateTime = DateTime.now().millisecondsSinceEpoch;
    }
  }

  void _onTick(Duration elapsed) {
    if (!_isUserSeeking && widget.playbackState == 'playing') {
      final now = DateTime.now().millisecondsSinceEpoch;
      final elapsedMs = now - _lastNativeUpdateTime;
      final estPosition = _lastNativePosition + elapsedMs;
      final maxValue =
          (widget.totalDurationMs != null && widget.totalDurationMs! > 0)
          ? widget.totalDurationMs!.toDouble()
          : (_sliderValue + 1000);
      setState(() {
        _sliderValue = estPosition.clamp(0, maxValue).toDouble();
      });
    }
  }

  @override
  void dispose() {
    _ticker?.dispose();
    _sleepTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final maxValue =
        (widget.totalDurationMs != null && widget.totalDurationMs! > 0)
        ? widget.totalDurationMs!.toDouble()
        : (_sliderValue + 1000);
    return Container(
      decoration: BoxDecoration(gradient: AppThemes.currentMainGradient),
      child: Center(
        child: widget.isAudioPlayerReady
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.audiotrack,
                    color: Theme.of(context).colorScheme.primary,
                    size: 80,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: widget.onSwitchToVideo,
                    icon: Icon(
                      Icons.videocam,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    label: Text(
                      'Switch to Video',
                      style: GoogleFonts.poppins(
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () => _showEqualizerDialog(context),
                    icon: Icon(
                      Icons.equalizer,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                    label: Text(
                      'Equalizer',
                      style: GoogleFonts.poppins(
                        color: Theme.of(context).colorScheme.onSecondary,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.timer,
                          color: _sleepTimer == null
                              ? Theme.of(context).colorScheme.onSurface
                              : Theme.of(context).colorScheme.error,
                        ),
                        onPressed: () => _showTimerSelector(context),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.skip_previous,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        iconSize: 48,
                        onPressed: widget.onPrevious,
                      ),
                      // Glassmorphic Play/Pause Button
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.13),
                          borderRadius: BorderRadius.circular(40),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.18),
                            width: 2,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(40),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                            child: IconButton(
                              iconSize: 64,
                              color: Theme.of(context).colorScheme.onSurface,
                              icon: Icon(
                                widget.playbackState == 'playing'
                                    ? Icons.pause
                                    : Icons.play_arrow,
                              ),
                              onPressed: () async {
                                if (widget.playbackState == 'playing') {
                                  (context as Element).markNeedsBuild();
                                  await NativeAudioService.pauseAudio();
                                } else {
                                  (context as Element).markNeedsBuild();
                                  await NativeAudioService.playAudio();
                                }
                              },
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.skip_next,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        iconSize: 48,
                        onPressed: widget.onNext,
                      ),
                      if (widget.onMoreOptions != null)
                        IconButton(
                          icon: Icon(
                            Icons.more_vert,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                          onPressed: widget.onMoreOptions,
                        ),
                    ],
                  ),
                  Slider(
                    value: _sliderValue.clamp(0, maxValue),
                    min: 0,
                    max: maxValue,
                    onChanged: (value) {
                      setState(() {
                        _isUserSeeking = true;
                        _sliderValue = value;
                      });
                    },
                    onChangeEnd: (value) {
                      setState(() {
                        _isUserSeeking = false;
                      });
                      if (widget.onSeek != null) {
                        widget.onSeek!(value.toInt());
                      }
                    },
                  ),
                ],
              )
            : const CircularProgressIndicator(),
      ),
    );
  }

  void _showEqualizerDialog(BuildContext context) async {
    final bands = await NativeAudioService.getEqualizerBands();
    if (bands == 0) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Equalizer'),
          content: const Text('Equalizer not available.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }
    final range = await NativeAudioService.getEqualizerBandLevelRange();
    final min = range[0];
    final max = range[1];
    List<int> levels = [];
    for (int i = 0; i < bands; i++) {
      levels.add(await NativeAudioService.getEqualizerBandLevel(i));
    }
    final presets = [
      'Custom',
      'Normal',
      'Classical',
      'Dance',
      'Flat',
      'Folk',
      'Heavy Metal',
      'Hip Hop',
      'Jazz',
      'Pop',
      'Rock',
    ];
    int selectedPreset = 0;
    bool eqEnabled = await NativeAudioService.getEqualizerEnabled();
    int reverbPreset = await NativeAudioService.getReverbPreset();
    int bassBoost = await NativeAudioService.getBassBoostStrength();
    int virtualizer = await NativeAudioService.getVirtualizerStrength();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Equalizer',
                        style: GoogleFonts.poppins(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            'ON',
                            style: GoogleFonts.poppins(
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          Switch(
                            value: eqEnabled,
                            onChanged: (v) async {
                              await NativeAudioService.setEqualizerEnabled(v);
                              setState(() => eqEnabled = v);
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: List.generate(
                        presets.length,
                        (i) => Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4.0),
                          child: ChoiceChip(
                            label: Text(presets[i]),
                            selected: selectedPreset == i,
                            onSelected: (selected) async {
                              if (selected) {
                                await NativeAudioService.setEqualizerPreset(i);
                                final newLevels =
                                    await NativeAudioService.getBandLevelsForPreset(
                                      i,
                                    );
                                setState(() {
                                  selectedPreset = i;
                                  for (
                                    int j = 0;
                                    j < levels.length && j < newLevels.length;
                                    j++
                                  ) {
                                    levels[j] = newLevels[j];
                                  }
                                });
                              }
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Reverb',
                        style: GoogleFonts.poppins(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      DropdownButton<int>(
                        value: reverbPreset,
                        dropdownColor: Theme.of(
                          context,
                        ).colorScheme.surfaceVariant,
                        style: GoogleFonts.poppins(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        items: [
                          DropdownMenuItem(value: 0, child: Text('None')),
                          DropdownMenuItem(value: 1, child: Text('Small Room')),
                          DropdownMenuItem(
                            value: 2,
                            child: Text('Medium Room'),
                          ),
                          DropdownMenuItem(value: 3, child: Text('Large Room')),
                          DropdownMenuItem(
                            value: 4,
                            child: Text('Medium Hall'),
                          ),
                          DropdownMenuItem(value: 5, child: Text('Large Hall')),
                          DropdownMenuItem(value: 6, child: Text('Plate')),
                        ],
                        onChanged: (v) async {
                          if (v != null) {
                            await NativeAudioService.setReverbPreset(v);
                            setState(() => reverbPreset = v);
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'BassBooster',
                        style: GoogleFonts.poppins(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      Expanded(
                        child: Slider(
                          value: bassBoost.toDouble(),
                          min: 0,
                          max: 1000,
                          onChanged: (v) async {
                            await NativeAudioService.setBassBoostStrength(
                              v.toInt(),
                            );
                            setState(() => bassBoost = v.toInt());
                          },
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Virtualizer',
                        style: GoogleFonts.poppins(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      Expanded(
                        child: Slider(
                          value: virtualizer.toDouble(),
                          min: 0,
                          max: 1000,
                          onChanged: (v) async {
                            await NativeAudioService.setVirtualizerStrength(
                              v.toInt(),
                            );
                            setState(() => virtualizer = v.toInt());
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(
                      bands,
                      (i) => Expanded(
                        child: Column(
                          children: [
                            Text(
                              '${[60, 230, 910, 3600, 14000][i % 5]}Hz',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface,
                                fontSize: 12,
                              ),
                            ),
                            RotatedBox(
                              quarterTurns: -1,
                              child: Slider(
                                value: levels[i].toDouble(),
                                min: min.toDouble(),
                                max: max.toDouble(),
                                divisions: (max - min) > 0 ? (max - min) : null,
                                label: levels[i].toString(),
                                onChanged: eqEnabled
                                    ? (v) async {
                                        await NativeAudioService.setEqualizerBandLevel(
                                          i,
                                          v.toInt(),
                                        );
                                        setState(() => levels[i] = v.toInt());
                                      }
                                    : null,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Close',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showTimerSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (c) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('Off'),
                onTap: () {
                  _cancelSleepTimer();
                  Navigator.pop(c);
                },
              ),
              for (var m in [15, 30, 45, 60])
                ListTile(
                  title: Text('$m minutes'),
                  onTap: () {
                    _setSleepTimer(Duration(minutes: m));
                    Navigator.pop(c);
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  void _setSleepTimer(Duration d) {
    _sleepTimer?.cancel();
    _sleepTimer = Timer(d, () async {
      await NativeAudioService.pauseAudio();
      if (mounted) setState(() => _sleepTimer = null);
    });
    setState(() => _sleepMinutes = d.inMinutes);
  }

  void _cancelSleepTimer() {
    _sleepTimer?.cancel();
    setState(() {
      _sleepTimer = null;
      _sleepMinutes = null;
    });
  }
}
