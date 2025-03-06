import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiException implements Exception {
  final String message;
  ApiException(this.message);

  @override
  String toString() => message;
}

class ApiClient {
  static const String baseUrl = 'https://ocs.kttprojects.com/api';

  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required int institutionId,
    required int grade,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/register.php'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'email': email,
        'password': password,
        'institution_id': institutionId,
        'grade': grade,
      }),
    );

    final data = json.decode(response.body);
    if (response.statusCode != 200) {
      final errorMessage = data['message'] ?? 'Registration failed';
      final errorDetails = data['error_details'];

      String fullError = errorMessage;
      if (errorDetails != null) {
        fullError += '\n\nDetails:\n' + (errorDetails['error_type'] ?? 'Unknown error type') + ' at ' + (errorDetails['error_file'] ?? 'unknown file') + ':' + (errorDetails['error_line']?.toString() ?? 'unknown line') + '\n\nStack trace:\n' + (errorDetails['stack_trace'] ?? 'No stack trace available');
      }

      throw ApiException(fullError);
    }

    return data;
  }

  Future<Map<String, dynamic>> verifyEmail({
    required String email,
    required String otp,
  }) async {
    try {
      // print('Verifying email with OTP: $otp'); // Debug log
      final response = await http.post(
        Uri.parse('$baseUrl/verify.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'otp': otp,
        }),
      );

      // print('Verify response: ${response.body}'); // Debug log
      final data = json.decode(response.body);

      if (response.statusCode != 200) {
        throw ApiException(data['message'] ?? 'Verification failed');
      }

      if (data['status'] != 'success' || data['token'] == null) {
        throw ApiException(data['message'] ?? 'Verification failed');
      }

      return data;
    } catch (e) {
      // print('Verification error: $e'); // Debug log
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException('Verification failed: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
    String? otp,
  }) async {
    try {
      // print('Login attempt for: $email'); // Debug log
      final response = await http.post(
        Uri.parse('$baseUrl/login.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'password': password,
          if (otp != null) 'otp': otp,
        }),
      );

      // print('Login response: ${response.body}'); // Debug log
      final data = json.decode(response.body);

      if (response.statusCode != 200) {
        throw ApiException(data['message'] ?? 'Login failed');
      }

      // Handle verification needed case first
      if (data['status'] == 'needs_verification') {
        return data;
      }

      if (data['status'] != 'success') {
        throw ApiException(data['message'] ?? 'Login failed');
      }

      return data;
    } catch (e) {
      // print('Login error: $e'); // Debug log
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException('Login failed: ${e.toString()}');
    }
  }

  Future<List<Map<String, dynamic>>> getInstitutions() async {
    final response = await http.get(Uri.parse('$baseUrl/institutions.php'));

    if (response.statusCode != 200) {
      throw ApiException('Failed to load institutions');
    }

    final data = json.decode(response.body);
    return List<Map<String, dynamic>>.from(data['data'] ?? []);
  }
}
