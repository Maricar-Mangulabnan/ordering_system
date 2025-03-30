// settings.dart

import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;

/// SettingsPage accepts a user parameter to pass along user data.
class SettingsPage extends StatelessWidget {
  final Map<String, dynamic> user;

  const SettingsPage({Key? key, required this.user}) : super(key: key);

  void _showAboutDialog(BuildContext context) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('About OrderKo'),
        content: const Text('OrderKo App v1.0\nBuilt with Flutter & Prisma.'),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () => Navigator.pop(context),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Settings'),
      ),
      child: SafeArea(
        child: ListView(
          children: [
            // Account Settings Button
            CupertinoButton(
              padding:
              const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              color: CupertinoColors.systemGrey6,
              onPressed: () {
                Navigator.push(
                  context,
                  CupertinoPageRoute(
                    builder: (context) => AccountSettingsPage(user: user),
                  ),
                );
              },
              child: Row(
                children: const [
                  Icon(CupertinoIcons.person, color: CupertinoColors.activeBlue),
                  SizedBox(width: 12),
                  Text('Account Settings'),
                ],
              ),
            ),
            const SizedBox(height: 1),
            // About Button
            CupertinoButton(
              padding:
              const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              color: CupertinoColors.systemGrey6,
              onPressed: () => _showAboutDialog(context),
              child: Row(
                children: const [
                  Icon(CupertinoIcons.info, color: CupertinoColors.activeBlue),
                  SizedBox(width: 12),
                  Text('About'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// AccountSettingsPage provides update (username, password) and deletion of account.
class AccountSettingsPage extends StatefulWidget {
  final Map<String, dynamic> user;

  const AccountSettingsPage({Key? key, required this.user}) : super(key: key);

  @override
  _AccountSettingsPageState createState() => _AccountSettingsPageState();
}

class _AccountSettingsPageState extends State<AccountSettingsPage> {
  late TextEditingController _usernameController;
  late TextEditingController _passwordController;
  // Use your deployed server URL.
  final String baseUrl = 'https://orderko-server.onrender.com';

  @override
  void initState() {
    super.initState();
    _usernameController =
        TextEditingController(text: widget.user['username'] ?? '');
    _passwordController =
        TextEditingController(text: widget.user['password'] ?? '');
  }

  Future<void> _updateAccount() async {
    final updatedData = {
      'username': _usernameController.text.trim(),
      'password': _passwordController.text.trim(),
      'role': widget.user['role'], // keep the current role
    };

    try {
      final response = await http.put(
        Uri.parse('$baseUrl/users/${widget.user['id']}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(updatedData),
      );

      if (response.statusCode == 200) {
        final updatedUser = jsonDecode(response.body);
        setState(() {
          widget.user['username'] = updatedUser['username'];
          widget.user['password'] = updatedUser['password'];
        });
        _showDialog('Success', 'Your account details have been updated.');
      } else {
        final errorData = jsonDecode(response.body);
        _showDialog('Error',
            errorData['error'] ?? 'Failed to update account.');
      }
    } catch (e) {
      _showDialog(
          'Error', 'Failed to connect to server. Please try again later.');
    }
  }

  Future<void> _deleteAccount() async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/users/${widget.user['id']}'),
      );
      if (response.statusCode == 200) {
        _showDialog('Account Deleted', 'Your account has been deleted.');
        // Optionally, navigate to the login screen.
      } else {
        final errorData = jsonDecode(response.body);
        _showDialog('Error',
            errorData['error'] ?? 'Failed to delete account.');
      }
    } catch (e) {
      _showDialog(
          'Error', 'Failed to connect to server. Please try again later.');
    }
  }

  void _confirmDeleteAccount() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Delete Account'),
        content: Text(
            'Are you sure you want to delete your account, ${widget.user['username']}? This action cannot be undone.'),
        actions: [
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text('Delete'),
            onPressed: () {
              Navigator.pop(context);
              _deleteAccount();
            },
          ),
          CupertinoDialogAction(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  void _showDialog(String title, String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () => Navigator.pop(context),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar:
      const CupertinoNavigationBar(middle: Text('Account Settings')),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              const Icon(CupertinoIcons.person_circle,
                  size: 100, color: CupertinoColors.systemGrey),
              const SizedBox(height: 16),
              CupertinoTextField(
                controller: _usernameController,
                placeholder: 'Username',
                prefix: const Icon(CupertinoIcons.person),
              ),
              const SizedBox(height: 16),
              CupertinoTextField(
                controller: _passwordController,
                placeholder: 'Password',
                obscureText: true,
                prefix: const Icon(CupertinoIcons.lock),
              ),
              const SizedBox(height: 24),
              CupertinoButton.filled(
                onPressed: _updateAccount,
                child: const Text('Save Changes'),
              ),
              const SizedBox(height: 16),
              CupertinoButton(
                color: CupertinoColors.destructiveRed,
                onPressed: _confirmDeleteAccount,
                child: const Text('Delete Account'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
