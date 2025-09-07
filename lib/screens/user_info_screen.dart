// This file remains the same as provided in the last response,
// ensuring navigation to UserDebtsDetailScreen after adding a new user.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dubie_app/providers/home_provider.dart';
import 'package:dubie_app/services/api_service.dart';
import 'package:dubie_app/screens/user_debts_detail_screen.dart';

import '../models/user.dart';
import '../providers/user_provider.dart'; // Import the detail screen

class UserInfoScreen extends StatefulWidget {
  final User user;
  const UserInfoScreen({super.key,required this.user});

  @override
  State<UserInfoScreen> createState() => _UserInfoScreenState();
}

class _UserInfoScreenState extends State<UserInfoScreen> {
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;


  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Provider.of<UserProvider>(context, listen: false).getUserById(widget.user.id);
    });
  }

  Future<void> _updateUser(String name, String phone, String email, String username) async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      try {
        if(widget.user.userType != 'real'){
          if (name.isNotEmpty){
            final updatedUser = await Provider.of<UserProvider>(context, listen: false).editTemporaryUser(
              widget.user.id,
              name: name,
              phone: phone ,//_phoneController.text.isNotEmpty ? _phoneController.text : null,
              email: email, //_emailController.text.isNotEmpty ? _emailController.text : null,
              username: username, //_usernameController.text.isNotEmpty ? _usernameController.text : null,
            );
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Person updated successfully!')),
              );
              // Navigator.of(context).pop(); // Pop this AddUserScreen first
              //
            }
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Name can\'t be empty')),
            );
          }
        }

      } on ApiException catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to update person: ${e.message}')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('An unexpected error occurred.')),
          );
        }
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  String getInitials(String fullName) {
    final parts = fullName.trim().split(" ");
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return "${parts[0][0].toUpperCase()}${parts[1][0].toUpperCase()}";
  }

  @override
  void dispose() {
    // nameController.dispose();
    // phoneController.dispose();
    // emailController.dispose();
    // usernameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final thisUser = userProvider.currentUser;

    final TextEditingController nameController = TextEditingController(text: thisUser?.name ?? "");
    final TextEditingController phoneController = TextEditingController(text: thisUser?.phone ?? "");
    final TextEditingController emailController = TextEditingController(text: thisUser?.email ?? "");
    final TextEditingController usernameController = TextEditingController(text: thisUser?.username ?? "");

    if (userProvider.isLoading){
      return Center(
        child: CircularProgressIndicator(),
      );
    }

    if (thisUser?.userType != 'real'){
      return Scaffold(
        appBar: AppBar(
          title: const Text('update User data'),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Name is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16.0),
                TextFormField(
                  controller: phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Phone (Optional)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16.0),
                TextFormField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email (Optional)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16.0),
                TextFormField(
                  controller: usernameController,
                  decoration: const InputDecoration(
                    labelText: 'Username (Optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 24.0),
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                  onPressed: () {
                    _updateUser(
                        nameController.text,
                        phoneController.text,
                        emailController.text,
                        usernameController.text
                    );
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  child: const Text('Save', style: TextStyle(fontSize: 18)),
                ),
              ],
            ),
          ),
        ),
      );
    }else {
      return Center(child: Text("Unknown error occurred"));
    }
  }
}