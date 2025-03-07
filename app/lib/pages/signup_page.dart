import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../services/api_client.dart';
import 'home_page.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _formKey = GlobalKey<FormState>();
  final _apiClient = ApiClient();
  bool _isLoading = false;
  String? _errorMessage;
  bool _registrationComplete = false;
  bool _institutionsLoaded = false;

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _otpController = TextEditingController();

  int? _selectedInstitutionId;
  int? _selectedGrade;
  List<Map<String, dynamic>> _institutions = [];
  bool _showOtpField = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_institutionsLoaded) {
      _loadInstitutions();
      _institutionsLoaded = true;
    }
  }

  Future<void> _loadInstitutions() async {
    try {
      setState(() => _isLoading = true);
      _institutions = await _apiClient.getInstitutions(context);
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _resetForm() {
    setState(() {
      _showOtpField = false;
      _otpController.clear();
      _errorMessage = null;
    });
  }

  Future<void> _handleSignup() async {
    final l10n = AppLocalizations.of(context)!;

    if (_showOtpField) {
      // Only validate OTP in verification mode
      if (_otpController.text.length != 6) {
        setState(() => _errorMessage = l10n.invalidVerificationCode);
        return;
      }
    } else {
      // Validate all fields in signup mode
      if (!_formKey.currentState!.validate()) {
        return;
      }
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (_showOtpField) {
        // Verify OTP
        final response = await _apiClient.verifyEmail(
          context: context,
          email: _emailController.text,
          otp: _otpController.text,
        );

        if (mounted && response['status'] == 'success') {
          if (response['token'] != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(l10n.emailVerifiedSuccess),
                backgroundColor: Colors.green,
              ),
            );
            // Navigate to home page with the user's name
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => HomePage(userName: _nameController.text),
              ),
            );
          } else {
            setState(() => _errorMessage = l10n.verificationFailed);
          }
        }
      } else {
        // Normal signup
        await _apiClient.register(
          context: context,
          email: _emailController.text,
          password: _passwordController.text,
          institutionId: _selectedInstitutionId!,
          grade: _selectedGrade!,
        );

        if (mounted) {
          setState(() {
            _showOtpField = true;
            _emailController.text = _emailController.text.trim();
            _passwordController.clear(); // Clear password for security
          });

          // Give time for the OTP field to be built before focusing
          Future.delayed(Duration(milliseconds: 100), () {
            FocusScope.of(context).requestFocus(FocusNode());
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.verifyEmail),
              duration: Duration(seconds: 8),
            ),
          );
        }
      }
    } catch (e) {
      setState(() => _errorMessage = e.toString());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
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
                                  l10n.createAccount,
                                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                        color: Theme.of(context).colorScheme.onPrimary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _showOtpField ? l10n.verifyEmail : l10n.signUpToGetStarted,
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
                                if (!_showOtpField) ...[
                                  TextFormField(
                                    controller: _nameController,
                                    decoration: InputDecoration(
                                      hintText: l10n.fullName,
                                      prefixIcon: Icon(
                                        Icons.person_outline,
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
                                    validator: (value) => value?.isEmpty ?? true ? l10n.fullName : null,
                                  ),
                                ],
                                if (!_showOtpField) ...[
                                  const SizedBox(height: 16),
                                  Theme(
                                    data: Theme.of(context).copyWith(
                                      inputDecorationTheme: InputDecorationTheme(
                                        filled: true,
                                        fillColor: Theme.of(context).colorScheme.onPrimary.withOpacity(0.1),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: BorderSide.none,
                                        ),
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                      ),
                                      dropdownMenuTheme: DropdownMenuThemeData(
                                        menuStyle: MenuStyle(
                                          shape: MaterialStateProperty.all(
                                            RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                          ),
                                        ),
                                        inputDecorationTheme: InputDecorationTheme(
                                          filled: true,
                                          fillColor: Theme.of(context).colorScheme.onPrimary.withOpacity(0.1),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                            borderSide: BorderSide.none,
                                          ),
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                        ),
                                      ),
                                    ),
                                    child: Column(
                                      children: [
                                        DropdownButtonFormField<int>(
                                          value: _selectedInstitutionId,
                                          items: _institutions.map((institution) {
                                            return DropdownMenuItem(
                                              value: int.parse(institution['id'].toString()),
                                              child: Text(
                                                (institution['name'] as String).split('/')[Localizations.localeOf(context).languageCode == 'ja' ? 1 : 0].trim(),
                                                style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
                                              ),
                                            );
                                          }).toList(),
                                          onChanged: (value) {
                                            setState(() => _selectedInstitutionId = value);
                                          },
                                          decoration: InputDecoration(
                                            hintText: l10n.selectInstitution,
                                            prefixIcon: Icon(
                                              Icons.school_outlined,
                                              color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.7),
                                            ),
                                            hintStyle: TextStyle(color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.7)),
                                            errorStyle: TextStyle(color: Theme.of(context).colorScheme.error),
                                          ),
                                          dropdownColor: Theme.of(context).colorScheme.primary.withOpacity(0.9),
                                          icon: Icon(
                                            Icons.arrow_drop_down,
                                            color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.7),
                                          ),
                                          validator: (value) => value == null ? l10n.pleaseSelectInstitution : null,
                                        ),
                                        const SizedBox(height: 16),
                                        DropdownButtonFormField<int>(
                                          value: _selectedGrade,
                                          items: [
                                            for (var i = 7; i <= 14; i++)
                                              DropdownMenuItem(
                                                value: i,
                                                child: Text(
                                                  'G$i',
                                                  style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
                                                ),
                                              ),
                                            DropdownMenuItem(
                                              value: 99,
                                              child: Text(
                                                'OB',
                                                style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
                                              ),
                                            ),
                                          ],
                                          onChanged: (value) {
                                            setState(() => _selectedGrade = value);
                                          },
                                          decoration: InputDecoration(
                                            hintText: l10n.grade,
                                            prefixIcon: Icon(
                                              Icons.grade_outlined,
                                              color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.7),
                                            ),
                                            hintStyle: TextStyle(color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.7)),
                                            errorStyle: TextStyle(color: Theme.of(context).colorScheme.error),
                                          ),
                                          dropdownColor: Theme.of(context).colorScheme.primary.withOpacity(0.9),
                                          icon: Icon(
                                            Icons.arrow_drop_down,
                                            color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.7),
                                          ),
                                          validator: (value) => value == null ? l10n.pleaseSelectGrade : null,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                                if (!_showOtpField) ...[
                                  const SizedBox(height: 16),
                                  TextFormField(
                                    controller: _emailController,
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
                                      if (value?.isEmpty ?? true) {
                                        return l10n.invalidEmail;
                                      }
                                      if (!value!.contains('@')) {
                                        return l10n.invalidEmail;
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 16),
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
                                      helperText: l10n.passwordHelper,
                                      helperStyle: TextStyle(
                                        color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.7),
                                      ),
                                    ),
                                    style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
                                    validator: (value) => (value?.length ?? 0) < 8 ? l10n.passwordRequirements : null,
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
                                    onPressed: _isLoading || _registrationComplete ? null : _handleSignup,
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
                                            _showOtpField ? l10n.verify : l10n.signUp,
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
                                      l10n.backToRegistration,
                                      style: TextStyle(
                                        color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.8),
                                      ),
                                    ),
                                  ),
                                ] else ...[
                                  const SizedBox(height: 16),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        l10n.alreadyHaveAccount,
                                        style: TextStyle(
                                          color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.8),
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          Navigator.pop(context);
                                        },
                                        child: Text(
                                          l10n.signIn,
                                          style: TextStyle(
                                            color: Theme.of(context).colorScheme.secondary,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
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
