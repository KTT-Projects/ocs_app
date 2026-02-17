import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ocs_app/l10n/app_localizations.dart';
import 'package:ocs_app/services/api_client.dart';
import 'package:ocs_app/widgets/glassmorphic_ui.dart';

class CreateStudyQuestionPage extends StatefulWidget {
  final ApiClient apiClient;

  const CreateStudyQuestionPage({
    super.key,
    required this.apiClient,
  });

  @override
  State<CreateStudyQuestionPage> createState() =>
      _CreateStudyQuestionPageState();
}

class _CreateStudyQuestionPageState extends State<CreateStudyQuestionPage> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  final _tagInputController = TextEditingController();
  final List<String> _tags = [];
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    _tagInputController.dispose();
    super.dispose();
  }

  bool _addTag({bool showError = true}) {
    final l10n = AppLocalizations.of(context)!;
    final raw = _tagInputController.text.trim();
    if (raw.isEmpty) {
      if (showError) {
        GlassmorphicUI.showGlassSnackBar(
          context,
          l10n.questionTagsRequired,
          isError: true,
        );
      }
      return false;
    }

    if (raw.length > 30) {
      GlassmorphicUI.showGlassSnackBar(
        context,
        l10n.questionTagTooLong,
        isError: true,
      );
      return false;
    }

    if (_tags.length >= 5) {
      GlassmorphicUI.showGlassSnackBar(
        context,
        l10n.questionTagsTooMany,
        isError: true,
      );
      return false;
    }

    final normalized = raw.toLowerCase();
    if (_tags.any((tag) => tag.toLowerCase() == normalized)) {
      _tagInputController.clear();
      return false;
    }

    setState(() {
      _tags.add(raw);
      _tagInputController.clear();
    });
    return true;
  }

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_tagInputController.text.trim().isNotEmpty) {
      _addTag();
    }
    if (_tags.isEmpty) {
      final l10n = AppLocalizations.of(context)!;
      GlassmorphicUI.showGlassSnackBar(
        context,
        l10n.questionTagsRequired,
        isError: true,
      );
      return;
    }

    try {
      setState(() {
        _isLoading = true;
      });

      await widget.apiClient.createStudyQuestion(
        context,
        title: _titleController.text.trim(),
        body: _bodyController.text.trim(),
        tags: _tags,
      );

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        GlassmorphicUI.showGlassSnackBar(
          context,
          e.toString(),
          isError: true,
        );
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
          l10n.createQuestion,
          style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
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
              icon: Icon(Icons.arrow_back,
                  color: Theme.of(context).colorScheme.onPrimary),
              onPressed: () => Navigator.pop(context),
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
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .background
                        .withOpacity(0.2),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: Theme.of(context)
                          .colorScheme
                          .onPrimary
                          .withOpacity(0.3),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _titleController,
                          maxLength: 300,
                          maxLengthEnforcement: MaxLengthEnforcement.enforced,
                          decoration: _inputDecoration(context, l10n.postTitle),
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return l10n.titleRequired;
                            }
                            if (value.length > 300) {
                              return l10n.titleTooLong;
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            l10n.questionTags,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _tagInputController,
                                maxLength: 30,
                                maxLengthEnforcement:
                                    MaxLengthEnforcement.enforced,
                                textInputAction: TextInputAction.done,
                                onSubmitted: (_) => _addTag(showError: false),
                                decoration: _inputDecoration(
                                  context,
                                  l10n.questionTagsHint,
                                ).copyWith(counterText: ''),
                                style: TextStyle(
                                  color:
                                      Theme.of(context).colorScheme.onPrimary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              height: 48,
                              child: ElevatedButton.icon(
                                onPressed: () => _addTag(),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      Theme.of(context).colorScheme.secondary,
                                  foregroundColor:
                                      Theme.of(context).colorScheme.onSecondary,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                icon: const Icon(Icons.add, size: 18),
                                label: Text(l10n.addTag),
                              ),
                            ),
                          ],
                        ),
                        if (_tags.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _tags
                                .map(
                                  (tag) => Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .background
                                          .withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onPrimary
                                            .withOpacity(0.3),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          tag,
                                          style: TextStyle(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onPrimary,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        InkWell(
                                          borderRadius:
                                              BorderRadius.circular(999),
                                          onTap: () => _removeTag(tag),
                                          child: Padding(
                                            padding: const EdgeInsets.all(2),
                                            child: Icon(
                                              Icons.close,
                                              size: 16,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onPrimary,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                        ],
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _bodyController,
                          maxLength: 5000,
                          maxLengthEnforcement: MaxLengthEnforcement.enforced,
                          maxLines: 10,
                          decoration:
                              _inputDecoration(context, l10n.questionBody),
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return l10n.contentRequired;
                            }
                            if (value.length > 5000) {
                              return l10n.contentTooLong;
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  Theme.of(context).colorScheme.secondary,
                              foregroundColor:
                                  Theme.of(context).colorScheme.onSecondary,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  )
                                : Text(
                                    l10n.postQuestion,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w700),
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
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(BuildContext context, String hintText) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(
        color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.55),
      ),
      filled: true,
      fillColor: Theme.of(context).colorScheme.background.withOpacity(0.1),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.3),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.onPrimary,
        ),
      ),
    );
  }
}
