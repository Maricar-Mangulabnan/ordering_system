import 'dart:convert';
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:ordering_system/employee/employee-products.dart';
import 'package:ordering_system/customer/customer-products.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with SingleTickerProviderStateMixin {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final String baseUrl = 'https://orderko-server.onrender.com';
  bool _isLoading = false;
  bool _obscurePassword = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeIn,
      ),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    String username = _usernameController.text.trim();
    String password = _passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      _showDialog('Error', 'Username and Password cannot be empty.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/signin'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'password': password}),
      );

      setState(() {
        _isLoading = false;
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Retrieve role from nested 'user' object
        String role = data['user']['role'];

        // Navigate based on role
        if (role == 'EMPLOYEE') {
          Navigator.pushReplacement(
            context,
            CupertinoPageRoute(
              builder: (context) => EmployeeProductsPage(user: data),
            ),
          );
        } else if (role == 'CUSTOMER') {
          Navigator.pushReplacement(
            context,
            CupertinoPageRoute(
              builder: (context) => CustomerProductsPage(user: data),
            ),
          );
        } else {
          _showDialog('Error', 'Invalid role received.');
        }
      } else {
        final errorResponse = jsonDecode(response.body);
        _showDialog(
          'Login Failed',
          errorResponse['message'] ?? 'Invalid username or password.',
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showDialog('Error', 'Failed to connect to server. Please try again later.');
    }
  }

  void _showDialog(String title, String message) {
    showCupertinoDialog(
      context: context,
      builder: (BuildContext context) => CupertinoAlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = CupertinoTheme.of(context).primaryColor;

    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemBackground,
      child: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 60),
                  // App Icon
                  Container(
                    height: 100,
                    width: 100,

                    child: Padding(
                      padding: const EdgeInsets.all(0.0),
                      child: Image.asset(
                        'assets/icon.png',
                      ),
                    ),
                  ),
                  // App Title
                  const SizedBox(height: 8),
                  Text(
                    "Sign in to your account",
                    style: TextStyle(
                      fontSize: 16,
                      color: CupertinoColors.systemGrey,
                    ),
                  ),
                  const SizedBox(height: 48),
                  // Username Field
                  Container(
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemGrey6,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: CupertinoTextField(
                      controller: _usernameController,
                      placeholder: 'Username',
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                      prefix: Padding(
                        padding: const EdgeInsets.only(left: 16.0),
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
                  const SizedBox(height: 16),
                  // Password Field
                  Container(
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemGrey6,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: CupertinoTextField(
                      controller: _passwordController,
                      placeholder: 'Password',
                      obscureText: _obscurePassword,
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                      prefix: Padding(
                        padding: const EdgeInsets.only(left: 16.0),
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
                  const SizedBox(height: 40),
                  // Login Button
                  SizedBox(
                    width: double.infinity,
                    child: CupertinoButton(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      color: Colors.teal,
                      borderRadius: BorderRadius.circular(12),
                      onPressed: _isLoading ? null : _login,
                      child: _isLoading
                          ? const CupertinoActivityIndicator(color: CupertinoColors.white)
                          : const Text(
                        'Sign In',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  // Forgot Password (Optional)
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}