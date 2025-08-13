import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:async';
import 'video_screen.dart';
import '../services/native_audio_service.dart';
import '../services/current_audio_context.dart';
import 'audio_player_screen.dart';
import 'audio_home_screen.dart';
import 'settings_screen.dart';
import '../widgets/animated_nav_bar.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({Key? key}) : super(key: key);

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0; // Default to Video tab
  String? _lastNowPlayingPath;

  @override
  void initState() {
    super.initState();
    // Ensure global playback bridge is initialized for Now Playing
    NativeAudioService.ensurePlaybackBridgeInitialized();
  }

  final List<Widget> _screens = const [
    VideoScreen(),
    AudioHomeScreen(),
    SettingsScreen(),
  ];

  void _openCurrentAudioIfPossible() {
    final sel = CurrentAudioContext.selection;
    if (sel != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) =>
              AudioPlayerScreen(audios: sel.audios, initialIndex: sel.index),
        ),
      );
    } else {
      // No selection cached; switch to Music tab as fallback
      setState(() => _selectedIndex = 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_selectedIndex != 0) {
          setState(() => _selectedIndex = 0);
          return false;
        }
        return true;
      },
      child: Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomLeft,
              end: Alignment.topRight,
              colors: [
                Color(0xFF06151C),
                Color(0xFF0C1A24),
                Color(0xFF172734),
                Color(0xFF2F404D),
                Color(0xFF64727A),
                Color(0xFFCCD1CF),
              ],
              stops: [0.0, 0.2, 0.43, 0.54, 0.78, 1.0],
            ),
          ),
          child: Stack(
            children: [
              IndexedStack(index: _selectedIndex, children: _screens),
              Positioned(
                left: 12,
                right: 12,
                bottom: 24,
                child: ValueListenableBuilder<Map<String, dynamic>?>(
                  valueListenable: NativeAudioService.nowPlayingNotifier,
                  builder: (context, event, _) {
                    final hasPlaybackState =
                        event != null &&
                        (event['state'] == 'playing' ||
                            event['state'] == 'paused');
                    String? filePath =
                        (event != null ? event['filePath'] : null) as String?;
                    if (filePath != null && filePath.isNotEmpty) {
                      _lastNowPlayingPath = filePath;
                    } else {
                      filePath = _lastNowPlayingPath;
                    }
                    if (!hasPlaybackState) return const SizedBox.shrink();
                    return ValueListenableBuilder(
                      valueListenable: CurrentAudioContext.selectionNotifier,
                      builder: (context, selection, __) {
                        final title = (filePath != null && filePath.isNotEmpty)
                            ? filePath.split('/').last
                            : (selection != null &&
                                      selection.index >= 0 &&
                                      selection.index < selection.audios.length
                                  ? (selection.audios[selection.index].title ??
                                        'Now Playing')
                                  : 'Now Playing');

                        Future<void> onPrev() async {
                          final sel = CurrentAudioContext.selection;
                          if (sel == null) return;
                          final newIndex = sel.index - 1;
                          if (newIndex < 0) return;
                          final file = await sel.audios[newIndex].file;
                          if (file == null) return;
                          await NativeAudioService.playNextAudio(file.path, 0);
                          CurrentAudioContext.setSelection(
                            sel.audios,
                            newIndex,
                          );
                          NativeAudioService.nowPlayingNotifier.value = {
                            'state': 'playing',
                            'filePath': file.path,
                            'position': 0,
                            'duration': 0,
                          };
                        }

                        Future<void> onNext() async {
                          final sel = CurrentAudioContext.selection;
                          if (sel == null) return;
                          final newIndex = sel.index + 1;
                          if (newIndex >= sel.audios.length) return;
                          final file = await sel.audios[newIndex].file;
                          if (file == null) return;
                          await NativeAudioService.playNextAudio(file.path, 0);
                          CurrentAudioContext.setSelection(
                            sel.audios,
                            newIndex,
                          );
                          NativeAudioService.nowPlayingNotifier.value = {
                            'state': 'playing',
                            'filePath': file.path,
                            'position': 0,
                            'duration': 0,
                          };
                        }

                        Future<void> onPlayPause() async {
                          final state = event != null ? event['state'] : null;
                          if (state == 'playing') {
                            await NativeAudioService.pauseAudio();
                            NativeAudioService.nowPlayingNotifier.value = {
                              ...?event,
                              'state': 'paused',
                            };
                          } else {
                            await NativeAudioService.playAudio();
                            NativeAudioService.nowPlayingNotifier.value = {
                              ...?event,
                              'state': 'playing',
                            };
                          }
                        }

                        Future<void> onClose() async {
                          // Clear the current playback state to hide the bar
                          NativeAudioService.nowPlayingNotifier.value = null;
                          CurrentAudioContext.selectionNotifier.value = null;
                        }

                        return ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.22),
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.18),
                                    blurRadius: 16,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(20),
                                  onTap: _openCurrentAudioIfPossible,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 10,
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(
                                              0.10,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.music_note,
                                            color: Colors.white70,
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            title,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                        Row(
                                          children: [
                                            _GlassIconButton(
                                              icon: Icons.skip_previous,
                                              onTap: onPrev,
                                            ),
                                            const SizedBox(width: 6),
                                            _GlassIconButton(
                                              icon:
                                                  (event != null &&
                                                      event['state'] ==
                                                          'playing')
                                                  ? Icons.pause
                                                  : Icons.play_arrow,
                                              onTap: onPlayPause,
                                            ),
                                            const SizedBox(width: 6),
                                            _GlassIconButton(
                                              icon: Icons.skip_next,
                                              onTap: onNext,
                                            ),
                                            const SizedBox(width: 6),
                                            _GlassIconButton(
                                              icon: Icons.close,
                                              onTap: onClose,
                                            ),
                                          ],
                                        ),
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
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: AnimatedNavBar(
          currentIndex: _selectedIndex,
          onTap: (index) => setState(() => _selectedIndex = index),
          items: [
            NavBarItem(label: 'Video', assetPath: 'assets/video.png'),
            NavBarItem(label: 'Music', assetPath: 'assets/music.png'),
            NavBarItem(label: 'Settings', assetPath: 'assets/settings.png'),
          ],
        ),
      ),
    );
  }
}

class _GlassIconButton extends StatelessWidget {
  final IconData icon;
  final Future<void> Function() onTap;
  const _GlassIconButton({required this.icon, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.10),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white.withOpacity(0.18), width: 1),
          ),
          child: Icon(icon, color: Colors.white),
        ),
      ),
    );
  }
}
