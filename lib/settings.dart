import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'login.dart'; // Ensure this path is correct for your project

/// SettingsPage accepts a user parameter to pass along user data.
class SettingsPage extends StatelessWidget {
  final Map<String, dynamic> user;

  const SettingsPage({Key? key, required this.user}) : super(key: key);

  // Logout function: navigate to LoginPage and clear the navigation stack.
  void _logout(BuildContext context) {
    Navigator.pushAndRemoveUntil(
      context,
      CupertinoPageRoute(builder: (context) => const LoginPage()),
          (route) => false,
    );
  }

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
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
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
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
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
            const SizedBox(height: 1),
            // Logout Button
            CupertinoButton(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              color: CupertinoColors.systemGrey6,
              onPressed: () => _logout(context),
              child: Row(
                children: const [
                  Icon(CupertinoIcons.square_arrow_right, color: CupertinoColors.activeBlue),
                  SizedBox(width: 12),
                  Text('Logout'),
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

  // Extract actual user data; in your login response the user data is nested under "user".
  late Map<String, dynamic> currentUser;

  @override
  void initState() {
    super.initState();
    currentUser = widget.user.containsKey('user') ? widget.user['user'] : widget.user;
    _usernameController = TextEditingController(text: currentUser['username'] ?? '');
    _passwordController = TextEditingController(text: currentUser['password'] ?? '');
  }

  // Logout function: navigate to LoginPage and clear the navigation stack.
  void _logout() {
    Navigator.pushAndRemoveUntil(
      context,
      CupertinoPageRoute(builder: (context) => const LoginPage()),
          (route) => false,
    );
  }

  // Show dialog and then logout.
  void _showDialogAndLogout(String title, String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () {
              Navigator.pop(context);
              _logout();
            },
          )
        ],
      ),
    );
  }

  Future<void> _updateAccount() async {
    final updatedData = {
      'username': _usernameController.text.trim(),
      'password': _passwordController.text.trim(),
      'role': currentUser['role'], // keep the current role unchanged
    };

    try {
      final response = await http.put(
        Uri.parse('$baseUrl/users/${currentUser['id']}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(updatedData),
      );

      if (response.statusCode == 200) {
        final updatedUser = jsonDecode(response.body);
        setState(() {
          currentUser['username'] = updatedUser['username'];
          currentUser['password'] = updatedUser['password'];
        });
        _showDialogAndLogout('Success', 'Your account details have been updated. Please log in again.');
      } else {
        final errorData = jsonDecode(response.body);
        _showDialog('Error', errorData['error'] ?? 'Failed to update account.');
      }
    } catch (e) {
      _showDialog('Error', 'Failed to connect to server. Please try again later.');
    }
  }

  Future<void> _deleteAccount() async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/users/${currentUser['id']}'),
      );
      if (response.statusCode == 200) {
        _showDialogAndLogout('Account Deleted', 'Your account has been deleted. Please log in again.');
      } else {
        final errorData = jsonDecode(response.body);
        _showDialog('Error', errorData['error'] ?? 'Failed to delete account.');
      }
    } catch (e) {
      _showDialog('Error', 'Failed to connect to server. Please try again later.');
    }
  }

  void _confirmDeleteAccount() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Delete Account'),
        content: Text('Are you sure you want to delete your account, ${currentUser['username']}? This action cannot be undone.'),
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
      navigationBar: const CupertinoNavigationBar(middle: Text('Account Settings')),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              const Icon(CupertinoIcons.person_circle, size: 100, color: CupertinoColors.systemGrey),
              const SizedBox(height: 16),
              // Display role as read-only.
              Row(
                children: [
                  const Icon(CupertinoIcons.info, size: 24),
                  const SizedBox(width: 12),
                  Text('Role: ${currentUser['role']}'),
                ],
              ),
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
              const SizedBox(height: 16),
              // Logout button in the Account Settings page as well.
              CupertinoButton(
                onPressed: _logout,
                child: const Text('Logout'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}