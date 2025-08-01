import 'dart:ui';
import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io';
import '../providers/language_provider.dart';
import '../widgets/language_toggle.dart';
import '../services/api_client.dart';
import '../widgets/glassmorphic_ui.dart';

class ProfilePage extends StatefulWidget {
  final ApiClient apiClient;

  const ProfilePage({
    super.key,
    required this.apiClient,
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _isLoading = true;
  bool _isUploadingAvatar = false;
  String? _error;
  Map<String, dynamic>? _profile;
  List<Map<String, dynamic>>? _institutions;

  bool _initialized = false;
  final _imagePicker = ImagePicker();

  Future<void> _pickImage(BuildContext context) async {
    try {
      final XFile? image = await _imagePicker.pickImage(source: ImageSource.gallery);
      if (image != null && mounted) {
        setState(() {
          _isUploadingAvatar = true;
        });
        String avatarUrl;
        if (kIsWeb) {
          final bytes = await image.readAsBytes();
          final fileName = image.name.isNotEmpty ? image.name : 'avatar.png';
          avatarUrl = await widget.apiClient.uploadAvatar(
            context,
            '',
            webBytes: bytes.toList(),
            webFileName: fileName,
          );
        } else {
          // Check if file exists before uploading (for iOS/Android)
          try {
            // Debug: print image path and check file existence
            print('Picked image path: ${image.path}');
            final file = File(image.path);
            final exists = await file.exists();
            if (!exists) {
              if (mounted) {
                GlassmorphicUI.showGlassSnackBar(
                  context,
                  'Selected file does not exist: ${image.path}',
                  isError: true,
                );
              }
              return;
            }
            avatarUrl = await widget.apiClient.uploadAvatar(context, image.path);
          } catch (e) {
            if (mounted) {
              GlassmorphicUI.showGlassSnackBar(
                context,
                'Failed to upload avatar. Please try again or check file permissions.',
                isError: true,
              );
            }
            return;
          }
        }
        setState(() {
          // Ensure absolute URL for all platforms
          String url = avatarUrl;
          if (url.startsWith('/')) {
            url = 'https://ocs.kttprojects.com' + url;
          }
          _profile!['avatar'] = url;
        });
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
      if (mounted) {
        setState(() {
          _isUploadingAvatar = false;
        });
      }
    }
  }

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

      final profile = await widget.apiClient.getProfile(context);
      final institutions = await widget.apiClient.getInstitutions(context);

      if (mounted) {
        // Ensure absolute avatar URL for all platforms
        if (profile != null && profile['avatar'] != null && profile['avatar'].toString().startsWith('/')) {
          profile['avatar'] = 'https://ocs.kttprojects.com' + profile['avatar'];
        }
        setState(() {
          _profile = profile;
          _institutions = institutions;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: Consumer<LanguageProvider>(
              builder: (context, languageProvider, _) => LanguageToggle(
                currentLanguage: languageProvider.currentLanguage,
                onLanguageChanged: (lang) => languageProvider.setLanguage(lang),
              ),
            ),
          ),
        ],
      ),
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
                        color: Theme.of(context).colorScheme.background.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.3),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
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
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                GestureDetector(
                                  onTap: _isUploadingAvatar ? null : () => _pickImage(context),
                                  child: Stack(
                                    alignment: Alignment.center,
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
                                      if (_isUploadingAvatar)
                                        const CircularProgressIndicator()
                                      else
                                        Positioned(
                                          right: 0,
                                          bottom: 0,
                                          child: Container(
                                            padding: const EdgeInsets.all(4),
                                            decoration: BoxDecoration(
                                              color: Theme.of(context).colorScheme.secondary,
                                              shape: BoxShape.circle,
                                            ),
                                            child: Icon(
                                              Icons.camera_alt,
                                              size: 20,
                                              color: Theme.of(context).colorScheme.onSecondary,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _profile!['email'] ?? '',
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.8),
                                  ),
                                ),
                                const SizedBox(height: 24),
                                Text(
                                  _profile!['name'] ?? l10n.noName,
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
                                  onEdit: () => _editField(
                                    l10n.bio,
                                    _profile!['bio'] ?? '',
                                    (value) async {
                                      await widget.apiClient.updateProfile(
                                        context,
                                        bio: value,
                                      );
                                      setState(() {
                                        _profile!['bio'] = value;
                                      });
                                    },
                                  ),
                                ),
                                const SizedBox(height: 12),
                                _buildInfoRow(
                                  context,
                                  l10n.selectInstitution,
                                  _getLocalizedInstitutionName(_profile!['institution'] ?? ''),
                                  onEdit: () async {
                                    try {
                                      final selectedInstitutionId = await _selectInstitution();
                                      if (selectedInstitutionId != null) {
                                        final selectedInst = _institutions?.firstWhere(
                                          (inst) => inst['id'].toString() == selectedInstitutionId,
                                        );
                                        await widget.apiClient.updateProfile(
                                          context,
                                          institutionId: int.parse(selectedInstitutionId),
                                        );
                                        if (mounted && selectedInst != null) {
                                          setState(() {
                                            _profile!['institution'] = selectedInst['name'];
                                          });
                                        }
                                      }
                                    } catch (e) {
                                      if (mounted) {
                                        GlassmorphicUI.showGlassSnackBar(
                                          context,
                                          e.toString(),
                                          isError: true,
                                        );
                                      }
                                    }
                                  },
                                ),
                                const SizedBox(height: 12),
                                _buildInfoRow(
                                  context,
                                  l10n.grade,
                                  _formatGrade(_profile!['grade']),
                                  onEdit: () => _selectGrade(),
                                ),
                                const SizedBox(height: 12),
                                _buildInfoRow(
                                  context,
                                  l10n.role,
                                  (_profile!['role'] as String).substring(0, 1).toUpperCase() + (_profile!['role'] as String).substring(1),
                                ),
                                const SizedBox(height: 24),
                                SwitchListTile(
                                  title: Text(
                                    l10n.allowDirectMessages,
                                    style: TextStyle(
                                      color: Theme.of(context).colorScheme.onPrimary,
                                    ),
                                  ),
                                  value: _profile!['allow_dm'] ?? false,
                                  onChanged: (bool value) async {
                                    try {
                                      await widget.apiClient.updateProfile(
                                        context,
                                        allowDm: value,
                                      );
                                      if (mounted) {
                                        setState(() {
                                          _profile!['allow_dm'] = value;
                                        });
                                      }
                                    } catch (e) {
                                      if (mounted) {
                                        GlassmorphicUI.showGlassSnackBar(
                                          context,
                                          e.toString(),
                                          isError: true,
                                        );
                                      }
                                    }
                                  },
                                  activeColor: Theme.of(context).colorScheme.secondary,
                                ),
                                const SizedBox(height: 32),
                                ElevatedButton.icon(
                                  icon: Icon(Icons.logout),
                                  label: Text(l10n.logout),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Theme.of(context).colorScheme.errorContainer,
                                    foregroundColor: Theme.of(context).colorScheme.onErrorContainer,
                                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  onPressed: () async {
                                    await widget.apiClient.logout(context);
                                    // MainPage listens for token changes and automatically
                                    // displays the login screen, so no navigation is needed here.
                                  },
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

  Widget _buildInfoRow(BuildContext context, String label, String value, {VoidCallback? onEdit}) {
    return InkWell(
      onTap: onEdit,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.7),
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
          if (onEdit != null) ...[
            const SizedBox(width: 8),
            Icon(
              Icons.edit,
              color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.7),
              size: 16,
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _selectGrade() async {
    final l10n = AppLocalizations.of(context)!;
    final selectedGrade = await showDialog<int>(
      context: context,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: 300, // Fixed width for dialog
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.background.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.3),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
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
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        l10n.grade,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Theme.of(context).colorScheme.onPrimary,
                            ),
                      ),
                      const SizedBox(height: 16),
                      ...List.generate(8, (index) => index + 7).map(
                        (grade) => ListTile(
                          title: Text(
                            'G$grade',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onPrimary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          onTap: () => Navigator.pop(context, grade),
                        ),
                      ),
                      ListTile(
                        title: Text(
                          'OB',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        onTap: () => Navigator.pop(context, 99),
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

    if (selectedGrade != null && mounted) {
      try {
        await widget.apiClient.updateProfile(
          context,
          grade: selectedGrade,
        );
        setState(() {
          _profile!['grade'] = selectedGrade;
        });
      } catch (e) {
        if (mounted) {
          GlassmorphicUI.showGlassSnackBar(
            context,
            e.toString(),
            isError: true,
          );
        }
      }
    }
  }

  Future<String?> _selectInstitution() async {
    final l10n = AppLocalizations.of(context)!;
    return showDialog<String>(
      context: context,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: 300, // Fixed width for dialog
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.background.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.3),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
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
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        l10n.selectInstitution,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Theme.of(context).colorScheme.onPrimary,
                            ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        constraints: BoxConstraints(
                          maxHeight: MediaQuery.of(context).size.height * 0.5,
                        ),
                        child: SingleChildScrollView(
                          child: Column(
                            children: _institutions?.map((institution) {
                                  final name = _getLocalizedInstitutionName(institution['name']);
                                  return ListTile(
                                    title: Text(
                                      name,
                                      style: TextStyle(
                                        color: Theme.of(context).colorScheme.onPrimary,
                                      ),
                                    ),
                                    onTap: () => Navigator.pop(context, institution['id'].toString()),
                                  );
                                }).toList() ??
                                [],
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
  }

  Future<void> _editField(String title, String initialValue, Function(String) onSave) async {
    final l10n = AppLocalizations.of(context)!;

    if (title == l10n.grade) {
      initialValue = _profile!['grade'] == 99 ? 'OB' : initialValue;
    }
    final controller = TextEditingController(text: initialValue);
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: 300, // Fixed width for dialog
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.background.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.3),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
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
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Theme.of(context).colorScheme.onPrimary,
                            ),
                      ),
                      const SizedBox(height: 16),
                      Form(
                        key: formKey,
                        child: TextFormField(
                          controller: controller,
                          autofocus: true,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.1),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.3),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Theme.of(context).colorScheme.onPrimary,
                              ),
                            ),
                            helperText: title == l10n.grade ? l10n.gradeInputHint : null,
                            helperStyle: TextStyle(
                              color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.7),
                            ),
                          ),
                          maxLines: title == l10n.bio ? 3 : 1,
                          textInputAction: title == l10n.bio ? TextInputAction.newline : TextInputAction.done,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              if (title == l10n.displayName) {
                                return l10n.displayNameRequired;
                              } else if (title == l10n.grade) {
                                return l10n.pleaseSelectGrade;
                              } else if (title == l10n.bio) {
                                return null; // Bio can be empty
                              }
                              return l10n.displayNameRequired;
                            }
                            if (title == l10n.grade && value.toUpperCase() != 'OB') {
                              final grade = int.tryParse(value);
                              if (grade == null || grade < 1 || grade > 6) {
                                return l10n.invalidGrade;
                              }
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(
                              l10n.cancel,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.7),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).colorScheme.secondary,
                              foregroundColor: Theme.of(context).colorScheme.onSecondary,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () async {
                              if (formKey.currentState!.validate()) {
                                String value = controller.text;
                                if (title == l10n.grade && value.toUpperCase() == 'OB') {
                                  value = '99';
                                }
                                Navigator.pop(context);
                                await onSave(value);
                              }
                            },
                            child: Text(l10n.saveProfile),
                          ),
                        ],
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
  }
}
