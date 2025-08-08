import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppTheme {
  final String name;
  final ThemeData themeData;
  final LinearGradient mainGradient;
  final LinearGradient cardGradient;
  final LinearGradient glassmorphicGradient;
  final Color primaryColor;
  final Color secondaryColor;
  final Color accentColor;
  final Color surfaceColor;
  final Color backgroundColor;
  final Color textColor;
  final Color mutedTextColor;
  final Color borderColor;
  final Color shadowColor;
  final BoxDecoration dialogDecoration;
  final BoxDecoration cardDecoration;
  final BoxDecoration glassmorphicDecoration;

  const AppTheme({
    required this.name,
    required this.themeData,
    required this.mainGradient,
    required this.cardGradient,
    required this.glassmorphicGradient,
    required this.primaryColor,
    required this.secondaryColor,
    required this.accentColor,
    required this.surfaceColor,
    required this.backgroundColor,
    required this.textColor,
    required this.mutedTextColor,
    required this.borderColor,
    required this.shadowColor,
    required this.dialogDecoration,
    required this.cardDecoration,
    required this.glassmorphicDecoration,
  });
}

class AppThemes {
  // Default Theme (Current Blue/Gray)
  static AppTheme defaultTheme = AppTheme(
    name: 'Default',
    themeData: ThemeData(
      brightness: Brightness.dark,
      primaryColor: Color(0xFF4A5C6A),
      scaffoldBackgroundColor: Color(0xFF06151C),
      cardColor: Color(0xFF11212D),
      colorScheme: ColorScheme.dark(
        primary: Color(0xFF4A5C6A),
        secondary: Color(0xFF9BA8AB),
        background: Color(0xFF06151B),
        surface: Color(0xFF253745),
        onPrimary: Color(0xFFCCD0CF),
        onSecondary: Color(0xFFCCD0CF),
        onBackground: Color(0xFFCCD0CF),
        onSurface: Color(0xFFCCD0CF),
      ),
      textTheme: TextTheme(
        displayLarge: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 32,
          letterSpacing: 1.2,
        ),
        titleLarge: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 24,
          letterSpacing: 1.1,
        ),
        titleMedium: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w500,
          fontSize: 16,
          letterSpacing: 0.8,
        ),
        bodyLarge: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w400,
          fontSize: 16,
        ),
        bodyMedium: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w400,
          fontSize: 14,
        ),
      ),
      fontFamily: 'Poppins',
      useMaterial3: true,
      appBarTheme: AppBarTheme(
        backgroundColor: Color(0xFF06151C),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        iconTheme: IconThemeData(color: Color(0xFF4A5C6A)),
      ),
      cardTheme: CardThemeData(
        color: Color(0xFF253745),
        elevation: 4,
        shadowColor: Color(0xFF4A5C6A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        tileColor: Color(0xFF253745),
        iconColor: Color(0xFF4A5C6A),
        textColor: Colors.white,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Color(0xFF253745),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0xFF4A5C6A),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: TextStyle(fontWeight: FontWeight.bold),
          shadowColor: Color(0xFF4A5C6A),
          elevation: 4,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: Color(0xFF253745),
        contentTextStyle: TextStyle(color: Colors.white),
      ),
    ),
    mainGradient: LinearGradient(
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
    cardGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF253745), Color(0xFF1A2A35), Color(0xFF11212D)],
    ),
    glassmorphicGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Colors.white.withOpacity(0.18),
        Colors.grey.withOpacity(0.10),
        Colors.white.withOpacity(0.12),
      ],
    ),
    primaryColor: Color(0xFF4A5C6A),
    secondaryColor: Color(0xFF9BA8AB),
    accentColor: Color(0xFF64727A),
    surfaceColor: Color(0xFF253745),
    backgroundColor: Color(0xFF06151C),
    textColor: Colors.white,
    mutedTextColor: Color(0xFF9BA8AB),
    borderColor: Color(0xFF4A5C6A),
    shadowColor: Color(0xFF4A5C6A),
    dialogDecoration: BoxDecoration(
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
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(24),
        topRight: Radius.circular(24),
      ),
      border: Border.all(color: Colors.white24, width: 1),
    ),
    cardDecoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF253745), Color(0xFF1A2A35), Color(0xFF11212D)],
      ),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: Color(0xFF4A5C6A).withOpacity(0.3), width: 1),
      boxShadow: [
        BoxShadow(
          color: Color(0xFF4A5C6A).withOpacity(0.4),
          blurRadius: 10,
          offset: Offset(0, 4),
        ),
      ],
    ),
    glassmorphicDecoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withOpacity(0.18),
          Colors.grey.withOpacity(0.10),
          Colors.white.withOpacity(0.12),
        ],
      ),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.white.withOpacity(0.18), width: 1.2),
    ),
  );

  // Red Mist Theme (renamed from Reddish)
  static AppTheme redMistTheme = AppTheme(
    name: 'Red Mist',
    themeData: ThemeData(
      brightness: Brightness.dark,
      primaryColor: Color(0xFFB71C1C),
      scaffoldBackgroundColor: Color(0xFF2D1313),
      cardColor: Color(0xFF3C1A1A),
      colorScheme: ColorScheme.dark(
        primary: Color(0xFFB71C1C),
        secondary: Color(0xFFD84315),
        background: Color(0xFF2D1313),
        surface: Color(0xFF3C1A1A),
        onPrimary: Color(0xFFFFCDD2),
        onSecondary: Color(0xFFFFAB91),
        onBackground: Color(0xFFFFCDD2),
        onSurface: Color(0xFFFFCDD2),
      ),
      textTheme: TextTheme(
        displayLarge: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 32,
          letterSpacing: 1.2,
        ),
        titleLarge: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 24,
          letterSpacing: 1.1,
        ),
        titleMedium: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w500,
          fontSize: 16,
          letterSpacing: 0.8,
        ),
        bodyLarge: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w400,
          fontSize: 16,
        ),
        bodyMedium: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w400,
          fontSize: 14,
        ),
      ),
      fontFamily: 'Poppins',
      useMaterial3: true,
      appBarTheme: AppBarTheme(
        backgroundColor: Color(0xFF2D1313),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        iconTheme: IconThemeData(color: Color(0xFFD84315)),
      ),
      cardTheme: CardThemeData(
        color: Color(0xFF3C1A1A).withOpacity(0.85),
        elevation: 4,
        shadowColor: Color(0xFFB71C1C),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        tileColor: Color(0xFF3C1A1A),
        iconColor: Color(0xFFD84315),
        textColor: Colors.white,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Color(0xFF3C1A1A),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0xFFB71C1C),
          foregroundColor: Color(0xFFFFCDD2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: TextStyle(fontWeight: FontWeight.bold),
          shadowColor: Color(0xFFB71C1C),
          elevation: 4,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: Color(0xFF3C1A1A),
        contentTextStyle: TextStyle(color: Colors.white),
      ),
    ),
    mainGradient: LinearGradient(
      begin: Alignment.bottomLeft,
      end: Alignment.topRight,
      colors: [Color(0xFF2D1313), Color(0xFF3C1A1A), Color(0xFFB71C1C)],
      stops: [0.0, 0.5, 1.0],
    ),
    cardGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF3C1A1A), Color(0xFF2D1313)],
    ),
    glassmorphicGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFFFFCDD2).withOpacity(0.18),
        Color(0xFF3C1A1A).withOpacity(0.10),
        Color(0xFFFFCDD2).withOpacity(0.12),
      ],
    ),
    primaryColor: Color(0xFFB71C1C),
    secondaryColor: Color(0xFFD84315),
    accentColor: Color(0xFFFFCDD2),
    surfaceColor: Color(0xFF3C1A1A),
    backgroundColor: Color(0xFF2D1313),
    textColor: Colors.white,
    mutedTextColor: Color(0xFFD84315),
    borderColor: Color(0xFFB71C1C),
    shadowColor: Color(0xFFB71C1C),
    dialogDecoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.bottomLeft,
        end: Alignment.topRight,
        colors: [Color(0xFF2D1313), Color(0xFF3C1A1A), Color(0xFFB71C1C)],
        stops: [0.0, 0.5, 1.0],
      ),
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(24),
        topRight: Radius.circular(24),
      ),
      border: Border.all(color: Color(0xFFFFCDD2).withOpacity(0.18), width: 1),
    ),
    cardDecoration: BoxDecoration(
      color: Color(0xFF3C1A1A).withOpacity(0.85),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(
        color: Color(0xFFFFCDD2).withOpacity(0.10),
        width: 1.2,
      ),
      boxShadow: [
        BoxShadow(
          color: Color(0xFFB71C1C).withOpacity(0.18),
          blurRadius: 18,
          offset: Offset(0, 6),
        ),
      ],
    ),
    glassmorphicDecoration: BoxDecoration(
      color: Colors.white.withOpacity(0.10),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: Color(0xFFFFCDD2).withOpacity(0.18),
        width: 1.2,
      ),
    ),
  );

  // --- Blue Violet Theme ---
  static final AppTheme blueVioletTheme = AppTheme(
    name: 'Blue Violet',
    themeData: ThemeData(
      brightness: Brightness.dark,
      primaryColor: Color(0xFF3A3E6C),
      scaffoldBackgroundColor: Color(0xFF0A1123),
      cardColor: Color(0xFF8387C3),
      colorScheme: ColorScheme.dark(
        primary: Color(0xFF3A3E6C),
        secondary: Color(0xFF8387C3),
        background: Color(0xFF0A1123),
        surface: Color(0xFF8387C3),
        onPrimary: Color(0xFFBABCAC),
        onSecondary: Color(0xFF959BB5),
        onBackground: Color(0xFFBABCAC),
        onSurface: Color(0xFFBABCAC),
      ),
      textTheme: TextTheme(
        displayLarge: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 32,
          letterSpacing: 1.2,
        ),
        titleLarge: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 24,
          letterSpacing: 1.1,
        ),
        titleMedium: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w500,
          fontSize: 16,
          letterSpacing: 0.8,
        ),
        bodyLarge: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w400,
          fontSize: 16,
        ),
        bodyMedium: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w400,
          fontSize: 14,
        ),
      ),
      fontFamily: 'Poppins',
      useMaterial3: true,
      appBarTheme: AppBarTheme(
        backgroundColor: Color(0xFF0A1123),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        iconTheme: IconThemeData(color: Color(0xFF3A3E6C)),
      ),
      cardTheme: CardThemeData(
        color: Color(0xFF8387C3),
        elevation: 4,
        shadowColor: Color(0xFF3A3E6C),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        tileColor: Color(0xFF8387C3),
        iconColor: Color(0xFF3A3E6C),
        textColor: Colors.white,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Color(0xFF8387C3),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0xFF3A3E6C),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: TextStyle(fontWeight: FontWeight.bold),
          shadowColor: Color(0xFF3A3E6C),
          elevation: 4,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: Color(0xFF8387C3),
        contentTextStyle: TextStyle(color: Colors.white),
      ),
    ),
    mainGradient: LinearGradient(
      begin: Alignment.bottomLeft,
      end: Alignment.topRight,
      colors: [
        Color(0xFF0A1123),
        Color(0xFF3A3E6C),
        Color(0xFF8387C3),
        Color(0xFFBABCAC),
      ],
      stops: [0.0, 0.3, 0.7, 1.0],
    ),
    cardGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF8387C3), Color(0xFF3A3E6C), Color(0xFF0A1123)],
    ),
    glassmorphicGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Colors.white.withOpacity(0.18),
        Colors.blue.withOpacity(0.10),
        Colors.white.withOpacity(0.12),
      ],
    ),
    primaryColor: Color(0xFF3A3E6C),
    secondaryColor: Color(0xFF8387C3),
    accentColor: Color(0xFF959BB5),
    surfaceColor: Color(0xFF8387C3),
    backgroundColor: Color(0xFF0A1123),
    textColor: Colors.white,
    mutedTextColor: Color(0xFF959BB5),
    borderColor: Color(0xFF3A3E6C),
    shadowColor: Color(0xFF3A3E6C),
    dialogDecoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.bottomLeft,
        end: Alignment.topRight,
        colors: [
          Color(0xFF0A1123),
          Color(0xFF3A3E6C),
          Color(0xFF8387C3),
          Color(0xFFBABCAC),
        ],
        stops: [0.0, 0.3, 0.7, 1.0],
      ),
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(24),
        topRight: Radius.circular(24),
      ),
      border: Border.all(color: Colors.white24, width: 1),
    ),
    cardDecoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF8387C3), Color(0xFF3A3E6C), Color(0xFF0A1123)],
      ),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: Color(0xFF3A3E6C).withOpacity(0.3), width: 1),
      boxShadow: [
        BoxShadow(
          color: Color(0xFF3A3E6C).withOpacity(0.4),
          blurRadius: 10,
          offset: Offset(0, 4),
        ),
      ],
    ),
    glassmorphicDecoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withOpacity(0.18),
          Colors.blue.withOpacity(0.10),
          Colors.white.withOpacity(0.12),
        ],
      ),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.white.withOpacity(0.18), width: 1.2),
    ),
  );

  // Sakura Theme
  static final AppTheme sakuraTheme = AppTheme(
    name: 'Sakura',
    themeData: ThemeData(
      brightness: Brightness.dark,
      primaryColor: Color(0xFF6D3C52),
      scaffoldBackgroundColor: Color(0xFF1B0C1A),
      cardColor: Color(0xFF2D222F),
      colorScheme: ColorScheme.dark(
        primary: Color(0xFF6D3C52),
        secondary: Color(0xFF4B2138),
        background: Color(0xFF1B0C1A),
        surface: Color(0xFF2D222F),
        onPrimary: Color(0xFFFADCD5),
        onSecondary: Color(0xFFFADCD5),
        onBackground: Color(0xFFFADCD5),
        onSurface: Color(0xFFFADCD5),
      ),
      textTheme: TextTheme(
        displayLarge: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 32,
          letterSpacing: 1.2,
        ),
        titleLarge: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 24,
          letterSpacing: 1.1,
        ),
        titleMedium: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w500,
          fontSize: 16,
          letterSpacing: 0.8,
        ),
        bodyLarge: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w400,
          fontSize: 16,
        ),
        bodyMedium: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w400,
          fontSize: 14,
        ),
      ),
      fontFamily: 'Poppins',
      useMaterial3: true,
      appBarTheme: AppBarTheme(
        backgroundColor: Color(0xFF1B0C1A),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        iconTheme: IconThemeData(color: Color(0xFF6D3C52)),
      ),
      cardTheme: CardThemeData(
        color: Color(0xFF2D222F),
        elevation: 4,
        shadowColor: Color(0xFF6D3C52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        tileColor: Color(0xFF2D222F),
        iconColor: Color(0xFF6D3C52),
        textColor: Colors.white,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Color(0xFF2D222F),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0xFF6D3C52),
          foregroundColor: Color(0xFFFADCD5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: TextStyle(fontWeight: FontWeight.bold),
          shadowColor: Color(0xFF6D3C52),
          elevation: 4,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: Color(0xFF2D222F),
        contentTextStyle: TextStyle(color: Colors.white),
      ),
    ),
    mainGradient: LinearGradient(
      begin: Alignment.bottomLeft,
      end: Alignment.topRight,
      colors: [
        Color(0xFF765D67),
        Color(0xFF6D3C52),
        Color(0xFF4B2138),
        Color(0xFF1B0C1A),
        Color(0xFF2D222F),
        Color(0xFFFADCD5),
      ],
      stops: [0.0, 0.15, 0.35, 0.55, 0.75, 1.0],
    ),
    cardGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF6D3C52), Color(0xFF4B2138), Color(0xFF2D222F)],
    ),
    glassmorphicGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFFFADCD5).withOpacity(0.18),
        Color(0xFF6D3C52).withOpacity(0.10),
        Color(0xFFFADCD5).withOpacity(0.12),
      ],
    ),
    primaryColor: Color(0xFF6D3C52),
    secondaryColor: Color(0xFF4B2138),
    accentColor: Color(0xFF765D67),
    surfaceColor: Color(0xFF2D222F),
    backgroundColor: Color(0xFF1B0C1A),
    textColor: Colors.white,
    mutedTextColor: Color(0xFF765D67),
    borderColor: Color(0xFF6D3C52),
    shadowColor: Color(0xFF6D3C52),
    dialogDecoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.bottomLeft,
        end: Alignment.topRight,
        colors: [
          Color(0xFF765D67),
          Color(0xFF6D3C52),
          Color(0xFF4B2138),
          Color(0xFF1B0C1A),
          Color(0xFF2D222F),
          Color(0xFFFADCD5),
        ],
        stops: [0.0, 0.15, 0.35, 0.55, 0.75, 1.0],
      ),
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(24),
        topRight: Radius.circular(24),
      ),
      border: Border.all(color: Color(0xFFFADCD5).withOpacity(0.18), width: 1),
    ),
    cardDecoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF6D3C52), Color(0xFF4B2138), Color(0xFF2D222F)],
      ),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: Color(0xFF6D3C52).withOpacity(0.3), width: 1),
      boxShadow: [
        BoxShadow(
          color: Color(0xFF6D3C52).withOpacity(0.4),
          blurRadius: 10,
          offset: Offset(0, 4),
        ),
      ],
    ),
    glassmorphicDecoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFFFADCD5).withOpacity(0.18),
          Color(0xFF6D3C52).withOpacity(0.10),
          Color(0xFFFADCD5).withOpacity(0.12),
        ],
      ),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: Color(0xFFFADCD5).withOpacity(0.18),
        width: 1.2,
      ),
    ),
  );

  // Forest Green Theme
  static final AppTheme forestGreenTheme = AppTheme(
    name: 'Forest Green',
    themeData: ThemeData(
      brightness: Brightness.dark,
      primaryColor: Color(0xFF193F28),
      scaffoldBackgroundColor: Color(0xFF0F1A1E),
      cardColor: Color(0xFF3E5646),
      colorScheme: ColorScheme.dark(
        primary: Color(0xFF193F28),
        secondary: Color(0xFF3E5646),
        background: Color(0xFF0F1A1E),
        surface: Color(0xFF887A67),
        onPrimary: Color(0xFF887A67),
        onSecondary: Color(0xFF887A67),
        onBackground: Color(0xFF887A67),
        onSurface: Color(0xFF887A67),
      ),
      textTheme: TextTheme(
        displayLarge: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 32,
          letterSpacing: 1.2,
        ),
        titleLarge: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 24,
          letterSpacing: 1.1,
        ),
        titleMedium: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w500,
          fontSize: 16,
          letterSpacing: 0.8,
        ),
        bodyLarge: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w400,
          fontSize: 16,
        ),
        bodyMedium: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w400,
          fontSize: 14,
        ),
      ),
      fontFamily: 'Poppins',
      useMaterial3: true,
      appBarTheme: AppBarTheme(
        backgroundColor: Color(0xFF0F1A1E),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        iconTheme: IconThemeData(color: Color(0xFF193F28)),
      ),
      cardTheme: CardThemeData(
        color: Color(0xFF3E5646),
        elevation: 4,
        shadowColor: Color(0xFF193F28),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        tileColor: Color(0xFF3E5646),
        iconColor: Color(0xFF193F28),
        textColor: Colors.white,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Color(0xFF3E5646),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0xFF193F28),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: TextStyle(fontWeight: FontWeight.bold),
          shadowColor: Color(0xFF193F28),
          elevation: 4,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: Color(0xFF3E5646),
        contentTextStyle: TextStyle(color: Colors.white),
      ),
    ),
    mainGradient: LinearGradient(
      begin: Alignment.bottomLeft,
      end: Alignment.topRight,
      colors: [
        Color(0xFF0F1A1E),
        Color(0xFF193F28),
        Color(0xFF3E5646),
        Color(0xFF887A67),
      ],
      stops: [0.0, 0.25, 0.6, 1.0],
    ),
    cardGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF193F28), Color(0xFF3E5646), Color(0xFF887A67)],
    ),
    glassmorphicGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFF887A67).withOpacity(0.18),
        Color(0xFF193F28).withOpacity(0.10),
        Color(0xFF887A67).withOpacity(0.12),
      ],
    ),
    primaryColor: Color(0xFF193F28),
    secondaryColor: Color(0xFF3E5646),
    accentColor: Color(0xFF887A67),
    surfaceColor: Color(0xFF3E5646),
    backgroundColor: Color(0xFF0F1A1E),
    textColor: Colors.white,
    mutedTextColor: Color(0xFF3E5646),
    borderColor: Color(0xFF193F28),
    shadowColor: Color(0xFF193F28),
    dialogDecoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.bottomLeft,
        end: Alignment.topRight,
        colors: [
          Color(0xFF0F1A1E),
          Color(0xFF193F28),
          Color(0xFF3E5646),
          Color(0xFF887A67),
        ],
        stops: [0.0, 0.25, 0.6, 1.0],
      ),
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(24),
        topRight: Radius.circular(24),
      ),
      border: Border.all(color: Color(0xFF887A67).withOpacity(0.18), width: 1),
    ),
    cardDecoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF193F28), Color(0xFF3E5646), Color(0xFF887A67)],
      ),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: Color(0xFF193F28).withOpacity(0.3), width: 1),
      boxShadow: [
        BoxShadow(
          color: Color(0xFF193F28).withOpacity(0.4),
          blurRadius: 10,
          offset: Offset(0, 4),
        ),
      ],
    ),
    glassmorphicDecoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF887A67).withOpacity(0.18),
          Color(0xFF193F28).withOpacity(0.10),
          Color(0xFF887A67).withOpacity(0.12),
        ],
      ),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: Color(0xFF887A67).withOpacity(0.18),
        width: 1.2,
      ),
    ),
  );

  // Blue Palette Theme
  static final AppTheme bluePaletteTheme = AppTheme(
    name: 'Blue Palette',
    themeData: ThemeData(
      brightness: Brightness.dark,
      primaryColor: Color(0xFF171F55),
      scaffoldBackgroundColor: Color(0xFF0D1433),
      cardColor: Color(0xFF274272),
      colorScheme: ColorScheme.dark(
        primary: Color(0xFF171F55),
        secondary: Color(0xFF274272),
        background: Color(0xFF0D1433),
        surface: Color(0xFF6C90C3),
        onPrimary: Color(0xFF6C90C3),
        onSecondary: Color(0xFF6C90C3),
        onBackground: Color(0xFF6C90C3),
        onSurface: Color(0xFF6C90C3),
      ),
      textTheme: TextTheme(
        displayLarge: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 32,
          letterSpacing: 1.2,
        ),
        titleLarge: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 24,
          letterSpacing: 1.1,
        ),
        titleMedium: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w500,
          fontSize: 16,
          letterSpacing: 0.8,
        ),
        bodyLarge: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w400,
          fontSize: 16,
        ),
        bodyMedium: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w400,
          fontSize: 14,
        ),
      ),
      fontFamily: 'Poppins',
      useMaterial3: true,
      appBarTheme: AppBarTheme(
        backgroundColor: Color(0xFF0D1433),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        iconTheme: IconThemeData(color: Color(0xFF171F55)),
      ),
      cardTheme: CardThemeData(
        color: Color(0xFF274272),
        elevation: 4,
        shadowColor: Color(0xFF171F55),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        tileColor: Color(0xFF274272),
        iconColor: Color(0xFF171F55),
        textColor: Colors.white,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Color(0xFF274272),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0xFF171F55),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: TextStyle(fontWeight: FontWeight.bold),
          shadowColor: Color(0xFF171F55),
          elevation: 4,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: Color(0xFF274272),
        contentTextStyle: TextStyle(color: Colors.white),
      ),
    ),
    mainGradient: LinearGradient(
      begin: Alignment.bottomLeft,
      end: Alignment.topRight,
      colors: [
        Color(0xFF0D1433),
        Color(0xFF171F55),
        Color(0xFF274272),
        Color(0xFF6C90C3),
      ],
      stops: [0.0, 0.25, 0.6, 1.0],
    ),
    cardGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF171F55), Color(0xFF274272), Color(0xFF6C90C3)],
    ),
    glassmorphicGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFF6C90C3).withOpacity(0.18),
        Color(0xFF171F55).withOpacity(0.10),
        Color(0xFF6C90C3).withOpacity(0.12),
      ],
    ),
    primaryColor: Color(0xFF171F55),
    secondaryColor: Color(0xFF274272),
    accentColor: Color(0xFF6C90C3),
    surfaceColor: Color(0xFF274272),
    backgroundColor: Color(0xFF0D1433),
    textColor: Colors.white,
    mutedTextColor: Color(0xFF274272),
    borderColor: Color(0xFF171F55),
    shadowColor: Color(0xFF171F55),
    dialogDecoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.bottomLeft,
        end: Alignment.topRight,
        colors: [
          Color(0xFF0D1433),
          Color(0xFF171F55),
          Color(0xFF274272),
          Color(0xFF6C90C3),
        ],
        stops: [0.0, 0.25, 0.6, 1.0],
      ),
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(24),
        topRight: Radius.circular(24),
      ),
      border: Border.all(color: Color(0xFF6C90C3).withOpacity(0.18), width: 1),
    ),
    cardDecoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF171F55), Color(0xFF274272), Color(0xFF6C90C3)],
      ),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: Color(0xFF171F55).withOpacity(0.3), width: 1),
      boxShadow: [
        BoxShadow(
          color: Color(0xFF171F55).withOpacity(0.4),
          blurRadius: 10,
          offset: Offset(0, 4),
        ),
      ],
    ),
    glassmorphicDecoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF6C90C3).withOpacity(0.18),
          Color(0xFF171F55).withOpacity(0.10),
          Color(0xFF6C90C3).withOpacity(0.12),
        ],
      ),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: Color(0xFF6C90C3).withOpacity(0.18),
        width: 1.2,
      ),
    ),
  );

  // Sandstone Palette (beige/brown)
  static final AppTheme sandstoneTheme = AppTheme(
    name: 'Sandstone',
    themeData: ThemeData(
      brightness: Brightness.dark,
      primaryColor: const Color(0xFFC9B08B), // light beige
      scaffoldBackgroundColor: const Color(0xFF2E241C),
      cardColor: const Color(0xFF5C4A3E),
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFFC9B08B),
        secondary: Color(0xFFA98365),
        background: Color(0xFF2E241C),
        surface: Color(0xFF5C4A3E),
        onPrimary: Color(0xFF15110D),
        onSecondary: Color(0xFF15110D),
        onBackground: Color(0xFFDCCAAE),
        onSurface: Color(0xFFDCCAAE),
      ),
      textTheme: TextTheme(
        displayLarge: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 32,
          letterSpacing: 1.2,
        ),
        titleLarge: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 24,
          letterSpacing: 1.1,
        ),
        titleMedium: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w500,
          fontSize: 16,
          letterSpacing: 0.8,
        ),
        bodyLarge: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w400,
          fontSize: 16,
        ),
        bodyMedium: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w400,
          fontSize: 14,
        ),
      ),
      fontFamily: 'Poppins',
      useMaterial3: true,
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFF2E241C),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        iconTheme: IconThemeData(color: const Color(0xFFC9B08B)),
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF5C4A3E),
        elevation: 4,
        shadowColor: const Color(0xFFC9B08B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        tileColor: const Color(0xFF5C4A3E),
        iconColor: const Color(0xFFC9B08B),
        textColor: Colors.white,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF5C4A3E),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFC9B08B),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: TextStyle(fontWeight: FontWeight.bold),
          shadowColor: const Color(0xFFC9B08B),
          elevation: 4,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: const Color(0xFF5C4A3E),
        contentTextStyle: TextStyle(color: Colors.white),
      ),
    ),
    mainGradient: const LinearGradient(
      begin: Alignment.bottomLeft,
      end: Alignment.topRight,
      colors: [
        Color(0xFF2E241C), // deep brown
        Color(0xFF5C4A3E), // mid brown
        Color(0xFFA98365), // warm tan
        Color(0xFFC9B08B), // light beige
      ],
      stops: [0.0, 0.35, 0.7, 1.0],
    ),
    cardGradient: const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF5C4A3E), Color(0xFFA98365)],
    ),
    glassmorphicGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Colors.white.withOpacity(0.18),
        const Color(0xFF5C4A3E).withOpacity(0.10),
        Colors.white.withOpacity(0.12),
      ],
    ),
    primaryColor: const Color(0xFFC9B08B),
    secondaryColor: const Color(0xFFA98365),
    accentColor: const Color(0xFFDCCAAE),
    surfaceColor: const Color(0xFF5C4A3E),
    backgroundColor: const Color(0xFF2E241C),
    textColor: Colors.white,
    mutedTextColor: const Color(0xFF9B8673),
    borderColor: const Color(0xFFA98365),
    shadowColor: const Color(0xFF2E241C),
    dialogDecoration: BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.bottomLeft,
        end: Alignment.topRight,
        colors: [
          Color(0xFF2E241C),
          Color(0xFF5C4A3E),
          Color(0xFFA98365),
          Color(0xFFC9B08B),
        ],
      ),
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(24),
        topRight: Radius.circular(24),
      ),
      border: Border.all(color: Colors.white.withOpacity(0.18), width: 1),
    ),
    cardDecoration: BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF5C4A3E), Color(0xFFA98365)],
      ),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: Colors.white.withOpacity(0.10), width: 1.2),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFF2E241C).withOpacity(0.25),
          blurRadius: 18,
          offset: const Offset(0, 6),
        ),
      ],
    ),
    glassmorphicDecoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withOpacity(0.18),
          const Color(0xFF5C4A3E).withOpacity(0.10),
          Colors.white.withOpacity(0.12),
        ],
      ),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.white.withOpacity(0.18), width: 1.2),
    ),
  );

  // Monochrome (grayscale)
  static final AppTheme monochromeTheme = AppTheme(
    name: 'Monochrome',
    themeData: ThemeData(
      brightness: Brightness.dark,
      primaryColor: const Color(0xFF61625D),
      scaffoldBackgroundColor: const Color(0xFF171717),
      cardColor: const Color(0xFF5D5D5C),
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF61625D),
        secondary: Color(0xFFB4B4B4),
        background: Color(0xFF171717),
        surface: Color(0xFF5D5D5C),
        onPrimary: Color(0xFFB4B4B4),
        onSecondary: Color(0xFFB4B4B4),
        onBackground: Color(0xFFB4B4B4),
        onSurface: Color(0xFFB4B4B4),
      ),
      textTheme: TextTheme(
        displayLarge: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 32,
          letterSpacing: 1.2,
        ),
        titleLarge: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 24,
          letterSpacing: 1.1,
        ),
        titleMedium: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w500,
          fontSize: 16,
          letterSpacing: 0.8,
        ),
        bodyLarge: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w400,
          fontSize: 16,
        ),
        bodyMedium: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w400,
          fontSize: 14,
        ),
      ),
      fontFamily: 'Poppins',
      useMaterial3: true,
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFF171717),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        iconTheme: IconThemeData(color: const Color(0xFF61625D)),
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF5D5D5C),
        elevation: 4,
        shadowColor: const Color(0xFF61625D),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        tileColor: const Color(0xFF5D5D5C),
        iconColor: const Color(0xFF61625D),
        textColor: Colors.white,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF5D5D5C),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF61625D),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: TextStyle(fontWeight: FontWeight.bold),
          shadowColor: const Color(0xFF61625D),
          elevation: 4,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: const Color(0xFF5D5D5C),
        contentTextStyle: TextStyle(color: Colors.white),
      ),
    ),
    mainGradient: const LinearGradient(
      begin: Alignment.bottomLeft,
      end: Alignment.topRight,
      colors: [
        Color(0xFF171717),
        Color(0xFF5D5D5C),
        Color(0xFF737373),
        Color(0xFFB4B4B4),
      ],
      stops: [0.0, 0.35, 0.7, 1.0],
    ),
    cardGradient: const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF5D5D5C), Color(0xFF737373)],
    ),
    glassmorphicGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Colors.white.withOpacity(0.18),
        const Color(0xFF61625D).withOpacity(0.10),
        Colors.white.withOpacity(0.12),
      ],
    ),
    primaryColor: const Color(0xFF61625D),
    secondaryColor: const Color(0xFFB4B4B4),
    accentColor: const Color(0xFF737373),
    surfaceColor: const Color(0xFF5D5D5C),
    backgroundColor: const Color(0xFF171717),
    textColor: Colors.white,
    mutedTextColor: const Color(0xFF737373),
    borderColor: const Color(0xFF61625D),
    shadowColor: const Color(0xFF171717),
    dialogDecoration: BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.bottomLeft,
        end: Alignment.topRight,
        colors: [
          Color(0xFF171717),
          Color(0xFF5D5D5C),
          Color(0xFF737373),
          Color(0xFFB4B4B4),
        ],
      ),
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(24),
        topRight: Radius.circular(24),
      ),
      border: Border.all(color: Colors.white.withOpacity(0.18), width: 1),
    ),
    cardDecoration: BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF5D5D5C), Color(0xFF737373)],
      ),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: Colors.white.withOpacity(0.10), width: 1.2),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFF171717).withOpacity(0.25),
          blurRadius: 18,
          offset: const Offset(0, 6),
        ),
      ],
    ),
    glassmorphicDecoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withOpacity(0.18),
          const Color(0xFF61625D).withOpacity(0.10),
          Colors.white.withOpacity(0.12),
        ],
      ),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.white.withOpacity(0.18), width: 1.2),
    ),
  );

  // Modern Navy & Cream (based on #0D1321, #FFEDDF, #7D7D7D, #3855E8)
  static final AppTheme modernNavyTheme = AppTheme(
    name: 'Modern Navy',
    themeData: ThemeData(
      brightness: Brightness.dark,
      primaryColor: const Color(0xFF3855E8),
      scaffoldBackgroundColor: const Color(0xFF0D1321),
      cardColor: const Color(0xFF1B233A),
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF3855E8),
        secondary: Color(0xFF7D7D7D),
        background: Color(0xFF0D1321),
        surface: Color(0xFF1B233A),
        onPrimary: Color(0xFFFFEDDF),
        onSecondary: Color(0xFFFFEDDF),
        onBackground: Color(0xFFFFEDDF),
        onSurface: Color(0xFFFFEDDF),
      ),
      textTheme: TextTheme(
        displayLarge: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 32,
          letterSpacing: 1.2,
        ),
        titleLarge: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 24,
          letterSpacing: 1.1,
        ),
        titleMedium: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w500,
          fontSize: 16,
          letterSpacing: 0.8,
        ),
        bodyLarge: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w400,
          fontSize: 16,
        ),
        bodyMedium: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w400,
          fontSize: 14,
        ),
      ),
      fontFamily: 'Poppins',
      useMaterial3: true,
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFF0D1321),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        iconTheme: IconThemeData(color: const Color(0xFF3855E8)),
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF1B233A),
        elevation: 4,
        shadowColor: const Color(0xFF3855E8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        tileColor: const Color(0xFF1B233A),
        iconColor: const Color(0xFF3855E8),
        textColor: Colors.white,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF1B233A),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF3855E8),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: TextStyle(fontWeight: FontWeight.bold),
          shadowColor: const Color(0xFF3855E8),
          elevation: 4,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: const Color(0xFF1B233A),
        contentTextStyle: TextStyle(color: Colors.white),
      ),
    ),
    mainGradient: const LinearGradient(
      begin: Alignment.bottomLeft,
      end: Alignment.topRight,
      colors: [
        Color(0xFF0D1321),
        Color(0xFF1B233A),
        Color(0xFF7D7D7D),
        Color(0xFF3855E8),
      ],
      stops: [0.0, 0.3, 0.65, 1.0],
    ),
    cardGradient: const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF1B233A), Color(0xFF3855E8)],
    ),
    glassmorphicGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Colors.white.withOpacity(0.18),
        const Color(0xFF3855E8).withOpacity(0.10),
        Colors.white.withOpacity(0.12),
      ],
    ),
    primaryColor: const Color(0xFF3855E8),
    secondaryColor: const Color(0xFF7D7D7D),
    accentColor: const Color(0xFFFFEDDF),
    surfaceColor: const Color(0xFF1B233A),
    backgroundColor: const Color(0xFF0D1321),
    textColor: Colors.white,
    mutedTextColor: const Color(0xFF7D7D7D),
    borderColor: const Color(0xFF3855E8),
    shadowColor: const Color(0xFF0D1321),
    dialogDecoration: BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.bottomLeft,
        end: Alignment.topRight,
        colors: [
          Color(0xFF0D1321),
          Color(0xFF1B233A),
          Color(0xFF7D7D7D),
          Color(0xFF3855E8),
        ],
      ),
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(24),
        topRight: Radius.circular(24),
      ),
      border: Border.all(color: Colors.white.withOpacity(0.18), width: 1),
    ),
    cardDecoration: BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF1B233A), Color(0xFF3855E8)],
      ),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: Colors.white.withOpacity(0.10), width: 1.2),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFF0D1321).withOpacity(0.25),
          blurRadius: 18,
          offset: const Offset(0, 6),
        ),
      ],
    ),
    glassmorphicDecoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withOpacity(0.18),
          const Color(0xFF3855E8).withOpacity(0.10),
          Colors.white.withOpacity(0.12),
        ],
      ),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.white.withOpacity(0.18), width: 1.2),
    ),
  );

  static final ValueNotifier<AppTheme> currentThemeNotifier =
      ValueNotifier<AppTheme>(defaultTheme);

  static final List<AppTheme> availableThemes = [
    defaultTheme,
    redMistTheme,
    blueVioletTheme,
    sakuraTheme,
    forestGreenTheme,
    bluePaletteTheme,
    sandstoneTheme,
    monochromeTheme,
    modernNavyTheme,
  ];

  // Helper methods to get current theme properties
  static AppTheme get currentTheme => currentThemeNotifier.value;
  static ThemeData get currentThemeData => currentTheme.themeData;
  static LinearGradient get currentMainGradient => currentTheme.mainGradient;
  static LinearGradient get currentCardGradient => currentTheme.cardGradient;
  static LinearGradient get currentGlassmorphicGradient =>
      currentTheme.glassmorphicGradient;
  static Color get currentPrimaryColor => currentTheme.primaryColor;
  static Color get currentSecondaryColor => currentTheme.secondaryColor;
  static Color get currentAccentColor => currentTheme.accentColor;
  static Color get currentSurfaceColor => currentTheme.surfaceColor;
  static Color get currentBackgroundColor => currentTheme.backgroundColor;
  static Color get currentTextColor => currentTheme.textColor;
  static Color get currentMutedTextColor => currentTheme.mutedTextColor;
  static Color get currentBorderColor => currentTheme.borderColor;
  static Color get currentShadowColor => currentTheme.shadowColor;
  static BoxDecoration get currentDialogDecoration =>
      currentTheme.dialogDecoration;
  static BoxDecoration get currentCardDecoration => currentTheme.cardDecoration;
  static BoxDecoration get currentGlassmorphicDecoration =>
      currentTheme.glassmorphicDecoration;

  // Persistence
  static const String _prefsKeySelectedTheme = 'selected_theme_name';

  static Future<void> loadSavedTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final savedName = prefs.getString(_prefsKeySelectedTheme);
    if (savedName != null) {
      final theme = availableThemes.firstWhere(
        (t) => t.name == savedName,
        orElse: () => defaultTheme,
      );
      currentThemeNotifier.value = theme;
    }
  }

  static Future<void> setCurrentTheme(AppTheme theme) async {
    currentThemeNotifier.value = theme;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKeySelectedTheme, theme.name);
  }
}
