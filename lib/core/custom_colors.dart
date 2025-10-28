// theme_extensions.dart
import 'package:flutter/material.dart';

extension CustomColors on ColorScheme {
  Color get homeBackground => brightness == Brightness.dark
      ? const Color(0xFF121212) // typical dark background
      : const Color(0xFFF5F6F7);

  Color get homeCardBackground => brightness == Brightness.dark
      ? const  Color(0xFF1E1E1E) //Color(0xFF252525)//Color(0xFF282828)//Color(0xFF1E1E1E)
      : Colors.white;

  Color get homeOnCardButtonBackground => brightness == Brightness.dark
      ? const Color(0xFF2A2A2A)
      : Colors.grey[100]!;

  Color get homeToggleActiveBackground => brightness == Brightness.dark
      ? Colors.blueGrey[800]!
      : Colors.blueGrey[100]!;

  Color get homeToggleBorder => brightness == Brightness.dark
      ? Colors.grey[850]!
      : Colors.grey[300]!;

  Color get systemOverlay => brightness == Brightness.dark
      ? Colors.white
      : Colors.black;

  Color get homeOnCardButtonBorder => brightness == Brightness.dark
      ? Colors.grey[900]!
      : Colors.grey[200]!;

  Color get textBoldColor => brightness == Brightness.dark
      ? Colors.white
      : Colors.black;

  Color get textRegularColor => brightness == Brightness.dark
      ? Colors.grey[400]!  // softer contrast for dark bg
      : Colors.black54;

  Color get textSubTitle => brightness == Brightness.dark
      ? Colors.grey[300]!
      : Colors.grey[700]!;

  Color get floatingBackground => brightness == Brightness.dark
      ? Colors.blue[700]! // slightly dimmer blue
      : Colors.blue;

  Color get floatingIcon => Colors.white;
  Color get drawerBackground => brightness == Brightness.dark
      ? const Color(0xFF121212)
      : const Color(0xFFF5F6F7);

  Color get drawerHeaderBackground => brightness == Brightness.dark
      ? const  Color(0xFF1E1E1E)
      : Colors.white;

  Color get depositColor => Colors.green;
  Color get withdrawColor => Colors.red;
  Color get avatarColor => Colors.teal.shade700;
  Color get onAvatarColor => Colors.white;


  // Color get homeBackground => brightness == Brightness.dark
  //     ? Colors.grey[900]!
  //     : const Color(0xfff5f6f7);
  // Color get homeCardBackground => brightness == Brightness.dark
  //     ? Colors.black
  //     : Colors.white;
  // Color get homeOnCardButtonBackground => brightness == Brightness.dark
  //     ? Colors.grey[900]!
  //     : Colors.grey[100]!;
  // Color get homeToggleActiveBackground => brightness == Brightness.dark
  //     ? Colors.blueGrey[900]!
  //     : Colors.blueGrey[100]!;
  // Color get homeToggleBorder => brightness == Brightness.dark
  //     ? Colors.grey[700]!
  //     : Colors.grey[300]!;
  // Color get systemOverlay => brightness == Brightness.dark
  //     ? Colors.white
  //     : Colors.black;
  // Color get homeOnCardButtonBorder => brightness == Brightness.dark
  //     ? Colors.grey[800]!
  //     : Colors.grey[200]!;
  // Color get textBoldColor => brightness == Brightness.dark
  //     ? Colors.white
  //     : Colors.black;
  // Color get textRegularColor => brightness == Brightness.dark
  //     ? Colors.grey
  //     : Colors.black54;
  // Color get textSubTitle => brightness == Brightness.dark
  //     ? Colors.grey[200]!
  //     : Colors.grey[800]!;
  // Color get floatingBackground => brightness == Brightness.dark
  //     ? Colors.blue
  //     : Colors.blue;
  // Color get floatingIcon => brightness == Brightness.dark
  //     ? Colors.white
  //     : Colors.white;
  // Color get depositColor => brightness == Brightness.dark
  //     ? Colors.green
  //     : Colors.green;
  // Color get withdrawColor => brightness == Brightness.dark
  //     ? Colors.red
  //     : Colors.red;


  // Custom semantic colors for your app
  Color get incomeCard => brightness == Brightness.dark
      ? const Color(0xFF1E3A8A) // dark blue
      : const Color(0xFF90CAF9); // light blue

  Color get expenseCard => brightness == Brightness.dark
      ? const Color(0xFF7F1D1D) // dark red
      : const Color(0xFFFFCDD2); // light red

  Color get success => brightness == Brightness.dark
      ? const Color(0xFF4CAF50)
      : const Color(0xFF2E7D32);

  Color get warning => brightness == Brightness.dark
      ? const Color(0xFFFFB300)
      : const Color(0xFFF57C00);

  Color get info => brightness == Brightness.dark
      ? const Color(0xFF29B6F6)
      : const Color(0xFF0288D1);

  Color get divider => brightness == Brightness.dark
      ? Colors.white24
      : Colors.black12;
}
