import 'package:dubie_app/providers/auth_provider.dart';
import 'package:dubie_app/screens/auth/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SignInSuggestionCard extends StatefulWidget {
  const SignInSuggestionCard({super.key});

  @override
  SignInSuggestionCardState createState() => SignInSuggestionCardState();
}

class SignInSuggestionCardState extends State<SignInSuggestionCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;
  late AuthProvider authProvider = Provider.of<AuthProvider>(context, listen: false);
  late int visibilityCount;
  SharedPreferences? preferences;
  bool _isVisible = true;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0.0, 1.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _dismiss() async {
    _controller.reverse().then((_) {
      if (mounted) {
        setState(() {
          _isVisible = false;
        });
      }
    });
    preferences = await SharedPreferences.getInstance();
    visibilityCount = preferences!.getInt('visibility_count')!;
    await preferences!.setInt('visibility_count', ++visibilityCount);
  }

  @override
  Widget build(BuildContext context) {
    return _isVisible
        ? SlideTransition(
      position: _offsetAnimation,
      child: Card(
        margin: const EdgeInsets.all(16.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        elevation: 4.0,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Unlock Exclusive Features',
                    style: TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: _dismiss,
                  ),
                ],
              ),
              const SizedBox(height: 8.0),
              const Text(
                'Create an account to save your preferences, and to sync your data across devices.',
                style: TextStyle(fontSize: 14.0),
              ),
              const SizedBox(height: 16.0),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 32.0, vertical: 12.0),
                ),
                onPressed: () {
                  Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => const LoginScreen() ));
                },
                child: const Text('Sign In / Sign Up'),
              ),
            ],
          ),
        ),
      ),
    )
        : const SizedBox.shrink();
  }
}