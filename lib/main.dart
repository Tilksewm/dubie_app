// lib/main.dart
import 'package:dubie_app/models/comment.dart';
import 'package:dubie_app/models/debt.dart';
import 'package:dubie_app/models/debt_item.dart';
import 'package:dubie_app/models/user.dart';
import 'package:dubie_app/providers/user_provider.dart';
import 'package:dubie_app/screens/auth/login_screen.dart';
import 'package:dubie_app/screens/auth/signup_screen.dart';
import 'package:dubie_app/services/local_db_service.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dubie_app/providers/auth_provider.dart';
import 'package:dubie_app/providers/home_provider.dart';
import 'package:dubie_app/providers/debt_provider.dart'; // Ensure this is imported
//import 'package:dubie/screens/auth_screen.dart';
import 'package:dubie_app/screens/home_screen.dart';
import 'package:dubie_app/screens/pin_lock_screen.dart';
import 'package:dubie_app/utils/pin_storage.dart'; // Import PinStorage

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize Hive once
  await Hive.initFlutter();
  Hive.registerAdapter(SyncStatusAdapter());
  Hive.registerAdapter(DebtAdapter());
  Hive.registerAdapter(UserAdapter());
  Hive.registerAdapter(DebtItemAdapter());
  Hive.registerAdapter(CommentAdapter());

  final prefs = await SharedPreferences.getInstance();
  final dbService = LocalDbService(prefs);
  runApp(MyApp(prefs: prefs));
}

class MyApp extends StatefulWidget {
  final SharedPreferences prefs;
  const MyApp({super.key, required this.prefs});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  late AuthProvider _authProvider;
  bool _isAppLocked = false; // Internal state to control PIN screen display

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _authProvider = AuthProvider(widget.prefs);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // --- App Lifecycle Management for PIN Lock ---
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.paused) {
      // App is going to background
      if (_authProvider.isPinEnabled) {
        setState(() {
          _isAppLocked = true; // Mark app as locked
        });
      }
    } else if (state == AppLifecycleState.resumed) {
      // App is coming to foreground
      if (_isAppLocked && _authProvider.isPinEnabled) {
        // Show PIN screen if it was locked and PIN is enabled
        // Use a slight delay to ensure UI is ready
        Future.delayed(const Duration(milliseconds: 100), () {
          _showPinLockScreen();
        });
      }
    }
  }

  void _showPinLockScreen() {
    Navigator.of(context).push(
        MaterialPageRoute(
          builder: (ctx) => PinLockScreen(
            onPinVerified: () {
              Navigator.of(ctx).pop(); // Pop PIN screen on success
              setState(() {
                _isAppLocked = false; // Reset lock state
              });
            },
          ),
          fullscreenDialog: true, // Make it a full screen dialog
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: _authProvider),
        ChangeNotifierProvider<HomeProvider>(
          create: (_) => HomeProvider(widget.prefs),
        ),
        ChangeNotifierProvider<DebtProvider>(
          create: (_) => DebtProvider(widget.prefs),
        ),
        ChangeNotifierProvider<UserProvider>(
          create: (_) => UserProvider(widget.prefs),
        )
      ],
      child: MaterialApp(
        title: 'Dubie App',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
          floatingActionButtonTheme: const FloatingActionButtonThemeData(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
        ),
        home: Consumer<AuthProvider>(
          builder: (context, auth, _) {
            if (auth.isLoading) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            if (!auth.isAuthenticated) {
              auth.startWithNoAuth();
            }

              if (auth.isPinEnabled) {
                // Always show PIN on startup
                return PinLockScreen(
                  onPinVerified: () {
                    // After successful PIN entry, go to Home
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => const HomeScreen()),
                    );
                  },
                );
              } else {
                return const HomeScreen();
              }
            
          },
        ),

        // Define routes here if you use named routes
        routes: {
          //'/auth': (context) => const AuthScreen(),
          '/home': (context) => const HomeScreen(),
          '/login': (context) => const LoginScreen(),
          '/signup': (context) => const SignupScreen(),

        },
      ),
    );
  }
}
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:shared_preferences/shared_preferences.dart';
//
// import 'providers/auth_provider.dart';
// import 'providers/home_provider.dart';
// import 'providers/debt_provider.dart'; // Import DebtProvider
// import 'screens/auth/login_screen.dart';
// import 'screens/auth/signup_screen.dart';
// import 'screens/home_screen.dart';
//
// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   final prefs = await SharedPreferences.getInstance();
//   runApp(MyApp(prefs: prefs));
// }
//
// class MyApp extends StatelessWidget {
//   final SharedPreferences prefs;
//
//   const MyApp({super.key, required this.prefs});
//
//   @override
//   Widget build(BuildContext context) {
//     return MultiProvider(
//       providers: [
//         ChangeNotifierProvider(create: (_) => AuthProvider(prefs)),
//         ChangeNotifierProvider(create: (_) => HomeProvider(prefs)),
//         ChangeNotifierProvider(create: (_) => DebtProvider(prefs)), // Add DebtProvider here
//       ],
//       child: Consumer<AuthProvider>(
//         builder: (context, authProvider, child) {
//           return MaterialApp(
//             title: 'ዱቤ App',
//             theme: ThemeData(
//               primarySwatch: Colors.green,
//               visualDensity: VisualDensity.adaptivePlatformDensity,
//               appBarTheme: const AppBarTheme(
//                 backgroundColor: Colors.green,
//                 foregroundColor: Colors.white,
//               ),
//               colorScheme: ColorScheme.fromSwatch(primarySwatch: Colors.green).copyWith(secondary: Colors.amber), // Accent color
//             ),
//             home: authProvider.isAuthenticated ? const HomeScreen() : const LoginScreen(),
//             routes: {
//               '/login': (context) => const LoginScreen(),
//               '/signup': (context) => const SignupScreen(),
//               '/home': (context) => const HomeScreen(),
//               // Other routes will be added as we build more screens
//             },
//           );
//         },
//       ),
//     );
//   }
// }