import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/widgets.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../l10n/app_localizations.dart';
import 'dart:io';
import '../models/feed.dart';
import '../models/feed_post.dart';
import '../models/comment.dart';
import '../models/volunteer_opportunity.dart';
import '../models/volunteer_participant.dart';
import 'auth_service.dart';

class ApiException implements Exception {
  final String message;
  ApiException(this.message);

  @override
  String toString() => message;
}

class ApiClient extends ChangeNotifier {
  static const String baseUrl = 'https://ocs.kttprojects.com/api';
  String? _token;
  final _authService = AuthService();

  Uri _buildUri(String path) {
    final ts = DateTime.now().millisecondsSinceEpoch;
    final sep = path.contains('?') ? '&' : '?';
    return Uri.parse('$baseUrl/$path${sep}t=$ts');
  }

  String? get token => _token;

  Future<void> initialize() async {
    _token = await _authService.getToken();
  }

  Future<void> setToken(String? newToken) async {
    _token = newToken;
    if (newToken != null) {
      await _authService.saveToken(newToken);
    } else {
      await _authService.clearToken();
    }
    notifyListeners();
  }

  Future<void> clearToken() async {
    _token = null;
    await _authService.clearToken();
    notifyListeners();
  }

  Future<void> logout(BuildContext context) async {
    // Invalidate token on server (optional, depends on backend implementation)
    // For now, just clear local token
    await clearToken();
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
      case 'Invalid or expired token':
        clearToken(); // Clear token immediately
        return serverMessage;
      default:
        return serverMessage;
    }
  }

  Future<void> _handleUnauthorizedResponse(
    BuildContext context,
    Map<String, dynamic> data,
  ) async {
    final message = data['message'] ?? 'Unauthorized';
    if (message == 'Invalid or expired token') {
      await clearToken();
    }
    throw ApiException(message);
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
      headers: {
        'Content-Type': 'application/json',
        'Accept-Language': Localizations.localeOf(context).languageCode,
      },
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
      final errorMessage = _mapServerError(
        context,
        data['message'] ?? l10n.registrationFailed,
      );
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
        headers: {
          'Content-Type': 'application/json',
          'Accept-Language': Localizations.localeOf(context).languageCode,
        },
        body: json.encode({'email': email, 'otp': otp}),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 401) {
        await _handleUnauthorizedResponse(context, data);
      } else if (response.statusCode != 200) {
        final errorMessage = _mapServerError(
          context,
          data['message'] ?? l10n.verificationFailed,
        );
        throw ApiException(errorMessage);
      }

      if (data['status'] != 'success' || data['token'] == null) {
        final errorMessage = _mapServerError(
          context,
          data['message'] ?? l10n.verificationFailed,
        );
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
        headers: {
          'Content-Type': 'application/json',
          'Accept-Language': Localizations.localeOf(context).languageCode,
        },
        body: json.encode({
          'email': email,
          'password': password,
          if (otp != null) 'otp': otp,
        }),
      );

      final data = json.decode(response.body);

      if (response.statusCode != 200) {
        final errorMessage = _mapServerError(
          context,
          data['message'] ?? l10n.loginFailed,
        );
        throw ApiException(errorMessage);
      }

      // Handle verification needed case first
      if (data['status'] == 'needs_verification') {
        return data;
      }

      if (data['status'] != 'success') {
        final errorMessage = _mapServerError(
          context,
          data['message'] ?? l10n.loginFailed,
        );
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

  Future<String> uploadAvatar(
    BuildContext context,
    String filePath, {
    List<int>? webBytes,
    String? webFileName,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      // Always use POST for avatar uploads to simplify server handling
      final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/profile.php'))
        ..headers.addAll({
          'Authorization': 'Bearer $_token',
          'Accept': 'application/json',
          'Accept-Language': Localizations.localeOf(context).languageCode,
        });

      if (kIsWeb && webBytes != null && webFileName != null) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'avatar',
            webBytes,
            filename: webFileName,
          ),
        );
      } else {
        // Read file as bytes for better cross-platform compatibility (iOS/Android)
        final file = File(filePath);
        final bytes = await file.readAsBytes();
        final filename = filePath.split('/').last;
        request.files.add(
          http.MultipartFile.fromBytes('avatar', bytes, filename: filename),
        );
      }

      final response = await request.send();
      final data = json.decode(await response.stream.bytesToString());

      if (response.statusCode == 401) {
        await _handleUnauthorizedResponse(context, data);
      } else if (response.statusCode != 200) {
        throw ApiException(
          _mapServerError(
            context,
            data['message'] ?? l10n.failedToUpdateProfile,
          ),
        );
      }

      if (data['status'] != 'success' || data['avatar_url'] == null) {
        throw ApiException(
          _mapServerError(
            context,
            data['message'] ?? l10n.failedToUpdateProfile,
          ),
        );
      }

      return data['avatar_url'];
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(l10n.failedToUpdateProfile);
    }
  }

  Future<String> uploadFeedIcon(
    BuildContext context,
    int feedId, {
    String? filePath,
    List<int>? webBytes,
    String? webFileName,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/feeds.php?action=icon&feed_id=$feedId'),
      )..headers.addAll({
          'Authorization': 'Bearer $_token',
          'Accept': 'application/json',
          'Accept-Language': Localizations.localeOf(context).languageCode,
        });

      if (kIsWeb && webBytes != null && webFileName != null) {
        request.files.add(
          http.MultipartFile.fromBytes('icon', webBytes, filename: webFileName),
        );
      } else if (filePath != null) {
        final file = File(filePath);
        final bytes = await file.readAsBytes();
        final filename = filePath.split('/').last;
        request.files.add(
          http.MultipartFile.fromBytes('icon', bytes, filename: filename),
        );
      } else {
        throw ApiException(l10n.errorOccurred);
      }

      final response = await request.send();
      final data = json.decode(await response.stream.bytesToString());

      if (response.statusCode == 401) {
        await _handleUnauthorizedResponse(context, data);
      } else if (response.statusCode != 200) {
        throw ApiException(
          _mapServerError(context, data['message'] ?? l10n.errorOccurred),
        );
      }

      if (data['status'] != 'success' || data['icon_url'] == null) {
        throw ApiException(
          _mapServerError(context, data['message'] ?? l10n.errorOccurred),
        );
      }

      String url = data['icon_url'];
      if (url.startsWith('/')) {
        url = 'https://ocs.kttprojects.com' + url;
      }
      return url;
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(l10n.errorOccurred);
    }
  }

  Future<String> uploadPostMedia(
    BuildContext context,
    int feedId, {
    String? filePath,
    List<int>? webBytes,
    String? webFileName,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/feeds.php?action=media&feed_id=$feedId'),
      )..headers.addAll({
          'Authorization': 'Bearer $_token',
          'Accept': 'application/json',
          'Accept-Language': Localizations.localeOf(context).languageCode,
        });

      if (kIsWeb && webBytes != null && webFileName != null) {
        request.files.add(http.MultipartFile.fromBytes('media', webBytes, filename: webFileName));
      } else if (filePath != null) {
        final file = File(filePath);
        final bytes = await file.readAsBytes();
        final filename = filePath.split('/').last;
        request.files.add(http.MultipartFile.fromBytes('media', bytes, filename: filename));
      } else {
        throw ApiException(l10n.errorOccurred);
      }

      final response = await request.send();
      final data = json.decode(await response.stream.bytesToString());

      if (response.statusCode == 401) {
        await _handleUnauthorizedResponse(context, data);
      } else if (response.statusCode != 200) {
        throw ApiException(_mapServerError(context, data['message'] ?? l10n.errorOccurred));
      }

      if (data['status'] != 'success' || data['media_url'] == null) {
        throw ApiException(_mapServerError(context, data['message'] ?? l10n.errorOccurred));
      }

      String url = data['media_url'];
      if (url.startsWith('/')) {
        url = 'https://ocs.kttprojects.com' + url;
      }
      return url;
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(l10n.errorOccurred);
    }
  }

  Future<void> updateProfile(
    BuildContext context, {
    bool? allowDm,
    String? displayName,
    String? bio,
    int? grade,
    int? institutionId,
  }) async {
    final l10n = AppLocalizations.of(context)!;

    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/profile.php'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${_token}',
          'Cache-Control': 'no-cache',
          'Pragma': 'no-cache',
        },
        body: json.encode({
          if (allowDm != null) 'allow_dm': allowDm,
          if (displayName != null) 'display_name': displayName,
          if (bio != null) 'bio': bio,
          if (grade != null) 'grade': grade,
          if (institutionId != null) 'institution_id': institutionId,
        }),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 401) {
        await _handleUnauthorizedResponse(context, data);
      } else if (response.statusCode != 200) {
        throw ApiException(
          _mapServerError(
            context,
            data['message'] ?? l10n.failedToUpdateProfile,
          ),
        );
      }

      if (data['status'] != 'success') {
        throw ApiException(
          _mapServerError(
            context,
            data['message'] ?? l10n.failedToUpdateProfile,
          ),
        );
      }
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException(l10n.failedToUpdateProfile);
    }
  }

  Future<Map<String, dynamic>> getProfile(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;

    try {
      final response = await http.get(
        _buildUri('profile.php'),
        headers: {
          'Authorization': 'Bearer ${_token}',
          'Cache-Control': 'no-cache',
          'Pragma': 'no-cache',
        },
      );

      final data = json.decode(response.body);

      if (response.statusCode == 401) {
        await _handleUnauthorizedResponse(context, data);
      } else if (response.statusCode != 200) {
        throw ApiException(
          _mapServerError(context, data['message'] ?? l10n.failedToLoadProfile),
        );
      }

      if (data['status'] != 'success') {
        // Also check for token issues in status response
        if (data['message'] == 'Invalid or expired token') {
          await _handleUnauthorizedResponse(context, data);
        }
        throw ApiException(
          _mapServerError(context, data['message'] ?? l10n.failedToLoadProfile),
        );
      }

      return data['profile'];
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException(l10n.failedToLoadProfile);
    }
  }

  Future<int?> getCurrentUserId(BuildContext context) async {
    try {
      final profile = await getProfile(context);
      return profile['id'] is String ? int.parse(profile['id']) : profile['id'];
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>> getUserProfile(
    BuildContext context,
    int userId,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final response = await http.get(
        _buildUri('public_profile.php?user_id=$userId'),
        headers: {
          'Authorization': 'Bearer $_token',
          'Cache-Control': 'no-cache',
          'Pragma': 'no-cache',
        },
      );

      final data = json.decode(response.body);

      if (response.statusCode == 401) {
        await _handleUnauthorizedResponse(context, data);
      } else if (response.statusCode != 200) {
        throw ApiException(
          _mapServerError(context, data['message'] ?? l10n.failedToLoadProfile),
        );
      }

      if (data['status'] != 'success') {
        if (data['message'] == 'Invalid or expired token') {
          await _handleUnauthorizedResponse(context, data);
        }
        throw ApiException(
          _mapServerError(context, data['message'] ?? l10n.failedToLoadProfile),
        );
      }

      return data['profile'];
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(l10n.failedToLoadProfile);
    }
  }

  Future<List<Map<String, dynamic>>> getInstitutions(
    BuildContext context,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final response = await http.get(_buildUri('institutions.php'));

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
      // Get current locale and extract language code
      final locale = Localizations.localeOf(context);
      final lang = locale.languageCode;

      final response = await http.post(
        Uri.parse('$baseUrl/forgot_password.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email, 'lang': lang}),
      );

      final data = json.decode(response.body);
      if (response.statusCode != 200) {
        throw ApiException(
          _mapServerError(context, data['message'] ?? l10n.resetPasswordFailed),
        );
      }

      if (data['status'] != 'success') {
        throw ApiException(
          _mapServerError(context, data['message'] ?? l10n.resetPasswordFailed),
        );
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
        throw ApiException(
          _mapServerError(context, data['message'] ?? l10n.resetPasswordFailed),
        );
      }

      if (data['status'] != 'success') {
        throw ApiException(
          _mapServerError(context, data['message'] ?? l10n.resetPasswordFailed),
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('${l10n.resetPasswordFailed}: ${e.toString()}');
    }
  }

  Future<List<Feed>> getFeeds(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final response = await http.get(
        _buildUri('feeds.php?action=list'),
        headers: {
          'Authorization': 'Bearer $_token',
          'Cache-Control': 'no-cache',
          'Pragma': 'no-cache',
        },
      );

      final data = json.decode(response.body);
      if (response.statusCode == 401) {
        await _handleUnauthorizedResponse(context, data);
      } else if (response.statusCode != 200) {
        throw ApiException(
          _mapServerError(context, data['message'] ?? l10n.errorOccurred),
        );
      }

      return (data['data'] as List).map((feed) => Feed.fromJson(feed)).toList();
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(l10n.errorOccurred);
    }
  }

  Future<List<Feed>> getJoinedFeeds(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final response = await http.get(
        _buildUri('feeds.php?action=joined'),
        headers: {
          'Authorization': 'Bearer $_token',
          'Cache-Control': 'no-cache',
          'Pragma': 'no-cache',
        },
      );

      final data = json.decode(response.body);
      if (response.statusCode == 401) {
        await _handleUnauthorizedResponse(context, data);
      } else if (response.statusCode != 200) {
        throw ApiException(
          _mapServerError(context, data['message'] ?? l10n.errorOccurred),
        );
      }

      return (data['data'] as List).map((feed) => Feed.fromJson(feed)).toList();
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(l10n.errorOccurred);
    }
  }

  Future<List<FeedPost>> getFeedPosts(
    BuildContext context,
    int feedId, {
    int page = 1,
    String sort = 'default',
  }) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final response = await http.get(
        _buildUri('feeds.php?action=posts&feed_id=$feedId&page=$page&sort=$sort'),
        headers: {
          'Authorization': 'Bearer $_token',
          'Cache-Control': 'no-cache',
          'Pragma': 'no-cache',
        },
      );

      final data = json.decode(response.body);
      if (response.statusCode == 401) {
        await _handleUnauthorizedResponse(context, data);
      } else if (response.statusCode != 200) {
        throw ApiException(
          _mapServerError(context, data['message'] ?? l10n.errorOccurred),
        );
      }

      return (data['data'] as List).map((post) => FeedPost.fromJson(post)).toList();
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(l10n.errorOccurred);
    }
  }

  Future<List<FeedPost>> getHomeFeed(
    BuildContext context, {
    int page = 1,
    String sort = 'default',
  }) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final response = await http.get(
        _buildUri('feeds.php?action=home&page=$page&sort=$sort'),
        headers: {
          'Authorization': 'Bearer $_token',
          'Cache-Control': 'no-cache',
          'Pragma': 'no-cache',
        },
      );

      final data = json.decode(response.body);
      if (response.statusCode == 401) {
        await _handleUnauthorizedResponse(context, data);
      } else if (response.statusCode != 200) {
        throw ApiException(
          _mapServerError(context, data['message'] ?? l10n.errorOccurred),
        );
      }

      return (data['data'] as List).map((post) => FeedPost.fromJson(post)).toList();
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(l10n.errorOccurred);
    }
  }

  Future<List<Map<String, dynamic>>> getFeedMembers(
    BuildContext context,
    int feedId,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final response = await http.get(
        _buildUri('feeds.php?action=members&feed_id=$feedId'),
        headers: {
          'Authorization': 'Bearer $_token',
          'Cache-Control': 'no-cache',
          'Pragma': 'no-cache',
        },
      );

      final data = json.decode(response.body);
      if (response.statusCode == 401) {
        await _handleUnauthorizedResponse(context, data);
      } else if (response.statusCode != 200) {
        throw ApiException(
          _mapServerError(context, data['message'] ?? l10n.errorOccurred),
        );
      }

      final list = List<Map<String, dynamic>>.from(data['data'] ?? []);
      for (final item in list) {
        if (item['id'] != null) {
          item['id'] = int.tryParse(item['id'].toString()) ?? item['id'];
        }
      }
      return list;
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(l10n.errorOccurred);
    }
  }

  Future<List<FeedPost>> getDiscoverFeed(
    BuildContext context, {
    int page = 1,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final response = await http.get(
        _buildUri('feeds.php?action=discover&page=$page'),
        headers: {
          'Authorization': 'Bearer $_token',
          'Cache-Control': 'no-cache',
          'Pragma': 'no-cache',
        },
      );

      final data = json.decode(response.body);
      if (response.statusCode == 401) {
        await _handleUnauthorizedResponse(context, data);
      } else if (response.statusCode != 200) {
        throw ApiException(
          _mapServerError(context, data['message'] ?? l10n.errorOccurred),
        );
      }

      return (data['data'] as List).map((post) => FeedPost.fromJson(post)).toList();
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(l10n.errorOccurred);
    }
  }

  Future<void> joinFeed(BuildContext context, int feedId) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/feeds.php?action=join'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
        body: json.encode({'feed_id': feedId}),
      );

      final data = json.decode(response.body);
      if (response.statusCode == 401) {
        await _handleUnauthorizedResponse(context, data);
      } else if (response.statusCode != 200) {
        throw ApiException(
          _mapServerError(context, data['message'] ?? l10n.errorOccurred),
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(l10n.errorOccurred);
    }
  }

  Future<void> leaveFeed(
    BuildContext context,
    int feedId, {
    int? newAdminId,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final body = {'feed_id': feedId};
      if (newAdminId != null) {
        body['new_admin_id'] = newAdminId;
      }
      final response = await http.post(
        Uri.parse('$baseUrl/feeds.php?action=leave'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
        body: json.encode(body),
      );

      final data = json.decode(response.body);
      if (response.statusCode == 401) {
        await _handleUnauthorizedResponse(context, data);
      } else if (response.statusCode != 200) {
        throw ApiException(
          _mapServerError(context, data['message'] ?? l10n.errorOccurred),
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(l10n.errorOccurred);
    }
  }

  Future<int> createFeed(
    BuildContext context, {
    required String name,
    required String displayName,
    required String description,
    String? rules,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/feeds.php?action=create'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
        body: json.encode({
          'name': name,
          'display_name': displayName,
          'description': description,
          if (rules != null) 'rules': rules,
        }),
      );

      final data = json.decode(response.body);
      if (response.statusCode == 401) {
        await _handleUnauthorizedResponse(context, data);
      } else if (response.statusCode != 200 && response.statusCode != 201) {
        throw ApiException(
          _mapServerError(context, data['message'] ?? l10n.errorOccurred),
        );
      }

      return int.parse(data['data']['id'].toString());
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(l10n.errorOccurred);
    }
  }

  Future<void> updateFeed(
    BuildContext context,
    int feedId, {
    String? displayName,
    String? description,
    String? rules,
    int? adminId,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/feeds.php?action=update'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
        body: json.encode({
          'feed_id': feedId,
          if (displayName != null) 'display_name': displayName,
          if (description != null) 'description': description,
          'rules': rules,
          if (adminId != null) 'admin_id': adminId,
        }),
      );

      final data = json.decode(response.body);
      if (response.statusCode == 401) {
        await _handleUnauthorizedResponse(context, data);
      } else if (response.statusCode != 200) {
        throw ApiException(
          _mapServerError(context, data['message'] ?? l10n.errorOccurred),
        );
      }

      if (data['status'] != 'success') {
        throw ApiException(
          _mapServerError(context, data['message'] ?? l10n.errorOccurred),
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(l10n.errorOccurred);
    }
  }

  Future<int> createPost(
    BuildContext context, {
    required int feedId,
    required String title,
    String? content,
    String? mediaUrl,
    String? mediaType,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/feeds.php?action=post'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
        body: json.encode({
          'feed_id': feedId,
          'title': title,
          if (content != null) 'content': content,
          if (mediaUrl != null) 'media_url': mediaUrl,
          if (mediaType != null) 'media_type': mediaType,
        }),
      );

      final data = json.decode(response.body);
      if (response.statusCode == 401) {
        await _handleUnauthorizedResponse(context, data);
      } else if (response.statusCode != 200 && response.statusCode != 201) {
        throw ApiException(
          _mapServerError(context, data['message'] ?? l10n.errorOccurred),
        );
      }

      return int.parse(data['data']['id'].toString());
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(l10n.errorOccurred);
    }
  }

  Future<void> reorderFeeds(
    BuildContext context, {
    required List<int> feedOrder,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/feeds.php?action=reorder'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
        body: json.encode({'feed_order': feedOrder}),
      );

      final data = json.decode(response.body);
      if (response.statusCode == 401) {
        await _handleUnauthorizedResponse(context, data);
      } else if (response.statusCode != 200) {
        throw ApiException(
          _mapServerError(context, data['message'] ?? l10n.errorOccurred),
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(l10n.errorOccurred);
    }
  }

  Future<void> votePost(
    BuildContext context, {
    required int postId,
    required String voteType,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/feeds.php?action=vote'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
        body: json.encode({'post_id': postId, 'vote_type': voteType}),
      );

      final data = json.decode(response.body);
      if (response.statusCode != 200) {
        throw ApiException(
          _mapServerError(context, data['message'] ?? l10n.errorOccurred),
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(l10n.errorOccurred);
    }
  }

  Future<List<Comment>> getComments(
    BuildContext context,
    int postId,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final response = await http.get(
        _buildUri('feeds.php?action=comments&post_id=$postId'),
        headers: {
          'Authorization': 'Bearer $_token',
          'Cache-Control': 'no-cache',
          'Pragma': 'no-cache',
        },
      );

      final data = json.decode(response.body);
      if (response.statusCode == 401) {
        await _handleUnauthorizedResponse(context, data);
      } else if (response.statusCode != 200) {
        throw ApiException(
          _mapServerError(context, data['message'] ?? l10n.errorOccurred),
        );
      }

      return (data['data'] as List).map((c) => Comment.fromJson(c)).toList();
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(l10n.errorOccurred);
    }
  }

  Future<int> createComment(
    BuildContext context, {
    required int postId,
    required String content,
    int? parentCommentId,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/feeds.php?action=comment'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
        body: json.encode({
          'post_id': postId,
          'content': content,
          if (parentCommentId != null) 'parent_comment_id': parentCommentId,
        }),
      );

      final data = json.decode(response.body);
      if (response.statusCode == 401) {
        await _handleUnauthorizedResponse(context, data);
      } else if (response.statusCode != 200 && response.statusCode != 201) {
        throw ApiException(
          _mapServerError(context, data['message'] ?? l10n.errorOccurred),
        );
      }

      return int.parse(data['data']['id'].toString());
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(l10n.errorOccurred);
    }
  }

  // Volunteer API methods
  Future<List<VolunteerOpportunity>> getVolunteerOpportunities(
    BuildContext context, {
    String? status,
    String? sort,
    String? search,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      String query = 'volunteers.php?action=list';
      List<String> params = [];
      if (status != null) params.add('status=$status');
      if (sort != null) params.add('sort=$sort');
      if (search != null) params.add('search=${Uri.encodeComponent(search)}');
      if (params.isNotEmpty) query += '&${params.join('&')}';

      final response = await http.get(
        _buildUri(query),
        headers: {
          'Authorization': 'Bearer $_token',
          'Cache-Control': 'no-cache',
          'Pragma': 'no-cache',
        },
      );

      final data = json.decode(response.body);
      if (response.statusCode == 401) {
        await _handleUnauthorizedResponse(context, data);
      } else if (response.statusCode != 200) {
        throw ApiException(
          _mapServerError(context, data['message'] ?? l10n.errorOccurred),
        );
      }

      return (data['data'] as List).map((opportunity) => VolunteerOpportunity.fromJson(opportunity)).toList();
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(l10n.errorOccurred);
    }
  }

  Future<List<VolunteerOpportunity>> getMyVolunteerOpportunities(
    BuildContext context, {
    String? status,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      String query = 'volunteers.php?action=my_opportunities';
      if (status != null) query += '&status=$status';

      final response = await http.get(
        _buildUri(query),
        headers: {
          'Authorization': 'Bearer $_token',
          'Cache-Control': 'no-cache',
          'Pragma': 'no-cache',
        },
      );

      final data = json.decode(response.body);
      if (response.statusCode == 401) {
        await _handleUnauthorizedResponse(context, data);
      } else if (response.statusCode != 200) {
        throw ApiException(
          _mapServerError(context, data['message'] ?? l10n.errorOccurred),
        );
      }

      return (data['data'] as List).map((opportunity) => VolunteerOpportunity.fromJson(opportunity)).toList();
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(l10n.errorOccurred);
    }
  }

  Future<VolunteerOpportunity> getVolunteerOpportunity(
    BuildContext context,
    int id,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final response = await http.get(
        _buildUri('volunteers.php?action=get&id=$id'),
        headers: {
          'Authorization': 'Bearer $_token',
          'Cache-Control': 'no-cache',
          'Pragma': 'no-cache',
        },
      );

      final data = json.decode(response.body);
      if (response.statusCode == 401) {
        await _handleUnauthorizedResponse(context, data);
      } else if (response.statusCode != 200) {
        throw ApiException(
          _mapServerError(context, data['message'] ?? l10n.errorOccurred),
        );
      }

      return VolunteerOpportunity.fromJson(data['data']);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(l10n.errorOccurred);
    }
  }

  Future<int> createVolunteerOpportunity(
    BuildContext context, {
    required String title,
    required String description,
    required String location,
    required DateTime date,
    required DateTime startTime,
    required DateTime endTime,
    int? requiredParticipants,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/volunteers.php?action=create'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
        body: json.encode({
          'title': title,
          'description': description,
          'location': location,
          'date': date.toIso8601String().split('T')[0],
          'start_time': '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}:00',
          'end_time': '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}:00',
          if (requiredParticipants != null) 'required_participants': requiredParticipants,
        }),
      );

      final data = json.decode(response.body);
      if (response.statusCode == 401) {
        await _handleUnauthorizedResponse(context, data);
      } else if (response.statusCode != 200 && response.statusCode != 201) {
        throw ApiException(
          _mapServerError(context, data['message'] ?? l10n.errorOccurred),
        );
      }

      return int.parse(data['data']['id'].toString());
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(l10n.errorOccurred);
    }
  }

  Future<void> applyToVolunteerOpportunity(
    BuildContext context,
    int opportunityId,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/volunteers.php?action=apply'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
        body: json.encode({
          'opportunity_id': opportunityId,
        }),
      );

      final data = json.decode(response.body);
      if (response.statusCode == 401) {
        await _handleUnauthorizedResponse(context, data);
      } else if (response.statusCode != 200 && response.statusCode != 201) {
        throw ApiException(
          _mapServerError(context, data['message'] ?? l10n.errorOccurred),
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(l10n.errorOccurred);
    }
  }

  Future<void> cancelVolunteerApplication(
    BuildContext context,
    int opportunityId,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/volunteers.php?action=cancel'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
        body: json.encode({
          'opportunity_id': opportunityId,
        }),
      );

      final data = json.decode(response.body);
      if (response.statusCode == 401) {
        await _handleUnauthorizedResponse(context, data);
      } else if (response.statusCode != 200) {
        throw ApiException(
          _mapServerError(context, data['message'] ?? l10n.errorOccurred),
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(l10n.errorOccurred);
    }
  }

  Future<List<VolunteerParticipant>> getVolunteerParticipants(
    BuildContext context,
    int opportunityId,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final response = await http.get(
        _buildUri('volunteers.php?action=participants&opportunity_id=$opportunityId'),
        headers: {
          'Authorization': 'Bearer $_token',
          'Cache-Control': 'no-cache',
          'Pragma': 'no-cache',
        },
      );

      final data = json.decode(response.body);
      if (response.statusCode == 401) {
        await _handleUnauthorizedResponse(context, data);
      } else if (response.statusCode != 200) {
        throw ApiException(
          _mapServerError(context, data['message'] ?? l10n.errorOccurred),
        );
      }

      return (data['data'] as List).map((participant) => VolunteerParticipant.fromJson(participant)).toList();
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(l10n.errorOccurred);
    }
  }

  Future<void> updateParticipantStatus(
    BuildContext context, {
    required int opportunityId,
    required int userId,
    required String status,
    double? hoursCompleted,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/volunteers.php?action=update_participant'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
        body: json.encode({
          'opportunity_id': opportunityId,
          'user_id': userId,
          'status': status,
          if (hoursCompleted != null) 'hours_completed': hoursCompleted,
        }),
      );

      final data = json.decode(response.body);
      if (response.statusCode == 401) {
        await _handleUnauthorizedResponse(context, data);
      } else if (response.statusCode != 200) {
        throw ApiException(
          _mapServerError(context, data['message'] ?? l10n.errorOccurred),
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(l10n.errorOccurred);
    }
  }

  Future<String> downloadVolunteerCertificate(
    BuildContext context,
    int opportunityId,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final response = await http.get(
        _buildUri('volunteers.php?action=certificate&opportunity_id=$opportunityId'),
        headers: {
          'Authorization': 'Bearer $_token',
        },
      );

      if (response.statusCode == 401) {
        final data = json.decode(response.body);
        await _handleUnauthorizedResponse(context, data);
      } else if (response.statusCode != 200) {
        final data = json.decode(response.body);
        throw ApiException(
          _mapServerError(context, data['message'] ?? l10n.errorOccurred),
        );
      }

      // Return the PDF content as base64 string
      return response.body;
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(l10n.errorOccurred);
    }
  }
}
