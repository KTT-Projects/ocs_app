import 'package:flutter/material.dart';
import '../services/api_client.dart';
import 'login_page.dart';
import 'home_page.dart';

class MainPage extends StatefulWidget {
  final ApiClient apiClient;

  const MainPage({
    super.key,
    required this.apiClient,
  });

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  late final ApiClient _apiClient;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _apiClient = widget.apiClient;
    _apiClient.addListener(_onApiClientChanged);
    _checkExistingToken();
  }

  @override
  void dispose() {
    _apiClient.removeListener(_onApiClientChanged);
    super.dispose();
  }

  void _onApiClientChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _checkExistingToken() async {
    await _apiClient.initialize();
    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // If token exists, go to HomePage, otherwise go to LoginPage
    if (_apiClient.token != null) {
      return HomePage(
        token: _apiClient.token!,
        apiClient: _apiClient,
      );
    }

    return LoginPage(apiClient: _apiClient);
  }
}
