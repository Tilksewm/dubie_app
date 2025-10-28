import 'package:flutter/material.dart';
// import 'theme_extensions.dart'; // your CustomColors extension

class AppTheme {
  static ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
    useMaterial3: true,
    scaffoldBackgroundColor: Color(0xFFF5F6F7), // Grey[100] background

    appBarTheme: AppBarTheme(
      backgroundColor: Colors.white,
      elevation: 0,
      iconTheme: IconThemeData(color: Colors.black),
      shape: Border(
        bottom: BorderSide(
          color: Colors.grey[200]!,
          width: 1,
        ),
      ),
    ),

    cardTheme: CardThemeData(
      color: Colors.white, // White Card background
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: Colors.grey[200]!,
          width: 1
        )
      ),
    ),
    // 👇 Add your custom color extensions
    // extensions: const [],

    // --- BUTTONS ---
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue, // default bg color
        foregroundColor: Colors.white, // text/icon color
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 2,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: Colors.blue, // default text color
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.blue,
        side: const BorderSide(color: Colors.blue),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),

    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Colors.blue,
      foregroundColor: Colors.white,
      elevation: 3,
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: Colors.green,
      contentTextStyle: TextStyle(color: Colors.white),
    ),

  );

  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.blue,
      brightness: Brightness.dark,
    ),
    useMaterial3: true,
    scaffoldBackgroundColor: const Color(0xFF121212), // Dark grey background

    appBarTheme: AppBarTheme(
      backgroundColor: const  Color(0xFF1E1E1E),
      elevation: 0,
      iconTheme: IconThemeData(color: Colors.white),
      shape: Border(
        bottom: BorderSide(
          color: Colors.grey[900]!,
          width: 1,
        ),
      ),
    ),

    // Dark Card properties
    cardTheme: CardThemeData(
      color:  Color(0xFF1E1E1E), // Slightly lighter grey for contrast
      elevation: 0,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: Colors.grey[900]!,
            width: 1,
          )
      ),

    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 1,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: Colors.blue[300],
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.blue[300],
        side: BorderSide(color: Colors.blue[300]!),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),

    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: Colors.blue[700],
      foregroundColor: Colors.white,
      elevation: 3,
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: Colors.green,
      contentTextStyle: TextStyle(color: Colors.white),
    ),
  );
}
