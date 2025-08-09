// lib/screens/pin_lock_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dubie_app/providers/auth_provider.dart';

class PinLockScreen extends StatefulWidget {
  final VoidCallback onPinVerified;
  final bool isInitialSetup; // True if setting PIN for the first time

  const PinLockScreen({super.key, required this.onPinVerified, this.isInitialSetup = false});

  @override
  State<PinLockScreen> createState() => _PinLockScreenState();
}

class _PinLockScreenState extends State<PinLockScreen> {
  final TextEditingController _pinController = TextEditingController();
  String _errorMessage = '';
  bool _isLoading = false;
  String _currentPinInput = ''; // To build the PIN input visually

  @override
  void initState() {
    super.initState();
    // Clear any previous error message when screen is initialized
    _errorMessage = '';
  }

  void _onPinDigitEntered(String digit) {
    if (_currentPinInput.length < 4) {
      setState(() {
        _currentPinInput += digit;
      });
      if (_currentPinInput.length == 4) {
        _verifyPin();
      }
    }
  }

  void _onPinDigitRemoved() {
    if (_currentPinInput.isNotEmpty) {
      setState(() {
        _currentPinInput = _currentPinInput.substring(0, _currentPinInput.length - 1);
      });
    }
  }

  Future<void> _verifyPin() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    try {
      if (widget.isInitialSetup) {
        // If it's initial setup, we are setting the PIN, not verifying an existing one
        await authProvider.setPin(_currentPinInput);
        widget.onPinVerified(); // Signal success
      } else {
        // Regular verification
        final bool verified = await authProvider.verifyPin(_currentPinInput);
        if (verified) {
          widget.onPinVerified(); // Signal success
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _currentPinInput = ''; // Clear input on error
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final bool isLockedOut = authProvider.isPinLockedOut;
    final Duration? lockoutRemaining = authProvider.pinLockoutRemaining;

    return PopScope( // Use PopScope for back button handling
      canPop: false, // Prevent popping the PIN screen without successful PIN entry
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.isInitialSetup ? 'Set PIN' : 'Enter PIN'),
          automaticallyImplyLeading: false, // No back button on PIN screen
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  widget.isInitialSetup ? 'Create your 4-digit PIN' : 'Enter your 4-digit PIN',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 40),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(4, (index) {
                    return Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          index < _currentPinInput.length ? '•' : '', // Show dot for entered digits
                          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 20),
                if (_errorMessage.isNotEmpty)
                  Text(
                    _errorMessage,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                if (isLockedOut)
                  Padding(
                    padding: const EdgeInsets.only(top: 10.0),
                    child: Text(
                      'Locked out for ${lockoutRemaining!.inMinutes}m ${lockoutRemaining.inSeconds.remainder(60)}s',
                      style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
                    ),
                  ),
                const SizedBox(height: 40),
                _isLoading
                    ? const CircularProgressIndicator()
                    : AbsorbPointer( // Prevent input if locked out
                  absorbing: isLockedOut,
                  child: Column(
                    children: [
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          childAspectRatio: 1.5,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                        itemCount: 12,
                        itemBuilder: (context, index) {
                          if (index < 9) {
                            return _buildPinButton('${index + 1}');
                          } else if (index == 9) {
                            return const SizedBox.shrink(); // Empty space for 7,8,9,0,back
                          } else if (index == 10) {
                            return _buildPinButton('0');
                          } else {
                            return _buildPinButton('back');
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPinButton(String text) {
    return ElevatedButton(
      onPressed: () {
        if (text == 'back') {
          _onPinDigitRemoved();
        } else {
          _onPinDigitEntered(text);
        }
      },
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: EdgeInsets.zero,
        minimumSize: const Size(60, 60),
      ),
      child: text == 'back'
          ? const Icon(Icons.backspace_outlined)
          : Text(
        text,
        style: const TextStyle(fontSize: 28),
      ),
    );
  }

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }
}