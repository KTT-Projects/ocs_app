import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiClient {
  static const String baseUrl = 'https://ocs.kttprojects.com/api';

  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required int institutionId,
    required String studentId,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/register.php'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'email': email,
        'password': password,
        'institution_id': institutionId,
        'student_id': studentId,
      }),
    );

    final data = json.decode(response.body);
    if (response.statusCode != 200) {
      final errorMessage = data['message'] ?? 'Registration failed';
      final errorDetails = data['error_details'];
      
      String fullError = errorMessage;
      if (errorDetails != null) {
        fullError += '\n\nDetails:\n' +
          (errorDetails['error_type'] ?? 'Unknown error type') +
          ' at ' + (errorDetails['error_file'] ?? 'unknown file') +
          ':' + (errorDetails['error_line']?.toString() ?? 'unknown line') +
          '\n\nStack trace:\n' + (errorDetails['stack_trace'] ?? 'No stack trace available');
      }
      
      throw Exception(fullError);
    }

    return data;
  }

  Future<Map<String, dynamic>> verifyEmail(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/verify.php?token=$token'),
    );

    final data = json.decode(response.body);
    if (response.statusCode != 200) {
      throw Exception(data['message'] ?? 'Verification failed');
    }

    return data;
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login.php'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'email': email,
        'password': password,
      }),
    );

    final data = json.decode(response.body);
    if (response.statusCode != 200) {
      if (data['message']?.contains('not verified') ?? false) {
        throw Exception('Please verify your email before logging in');
      }
      throw Exception(data['message'] ?? 'Login failed');
    }

    return data;
  }

  Future<List<Map<String, dynamic>>> getInstitutions() async {
    final response = await http.get(Uri.parse('$baseUrl/institutions.php'));

    if (response.statusCode != 200) {
      throw Exception('Failed to load institutions');
    }

    final data = json.decode(response.body);
    return List<Map<String, dynamic>>.from(data['data'] ?? []);
  }
}
