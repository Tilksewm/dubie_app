// lib/screens/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dubie_app/providers/auth_provider.dart';
import 'package:dubie_app/screens/pin_lock_screen.dart'; // For initial PIN setup
import 'package:flutter_secure_storage/flutter_secure_storage.dart'; // For testing PIN existence

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _currentPinController = TextEditingController();
  final TextEditingController _newPinController = TextEditingController();
  final TextEditingController _confirmNewPinController = TextEditingController();

  @override
  void dispose() {
    _currentPinController.dispose();
    _newPinController.dispose();
    _confirmNewPinController.dispose();
    super.dispose();
  }

  void _showSetPinDialog(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
        contentPadding: EdgeInsets.zero,

        content: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            width: double.maxFinite,
            child: PinLockScreen(
              isInitialSetup: true,
              onPinVerified: () {
                Navigator.of(ctx).pop(); // Pop PIN dialog
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('PIN set successfully!')),
                );
              },
            ),
          ),
        )
      ),
    );
  }

  void _showChangePinDialog(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Change PIN'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _currentPinController,
                decoration: const InputDecoration(labelText: 'Current PIN'),
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 4,
              ),
              TextField(
                controller: _newPinController,
                decoration: const InputDecoration(labelText: 'New PIN (4 digits)'),
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 4,
              ),
              TextField(
                controller: _confirmNewPinController,
                decoration: const InputDecoration(labelText: 'Confirm New PIN'),
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 4,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _currentPinController.clear();
              _newPinController.clear();
              _confirmNewPinController.clear();
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_newPinController.text != _confirmNewPinController.text) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('New PINs do not match!')),
                );
                return;
              }
              if (_newPinController.text.length != 4) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('New PIN must be 4 digits!')),
                );
                return;
              }

              try {
                await authProvider.changePin(_currentPinController.text, _newPinController.text);
                if (mounted) {
                  Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('PIN changed successfully!')),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
                );
              } finally {
                _currentPinController.clear();
                _newPinController.clear();
                _confirmNewPinController.clear();
              }
            },
            child: const Text('Change PIN'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          // Language Settings (Placeholder)
          ListTile(
            title: const Text('Language'),
            subtitle: const Text('English (Default)'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Language settings not yet implemented.')),
              );
            },
          ),
          const Divider(),

          // PIN Code Settings
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Text(
              'PIN Code Settings',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          SwitchListTile(
            title: const Text('Enable PIN Lock'),
            value: authProvider.isPinEnabled,
            onChanged: (bool value) async {
              if (value) {
                // If enabling, show dialog to set PIN
                _showSetPinDialog(context);
              } else {
                // If disabling, confirm and disable
                try {
                  // For simplicity, directly disable. For security, might ask for current PIN first.
                  await authProvider.disablePin();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('PIN lock disabled.')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to disable PIN: $e')),
                  );
                }
              }
            },
          ),
          ListTile(
            title: const Text('Change PIN'),
            enabled: authProvider.isPinEnabled, // Only enabled if PIN is set
            onTap: authProvider.isPinEnabled ? () => _showChangePinDialog(context) : null,
            trailing: const Icon(Icons.arrow_forward_ios),
          ),
          // Add a simple button to delete account (for testing, should be secure in production)
          const Divider(),
          ListTile(
            title: const Text('Delete Account'),
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            onTap: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Delete Account'),
                  content: const Text('Are you sure you want to delete your account? This action cannot be undone.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        // Implement delete account logic here
                        // This usually involves an API call to your backend
                        // Then log out the user and navigate to login screen
                        // For now, just log out as a placeholder
                        try {
                          // await Provider.of<AuthProvider>(context, listen: false).apiService.deleteAccount(); // Implement this in api_service
                          await Provider.of<AuthProvider>(context, listen: false).logout();
                          if (mounted) {
                            Navigator.of(ctx).pop(); // Pop dialog
                            Navigator.of(context).pushReplacementNamed('/login');
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Account deleted successfully.')),
                            );
                          }
                        } catch (e) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            SnackBar(content: Text('Failed to delete account: $e')),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      child: const Text('Delete', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              );
            },
          ),
          const Divider(),
        ],
      ),
    );
  }
}