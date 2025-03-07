import 'package:flutter/material.dart';
import 'login_page.dart';
import 'home_page.dart';

class MainPage extends StatelessWidget {
  const MainPage({super.key});

  @override
  Widget build(BuildContext context) {
    // For development, start with login page
    return Scaffold(
      body: const LoginPage(),
    );
  }
}
