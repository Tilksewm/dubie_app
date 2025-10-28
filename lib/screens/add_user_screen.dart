// This file remains the same as provided in the last response,
// ensuring navigation to UserDebtsDetailScreen after adding a new user.
import 'package:dubie_app/core/custom_colors.dart';
import 'package:dubie_app/l10n/app_localizations.dart';
import 'package:dubie_app/models/user.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dubie_app/providers/home_provider.dart';
import 'package:dubie_app/screens/user_debts_detail_screen.dart'; // Import the detail screen

class AddUserScreen extends StatefulWidget {
  final User mainUser;

  const AddUserScreen({
    super.key,
    required this.mainUser
  });

  @override
  State<AddUserScreen> createState() => _AddUserScreenState();
}

class _AddUserScreenState extends State<AddUserScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  bool _isLoading = false;

  Future<void> _addPerson() async {
    final loc = AppLocalizations.of(context)!;
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      try {
        print('Adding person: ${_nameController.text}, Phone: ${_phoneController.text}, Email: ${_emailController.text}, Username: ${_usernameController.text}');
        final newUser = await Provider.of<HomeProvider>(context, listen: false).createPlaceholderUser(
          name: _nameController.text,
          phone: _phoneController.text.isNotEmpty ? _phoneController.text : null,
          email: _emailController.text.isNotEmpty ? _emailController.text : null,
          username: _usernameController.text.isNotEmpty ? _usernameController.text : null,
        );
        print('New user created with ID: ${newUser.id}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(loc.personAddedSuccessfully)),
          );
          Navigator.of(context).pop(); // Pop this AddUserScreen first
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => UserDebtsDetailScreen(
                otherUserId: newUser.id,
                mainUser: widget.mainUser,
                //totalAmountWithUser: 0.0, // Initial debt is 0.0 with a new user
              ),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(loc.somethingWentWrong),
              backgroundColor: Theme.of(context).colorScheme.withdrawColor,),
          );
        }
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(loc.addNewPerson),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: loc.fullName,
                  border: const OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return loc.enterYourFullName;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                controller: _phoneController,
                decoration: InputDecoration(
                  labelText: loc.phoneOptional,
                  border: const OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value != null && value.isNotEmpty && !RegExp(r'^\+[0-9]{7,15}$').hasMatch(value)) {
                    return loc.enterValidPhoneWithCountryCode;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: loc.emailOptional,
                  border: const OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if ((value != null && value.isNotEmpty) && !RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                    return loc.enterValidEmail;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                controller: _usernameController,
                decoration: InputDecoration(
                  labelText: loc.usernameOptional,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24.0),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                onPressed: _addPerson,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: Text(loc.addPerson, style: TextStyle(fontSize: 18)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}