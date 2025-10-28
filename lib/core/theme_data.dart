import 'package:flutter/material.dart';

// --- Light Theme Definition ---
final ThemeData lightTheme = ThemeData(
  brightness: Brightness.light,
  primaryColor: Colors.white, // White AppBar
  scaffoldBackgroundColor: Colors.grey[100], // Grey[100] background

  // Define Card properties
  cardTheme: CardThemeData(
    color: Colors.white, // White Card background
    elevation: 2,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
  ),

  // Define Text properties
  textTheme: TextTheme(
    bodyLarge: TextStyle(color: Colors.grey[900]), // Grey[900] text color
    bodyMedium: TextStyle(color: Colors.grey[900]),
    titleMedium: TextStyle(color: Colors.grey[900]), // Ensure titles are dark
  ),

  // Define Button properties
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.blueGrey[100], // BlueGrey[100] button color
      foregroundColor: Colors.black, // Black button text
      textStyle: const TextStyle(fontWeight: FontWeight.bold),
    ),
  ),

  // Ensure AppBar uses the primary color (white) and dark text/icons
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.white,
    foregroundColor: Colors.black, // Dark icons/text
    elevation: 1,
  ),
);

// --- Dark Theme Definition (Complementary) ---
final ThemeData darkTheme = ThemeData(
  brightness: Brightness.dark,
  primaryColor: Colors.grey[900], // Dark primary for AppBar
  scaffoldBackgroundColor: Colors.black, // Black background for true dark mode

  // Dark Card properties
  cardTheme: CardThemeData(
    color: Colors.grey[800], // Slightly lighter grey for contrast
    elevation: 4,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
  ),

  // Dark Text properties
  textTheme: const TextTheme(
    bodyLarge: TextStyle(color: Colors.white70), // Light text
    bodyMedium: TextStyle(color: Colors.white70),
    titleMedium: TextStyle(color: Colors.white),
  ),

  // Dark Button properties
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.blueGrey[700], // A darker blue-grey
      foregroundColor: Colors.white, // White button text
      textStyle: const TextStyle(fontWeight: FontWeight.bold),
    ),
  ),

  // Dark AppBar theme
  appBarTheme: AppBarTheme(
    backgroundColor: Colors.white,
    foregroundColor: Colors.black,
  ),
);