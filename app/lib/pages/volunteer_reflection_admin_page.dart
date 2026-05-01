import 'dart:ui';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/opportunity_experience.dart';
import '../models/volunteer_opportunity.dart';
import '../models/volunteer_reflection.dart';
import '../services/api_client.dart';
import '../widgets/glassmorphic_ui.dart';

class VolunteerReflectionAdminPage extends StatefulWidget {
  final ApiClient apiClient;
  final VolunteerOpportunity opportunity;
  final OpportunityExperience experience;

  const VolunteerReflectionAdminPage({
    super.key,
    required this.apiClient,
    required this.opportunity,
    this.experience = OpportunityExperience.volunteer,
  });

  @override
  State<VolunteerReflectionAdminPage> createState() =>
      _VolunteerReflectionAdminPageState();
}

class _VolunteerReflectionAdminPageState
    extends State<VolunteerReflectionAdminPage> {
  bool _loading = true;
  bool _saving = false;
  bool _uploadingImage = false;
  VolunteerReflection? _reflection;
  List<VolunteerReflectionImage> _images = [];
  late VolunteerOpportunity _opportunity;
  bool _didLoad = false;

  final _titleCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _opportunity = widget.opportunity;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didLoad) {
      _didLoad = true;
      _loadReflection();
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadReflection() async {
    try {
      final list = await widget.apiClient
          .getVolunteerReflections(context, _opportunity.id);
      final latest = list.isNotEmpty ? list.first : null;
      if (mounted) {
        setState(() {
          _reflection = latest;
          _images = latest?.images ?? [];
          _titleCtrl.text = latest?.title ?? '';
          _bodyCtrl.text = latest?.body ?? '';
          _loading = false;
          _opportunity = _opportunity.copyWith(
            reflectionCount: list.length,
            latestReflectionAt:
                latest?.createdAt ?? _opportunity.latestReflectionAt,
            latestReflectionTitle:
                latest?.title ?? _opportunity.latestReflectionTitle,
            latestReflectionExcerpt:
                latest?.body ?? _opportunity.latestReflectionExcerpt,
            latestReflectionImages:
                latest?.images ?? _opportunity.latestReflectionImages,
            status: latest != null ? 'completed' : _opportunity.status,
          );
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        GlassmorphicUI.showGlassSnackBar(context, e.toString(), isError: true);
      }
    }
  }

  Future<VolunteerReflection> _ensureReflection() async {
    if (_reflection != null) return _reflection!;
    final l10n = AppLocalizations.of(context)!;
    final title = _titleCtrl.text.trim().isEmpty
        ? l10n.recentReflection
        : _titleCtrl.text.trim();
    final body = _bodyCtrl.text.trim().isEmpty
        ? l10n.reflectionAutoBody
        : _bodyCtrl.text.trim();
    final created = await widget.apiClient.createVolunteerReflection(
      context,
      opportunityId: _opportunity.id,
      title: title,
      body: body,
    );
    setState(() {
      _reflection = created;
      _opportunity = _opportunity.copyWith(
        reflectionCount: 1,
        latestReflectionAt: created.createdAt,
        latestReflectionTitle: created.title,
        latestReflectionExcerpt: created.body,
        latestReflectionImages: created.images,
        status: 'completed',
      );
    });
    return created;
  }

  Future<void> _saveReflection() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _saving = true);
    try {
      VolunteerReflection target = _reflection ??
          VolunteerReflection(
            id: 0,
            opportunityId: _opportunity.id,
            title: '',
            body: '',
            createdBy: 0,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );

      final title = _titleCtrl.text.trim().isEmpty
          ? l10n.recentReflection
          : _titleCtrl.text.trim();
      final body = _bodyCtrl.text.trim().isEmpty
          ? l10n.reflectionAutoBody
          : _bodyCtrl.text.trim();

      if (target.id == 0) {
        target = await _ensureReflection();
      } else {
        target = await widget.apiClient.updateVolunteerReflection(
          context,
          reflectionId: target.id,
          title: title,
          body: body,
        );
      }

      if (mounted) {
        setState(() {
          _reflection = target.copyWith(images: _images);
          _saving = false;
          _opportunity = _opportunity.copyWith(
            reflectionCount: 1,
            latestReflectionAt: target.createdAt,
            latestReflectionTitle: target.title,
            latestReflectionExcerpt: target.body,
            latestReflectionImages: _images,
            status: 'completed',
          );
        });
        Navigator.pop(context, _opportunity);
        GlassmorphicUI.showGlassSnackBar(context, l10n.reflectionSaved);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        GlassmorphicUI.showGlassSnackBar(context, e.toString(), isError: true);
      }
    }
  }

  Future<void> _addPhotos() async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final reflection = await _ensureReflection();
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.image,
        withData: kIsWeb,
      );
      if (result == null || result.files.isEmpty) return;

      setState(() => _uploadingImage = true);

      for (final picked in result.files) {
        if (!kIsWeb && (picked.path == null || picked.path!.isEmpty)) {
          GlassmorphicUI.showGlassSnackBar(
              context, 'Could not read file path for ${picked.name}',
              isError: true);
          continue;
        }
        if (kIsWeb && picked.bytes == null) {
          GlassmorphicUI.showGlassSnackBar(
              context, 'Could not read file bytes for ${picked.name}',
              isError: true);
          continue;
        }

        final image = await widget.apiClient.uploadVolunteerReflectionImage(
          context,
          reflectionId: reflection.id,
          filePath: kIsWeb ? null : picked.path,
          webBytes: kIsWeb ? picked.bytes : null,
          fileName: picked.name,
          mimeType: _inferMime(picked),
        );

        if (mounted) {
          setState(() {
            _images = [image, ..._images];
            _reflection = (_reflection ?? reflection).copyWith(images: _images);
            _opportunity =
                _opportunity.copyWith(latestReflectionImages: _images);
          });
        }
      }

      if (mounted) {
        setState(() => _uploadingImage = false);
        GlassmorphicUI.showGlassSnackBar(context, l10n.reflectionImageUploaded);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _uploadingImage = false);
        GlassmorphicUI.showGlassSnackBar(context, e.toString(), isError: true);
      }
    }
  }

  Future<void> _deleteImage(VolunteerReflectionImage image) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      await widget.apiClient
          .deleteVolunteerReflectionImage(context, imageId: image.id);
      if (mounted) {
        setState(() {
          _images.removeWhere((i) => i.id == image.id);
          if (_reflection != null) {
            _reflection = _reflection!.copyWith(images: _images);
          }
          _opportunity = _opportunity.copyWith(
            latestReflectionImages: _images,
          );
        });
        GlassmorphicUI.showGlassSnackBar(context, l10n.reflectionImageRemoved);
      }
    } catch (e) {
      if (mounted) {
        GlassmorphicUI.showGlassSnackBar(context, e.toString(), isError: true);
      }
    }
  }

  String? _inferMime(PlatformFile file) {
    final ext = (file.extension ?? '').toLowerCase();
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      default:
        return null;
    }
  }

  Widget _glassPanel({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.background.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color:
                    Theme.of(context).colorScheme.onPrimary.withOpacity(0.3)),
          ),
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primary,
                Theme.of(context).colorScheme.secondary
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        Scaffold(
          backgroundColor: Colors.transparent,
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            titleSpacing: 0,
            leading: GlassmorphicUI.buildAppBarIconButton(
              context: context,
              icon: Icons.close,
              onPressed: () => Navigator.pop(context, _opportunity),
            ),
            title: Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Text(
                l10n.reflectionBodyLabel,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GlassmorphicUI.buildAppBarIconButton(
                  context: context,
                  icon: _saving ? null : Icons.check,
                  onPressed: _saving ? null : _saveReflection,
                  child: _saving
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                        )
                      : null,
                ),
              ),
            ],
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _glassPanel(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.recentReflection,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onPrimary,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            _buildTextField(
                                l10n.reflectionTitleLabel, _titleCtrl),
                            const SizedBox(height: 12),
                            _buildTextField(l10n.reflectionBodyLabel, _bodyCtrl,
                                maxLines: 5),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Text(
                                  l10n.reflectionImages,
                                  style: TextStyle(
                                    color:
                                        Theme.of(context).colorScheme.onPrimary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                if (_images.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(left: 8),
                                    child: Text(
                                      '${_images.length}',
                                      style: TextStyle(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onPrimary
                                              .withOpacity(0.7)),
                                    ),
                                  ),
                                const Spacer(),
                                TextButton.icon(
                                  onPressed:
                                      _uploadingImage ? null : _addPhotos,
                                  icon: _uploadingImage
                                      ? SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onPrimary,
                                          ),
                                        )
                                      : Icon(Icons.add_a_photo,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onPrimary),
                                  label: Text(
                                    l10n.addPhotos,
                                    style: TextStyle(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onPrimary),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            if (_loading)
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                child: Center(
                                  child: CircularProgressIndicator(
                                    color:
                                        Theme.of(context).colorScheme.onPrimary,
                                  ),
                                ),
                              )
                            else if (_images.isEmpty)
                              Text(
                                l10n.noReflectionImages,
                                style: TextStyle(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onPrimary
                                        .withOpacity(0.8)),
                              )
                            else
                              Wrap(
                                spacing: 12,
                                runSpacing: 12,
                                children: _images
                                    .map(
                                      (img) => Stack(
                                        children: [
                                          ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                            child: Image.network(
                                              img.fileUrl,
                                              width: 120,
                                              height: 120,
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) =>
                                                  Container(
                                                width: 120,
                                                height: 120,
                                                color: Colors.white24,
                                                child: const Icon(
                                                    Icons.broken_image),
                                              ),
                                            ),
                                          ),
                                          Positioned(
                                            top: 4,
                                            right: 4,
                                            child: InkWell(
                                              onTap: () => _deleteImage(img),
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.all(4),
                                                decoration: BoxDecoration(
                                                  color: Colors.black
                                                      .withOpacity(0.45),
                                                  shape: BoxShape.circle,
                                                ),
                                                child: const Icon(Icons.close,
                                                    size: 16,
                                                    color: Colors.white),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                    .toList(),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(String label, TextEditingController ctrl,
      {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                color:
                    Theme.of(context).colorScheme.onPrimary.withOpacity(0.85))),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          maxLines: maxLines,
          style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                  color: Theme.of(context)
                      .colorScheme
                      .onPrimary
                      .withOpacity(0.25)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                  color: Theme.of(context)
                      .colorScheme
                      .onPrimary
                      .withOpacity(0.25)),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(
                  color:
                      Theme.of(context).colorScheme.onPrimary.withOpacity(0.6)),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }
}
