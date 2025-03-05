import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiClient {
  static const String baseUrl = 'http://localhost/api'; // Change this to your server URL

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
      throw Exception(data['message'] ?? 'Registration failed');
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
      throw Exception(data['message'] ?? 'Login failed');
    }

    return data;
  }

  Future<List<Map<String, dynamic>>> getInstitutions() async {
    // This endpoint needs to be created on the server
    final response = await http.get(Uri.parse('$baseUrl/institutions.php'));

    if (response.statusCode != 200) {
      throw Exception('Failed to load institutions');
    }

    final data = json.decode(response.body);
    return List<Map<String, dynamic>>.from(data['data'] ?? []);
  }
}