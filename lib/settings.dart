import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'login.dart'; // Ensure this path is correct for your project

/// SettingsPage accepts a user parameter to pass along user data.
class SettingsPage extends StatelessWidget {
  final Map<String, dynamic> user;

  const SettingsPage({Key? key, required this.user}) : super(key: key);

  // Logout function: navigate to LoginPage and clear the navigation stack.
  void _logout(BuildContext context) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text('Logout'),
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushAndRemoveUntil(
                context,
                CupertinoPageRoute(builder: (context) => const LoginPage()),
                    (route) => false,
              );
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

  void _showAboutDialog(BuildContext context) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: CupertinoColors.systemBackground,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle to drag the modal
            Center(
              child: Container(
                width: 40,
                height: 5,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: CupertinoColors.systemGrey4,
                  borderRadius: BorderRadius.circular(2.5),
                ),
              ),
            ),
            const Icon(
              CupertinoIcons.cube_box,
              size: 60,
              color: Colors.teal,
            ),
            const SizedBox(height: 16),
            const Text(
              'OrderKo',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Version 1.0',
              style: TextStyle(
                fontSize: 16,
                color: CupertinoColors.systemGrey,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'OrderKo is a simple ordering system built with Flutter and Prisma.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: CupertinoColors.systemGrey,
              ),
            ),
            const SizedBox(height: 24),
            CupertinoButton(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
              color: Colors.teal,
              borderRadius: BorderRadius.circular(12),
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Close',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Extract actual user data; in your login response the user data is nested under "user".
    final currentUser = user.containsKey('user') ? user['user'] : user;

    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Settings'),
      ),
      child: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // User profile section
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: CupertinoColors.systemBackground,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: CupertinoColors.systemGrey.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          const Icon(
                            CupertinoIcons.person_circle_fill,
                            size: 80,
                            color: Colors.teal,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            currentUser['username'] ?? 'User',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.teal.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              currentUser['role'] ?? 'User',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.teal,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Settings section title
                    const Padding(
                      padding: EdgeInsets.only(left: 8, bottom: 8),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'SETTINGS',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: CupertinoColors.systemGrey,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Settings options
            SliverList(
              delegate: SliverChildListDelegate([
                // Account Settings Button
                _buildSettingsItem(
                  context,
                  icon: CupertinoIcons.person,
                  title: 'Account Settings',
                  onTap: () {
                    Navigator.push(
                      context,
                      CupertinoPageRoute(
                        builder: (context) => AccountSettingsPage(user: user),
                      ),
                    );
                  },
                ),
                _buildDivider(),
                // About Button
                _buildSettingsItem(
                  context,
                  icon: CupertinoIcons.info,
                  title: 'About',
                  onTap: () => _showAboutDialog(context),
                ),
                _buildDivider(),
                // Logout Button
                _buildSettingsItem(
                  context,
                  icon: CupertinoIcons.square_arrow_right,
                  title: 'Logout',
                  isDestructive: true,
                  onTap: () => _logout(context),
                ),
                const SizedBox(height: 40),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsItem(
      BuildContext context, {
        required IconData icon,
        required String title,
        bool isDestructive = false,
        required VoidCallback onTap,
      }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        color: CupertinoColors.systemBackground,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDestructive
                    ? CupertinoColors.destructiveRed.withOpacity(0.1)
                    : Colors.teal.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: isDestructive ? CupertinoColors.destructiveRed : Colors.teal,
                size: 22,
              ),
            ),
            const SizedBox(width: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: isDestructive ? CupertinoColors.destructiveRed : CupertinoColors.label,
              ),
            ),
            const Spacer(),
            Icon(
              CupertinoIcons.chevron_right,
              color: CupertinoColors.systemGrey,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      height: 1,
      color: CupertinoColors.systemGrey6,
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
  bool _isLoading = false;
  bool _obscurePassword = true;

  // Extract actual user data; in your login response the user data is nested under "user".
  late Map<String, dynamic> currentUser;

  @override
  void initState() {
    super.initState();
    currentUser = widget.user.containsKey('user') ? widget.user['user'] : widget.user;
    _usernameController = TextEditingController(text: currentUser['username'] ?? '');
    _passwordController = TextEditingController(text: '');
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
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
    if (_usernameController.text.trim().isEmpty) {
      _showDialog('Error', 'Username cannot be empty.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final updatedData = {
      'username': _usernameController.text.trim(),
      'role': currentUser['role'], // keep the current role unchanged
    };

    // Only include password if it's not empty
    if (_passwordController.text.trim().isNotEmpty) {
      updatedData['password'] = _passwordController.text.trim();
    }

    try {
      final response = await http.put(
        Uri.parse('$baseUrl/users/${currentUser['id']}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(updatedData),
      );

      setState(() {
        _isLoading = false;
      });

      if (response.statusCode == 200) {
        final updatedUser = jsonDecode(response.body);
        setState(() {
          currentUser['username'] = updatedUser['username'];
        });
        _showDialogAndLogout('Success', 'Your account details have been updated. Please log in again.');
      } else {
        final errorData = jsonDecode(response.body);
        _showDialog('Error', errorData['error'] ?? 'Failed to update account.');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showDialog('Error', 'Failed to connect to server. Please try again later.');
    }
  }

  Future<void> _deleteAccount() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/users/${currentUser['id']}'),
      );

      setState(() {
        _isLoading = false;
      });

      if (response.statusCode == 200) {
        _showDialogAndLogout('Account Deleted', 'Your account has been deleted successfully.');
      } else {
        final errorData = jsonDecode(response.body);
        _showDialog('Error', errorData['error'] ?? 'Failed to delete account.');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
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
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Account Settings'),
      ),
      child: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Profile section
                    Center(
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.teal.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              CupertinoIcons.person_circle_fill,
                              size: 80,
                              color: Colors.teal,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            currentUser['username'] ?? 'User',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.teal.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              currentUser['role'] ?? 'User',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.teal,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Form section title
                    const Text(
                      'ACCOUNT INFORMATION',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: CupertinoColors.systemGrey,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Username field
                    const Text(
                      'Username',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: CupertinoColors.systemGrey6,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: CupertinoTextField(
                        controller: _usernameController,
                        placeholder: 'Username',
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                        prefix: const Padding(
                          padding: EdgeInsets.only(left: 16.0),
                          child: Icon(
                            CupertinoIcons.person,
                            color: Colors.teal,
                            size: 20,
                          ),
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: CupertinoColors.systemGrey5),
                        ),
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Password field
                    const Text(
                      'Password',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: CupertinoColors.systemGrey6,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: CupertinoTextField(
                        controller: _passwordController,
                        placeholder: 'New Password',
                        obscureText: _obscurePassword,
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                        prefix: const Padding(
                          padding: EdgeInsets.only(left: 16.0),
                          child: Icon(
                            CupertinoIcons.lock,
                            color: Colors.teal,
                            size: 20,
                          ),
                        ),
                        suffix: Padding(
                          padding: const EdgeInsets.only(right: 16.0),
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                            child: Icon(
                              _obscurePassword ? CupertinoIcons.eye : CupertinoIcons.eye_slash,
                              color: Colors.teal,
                              size: 20,
                            ),
                          ),
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: CupertinoColors.systemGrey5),
                        ),
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Leave blank to keep current password',
                      style: TextStyle(
                        fontSize: 12,
                        color: CupertinoColors.systemGrey,
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Save button
                    SizedBox(
                      width: double.infinity,
                      child: CupertinoButton(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        color: Colors.teal,
                        borderRadius: BorderRadius.circular(12),
                        onPressed: _isLoading ? null : _updateAccount,
                        child: _isLoading
                            ? const CupertinoActivityIndicator(color: CupertinoColors.white)
                            : const Text(
                          'Save Changes',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Delete account button
                    SizedBox(
                      width: double.infinity,
                      child: CupertinoButton(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        color: CupertinoColors.systemGrey6,
                        borderRadius: BorderRadius.circular(12),
                        onPressed: _isLoading ? null : _confirmDeleteAccount,
                        child: Text(
                          'Delete Account',
                          style: TextStyle(
                            color: CupertinoColors.destructiveRed,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

