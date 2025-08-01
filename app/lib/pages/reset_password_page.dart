import 'dart:ui';
import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../services/api_client.dart';
import 'login_page.dart';
import '../widgets/glassmorphic_ui.dart';

class ResetPasswordPage extends StatefulWidget {
  final ApiClient apiClient;
  final String email; // Changed from token
  final String code;  // Added code

  const ResetPasswordPage({
    super.key,
    required this.apiClient,
    required this.email, // Changed from token
    required this.code,  // Added code
  });

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _errorMessage;

  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _showMessage(String message, {bool isError = false, int seconds = 4}) {
    if (mounted) {
      GlassmorphicUI.showGlassSnackBar(
        context,
        message,
        isError: isError,
        seconds: seconds,
      );
    }
  }

  Future<void> _handleReset() async {
    final l10n = AppLocalizations.of(context)!;

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await widget.apiClient.resetPassword(
        context: context,
        email: widget.email, // Pass email
        code: widget.code,   // Pass code
        newPassword: _passwordController.text,
      );

      if (mounted) {
        _showMessage(l10n.resetPasswordSent);
        // Return to login page after successful reset
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => LoginPage(apiClient: widget.apiClient),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        // TODO: Log the actual error e for debugging
        setState(() => _errorMessage = l10n.errorOccurred); // Use generic localized error
        _showMessage(_errorMessage!, isError: true); // Show the generic error in snackbar too
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: Stack(
        children: [
          // Gradient background
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.secondary,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          // Responsive layout
          LayoutBuilder(
            builder: (context, constraints) {
              final maxWidth = constraints.maxWidth;
              final isSmallScreen = maxWidth < 600;

              return Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(isSmallScreen ? 16.0 : 24.0),
                  child: Container(
                    width: isSmallScreen ? maxWidth - 32 : 400,
                    constraints: const BoxConstraints(maxHeight: 600),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.background.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.3),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Padding(
                        padding: EdgeInsets.all(isSmallScreen ? 20.0 : 32.0),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                l10n.resetPasswordTitle,
                                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                      color: Theme.of(context).colorScheme.onPrimary,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              const SizedBox(height: 8),
                              if (_errorMessage != null) ...[
                                const SizedBox(height: 16),
                                Text(
                                  _errorMessage!, // Display error message directly (consistent with forgot_password_page)
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.error,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                              const SizedBox(height: 32),
                              TextFormField(
                                controller: _passwordController,
                                obscureText: true,
                                decoration: InputDecoration(
                                  hintText: l10n.newPassword,
                                  prefixIcon: Icon(
                                    Icons.lock_outline,
                                    color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.7),
                                  ),
                                  hintStyle: TextStyle(color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.7)),
                                  filled: true,
                                  fillColor: Theme.of(context).colorScheme.onPrimary.withOpacity(0.1),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                                style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
                                validator: (value) {
                                  if (value == null || value.length < 8) {
                                    return l10n.passwordRequirements;
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _confirmPasswordController,
                                obscureText: true,
                                decoration: InputDecoration(
                                  hintText: l10n.confirmPassword,
                                  prefixIcon: Icon(
                                    Icons.lock_outline,
                                    color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.7),
                                  ),
                                  hintStyle: TextStyle(color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.7)),
                                  filled: true,
                                  fillColor: Theme.of(context).colorScheme.onPrimary.withOpacity(0.1),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                                style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
                                validator: (value) {
                                  if (value != _passwordController.text) {
                                    return l10n.passwordsDoNotMatch;
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 24),
                              SizedBox(
                                width: double.infinity,
                                height: 48,
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _handleReset,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Theme.of(context).colorScheme.secondary,
                                    foregroundColor: Theme.of(context).colorScheme.onSecondary,
                                    elevation: 2,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: _isLoading
                                      ? SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation<Color>(
                                              Theme.of(context).colorScheme.onSecondary,
                                            ),
                                          ),
                                        )
                                      : Text(
                                          l10n.resetPasswordButton,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              TextButton(
                                onPressed: () {
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => LoginPage(apiClient: widget.apiClient),
                                    ),
                                  );
                                },
                                child: Text(
                                  l10n.backToLogin,
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.8),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
