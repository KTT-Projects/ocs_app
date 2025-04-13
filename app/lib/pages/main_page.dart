import 'package:flutter/material.dart';
import '../services/api_client.dart';
import 'login_page.dart';
import 'home_page.dart';

class MainPage extends StatelessWidget {
  const MainPage({super.key});

  @override
  Widget build(BuildContext context) {
    // For development, start with login page with a new ApiClient instance
    return LoginPage(apiClient: ApiClient());
  }
}
