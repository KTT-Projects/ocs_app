import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import '../widgets/language_toggle.dart';
import '../widgets/glassmorphic_ui.dart';
import '../widgets/grade_selection_dialog.dart';
import '../widgets/institution_selection_dialog.dart';
import '../services/api_client.dart';
import 'home_page.dart';

class SignupPage extends StatefulWidget {
  final ApiClient apiClient;

  const SignupPage({
    super.key,
    required this.apiClient,
  });

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _errorMessage;
  bool _registrationComplete = false;
  bool _institutionsLoaded = false;

  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _otpController = TextEditingController();
  String? _savedPassword;
  bool _allowDm = true;

  int? _selectedInstitutionId;
  int? _selectedGrade;
  List<Map<String, dynamic>> _institutions = [];
  bool _showOtpField = false;

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
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

  String _getLocalizedInstitutionName(String fullName) {
    final parts = fullName.split(' / ');
    final isJapanese = Localizations.localeOf(context).languageCode == 'ja';
    return parts.length > 1 ? (isJapanese ? parts[1] : parts[0]) : fullName;
  }

  Future<void> _loadInstitutions() async {
    try {
      setState(() => _isLoading = true);
      _institutions = await widget.apiClient.getInstitutions(context);
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _selectInstitution() async {
    final l10n = AppLocalizations.of(context)!;
    final selectedId = await GlassmorphicUI.showDialog<String>(
      context: context,
      width: 320,
      child: InstitutionSelectionDialog(
        title: l10n.selectInstitution,
        institutions: _institutions,
        onInstitutionSelected: (id) => Navigator.pop(context, id),
        getLocalizedName: _getLocalizedInstitutionName,
      ),
    );
    if (selectedId != null) {
      setState(() => _selectedInstitutionId = int.parse(selectedId));
    }
  }

  Future<void> _selectGrade() async {
    final l10n = AppLocalizations.of(context)!;
    final selectedGrade = await GlassmorphicUI.showDialog<int>(
      context: context,
      width: 320,
      child: GradeSelectionDialog(
        title: l10n.grade,
        onGradeSelected: (grade) => Navigator.pop(context, grade),
      ),
    );
    if (selectedGrade != null) {
      setState(() => _selectedGrade = selectedGrade);
    }
  }

  void _resetForm() {
    setState(() {
      _showOtpField = false;
      _otpController.clear();
      _errorMessage = null;
      _savedPassword = null;
    });
  }

  bool _validateFields() {
    final l10n = AppLocalizations.of(context)!;

    if (!_formKey.currentState!.validate()) {
      return false;
    }

    if (_selectedInstitutionId == null) {
      setState(() => _errorMessage = l10n.pleaseSelectInstitution);
      return false;
    }

    if (_selectedGrade == null) {
      setState(() => _errorMessage = l10n.pleaseSelectGrade);
      return false;
    }

    if (_nameController.text.isEmpty) {
      setState(() => _errorMessage = l10n.displayNameRequired);
      return false;
    }

    return true;
  }

  Future<void> _handleSignup() async {
    final l10n = AppLocalizations.of(context)!;

    if (_showOtpField) {
      if (_otpController.text.length != 6) {
        setState(() => _errorMessage = l10n.invalidVerificationCode);
        return;
      }
    } else {
      if (!_validateFields()) {
        return;
      }
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (_showOtpField) {
        final response = await widget.apiClient.verifyEmail(
          context: context,
          email: _emailController.text,
          otp: _otpController.text,
        );

        if (mounted && response['status'] == 'success') {
          if (response['token'] != null) {
            GlassmorphicUI.showGlassSnackBar(
              context,
              l10n.emailVerifiedSuccess,
            );
            await widget.apiClient.setToken(response['token']);
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => HomePage(
                  token: response['token'],
                  apiClient: widget.apiClient,
                ),
              ),
            );
            _savedPassword = null;
          } else {
            setState(() => _errorMessage = l10n.verificationFailed);
          }
        }
      } else {
        await widget.apiClient.register(
          context: context,
          email: _emailController.text,
          password: _passwordController.text,
          institutionId: _selectedInstitutionId!,
          grade: _selectedGrade!,
          displayName: _nameController.text,
          bio: _bioController.text,
          allowDm: _allowDm,
        );

        if (mounted) {
          setState(() {
            _showOtpField = true;
            _emailController.text = _emailController.text.trim();
            _savedPassword = _passwordController.text;
            _passwordController.clear();
          });

          Future.delayed(Duration(milliseconds: 100), () {
            FocusScope.of(context).requestFocus(FocusNode());
          });
          GlassmorphicUI.showGlassSnackBar(
            context,
            '${l10n.verifyEmail}\n${l10n.checkSpamJunk}',
            seconds: 12,
          );
        }
      }
    } catch (e) {
      setState(() => _errorMessage = e.toString());
      GlassmorphicUI.showGlassSnackBar(
        context,
        e.toString(),
        isError: true,
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
          LayoutBuilder(
            builder: (context, constraints) {
              final maxWidth = constraints.maxWidth;
              final isSmallScreen = maxWidth < 600;

              return Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    isSmallScreen ? 16.0 : 24.0,
                    Theme.of(context).platform == TargetPlatform.iOS ? 120.0 : 56.0,
                    isSmallScreen ? 16.0 : 24.0,
                    isSmallScreen ? 16.0 : 24.0,
                  ),
                  child: Container(
                    width: isSmallScreen ? maxWidth - 32 : 400,
                    constraints: BoxConstraints(maxWidth: 600),
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
                                  _errorMessage!,
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.error,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 32),
                              if (!_showOtpField) ...[
                                TextFormField(
                                  controller: _nameController,
                                  maxLength: 100,
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
                                  validator: (value) => value?.isEmpty ?? true ? l10n.displayNameRequired : null,
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _bioController,
                                  maxLines: 3,
                                  maxLength: 500,
                                  decoration: InputDecoration(
                                    hintText: l10n.bio,
                                    prefixIcon: Icon(
                                      Icons.description_outlined,
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
                                const SizedBox(height: 16),
                                SwitchListTile(
                                  title: Text(
                                    l10n.allowDirectMessages,
                                    style: TextStyle(
                                      color: Theme.of(context).colorScheme.onPrimary,
                                    ),
                                  ),
                                  value: _allowDm,
                                  onChanged: (value) {
                                    setState(() => _allowDm = value);
                                  },
                                  tileColor: Theme.of(context).colorScheme.onPrimary.withOpacity(0.1),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  readOnly: true,
                                  onTap: _selectInstitution,
                                  decoration: InputDecoration(
                                    hintText: l10n.selectInstitution,
                                    prefixIcon: Icon(
                                      Icons.apartment_outlined,
                                      color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.7),
                                    ),
                                    suffixIcon: Icon(
                                      Icons.arrow_drop_down,
                                      color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.7),
                                      size: 24,
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
                                  controller: TextEditingController(
                                    text: _selectedInstitutionId != null ? _getLocalizedInstitutionName(_institutions.firstWhere((i) => int.parse(i['id'].toString()) == _selectedInstitutionId)['name'] as String) : '',
                                  ),
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  readOnly: true,
                                  onTap: _selectGrade,
                                  decoration: InputDecoration(
                                    hintText: l10n.grade,
                                    prefixIcon: Icon(
                                      Icons.school_outlined,
                                      color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.7),
                                    ),
                                    suffixIcon: Icon(
                                      Icons.arrow_drop_down,
                                      color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.7),
                                      size: 24,
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
                                  controller: TextEditingController(
                                    text: _selectedGrade != null
                                        ? _selectedGrade == 99
                                            ? 'OB'
                                            : 'G${_selectedGrade}'
                                        : '',
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
                                    final l10n = AppLocalizations.of(context)!;
                                    if (value?.isEmpty ?? true) {
                                      return l10n.invalidEmail;
                                    }
                                    if (!value!.contains('@')) {
                                      return l10n.invalidEmail;
                                    }
                                    if (!value.endsWith('@gmail.com')) {
                                      return l10n.onlyGoogleEmailAllowed;
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
                                const SizedBox(height: 8),
                                Text(
                                  l10n.checkSpamJunk,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.7),
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextButton.icon(
                                  onPressed: () async {
                                    if (_savedPassword == null) return;
                                    setState(() => _isLoading = true);
                                    try {
                                      await widget.apiClient.login(
                                        context: context,
                                        email: _emailController.text,
                                        password: _savedPassword!,
                                      );
                                      if (mounted) {
                                        GlassmorphicUI.showGlassSnackBar(
                                          context,
                                          l10n.verificationCodeSent(
                                            _emailController.text,
                                          ),
                                        );
                                      }
                                    } catch (e) {
                                      if (mounted) {
                                        GlassmorphicUI.showGlassSnackBar(
                                          context,
                                          e.toString(),
                                          isError: true,
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
                                      onPressed: () => Navigator.pop(context),
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
              );
            },
          ),
          // Language toggle button
          Positioned(
            top: Theme.of(context).platform == TargetPlatform.iOS ? MediaQuery.of(context).padding.top + 16 : 16,
            right: 16,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(45),
              child: Material(
                color: Colors.transparent,
                elevation: 0,
                child: Consumer<LanguageProvider>(
                  builder: (context, languageProvider, _) => LanguageToggle(
                    currentLanguage: languageProvider.currentLanguage,
                    onLanguageChanged: (lang) => languageProvider.setLanguage(lang),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
