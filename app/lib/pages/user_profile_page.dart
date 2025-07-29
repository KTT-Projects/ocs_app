import 'dart:ui';
import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../services/api_client.dart';

class UserProfilePage extends StatefulWidget {
  final ApiClient apiClient;
  final int userId;

  const UserProfilePage({super.key, required this.apiClient, required this.userId});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _profile;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _loadProfile();
      _initialized = true;
    }
  }

  Future<void> _loadProfile() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });
      final profile = await widget.apiClient.getUserProfile(context, widget.userId);
      if (!mounted) return;
      if (profile['avatar'] != null && profile['avatar'].toString().startsWith('/')) {
        profile['avatar'] = 'https://ocs.kttprojects.com' + profile['avatar'];
      }
      setState(() {
        _profile = profile;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  String _formatGrade(dynamic grade) {
    if (grade == null) return '';
    final gradeNum = int.tryParse(grade.toString());
    if (gradeNum == null) return grade.toString();
    if (gradeNum == 99) return 'OB';
    if (gradeNum >= 7 && gradeNum <= 14) return 'G$gradeNum';
    return grade.toString();
  }

  String _getLocalizedInstitutionName(String fullName) {
    final parts = fullName.split(' / ');
    final isJapanese = Localizations.localeOf(context).languageCode == 'ja';
    return parts.length > 1 ? (isJapanese ? parts[1] : parts[0]) : fullName;
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.7),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onPrimary,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.background.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.3),
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: IconButton(
                icon: Icon(
                  Icons.arrow_back,
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
        ),
      ),
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
          if (_isLoading)
            Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).colorScheme.onPrimary,
                ),
              ),
            )
          else if (_error != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  _error!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          else if (_profile != null)
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
                        child: Padding(
                            padding: EdgeInsets.all(isSmallScreen ? 20.0 : 32.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                CircleAvatar(
                                  radius: 50,
                                  backgroundColor: Theme.of(context).colorScheme.secondary,
                                  child: _profile!['avatar'] != null
                                      ? ClipOval(
                                          child: Image.network(
                                            _profile!['avatar'],
                                            width: 100,
                                            height: 100,
                                            fit: BoxFit.cover,
                                          ),
                                        )
                                      : Text(
                                          _profile!['name']?[0] ?? '?',
                                          style: TextStyle(
                                            fontSize: 32,
                                            color: Theme.of(context).colorScheme.onSecondary,
                                          ),
                                        ),
                                ),
                                const SizedBox(height: 16),
                                const SizedBox(height: 24),
                                Text(
                                  _profile!['name'] ?? '',
                                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                        color: Theme.of(context).colorScheme.onPrimary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                                const SizedBox(height: 24),
                                _buildInfoRow(
                                  context,
                                  l10n.bio,
                                  _profile!['bio'] ?? '',
                                ),
                                const SizedBox(height: 12),
                                _buildInfoRow(
                                  context,
                                  l10n.selectInstitution,
                                  _getLocalizedInstitutionName(_profile!['institution'] ?? ''),
                                ),
                                const SizedBox(height: 12),
                                _buildInfoRow(
                                  context,
                                  l10n.grade,
                                  _formatGrade(_profile!['grade']),
                                ),
                                const SizedBox(height: 12),
                                _buildInfoRow(
                                  context,
                                  l10n.role,
                                  (_profile!['role'] as String).substring(0, 1).toUpperCase() +
                                      (_profile!['role'] as String).substring(1),
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
