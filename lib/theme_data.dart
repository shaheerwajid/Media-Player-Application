import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
          color: Color(0xFF9BA8AB),
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
          color: Color(0xFF9BA8AB),
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

  // Reddish Theme
  static AppTheme reddishTheme = AppTheme(
    name: 'Reddish',
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
          color: Color(0xFFFFCDD2),
          fontWeight: FontWeight.bold,
          fontSize: 32,
          letterSpacing: 1.2,
        ),
        titleLarge: TextStyle(
          color: Color(0xFFFFCDD2),
          fontWeight: FontWeight.bold,
          fontSize: 24,
          letterSpacing: 1.1,
        ),
        titleMedium: TextStyle(
          color: Color(0xFFD84315),
          fontWeight: FontWeight.w500,
          fontSize: 16,
          letterSpacing: 0.8,
        ),
        bodyLarge: TextStyle(
          color: Color(0xFFFFCDD2),
          fontWeight: FontWeight.w400,
          fontSize: 16,
        ),
        bodyMedium: TextStyle(
          color: Color(0xFFD84315),
          fontWeight: FontWeight.w400,
          fontSize: 14,
        ),
      ),
      fontFamily: 'Poppins',
      useMaterial3: true,
      appBarTheme: AppBarTheme(
        backgroundColor: Color(0xFF2D1313),
        foregroundColor: Color(0xFFFFCDD2),
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: Color(0xFFFFCDD2),
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
        textColor: Color(0xFFFFCDD2),
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
        contentTextStyle: TextStyle(color: Color(0xFFFFCDD2)),
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
    textColor: Color(0xFFFFCDD2),
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

  // --- Red Mist Theme ---
  static final AppTheme redMistTheme = AppTheme(
    name: 'Red Mist',
    themeData: ThemeData(
      brightness: Brightness.dark,
      primaryColor: Color(0xFFDF643F),
      scaffoldBackgroundColor: Color(0xFF3D1F1D),
      cardColor: Color(0xFFA73728),
      colorScheme: ColorScheme.dark(
        primary: Color(0xFFDF643F),
        secondary: Color(0xFFA73728),
        background: Color(0xFF3D1F1D),
        surface: Color(0xFFA73728),
        onPrimary: Color(0xFFFFE5DE),
        onSecondary: Color(0xFFFFE5DE),
        onBackground: Color(0xFFFFE5DE),
        onSurface: Color(0xFFFFE5DE),
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
          color: Color(0xFFDF643F),
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
          color: Color(0xFFDF643F),
          fontWeight: FontWeight.w400,
          fontSize: 14,
        ),
      ),
      fontFamily: 'Poppins',
      useMaterial3: true,
      appBarTheme: AppBarTheme(
        backgroundColor: Color(0xFF3D1F1D),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        iconTheme: IconThemeData(color: Color(0xFFDF643F)),
      ),
      cardTheme: CardThemeData(
        color: Color(0xFFA73728),
        elevation: 4,
        shadowColor: Color(0xFFDF643F),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        tileColor: Color(0xFFA73728),
        iconColor: Color(0xFFDF643F),
        textColor: Colors.white,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Color(0xFFA73728),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0xFFDF643F),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: TextStyle(fontWeight: FontWeight.bold),
          shadowColor: Color(0xFFDF643F),
          elevation: 4,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: Color(0xFFA73728),
        contentTextStyle: TextStyle(color: Colors.white),
      ),
    ),
    mainGradient: LinearGradient(
      begin: Alignment.bottomLeft,
      end: Alignment.topRight,
      colors: [Color(0xFF3D1F1D), Color(0xFFA73728), Color(0xFFDF643F)],
      stops: [0.0, 0.5, 1.0],
    ),
    cardGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFA73728), Color(0xFF3D1F1D)],
    ),
    glassmorphicGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Colors.white.withOpacity(0.18),
        Colors.red.withOpacity(0.10),
        Colors.white.withOpacity(0.12),
      ],
    ),
    primaryColor: Color(0xFFDF643F),
    secondaryColor: Color(0xFFA73728),
    accentColor: Color(0xFFDF643F),
    surfaceColor: Color(0xFFA73728),
    backgroundColor: Color(0xFF3D1F1D),
    textColor: Colors.white,
    mutedTextColor: Color(0xFFA73728),
    borderColor: Color(0xFFDF643F),
    shadowColor: Color(0xFFDF643F),
    dialogDecoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.bottomLeft,
        end: Alignment.topRight,
        colors: [Color(0xFF3D1F1D), Color(0xFFA73728), Color(0xFFDF643F)],
        stops: [0.0, 0.5, 1.0],
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
        colors: [Color(0xFFA73728), Color(0xFF3D1F1D)],
      ),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: Color(0xFFDF643F).withOpacity(0.3), width: 1),
      boxShadow: [
        BoxShadow(
          color: Color(0xFFDF643F).withOpacity(0.4),
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
          Colors.red.withOpacity(0.10),
          Colors.white.withOpacity(0.12),
        ],
      ),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.white.withOpacity(0.18), width: 1.2),
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
          color: Color(0xFF959BB5),
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
          color: Color(0xFF959BB5),
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
          color: Color(0xFFFADCD5),
          fontWeight: FontWeight.bold,
          fontSize: 32,
          letterSpacing: 1.2,
        ),
        titleLarge: TextStyle(
          color: Color(0xFFFADCD5),
          fontWeight: FontWeight.bold,
          fontSize: 24,
          letterSpacing: 1.1,
        ),
        titleMedium: TextStyle(
          color: Color(0xFF765D67),
          fontWeight: FontWeight.w500,
          fontSize: 16,
          letterSpacing: 0.8,
        ),
        bodyLarge: TextStyle(
          color: Color(0xFFFADCD5),
          fontWeight: FontWeight.w400,
          fontSize: 16,
        ),
        bodyMedium: TextStyle(
          color: Color(0xFF765D67),
          fontWeight: FontWeight.w400,
          fontSize: 14,
        ),
      ),
      fontFamily: 'Poppins',
      useMaterial3: true,
      appBarTheme: AppBarTheme(
        backgroundColor: Color(0xFF1B0C1A),
        foregroundColor: Color(0xFFFADCD5),
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: Color(0xFFFADCD5),
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
        textColor: Color(0xFFFADCD5),
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
        contentTextStyle: TextStyle(color: Color(0xFFFADCD5)),
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
    textColor: Color(0xFFFADCD5),
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

  // Winter Night Theme
  static final AppTheme winterNightTheme = AppTheme(
    name: 'Winter Night',
    themeData: ThemeData(
      brightness: Brightness.dark,
      primaryColor: Color(0xFF2E3061),
      scaffoldBackgroundColor: Color(0xFF28293D),
      cardColor: Color(0xFF555184),
      colorScheme: ColorScheme.dark(
        primary: Color(0xFF2E3061),
        secondary: Color(0xFF555184),
        background: Color(0xFF28293D),
        surface: Color(0xFF9997BC),
        onPrimary: Color(0xFFFEE9CE),
        onSecondary: Color(0xFFFEE9CE),
        onBackground: Color(0xFFFEE9CE),
        onSurface: Color(0xFFFEE9CE),
      ),
      textTheme: TextTheme(
        displayLarge: TextStyle(
          color: Color(0xFFFEE9CE),
          fontWeight: FontWeight.bold,
          fontSize: 32,
          letterSpacing: 1.2,
        ),
        titleLarge: TextStyle(
          color: Color(0xFFFEE9CE),
          fontWeight: FontWeight.bold,
          fontSize: 24,
          letterSpacing: 1.1,
        ),
        titleMedium: TextStyle(
          color: Color(0xFFB2A6BE),
          fontWeight: FontWeight.w500,
          fontSize: 16,
          letterSpacing: 0.8,
        ),
        bodyLarge: TextStyle(
          color: Color(0xFFFEE9CE),
          fontWeight: FontWeight.w400,
          fontSize: 16,
        ),
        bodyMedium: TextStyle(
          color: Color(0xFFB2A6BE),
          fontWeight: FontWeight.w400,
          fontSize: 14,
        ),
      ),
      fontFamily: 'Poppins',
      useMaterial3: true,
      appBarTheme: AppBarTheme(
        backgroundColor: Color(0xFF28293D),
        foregroundColor: Color(0xFFFEE9CE),
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: Color(0xFFFEE9CE),
        ),
        iconTheme: IconThemeData(color: Color(0xFF2E3061)),
      ),
      cardTheme: CardThemeData(
        color: Color(0xFF555184),
        elevation: 4,
        shadowColor: Color(0xFF2E3061),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        tileColor: Color(0xFF555184),
        iconColor: Color(0xFF2E3061),
        textColor: Color(0xFFFEE9CE),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Color(0xFF555184),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0xFF2E3061),
          foregroundColor: Color(0xFFFEE9CE),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: TextStyle(fontWeight: FontWeight.bold),
          shadowColor: Color(0xFF2E3061),
          elevation: 4,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: Color(0xFF555184),
        contentTextStyle: TextStyle(color: Color(0xFFFEE9CE)),
      ),
    ),
    mainGradient: LinearGradient(
      begin: Alignment.bottomLeft,
      end: Alignment.topRight,
      colors: [
        Color(0xFF2E3061),
        Color(0xFF28293D),
        Color(0xFF555184),
        Color(0xFF9997BC),
        Color(0xFFB2A6BE),
        Color(0xFFFEE9CE),
      ],
      stops: [0.0, 0.15, 0.35, 0.55, 0.75, 1.0],
    ),
    cardGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF555184), Color(0xFF9997BC), Color(0xFFB2A6BE)],
    ),
    glassmorphicGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFFFEE9CE).withOpacity(0.18),
        Color(0xFF2E3061).withOpacity(0.10),
        Color(0xFFFEE9CE).withOpacity(0.12),
      ],
    ),
    primaryColor: Color(0xFF2E3061),
    secondaryColor: Color(0xFF555184),
    accentColor: Color(0xFF9997BC),
    surfaceColor: Color(0xFFB2A6BE),
    backgroundColor: Color(0xFF28293D),
    textColor: Color(0xFFFEE9CE),
    mutedTextColor: Color(0xFFB2A6BE),
    borderColor: Color(0xFF2E3061),
    shadowColor: Color(0xFF2E3061),
    dialogDecoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.bottomLeft,
        end: Alignment.topRight,
        colors: [
          Color(0xFF2E3061),
          Color(0xFF28293D),
          Color(0xFF555184),
          Color(0xFF9997BC),
          Color(0xFFB2A6BE),
          Color(0xFFFEE9CE),
        ],
        stops: [0.0, 0.15, 0.35, 0.55, 0.75, 1.0],
      ),
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(24),
        topRight: Radius.circular(24),
      ),
      border: Border.all(color: Color(0xFFFEE9CE).withOpacity(0.18), width: 1),
    ),
    cardDecoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF555184), Color(0xFF9997BC), Color(0xFFB2A6BE)],
      ),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: Color(0xFF2E3061).withOpacity(0.3), width: 1),
      boxShadow: [
        BoxShadow(
          color: Color(0xFF2E3061).withOpacity(0.4),
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
          Color(0xFFFEE9CE).withOpacity(0.18),
          Color(0xFF2E3061).withOpacity(0.10),
          Color(0xFFFEE9CE).withOpacity(0.12),
        ],
      ),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: Color(0xFFFEE9CE).withOpacity(0.18),
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
          color: Color(0xFF887A67),
          fontWeight: FontWeight.bold,
          fontSize: 32,
          letterSpacing: 1.2,
        ),
        titleLarge: TextStyle(
          color: Color(0xFF887A67),
          fontWeight: FontWeight.bold,
          fontSize: 24,
          letterSpacing: 1.1,
        ),
        titleMedium: TextStyle(
          color: Color(0xFF3E5646),
          fontWeight: FontWeight.w500,
          fontSize: 16,
          letterSpacing: 0.8,
        ),
        bodyLarge: TextStyle(
          color: Color(0xFF887A67),
          fontWeight: FontWeight.w400,
          fontSize: 16,
        ),
        bodyMedium: TextStyle(
          color: Color(0xFF3E5646),
          fontWeight: FontWeight.w400,
          fontSize: 14,
        ),
      ),
      fontFamily: 'Poppins',
      useMaterial3: true,
      appBarTheme: AppBarTheme(
        backgroundColor: Color(0xFF0F1A1E),
        foregroundColor: Color(0xFF887A67),
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: Color(0xFF887A67),
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
        textColor: Color(0xFF887A67),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Color(0xFF3E5646),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0xFF193F28),
          foregroundColor: Color(0xFF887A67),
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
        contentTextStyle: TextStyle(color: Color(0xFF887A67)),
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
    textColor: Color(0xFF887A67),
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
          color: Color(0xFF6C90C3),
          fontWeight: FontWeight.bold,
          fontSize: 32,
          letterSpacing: 1.2,
        ),
        titleLarge: TextStyle(
          color: Color(0xFF6C90C3),
          fontWeight: FontWeight.bold,
          fontSize: 24,
          letterSpacing: 1.1,
        ),
        titleMedium: TextStyle(
          color: Color(0xFF274272),
          fontWeight: FontWeight.w500,
          fontSize: 16,
          letterSpacing: 0.8,
        ),
        bodyLarge: TextStyle(
          color: Color(0xFF6C90C3),
          fontWeight: FontWeight.w400,
          fontSize: 16,
        ),
        bodyMedium: TextStyle(
          color: Color(0xFF274272),
          fontWeight: FontWeight.w400,
          fontSize: 14,
        ),
      ),
      fontFamily: 'Poppins',
      useMaterial3: true,
      appBarTheme: AppBarTheme(
        backgroundColor: Color(0xFF0D1433),
        foregroundColor: Color(0xFF6C90C3),
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: Color(0xFF6C90C3),
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
        textColor: Color(0xFF6C90C3),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Color(0xFF274272),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0xFF171F55),
          foregroundColor: Color(0xFF6C90C3),
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
        contentTextStyle: TextStyle(color: Color(0xFF6C90C3)),
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
    textColor: Color(0xFF6C90C3),
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

  static final ValueNotifier<AppTheme> currentThemeNotifier =
      ValueNotifier<AppTheme>(defaultTheme);

  static final List<AppTheme> availableThemes = [
    defaultTheme,
    reddishTheme,
    redMistTheme,
    blueVioletTheme,
    sakuraTheme,
    winterNightTheme,
    forestGreenTheme,
    bluePaletteTheme,
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
}
