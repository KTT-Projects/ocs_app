import 'package:flutter/material.dart';
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

  @override
  void initState() {
    super.initState();
    _displayNameController =
        TextEditingController(text: widget.feed.displayName);
    _descriptionController =
        TextEditingController(text: widget.feed.description);
    _rulesController = TextEditingController(text: widget.feed.rules ?? '');
    _loadMembers();
  }

  Future<void> _loadMembers() async {
    try {
      final members = await widget.apiClient.getFeedMembers(
        context,
        widget.feed.id,
      );
      if (mounted) {
        setState(() {
          _members = members;
          final current = members.firstWhere(
              (m) => int.parse(m['id'].toString()) == widget.feed.createdBy,
              orElse: () => {});
          _selectedAdmin = current.isNotEmpty ? current : null;
        });
      }
    } catch (_) {}
  }

  Future<void> _selectAdmin() async {
    final l10n = AppLocalizations.of(context)!;
    final members = _members ??
        await widget.apiClient.getFeedMembers(context, widget.feed.id);
    final selected = await GlassmorphicUI.showDialog<Map<String, dynamic>>(
      context: context,
      width: 320,
      child: UserSelectionDialog(
        title: l10n.selectNewAdmin,
        users: members,
        onUserSelected: (u) => Navigator.pop(context, u),
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
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
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
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
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
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
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
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    l10n.currentAdmin,
                                    style: TextStyle(
                                      color: Theme.of(context).colorScheme.onPrimary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        _selectedAdmin != null
                                            ? _selectedAdmin!['display_name'] ?? ''
                                            : '',
                                        style: TextStyle(
                                          color: Theme.of(context).colorScheme.onPrimary,
                                        ),
                                      ),
                                    ),
                                    ElevatedButton(
                                      onPressed: _selectAdmin,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            Theme.of(context).colorScheme.secondary,
                                        foregroundColor:
                                            Theme.of(context).colorScheme.onSecondary,
                                        elevation: 0,
                                      ),
                                      child: Text(l10n.change),
                                    ),
                                  ],
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
