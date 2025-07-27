import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io';
import 'dart:convert';
import '../l10n/app_localizations.dart';
import '../services/api_client.dart';
import '../widgets/glassmorphic_ui.dart';

class CreateFeedPage extends StatefulWidget {
  final ApiClient apiClient;

  const CreateFeedPage({
    super.key,
    required this.apiClient,
  });

  @override
  State<CreateFeedPage> createState() => _CreateFeedPageState();
}

class _CreateFeedPageState extends State<CreateFeedPage> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _rulesController = TextEditingController();
  bool _isLoading = false;
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

        setState(() {});
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
          _isUploadingIcon = false;
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

  Future<void> _submitFeed() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      setState(() {
        _isLoading = true;
      });

      final feedId = await widget.apiClient.createFeed(
        context,
        name: _displayNameController.text,
        displayName: _displayNameController.text,
        description: _descriptionController.text,
        rules: _rulesController.text.isNotEmpty ? _rulesController.text : null,
      );

      if (_iconFilePath != null || _iconBytes != null) {
        await widget.apiClient.uploadFeedIcon(
          context,
          feedId,
          filePath: _iconFilePath,
          webBytes: _iconBytes,
          webFileName: _iconFileName,
        );
      }

      if (mounted) {
        Navigator.pop(context, feedId);
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
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          l10n.createFeed,
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
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: IconButton(
                icon: Icon(Icons.close, color: Theme.of(context).colorScheme.onPrimary),
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
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: IconButton(
                  icon: Icon(Icons.check, color: Theme.of(context).colorScheme.onPrimary),
                  onPressed: _isLoading ? null : _submitFeed,
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
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
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
                                                child: kIsWeb
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
                                  maxLengthEnforcement: MaxLengthEnforcement.enforced,
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
                                  maxLengthEnforcement: MaxLengthEnforcement.enforced,
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
                                  maxLines: 3,
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
                                  maxLengthEnforcement: MaxLengthEnforcement.enforced,
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
                                  maxLines: 5,
                                  validator: (value) {
                                    if (value != null && value.length > 1000) {
                                      return l10n.rulesTooLong;
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 24),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: _isLoading ? null : _submitFeed,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Theme.of(context).colorScheme.secondary,
                                      foregroundColor: Theme.of(context).colorScheme.onSecondary,
                                      padding: const EdgeInsets.symmetric(vertical: 16),
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
                                        : Text(l10n.createFeed),
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
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
