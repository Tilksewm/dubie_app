// lib/screens/settings_screen.dart
import 'package:dubie_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dubie_app/providers/auth_provider.dart';
import 'package:dubie_app/screens/pin_lock_screen.dart'; // For initial PIN setup
// For testing PIN existence

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
    final loc = AppLocalizations.of(context)!;
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
                  SnackBar(content: Text('${loc.pinSetSuccessfully}!')),
                );
              },
            ),
          ),
        )
      ),
    );
  }

  void _showChangePinDialog(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(loc.changePin),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _currentPinController,
                decoration: InputDecoration(labelText: loc.currentPin),
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 4,
              ),
              TextField(
                controller: _newPinController,
                decoration: InputDecoration(labelText: loc.newPin),
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 4,
              ),
              TextField(
                controller: _confirmNewPinController,
                decoration: InputDecoration(labelText: loc.confirmNewPin),
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
            child: Text(loc.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_newPinController.text != _confirmNewPinController.text) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  SnackBar(content: Text('${loc.pinsDoNotMatch}!')),
                );
                return;
              }
              if (_newPinController.text.length != 4) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  SnackBar(content: Text('${loc.newPinMustBe4Digits}!')),
                );
                return;
              }

              try {
                await authProvider.changePin(_currentPinController.text, _newPinController.text);
                if (mounted) {
                  Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${loc.pinChangedSuccessfully}!')),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  SnackBar(content: Text(loc.somethingWentWrong/*e.toString().replaceFirst('Exception: ', '')*/)),
                );
              } finally {
                _currentPinController.clear();
                _newPinController.clear();
                _confirmNewPinController.clear();
              }
            },
            child: Text(loc.changePinBtn),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.settings),
      ),
      body: ListView(
        children: [
          const Divider(),

          // PIN Code Settings
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Text(
              loc.pinCodeSettings,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          SwitchListTile(
            title: Text(loc.enablePinLock),
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
                    SnackBar(content: Text(loc.pinLockedDisabled)),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(loc.failedToDisablePin)),
                  );
                }
              }
            },
          ),
          ListTile(
            title: Text(loc.changePin),
            enabled: authProvider.isPinEnabled, // Only enabled if PIN is set
            onTap: authProvider.isPinEnabled ? () => _showChangePinDialog(context) : null,
            trailing: const Icon(Icons.arrow_forward_ios),
          ),
          // Add a simple button to delete account (for testing, should be secure in production)
          const Divider(),
          ListTile(
            title: Text(loc.deleteAccountTitle),
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            onTap: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: Text(loc.deleteAccountTitle),
                  content: Text(loc.deleteAccountWarning),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: Text(loc.cancel),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        // Implement delete account logic here
                        // This usually involves an API call to your backend
                        // Then log out the user and navigate to login screen
                        // For now, just log out as a placeholder
                        try {
                          await Provider.of<AuthProvider>(context, listen: false).apiService.deleteAccount(); // Implement this in api_service
                          await Provider.of<AuthProvider>(context, listen: false).logout();
                          if (mounted) {
                            Navigator.of(ctx).pop(); // Pop dialog
                            Navigator.of(context).pushReplacementNamed('/login');
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(loc.accountDeletedSuccessfully)),
                            );
                          }
                        } catch (e) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            SnackBar(content: Text(loc.failedDeleteAccount)),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      child: Text(loc.delete, style: TextStyle(color: Colors.white)),
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