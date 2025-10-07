import 'dart:io';

class AppConstants {
  static const String baseUrl = 'https://dubie-backend.onrender.com/api'; // For Android Emulator, use 10.0.2.2.
// For iOS Simulator, use localhost.
// For real device, use your machine's actual IP address.
// Example: 'http://192.168.1.100:3000/api'
  static String bannerAdUnitId = Platform.isAndroid
      ? 'ca-app-pub-3940256099942544/6300978111' // Android test ad unit ID
      : 'ca-app-pub-3940256099942544/2934735716'; // iOS test ad unit ID
 // Test AdMob ID
}