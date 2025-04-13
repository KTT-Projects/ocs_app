import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../services/api_client.dart';
import 'signup_page.dart';
import 'home_page.dart';

class LoginPage extends StatefulWidget {
  final ApiClient apiClient;

  const LoginPage({
    super.key,
    required this.apiClient,
  });

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _errorMessage;
  bool _showOtpField = false;
  String? _userId;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _otpController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _otpController.dispose();
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

  Future<void> _handleLogin() async {
    final l10n = AppLocalizations.of(context)!;

    if (_showOtpField) {
      // Only validate OTP in verification mode
      if (_otpController.text.length != 6) {
        setState(() => _errorMessage = l10n.invalidVerificationCode);
        return;
      }
    } else {
      // Validate all fields in login mode
      if (!_formKey.currentState!.validate()) {
        return;
      }
      if (_passwordController.text.isEmpty) {
        setState(() => _errorMessage = l10n.passwordRequirements);
        return;
      }
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      Map<String, dynamic> response;
      if (_showOtpField) {
        // Verify OTP
        response = await widget.apiClient.verifyEmail(
          context: context,
          email: _emailController.text,
          otp: _otpController.text,
        );

        if (mounted && response['status'] == 'success') {
          if (response['token'] != null) {
            _showMessage(response['message'] ?? l10n.emailVerifiedSuccess, seconds: 4);
            setState(() {
              _showOtpField = false;
              _errorMessage = null;
              _otpController.clear();
            });
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => HomePage(
                  token: response['token'],
                  apiClient: widget.apiClient,
                ),
              ),
            );
          } else {
            setState(() => _errorMessage = l10n.verificationFailed);
          }
        }
      } else {
        // Normal login attempt
        response = await widget.apiClient.login(
          context: context,
          email: _emailController.text,
          password: _passwordController.text,
        );

        if (mounted) {
          if (response['status'] == 'needs_verification') {
            setState(() {
              _showOtpField = true;
              _emailController.text = _emailController.text.trim();
              _userId = response['user_id'].toString();
              _passwordController.clear(); // Clear password for security
            });

            // Give time for the OTP field to be built before focusing
            Future.delayed(Duration(milliseconds: 100), () {
              FocusScope.of(context).requestFocus(FocusNode());
            });
            _showMessage(l10n.verifyEmail, seconds: 8);
          } else if (response['status'] == 'success' && response['token'] != null) {
            _showMessage(l10n.loginSuccessful, seconds: 4);
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => HomePage(
                  token: response['token'],
                  apiClient: widget.apiClient,
                ),
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = e.toString());
        _showMessage(e.toString(), isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _resetForm() {
    setState(() {
      _showOtpField = false;
      _userId = null;
      _otpController.clear();
      _errorMessage = null;
    });
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
                    constraints: const BoxConstraints(maxHeight: 500),
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
                                  l10n.welcomeBack,
                                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                        color: Theme.of(context).colorScheme.onPrimary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _showOtpField ? l10n.verifyEmail : l10n.signInToContinue,
                                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                        color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.8),
                                      ),
                                ),
                                if (_errorMessage != null) ...[
                                  const SizedBox(height: 16),
                                  Text(
                                    l10n.errorMessage(_errorMessage!),
                                    style: TextStyle(
                                      color: Theme.of(context).colorScheme.error,
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 32),
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
                                const SizedBox(height: 16),
                                if (!_showOtpField) ...[
                                  TextFormField(
                                    controller: _passwordController,
                                    obscureText: true,
                                    decoration: InputDecoration(
                                      hintText: l10n.password,
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
                                  ),
                                ],
                                if (_showOtpField) ...[
                                  const SizedBox(height: 16),
                                  TextFormField(
                                    controller: _otpController,
                                    autofocus: true,
                                    maxLength: 6,
                                    keyboardType: const TextInputType.numberWithOptions(decimal: false),
                                    autofillHints: null,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                      LengthLimitingTextInputFormatter(6),
                                    ],
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
                                ],
                                const SizedBox(height: 24),
                                SizedBox(
                                  width: double.infinity,
                                  height: 48,
                                  child: ElevatedButton(
                                    onPressed: _isLoading ? null : _handleLogin,
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
                                            _showOtpField ? l10n.verify : l10n.signIn,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                  ),
                                ),
                                if (_showOtpField) ...[
                                  const SizedBox(height: 8),
                                  TextButton(
                                    onPressed: _resetForm,
                                    child: Text(
                                      l10n.backToLogin,
                                      style: TextStyle(
                                        color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.8),
                                      ),
                                    ),
                                  ),
                                ],
                                if (!_showOtpField) ...[
                                  const SizedBox(height: 16),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        l10n.newToApp,
                                        style: TextStyle(
                                          color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.8),
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => SignupPage(apiClient: widget.apiClient),
                                            ),
                                          );
                                        },
                                        child: Text(
                                          l10n.signUp,
                                          style: TextStyle(
                                            color: Theme.of(context).colorScheme.secondary,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  TextButton(
                                    onPressed: () {},
                                    child: Text(
                                      l10n.forgotPassword,
                                      style: TextStyle(
                                        color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.8),
                                      ),
                                    ),
                                  ),
                                ],
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
