import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import '../l10n/app_localizations.dart';
import '../models/volunteer_attachment.dart';
import '../models/volunteer_opportunity.dart';
import '../models/volunteer_participant.dart';
import '../services/api_client.dart';
import '../widgets/glassmorphic_ui.dart';

class VolunteerAdminPage extends StatefulWidget {
  final ApiClient apiClient;
  final VolunteerOpportunity opportunity;

  const VolunteerAdminPage({super.key, required this.apiClient, required this.opportunity});

  @override
  State<VolunteerAdminPage> createState() => _VolunteerAdminPageState();
}

class _VolunteerAdminPageState extends State<VolunteerAdminPage> {
  late VolunteerOpportunity _opportunity;
  bool _saving = false;
  bool _loadingParticipants = true;
  bool _didRequestParticipants = false;
  bool _didLoadUserId = false;
  bool _didRequestAttachments = false;
  bool _loadingAttachments = true;
  bool _uploadingAttachment = false;
  int? _currentUserId;
  List<VolunteerParticipant> _participants = [];
  List<VolunteerAttachment> _attachments = [];

  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _locationController = TextEditingController();
  final _requiredCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _opportunity = widget.opportunity;
    _titleController.text = _opportunity.title;
    _descController.text = _opportunity.description;
    _locationController.text = _opportunity.location;
    if (_opportunity.requiredParticipants != null) {
      _requiredCtrl.text = _opportunity.requiredParticipants.toString();
    }
    _attachments = _opportunity.attachments;
    _loadingAttachments = _attachments.isEmpty;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Avoid inherited widget lookups in initState; defer API calls that rely on context.
    if (!_didRequestParticipants) {
      _didRequestParticipants = true;
      _loadParticipants();
    }
    if (!_didLoadUserId) {
      _didLoadUserId = true;
      _loadCurrentUserId();
    }
    if (!_didRequestAttachments) {
      _didRequestAttachments = true;
      _loadAttachments();
    }
  }

  Future<void> _loadParticipants() async {
    try {
      final list = await widget.apiClient.getVolunteerParticipants(context, _opportunity.id);
      if (mounted) {
        setState(() {
          _participants = list;
          _loadingParticipants = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingParticipants = false);
        GlassmorphicUI.showGlassSnackBar(context, e.toString(), isError: true);
      }
    }
  }

  Future<void> _loadCurrentUserId() async {
    try {
      final id = await widget.apiClient.getCurrentUserId(context);
      if (mounted) {
        setState(() {
          _currentUserId = id;
        });
      }
    } catch (_) {
      // If the current user cannot be fetched, leave _currentUserId as null.
    }
  }

  Future<void> _loadAttachments() async {
    try {
      setState(() => _loadingAttachments = true);
      final list = await widget.apiClient.getVolunteerAttachments(context, _opportunity.id);
      if (mounted) {
        setState(() {
          _attachments = list;
          _opportunity = _opportunity.copyWith(
            attachments: list,
            attachmentCount: list.length,
          );
          _loadingAttachments = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingAttachments = false);
        GlassmorphicUI.showGlassSnackBar(context, e.toString(), isError: true);
      }
    }
  }

  Future<void> _addAttachment() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
        withData: kIsWeb,
      );
      if (result == null || result.files.isEmpty) return;

      setState(() => _uploadingAttachment = true);

      for (final picked in result.files) {
        if (!kIsWeb && (picked.path == null || picked.path!.isEmpty)) {
          GlassmorphicUI.showGlassSnackBar(context, 'Could not read file path for ${picked.name}', isError: true);
          continue;
        }
        if (kIsWeb && picked.bytes == null) {
          GlassmorphicUI.showGlassSnackBar(context, 'Could not read file bytes for ${picked.name}', isError: true);
          continue;
        }

        try {
          final attachment = await widget.apiClient.uploadVolunteerAttachment(
            context,
            opportunityId: _opportunity.id,
            filePath: kIsWeb ? null : picked.path,
            webBytes: kIsWeb ? picked.bytes : null,
            fileName: picked.name,
            mimeType: _inferMime(picked),
          );

          if (mounted) {
            setState(() {
              _attachments = [attachment, ..._attachments];
              _opportunity = _opportunity.copyWith(
                attachments: [attachment, ..._opportunity.attachments],
                attachmentCount: _opportunity.attachmentCount + 1,
                coverAttachmentUrl: attachment.isImage ? attachment.fileUrl : _opportunity.coverAttachmentUrl,
              );
            });
          }
        } catch (e) {
          if (mounted) {
            GlassmorphicUI.showGlassSnackBar(context, 'Failed to upload ${picked.name}: $e', isError: true);
          }
        }
      }

      if (mounted) {
        setState(() => _uploadingAttachment = false);
        GlassmorphicUI.showGlassSnackBar(context, 'Attachments updated');
      }
    } catch (e) {
      if (mounted) GlassmorphicUI.showGlassSnackBar(context, e.toString(), isError: true);
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
      case 'pdf':
        return 'application/pdf';
      default:
        return null;
    }
  }

  Future<void> _deleteAttachment(VolunteerAttachment attachment) async {
    try {
      await widget.apiClient.deleteVolunteerAttachment(context, attachmentId: attachment.id);
      if (mounted) {
        setState(() {
          _attachments.removeWhere((a) => a.id == attachment.id);
          _opportunity = _opportunity.copyWith(
            attachments: _attachments,
            attachmentCount: _attachments.length,
          );
        });
        GlassmorphicUI.showGlassSnackBar(context, 'Saved');
      }
    } catch (e) {
      if (mounted) GlassmorphicUI.showGlassSnackBar(context, e.toString(), isError: true);
    }
  }

  Future<void> _saveDetails() async {
    setState(() => _saving = true);
    try {
      await widget.apiClient.updateVolunteerOpportunity(
        context,
        id: _opportunity.id,
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        location: _locationController.text.trim(),
        requiredParticipants: _requiredCtrl.text.isEmpty ? null : int.tryParse(_requiredCtrl.text),
      );
      if (mounted) {
        setState(() {
          _opportunity = _opportunity.copyWith(
            title: _titleController.text.trim(),
            description: _descController.text.trim(),
            location: _locationController.text.trim(),
            requiredParticipants: _requiredCtrl.text.isEmpty ? null : int.tryParse(_requiredCtrl.text),
          );
          _saving = false;
        });
        GlassmorphicUI.showGlassSnackBar(context, 'Saved');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        GlassmorphicUI.showGlassSnackBar(context, e.toString(), isError: true);
      }
    }
  }

  Future<void> _changeRole(VolunteerParticipant p, String role) async {
    try {
      await widget.apiClient.updateParticipantRole(
        context,
        opportunityId: _opportunity.id,
        userId: p.userId,
        role: role,
      );
      if (mounted) {
        GlassmorphicUI.showGlassSnackBar(context, AppLocalizations.of(context)!.participantStatusUpdated);
        _loadParticipants();
      }
    } catch (e) {
      if (mounted) GlassmorphicUI.showGlassSnackBar(context, e.toString(), isError: true);
    }
  }

  Future<void> _changeStatus(VolunteerParticipant p, String status) async {
    try {
      await widget.apiClient.updateParticipantStatus(
        context,
        opportunityId: _opportunity.id,
        userId: p.userId,
        status: status,
      );
      if (mounted) {
        GlassmorphicUI.showGlassSnackBar(context, AppLocalizations.of(context)!.participantStatusUpdated);
        _loadParticipants();
      }
    } catch (e) {
      if (mounted) GlassmorphicUI.showGlassSnackBar(context, e.toString(), isError: true);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _locationController.dispose();
    _requiredCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Theme.of(context).colorScheme.primary, Theme.of(context).colorScheme.secondary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        Scaffold(
          backgroundColor: Colors.transparent,
          body: Column(
                  children: [
                    // Glassy header matching feed/profile style
                    Container(
                      padding: EdgeInsets.only(
                        top: MediaQuery.of(context).padding.top + 8,
                  left: 12,
                  right: 12,
                  bottom: 12,
                ),
                    child: Row(
                      children: [
                        // Back button
                        _headerIconButton(
                          icon: Icons.close,
                          onPressed: () => Navigator.pop(context, _opportunity),
                        ),
                        const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        AppLocalizations.of(context)!.volunteerManageTitle,
                        style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 12),
                    _headerIconButton(
                      icon: _saving ? null : Icons.check,
                      onPressed: _saving ? null : _saveDetails,
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
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 600),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildDetailsCard(context),
                          const SizedBox(height: 16),
                          _buildAttachmentsCard(context),
                          const SizedBox(height: 16),
                          _buildParticipantsCard(context),
                          const SizedBox(height: 100),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _participantStatusLabel(BuildContext context, String status) {
    final l10n = AppLocalizations.of(context)!;
    switch (status) {
      case 'applied':
        return l10n.volunteerApplied;
      case 'approved':
        return l10n.volunteerApproved;
      case 'completed':
        return l10n.volunteerCompleted;
      case 'cancelled':
        return l10n.volunteerCancelled;
      default:
        return status;
    }
  }

  Color _participantStatusColor(String status) {
    switch (status) {
      case 'approved':
        return const Color(0xFF2ECC71);
      case 'applied':
        return const Color(0xFFF39C12);
      case 'completed':
        return const Color(0xFF3498DB);
      case 'cancelled':
        return const Color(0xFFE74C3C);
      default:
        return Colors.grey;
    }
  }

  bool _isSelfWithoutBackupAdmin(VolunteerParticipant participant) {
    if (_currentUserId == null) return false;
    if (participant.userId != _currentUserId || participant.role != 'admin') return false;
    final hasAnotherAdmin = _participants.any(
      (p) => p.userId != participant.userId && p.role == 'admin' && p.status != 'cancelled',
    );
    return !hasAnotherAdmin;
  }

  Widget _glassPanel({
    required Widget child,
    EdgeInsets padding = const EdgeInsets.all(16),
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: double.infinity,
          padding: padding,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.background.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.3)),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _headerIconButton({
    required IconData? icon,
    required VoidCallback? onPressed,
    Widget? child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.background.withOpacity(0.25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.25)),
      ),
      child: IconButton(
        icon: child ??
            Icon(
              icon,
              color: Theme.of(context).colorScheme.onPrimary,
            ),
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildDetailsCard(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return _glassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Activity details',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          // Keep consistent with other pages using outlined text fields.
          const SizedBox(height: 12),
          _buildTextField(l10n.opportunityTitle, _titleController),
          const SizedBox(height: 12),
          _buildTextField(l10n.opportunityDescription, _descController, maxLines: 3),
          const SizedBox(height: 12),
          _buildTextField(l10n.opportunityLocation, _locationController),
          const SizedBox(height: 12),
          _buildTextField(l10n.volunteerRequiredParticipantsOptional, _requiredCtrl, keyboardType: TextInputType.number),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController ctrl, {int maxLines = 1, TextInputType? keyboardType}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.85))),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          maxLines: maxLines,
          keyboardType: keyboardType,
          style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.25)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.25)),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.6)),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _openAttachment(VolunteerAttachment attachment) async {
    final uri = Uri.parse(attachment.fileUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Widget _buildAttachmentsCard(BuildContext context) {
    return _glassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Attachments',
                style: TextStyle(color: Theme.of(context).colorScheme.onPrimary, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: _uploadingAttachment ? null : _addAttachment,
                icon: _uploadingAttachment
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Theme.of(context).colorScheme.onPrimary),
                      )
                    : Icon(Icons.attach_file, color: Theme.of(context).colorScheme.onPrimary),
                label: Text(
                  _uploadingAttachment ? 'Uploading...' : 'Add file',
                  style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_loadingAttachments)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Center(
                child: CircularProgressIndicator(color: Theme.of(context).colorScheme.onPrimary),
              ),
            )
          else if (_attachments.isEmpty)
            Text(
              'No attachments yet',
              style: TextStyle(color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.8)),
            )
          else
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _attachments.map((a) {
                return InkWell(
                  onTap: () => _openAttachment(a),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 170,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.background.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.12)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (a.isImage)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(
                              a.fileUrl,
                              width: double.infinity,
                              height: 90,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                height: 90,
                                color: Colors.white24,
                                child: const Icon(Icons.broken_image),
                              ),
                            ),
                          )
                        else
                          Container(
                            height: 90,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.background.withOpacity(0.18),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: Icon(
                                a.isPdf ? Icons.picture_as_pdf : Icons.insert_drive_file,
                                color: Theme.of(context).colorScheme.onPrimary,
                                size: 32,
                              ),
                            ),
                          ),
                        const SizedBox(height: 8),
                        Text(
                          a.fileName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Theme.of(context).colorScheme.onPrimary, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                        Align(
                          alignment: Alignment.centerRight,
                          child: IconButton(
                            icon: Icon(Icons.delete_outline, color: Colors.red[300]),
                            onPressed: () => _deleteAttachment(a),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildParticipantsCard(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final pending = _participants.where((p) => p.status == 'applied').toList();
    final others = _participants.where((p) => p.status != 'applied').toList();
    return _glassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.volunteerParticipants,
            style: TextStyle(color: Theme.of(context).colorScheme.onPrimary, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          if (_loadingParticipants)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: CircularProgressIndicator(
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
            )
          else if (_participants.isEmpty)
            Text(l10n.noVolunteerActivities, style: TextStyle(color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.8)))
          else ...[
            if (pending.isNotEmpty) ...[
              Text(l10n.volunteerApplied, style: TextStyle(color: Theme.of(context).colorScheme.onPrimary, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              ...pending.map((p) => _buildPendingRow(context, p)),
              const SizedBox(height: 12),
              Divider(color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.2)),
              const SizedBox(height: 12),
            ],
            Text(l10n.volunteerParticipants, style: TextStyle(color: Theme.of(context).colorScheme.onPrimary, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            ...others.map((p) => _buildParticipantRow(context, p)).toList(),
          ],
        ],
      ),
    );
  }

  Widget _buildParticipantRow(BuildContext context, VolunteerParticipant p) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.background.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.12)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: Theme.of(context).colorScheme.background.withOpacity(0.25),
            child: p.userAvatar != null
                ? ClipOval(child: Image.network(p.userAvatar!, width: 32, height: 32, fit: BoxFit.cover))
                : Icon(Icons.person, color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.7), size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p.userName, style: TextStyle(color: Theme.of(context).colorScheme.onPrimary, fontWeight: FontWeight.bold)),
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.background.withOpacity(0.16),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _participantStatusColor(p.status).withOpacity(0.7)),
                  ),
                  child: Text(
                    _participantStatusLabel(context, p.status),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (p.hoursCompleted != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      '${AppLocalizations.of(context)!.hoursCompleted}: ${p.hoursCompleted!.toStringAsFixed(1)}',
                      style: TextStyle(color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.7), fontSize: 12),
                    ),
                  ),
              ],
            ),
          ),
          _buildRoleSelector(context, p),
        ],
      ),
    );
  }

  Widget _buildPendingRow(BuildContext context, VolunteerParticipant p) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.background.withOpacity(0.14),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.15)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: Theme.of(context).colorScheme.background.withOpacity(0.25),
                child: p.userAvatar != null
                    ? ClipOval(child: Image.network(p.userAvatar!, width: 32, height: 32, fit: BoxFit.cover))
                    : Icon(Icons.person, color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.7), size: 16),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  p.userName,
                  style: TextStyle(color: Theme.of(context).colorScheme.onPrimary, fontWeight: FontWeight.bold),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.background.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.orangeAccent.withOpacity(0.7)),
                ),
                child: Text(
                  AppLocalizations.of(context)!.volunteerApplied,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _changeStatus(p, 'approved'),
                  icon: const Icon(Icons.check, size: 16),
                  label: Text(AppLocalizations.of(context)!.approveParticipant),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _changeStatus(p, 'cancelled'),
                  icon: const Icon(Icons.close, size: 16),
                  label: Text(AppLocalizations.of(context)!.rejectParticipant),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRoleSelector(BuildContext context, VolunteerParticipant p) {
    final roleLabel = _roleLabel(p.role);
    final isLocked = _isSelfWithoutBackupAdmin(p);
    final roleButton = ElevatedButton.icon(
      onPressed: isLocked ? null : () => _openRoleSelector(context, p),
      icon: const Icon(Icons.manage_accounts, size: 18),
      label: Text(roleLabel, style: const TextStyle(fontWeight: FontWeight.w700)),
      style: ElevatedButton.styleFrom(
        backgroundColor: Theme.of(context).colorScheme.background.withOpacity(0.18),
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.3)),
        ),
        elevation: 0,
        disabledBackgroundColor: Theme.of(context).colorScheme.background.withOpacity(0.12),
        disabledForegroundColor: Theme.of(context).colorScheme.onPrimary.withOpacity(0.5),
      ),
    );

    return Align(
      alignment: Alignment.centerRight,
      child: isLocked
          ? Tooltip(
              message: 'Add another admin before changing your role',
              child: roleButton,
            )
          : roleButton,
    );
  }

  String _roleLabel(String? role) {
    switch (role) {
      case 'admin':
        return AppLocalizations.of(context)!.volunteerRoleAdmin;
      case 'coordinator':
        return AppLocalizations.of(context)!.volunteerRoleCoordinator;
      case 'member':
      default:
        return AppLocalizations.of(context)!.volunteerRoleMember;
    }
  }

  Future<void> _openRoleSelector(BuildContext context, VolunteerParticipant p) async {
    if (_isSelfWithoutBackupAdmin(p)) {
      GlassmorphicUI.showGlassSnackBar(
        context,
        'Add another admin before changing your role',
        isError: true,
      );
      return;
    }

    final roles = [
      {'value': 'member', 'label': AppLocalizations.of(context)!.volunteerRoleMember},
      {'value': 'coordinator', 'label': AppLocalizations.of(context)!.volunteerRoleCoordinator},
      {'value': 'admin', 'label': AppLocalizations.of(context)!.volunteerRoleAdmin},
    ];
    final current = p.role ?? 'member';

    final selected = await GlassmorphicUI.showDialog<String>(
      context: context,
      width: 320,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            child: Text(
              AppLocalizations.of(context)!.role,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          ...roles.map((role) {
            final isSelected = role['value'] == current;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => Navigator.of(context).pop(role['value'] as String),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          role['label'] as String,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isSelected)
                        Icon(
                          Icons.check,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
          const SizedBox(height: 12),
        ],
      ),
    );

    if (selected != null && selected != current) {
      _changeRole(p, selected);
    }
  }
}
