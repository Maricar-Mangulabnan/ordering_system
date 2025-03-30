// main.dart

import 'package:flutter/cupertino.dart';
import 'package:ordering_system/login.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const CupertinoApp(
      debugShowCheckedModeBanner: false,
      home: LoginPage(),
    );
  }
}