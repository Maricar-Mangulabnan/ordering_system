import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:ordering_system/employee/employee-products.dart';
import 'package:ordering_system/customer/customer-products.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final String baseUrl = 'https://orderko-server.onrender.com';

  Future<void> _login() async {
    String username = _usernameController.text.trim();
    String password = _passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      _showDialog('Error', 'Username and Password cannot be empty.');
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/signin'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Retrieve role from nested 'user' object
        String role = data['user']['role'];

        // Navigate based on role
        if (role == 'EMPLOYEE') {
          Navigator.push(
            context,
            CupertinoPageRoute(
              builder: (context) => EmployeeProductsPage(user: data),
            ),
          );
        } else if (role == 'CUSTOMER') {
          Navigator.push(
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
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Sign In'),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CupertinoTextField(
                controller: _usernameController,
                placeholder: 'Username',
                padding: const EdgeInsets.all(16),
                prefix: const Icon(CupertinoIcons.person),
              ),
              const SizedBox(height: 16),
              CupertinoTextField(
                controller: _passwordController,
                placeholder: 'Password',
                obscureText: true,
                padding: const EdgeInsets.all(16),
                prefix: const Icon(CupertinoIcons.lock),
              ),
              const SizedBox(height: 24),
              CupertinoButton.filled(
                onPressed: _login,
                child: const Text('Login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
