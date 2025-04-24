import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import '../widgets/language_toggle.dart';
import '../services/api_client.dart';

class ForgotPasswordPage extends StatefulWidget {
  final ApiClient apiClient;

  const ForgotPasswordPage({
    super.key,
    required this.apiClient,
  });

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _errorMessage;
  bool _showOtpField = false;
  bool _showPasswordFields = false;
  String _email = '';

  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _showMessage(String message, {bool isError = false, int seconds = 4}) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          duration: Duration(seconds: seconds),
          backgroundColor: isError ? Theme.of(context).colorScheme.error : null,
        ),
      );
    }
  }

  void _resetForm() {
    setState(() {
      _showOtpField = false;
      _showPasswordFields = false;
      _otpController.clear();
      _passwordController.clear();
      _confirmPasswordController.clear();
      _errorMessage = null;
    });
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
      if (_showPasswordFields) {
        // Reset password with code
        await widget.apiClient.resetPassword(
          context: context,
          email: _email,
          code: _otpController.text,
          newPassword: _passwordController.text,
        );

        if (mounted) {
          _showMessage(l10n.resetPasswordSuccess);
          Navigator.pop(context); // Return to login
        }
      } else if (_showOtpField) {
        // Validate OTP format
        if (_otpController.text.length != 6) {
          setState(() => _errorMessage = l10n.invalidVerificationCode);
          return;
        }
        // Show password fields after OTP entry
        setState(() {
          _showPasswordFields = true;
          _errorMessage = null;
        });
      } else {
        // Initial state: request password reset
        await widget.apiClient.requestPasswordReset(
          context: context,
          email: _emailController.text,
        );

        if (mounted) {
          _showMessage(l10n.resetPasswordSent);
          setState(() {
            _showOtpField = true;
            _email = _emailController.text.trim();
            _emailController.text = _email;
          });

          // Give time for the OTP field to be built before focusing
          Future.delayed(Duration(milliseconds: 100), () {
            FocusScope.of(context).requestFocus(FocusNode());
          });
        }
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
          // Language toggle
          Positioned(
            top: 16,
            right: 16,
            child: Consumer<LanguageProvider>(
              builder: (context, languageProvider, _) => LanguageToggle(
                currentLanguage: languageProvider.currentLanguage,
                onLanguageChanged: (lang) => languageProvider.setLanguage(lang),
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
                  padding: EdgeInsets.fromLTRB(
                    isSmallScreen ? 16.0 : 24.0,
                    56.0, // Added extra top padding for language toggle
                    isSmallScreen ? 16.0 : 24.0,
                    isSmallScreen ? 16.0 : 24.0,
                  ),
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
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
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
                                Text(
                                  l10n.resetPasswordSubtitle,
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                        color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.8),
                                      ),
                                ),
                                if (_errorMessage != null) ...[
                                  const SizedBox(height: 16),
                                  Text(
                                    _errorMessage!, // Display error message directly
                                    style: TextStyle(
                                      color: Theme.of(context).colorScheme.error,
                                      fontWeight: FontWeight.bold, // Make error more prominent
                                    ),
                                    textAlign: TextAlign.center, // Center align error
                                  ),
                                ],
                                const SizedBox(height: 32),
                                if (!_showOtpField && !_showPasswordFields) ...[
                                  TextFormField(
                                    controller: _emailController,
                                    enabled: !_showOtpField,
                                    decoration: InputDecoration(
                                      hintText: l10n.email,
                                      prefixIcon: Icon(
                                        Icons.email_outlined,
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
                                      if (!_showOtpField) {
                                        if (value?.isEmpty ?? true) {
                                          return l10n.invalidEmail;
                                        }
                                        if (!value!.contains('@')) {
                                          return l10n.invalidEmail;
                                        }
                                      }
                                      return null;
                                    },
                                  ),
                                ],
                                if (_showOtpField) ...[
                                  TextFormField(
                                    controller: _otpController,
                                    autofocus: true,
                                    maxLength: 6,
                                    keyboardType: const TextInputType.numberWithOptions(decimal: false),
                                    decoration: InputDecoration(
                                      hintText: l10n.enterOtp,
                                      counterText: '', // Hide character counter
                                      prefixIcon: Icon(
                                        Icons.security_outlined,
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
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    l10n.checkSpamJunk,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.7),
                                      fontSize: 12,
                                    ),
                                  ),
                                  if (!_showPasswordFields) ...[
                                    const SizedBox(height: 8),
                                    TextButton.icon(
                                      onPressed: _isLoading ? null : () async {
                                        setState(() => _isLoading = true);
                                        try {
                                          await widget.apiClient.requestPasswordReset(
                                            context: context,
                                            email: _email,
                                          );
                                          if (mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(content: Text(l10n.resetPasswordSent)),
                                            );
                                          }
                                        } catch (e) {
                                          if (mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text(e.toString()),
                                                backgroundColor: Theme.of(context).colorScheme.error,
                                              ),
                                            );
                                          }
                                        } finally {
                                          setState(() => _isLoading = false);
                                        }
                                      },
                                      icon: Icon(
                                        Icons.refresh,
                                        color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.8),
                                        size: 16,
                                      ),
                                      label: Text(
                                        l10n.resendOtp,
                                        style: TextStyle(
                                          color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.8),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                                if (_showPasswordFields) ...[
                                  const SizedBox(height: 16), // Add spacing before password fields
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
                                    validator: (value) =>
                                        (value?.length ?? 0) < 8 ? l10n.passwordRequirements : null,
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
                                ],
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
                                            _showPasswordFields
                                                ? l10n.resetPasswordButton
                                                : _showOtpField
                                                    ? l10n.verify
                                                    : l10n.requestPasswordReset,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                TextButton(
                                    onPressed: () => Navigator.pop(context),
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
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
