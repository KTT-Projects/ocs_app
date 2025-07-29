import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io';
import 'dart:convert';
import 'dart:ui';
import '../l10n/app_localizations.dart';
import '../models/feed.dart';
import '../services/api_client.dart';
import '../widgets/glassmorphic_ui.dart';
import '../widgets/user_selection_dialog.dart';

class FeedSettingsPage extends StatefulWidget {
  final ApiClient apiClient;
  final Feed feed;

  const FeedSettingsPage({
    super.key,
    required this.apiClient,
    required this.feed,
  });

  @override
  State<FeedSettingsPage> createState() => _FeedSettingsPageState();
}

class _FeedSettingsPageState extends State<FeedSettingsPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _displayNameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _rulesController;
  bool _isLoading = false;
  List<Map<String, dynamic>>? _members;
  Map<String, dynamic>? _selectedAdmin;
  bool _isMembersLoading = false;
  bool _isUploadingIcon = false;
  final _imagePicker = ImagePicker();
  String? _iconUrl;
  String? _iconFilePath;
  List<int>? _iconBytes;
  String? _iconFileName;

  Future<void> _pickIcon() async {
    try {
      final XFile? image = await _imagePicker.pickImage(source: ImageSource.gallery);
      if (image != null && mounted) {
        setState(() {
          _isUploadingIcon = true;
        });

        if (kIsWeb) {
          _iconBytes = await image.readAsBytes();
          _iconFileName = image.name.isNotEmpty ? image.name : 'icon.png';
          _iconUrl = 'data:${image.mimeType};base64,${base64Encode(_iconBytes!)}';
        } else {
          _iconFilePath = image.path;
          _iconUrl = image.path;
        }

        setState(() {
          _isUploadingIcon = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isUploadingIcon = false;
        });
        GlassmorphicUI.showGlassSnackBar(
          context,
          e.toString(),
          isError: true,
        );
      }
    }
  }
  @override
  void initState() {
    super.initState();
    _displayNameController =
        TextEditingController(text: widget.feed.displayName);
    _descriptionController =
        TextEditingController(text: widget.feed.description);
    _rulesController = TextEditingController(text: widget.feed.rules ?? '');
    _iconUrl = widget.feed.iconUrl;
  }

  Future<void> _loadMembers() async {
    if (_isMembersLoading) return;
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _isMembersLoading = true;
    });
    try {
      final members = await widget.apiClient.getFeedMembers(
        context,
        widget.feed.id,
      );
      if (mounted) {
        setState(() {
          _members = members;
          final current = members.firstWhere(
            (m) => m['role'] == 'admin',
            orElse: () => {},
          );
          _selectedAdmin = current.isNotEmpty ? current : null;
        });
      }
    } catch (_) {
      if (mounted) {
        GlassmorphicUI.showGlassSnackBar(
          context,
          l10n.failedToLoadFeedMembers,
          isError: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isMembersLoading = false;
        });
      }
    }
  }

  Future<void> _selectAdmin() async {
    if (_members == null || _members!.isEmpty) return;
    final l10n = AppLocalizations.of(context)!;
    final selected = await GlassmorphicUI.showDialog<Map<String, dynamic>>(
      context: context,
      width: 320,
      child: UserSelectionDialog(
        title: l10n.selectNewAdmin,
        users: _members!,
        onUserSelected: (user) => Navigator.pop(context, user),
      ),
    );
    if (selected != null && mounted) {
      setState(() {
        _selectedAdmin = selected;
      });
    }
  }


  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;
    try {
      setState(() {
        _isLoading = true;
      });
      await widget.apiClient.updateFeed(
        context,
        widget.feed.id,
        displayName: _displayNameController.text,
        description: _descriptionController.text,
        rules: _rulesController.text.isNotEmpty ? _rulesController.text : null,
        adminId: _selectedAdmin != null
            ? int.parse(_selectedAdmin!['id'].toString())
            : null,
      );
      if (_iconFilePath != null || _iconBytes != null) {
        _iconUrl = await widget.apiClient.uploadFeedIcon(
          context,
          widget.feed.id,
          filePath: _iconFilePath,
          webBytes: _iconBytes,
          webFileName: _iconFileName,
        );
        _iconFilePath = null;
        _iconBytes = null;
        _iconFileName = null;
      }
      if (mounted) {
        GlassmorphicUI.showGlassSnackBar(
          context,
          AppLocalizations.of(context)!.feedUpdatedSuccess,
        );
        Navigator.pop(context, true);
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
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _descriptionController.dispose();
    _rulesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (_members == null && !_isMembersLoading) {
      // Trigger loading of feed members when page is first built
      _loadMembers();
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          l10n.feedSettings,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onPrimary,
          ),
        ),
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
                icon:
                    Icon(Icons.close, color: Theme.of(context).colorScheme.onPrimary),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
        ),
        actions: [
          Container(
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
                  icon: Icon(Icons.check,
                      color: Theme.of(context).colorScheme.onPrimary),
                  onPressed: _isLoading ? null : _saveSettings,
                ),
              ),
            ),
          ),
        ],
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
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    Container(
                      constraints: BoxConstraints(
                        minHeight: MediaQuery.of(context).size.height * 0.9,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.background.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.3),
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                GestureDetector(
                                  onTap: _isUploadingIcon ? null : _pickIcon,
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      CircleAvatar(
                                        radius: 40,
                                        backgroundColor: Theme.of(context).colorScheme.secondary,
                                        child: _iconUrl != null
                                            ? ClipOval(
                                                child: kIsWeb || _iconUrl!.startsWith('http')
                                                    ? Image.network(
                                                        _iconUrl!,
                                                        width: 80,
                                                        height: 80,
                                                        fit: BoxFit.cover,
                                                      )
                                                    : Image.file(
                                                        File(_iconUrl!),
                                                        width: 80,
                                                        height: 80,
                                                        fit: BoxFit.cover,
                                                      ),
                                              )
                                            : Icon(
                                                Icons.camera_alt,
                                                color: Theme.of(context).colorScheme.onSecondary,
                                              ),
                                      ),
                                      if (_isUploadingIcon)
                                        const CircularProgressIndicator(),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _displayNameController,
                                  maxLength: 30,
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.onPrimary,
                                  ),
                                  decoration: InputDecoration(
                                    labelText: l10n.feedDisplayName,
                                    labelStyle: TextStyle(
                                      color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.7),
                                    ),
                                    enabledBorder: UnderlineInputBorder(
                                      borderSide: BorderSide(
                                        color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.3),
                                      ),
                                    ),
                                    focusedBorder: UnderlineInputBorder(
                                      borderSide: BorderSide(
                                        color: Theme.of(context).colorScheme.onPrimary,
                                      ),
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return l10n.displayNameRequired;
                                    }
                                    if (value.length > 30) {
                                      return l10n.displayNameTooLong;
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _descriptionController,
                                  maxLength: 1000,
                                  minLines: 3,
                                  maxLines: 20,
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.onPrimary,
                                  ),
                                  decoration: InputDecoration(
                                    labelText: l10n.feedDescription,
                                    labelStyle: TextStyle(
                                      color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.7),
                                    ),
                                    enabledBorder: UnderlineInputBorder(
                                      borderSide: BorderSide(
                                        color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.3),
                                      ),
                                    ),
                                    focusedBorder: UnderlineInputBorder(
                                      borderSide: BorderSide(
                                        color: Theme.of(context).colorScheme.onPrimary,
                                      ),
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return l10n.descriptionRequired;
                                    }
                                    if (value.length > 1000) {
                                      return l10n.descriptionTooLong;
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _rulesController,
                                  maxLength: 1000,
                                  minLines: 5,
                                  maxLines: 20,
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.onPrimary,
                                  ),
                                  decoration: InputDecoration(
                                    labelText: l10n.feedRules,
                                    labelStyle: TextStyle(
                                      color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.7),
                                    ),
                                    enabledBorder: UnderlineInputBorder(
                                      borderSide: BorderSide(
                                        color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.3),
                                      ),
                                    ),
                                    focusedBorder: UnderlineInputBorder(
                                      borderSide: BorderSide(
                                        color: Theme.of(context).colorScheme.onPrimary,
                                      ),
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value != null && value.length > 1000) {
                                      return l10n.rulesTooLong;
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  readOnly: true,
                                  onTap: _selectAdmin,
                                  controller: TextEditingController(
                                    text: _selectedAdmin != null
                                        ? _selectedAdmin!['display_name'] ?? ''
                                        : '',
                                  ),
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.onPrimary,
                                  ),
                                  decoration: InputDecoration(
                                    labelText: l10n.currentAdmin,
                                    labelStyle: TextStyle(
                                      color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.7),
                                    ),
                                    suffixIcon: _isMembersLoading
                                        ? const Padding(
                                            padding: EdgeInsets.only(right: 8),
                                            child: SizedBox(
                                              width: 16,
                                              height: 16,
                                              child: CircularProgressIndicator(strokeWidth: 2),
                                            ),
                                          )
                                        : Icon(
                                            Icons.arrow_drop_down,
                                            color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.7),
                                          ),
                                    enabledBorder: UnderlineInputBorder(
                                      borderSide: BorderSide(
                                        color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.3),
                                      ),
                                    ),
                                    focusedBorder: UnderlineInputBorder(
                                      borderSide: BorderSide(
                                        color: Theme.of(context).colorScheme.onPrimary,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: Center(
                child: CircularProgressIndicator(
                  valueColor:
                      AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.onPrimary),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
