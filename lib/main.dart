import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_store_plus/media_store_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'screens/splash_screen.dart';
import 'services/native_audio_service.dart';
import 'screens/permission_screen.dart';
import 'screens/main_navigation_screen.dart';
import 'screens/settings_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'theme_data.dart';

final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

class AppWrapper extends StatefulWidget {
  const AppWrapper({Key? key}) : super(key: key);

  @override
  State<AppWrapper> createState() => _AppWrapperState();
}

class _AppWrapperState extends State<AppWrapper> {
  bool _isCheckingPermission = true;
  bool _hasPermission = false;
  bool _showSplash = true;
  bool _splashComplete = false;

  @override
  void initState() {
    super.initState();
    _initializeApp();
    // Initialize playback bridge for Now Playing
    NativeAudioService.ensurePlaybackBridgeInitialized();
  }

  Future<void> _initializeApp() async {
    // Always show splash for minimum duration
    await Future.delayed(const Duration(seconds: 4));

    if (!mounted) return;

    // Check permissions
    final storageStatus = await Permission.storage.status;
    final photosStatus = await Permission.photos.status;
    final videosStatus = await Permission.videos.status;
    final audioStatus = await Permission.audio.status;

    // Consider permission granted if any of the media permissions are granted
    final hasPermission =
        storageStatus.isGranted ||
        photosStatus.isGranted ||
        videosStatus.isGranted ||
        audioStatus.isGranted;

    if (mounted) {
      setState(() {
        _hasPermission = hasPermission;
        _isCheckingPermission = false;
        _splashComplete = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Always show splash screen first
    if (_showSplash && !_splashComplete) {
      return const SplashScreen();
    }

    // After splash is complete, check permissions
    if (_isCheckingPermission) {
      return const SplashScreen();
    }

    if (!_hasPermission) {
      return const PermissionScreen();
    }

    return const MainNavigationScreen();
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();
  MediaStore.appFolder = "video_player";
  await AppThemes.loadSavedTheme();
  SystemChrome.setSystemUIOverlayStyle(
    SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.black,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  await NativeAudioService.ensurePlaybackBridgeInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppTheme>(
      valueListenable: AppThemes.currentThemeNotifier,
      builder: (context, theme, _) {
        return MaterialApp(
          title: 'Media Player',
          theme: theme.themeData,
          home: const AppWrapper(),
          navigatorObservers: [routeObserver],
          routes: {'/settings': (context) => const SettingsScreen()},
        );
      },
    );
  }
}
