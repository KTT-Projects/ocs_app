import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/widgets.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ApiException implements Exception {
  final String message;
  ApiException(this.message);

  @override
  String toString() => message;
}

class ApiClient {
  static const String baseUrl = 'https://ocs.kttprojects.com/api';
  String? _token;

  void setToken(String? token) {
    _token = token;
  }

  void clearToken() {
    _token = null;
  }

  String _mapServerError(BuildContext context, String serverMessage) {
    final l10n = AppLocalizations.of(context)!;

    // Map known server error messages to localized strings
    switch (serverMessage) {
      case 'Invalid email or password':
      case 'Invalid credentials':
        return l10n.invalidCredentials;
      case 'Invalid or expired OTP. Please request a new code.':
        return l10n.invalidOrExpiredOtp;
      default:
        return serverMessage;
    }
  }

  Future<Map<String, dynamic>> register({
    required BuildContext context,
    required String email,
    required String password,
    required int institutionId,
    required int grade,
    required String displayName,
    String? bio,
    bool allowDm = true,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final response = await http.post(
      Uri.parse('$baseUrl/register.php'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'email': email,
        'password': password,
        'institution_id': institutionId,
        'grade': grade,
        'display_name': displayName,
        'bio': bio,
        'allow_dm': allowDm,
      }),
    );

    final data = json.decode(response.body);
    if (response.statusCode != 200) {
      final errorMessage = _mapServerError(context, data['message'] ?? l10n.registrationFailed);
      final errorDetails = data['error_details'];

      String fullError = errorMessage;
      if (errorDetails != null) {
        fullError += '\n\n' +
            l10n.errorDetailsText(
              errorDetails['error_type'] ?? l10n.unknownErrorType,
              errorDetails['error_file'] ?? l10n.unknownFile,
              errorDetails['error_line']?.toString() ?? l10n.unknownLine,
              errorDetails['stack_trace'] ?? l10n.noStackTrace,
            );
      }

      throw ApiException(fullError);
    }

    return data;
  }

  Future<Map<String, dynamic>> verifyEmail({
    required BuildContext context,
    required String email,
    required String otp,
  }) async {
    try {
      final l10n = AppLocalizations.of(context)!;
      final response = await http.post(
        Uri.parse('$baseUrl/verify.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'otp': otp,
        }),
      );

      final data = json.decode(response.body);

      if (response.statusCode != 200) {
        final errorMessage = _mapServerError(context, data['message'] ?? l10n.verificationFailed);
        throw ApiException(errorMessage);
      }

      if (data['status'] != 'success' || data['token'] == null) {
        final errorMessage = _mapServerError(context, data['message'] ?? l10n.verificationFailed);
        throw ApiException(errorMessage);
      }

      return data;
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      final l10n = AppLocalizations.of(context)!;
      throw ApiException('${l10n.verificationFailed}: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>> login({
    required BuildContext context,
    required String email,
    required String password,
    String? otp,
  }) async {
    try {
      final l10n = AppLocalizations.of(context)!;
      final response = await http.post(
        Uri.parse('$baseUrl/login.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'password': password,
          if (otp != null) 'otp': otp,
        }),
      );

      final data = json.decode(response.body);

      if (response.statusCode != 200) {
        final errorMessage = _mapServerError(context, data['message'] ?? l10n.loginFailed);
        throw ApiException(errorMessage);
      }

      // Handle verification needed case first
      if (data['status'] == 'needs_verification') {
        return data;
      }

      if (data['status'] != 'success') {
        final errorMessage = _mapServerError(context, data['message'] ?? l10n.loginFailed);
        throw ApiException(errorMessage);
      }

      return data;
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      final l10n = AppLocalizations.of(context)!;
      throw ApiException('${l10n.loginFailed}: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>> getProfile(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/profile.php'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${_token}',
        },
      );

      final data = json.decode(response.body);

      if (response.statusCode != 200) {
        throw ApiException(_mapServerError(context, data['message'] ?? l10n.failedToLoadProfile));
      }

      if (data['status'] != 'success') {
        throw ApiException(_mapServerError(context, data['message'] ?? l10n.failedToLoadProfile));
      }

      return data['profile'];
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException(l10n.failedToLoadProfile);
    }
  }

  Future<List<Map<String, dynamic>>> getInstitutions(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final response = await http.get(Uri.parse('$baseUrl/institutions.php'));

    if (response.statusCode != 200) {
      throw ApiException(l10n.failedToLoadInstitutions);
    }

    final data = json.decode(response.body);
    return List<Map<String, dynamic>>.from(data['data'] ?? []);
  }

  Future<void> requestPasswordReset({
    required BuildContext context,
    required String email,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/forgot_password.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email}),
      );

      final data = json.decode(response.body);
      if (response.statusCode != 200) {
        throw ApiException(_mapServerError(context, data['message'] ?? l10n.resetPasswordFailed));
      }

      if (data['status'] != 'success') {
        throw ApiException(_mapServerError(context, data['message'] ?? l10n.resetPasswordFailed));
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('${l10n.resetPasswordFailed}: ${e.toString()}');
    }
  }

  Future<void> resetPassword({
    required BuildContext context,
    required String email,
    required String code,
    required String newPassword,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/reset_password.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'code': code,
          'new_password': newPassword,
        }),
      );

      final data = json.decode(response.body);
      if (response.statusCode != 200) {
        throw ApiException(_mapServerError(context, data['message'] ?? l10n.resetPasswordFailed));
      }

      if (data['status'] != 'success') {
        throw ApiException(_mapServerError(context, data['message'] ?? l10n.resetPasswordFailed));
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('${l10n.resetPasswordFailed}: ${e.toString()}');
    }
  }
}
