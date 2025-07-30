import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_store_plus/media_store_plus.dart';
import 'screens/home_screen.dart';
import 'screens/landing_screen.dart';
import 'screens/settings_screen.dart';
import 'package:google_fonts/google_fonts.dart';

final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();
  MediaStore.appFolder = "video_player";
  SystemChrome.setSystemUIOverlayStyle(
    SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.black,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final baseTextTheme = GoogleFonts.montserratTextTheme(
      ThemeData.dark().textTheme,
    );
    final colorScheme = const ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xFF4A5C6A), // Accent/Primary
      onPrimary: Color(0xFFCCD0CF),
      secondary: Color(0xFF9BA8AB),
      onSecondary: Color(0xFF06141B),
      background: Color(0xFF06141B),
      onBackground: Color(0xFFCCD0CF),
      surface: Color(0xFF11212D),
      onSurface: Color(0xFFCCD0CF),
      surfaceVariant: Color(0xFF253745),
      onSurfaceVariant: Color(0xFF9BA8AB),
      error: Colors.red,
      onError: Colors.white,
      outline: Color(0xFF253745),
      inverseSurface: Color(0xFFCCD0CF),
      onInverseSurface: Color(0xFF06141B),
      tertiary: Color(0xFF253745),
      onTertiary: Color(0xFFCCD0CF),
      shadow: Color(0xFF06141B),
      surfaceTint: Color(0xFF4A5C6A),
    );
    return MaterialApp(
      title: 'Media Player',
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFF4A5C6A),
        scaffoldBackgroundColor: const Color(0xFF06141B),
        cardColor: const Color(0xFF11212D),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF4A5C6A),
          secondary: Color(0xFF9BA8AB),
          background: Color(0xFF06141B),
          surface: Color(0xFF253745),
          onPrimary: Color(0xFFCCD0CF),
          onSecondary: Color(0xFFCCD0CF),
          onBackground: Color(0xFFCCD0CF),
          onSurface: Color(0xFFCCD0CF),
        ),
        textTheme: baseTextTheme.copyWith(
          displayLarge: GoogleFonts.montserrat(
            color: const Color(0xFFCCD0CF),
            fontWeight: FontWeight.bold,
            fontSize: 32,
            letterSpacing: 1.2,
          ),
          titleLarge: GoogleFonts.montserrat(
            color: const Color(0xFFCCD0CF),
            fontWeight: FontWeight.bold,
            fontSize: 24,
            letterSpacing: 1.1,
          ),
          titleMedium: GoogleFonts.montserrat(
            color: const Color(0xFF9BA8AB),
            fontWeight: FontWeight.w500,
            fontSize: 16,
            letterSpacing: 0.8,
          ),
          bodyLarge: GoogleFonts.montserrat(
            color: const Color(0xFFCCD0CF),
            fontWeight: FontWeight.w400,
            fontSize: 16,
          ),
          bodyMedium: GoogleFonts.montserrat(
            color: const Color(0xFF9BA8AB),
            fontWeight: FontWeight.w400,
            fontSize: 14,
          ),
        ),
        fontFamily: GoogleFonts.montserrat().fontFamily,
        useMaterial3: true,
        appBarTheme: AppBarTheme(
          backgroundColor: colorScheme.surface,
          foregroundColor: colorScheme.onSurface,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xFFCCD0CF),
          ),
          iconTheme: const IconThemeData(color: Color(0xFF4A5C6A)),
        ),
        cardTheme: CardThemeData(
          color: colorScheme.surfaceVariant,
          elevation: 4,
          shadowColor: colorScheme.shadow.withOpacity(0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
        listTileTheme: ListTileThemeData(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          tileColor: colorScheme.surface,
          iconColor: colorScheme.primary,
          textColor: colorScheme.onSurface,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: colorScheme.surfaceVariant,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            textStyle: const TextStyle(fontWeight: FontWeight.bold),
            shadowColor: colorScheme.shadow.withOpacity(0.3),
            elevation: 4,
          ),
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: colorScheme.inverseSurface,
          contentTextStyle: TextStyle(color: colorScheme.onInverseSurface),
        ),
      ),
      home: const LandingScreen(),
      navigatorObservers: [routeObserver],
      routes: {'/settings': (context) => const SettingsScreen()},
    );
  }
}
