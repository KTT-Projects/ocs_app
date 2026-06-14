import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/app_localizations.dart';
import '../models/opportunity_experience.dart';
import '../models/volunteer_attachment.dart';
import '../models/volunteer_opportunity.dart';
import '../models/volunteer_participant.dart';
import '../models/volunteer_reflection.dart';
import '../services/api_client.dart';
import '../widgets/glassmorphic_ui.dart';
import '../widgets/report_content_dialog.dart';
import 'full_screen_image_page.dart';
import 'volunteer_admin_page.dart';
import 'volunteer_reflection_view_page.dart';

class VolunteerOpportunityDetailsPage extends StatefulWidget {
  final ApiClient apiClient;
  final VolunteerOpportunity opportunity;
  final OpportunityExperience experience;

  const VolunteerOpportunityDetailsPage({
    super.key,
    required this.apiClient,
    required this.opportunity,
    this.experience = OpportunityExperience.volunteer,
  });

  @override
  State<VolunteerOpportunityDetailsPage> createState() =>
      _VolunteerOpportunityDetailsPageState();
}

class _VolunteerOpportunityDetailsPageState
    extends State<VolunteerOpportunityDetailsPage> {
  bool _isLoading = false;
  bool _didLoadParticipants = false;
  List<VolunteerParticipant>? _participants;
  late VolunteerOpportunity _opportunity;
  bool _isOrganizer = false;
  bool _didLoadAttachments = false;
  bool _loadingAttachments = false;
  List<VolunteerAttachment> _attachments = [];
  bool _loadingReflections = false;
  bool _didLoadReflections = false;
  List<VolunteerReflectionImage> _reflectionImages = [];
  bool get _canViewParticipants =>
      _opportunity.isParticipant ||
      _isOrganizer ||
      _opportunity.canManageParticipants;

  @override
  void initState() {
    super.initState();
    _opportunity = widget.opportunity;
    _attachments = widget.opportunity.attachments;
    _checkOrganizerStatus();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didLoadParticipants && _canViewParticipants) {
      _didLoadParticipants = true;
      _loadParticipants();
    }
    if (!_didLoadAttachments) {
      _didLoadAttachments = true;
      _loadAttachments();
    }
    if (!_didLoadReflections) {
      _didLoadReflections = true;
      _loadReflectionPreview();
    }
  }

  Future<void> _checkOrganizerStatus() async {
    try {
      final userId = await widget.apiClient.getCurrentUserId(context);
      if (userId != null) {
        setState(() {
          _isOrganizer = _opportunity.isOrganizer(userId);
          if (_isOrganizer && _opportunity.participantRole != 'admin') {
            _opportunity = _opportunity.copyWith(participantRole: 'admin');
          }
        });
        if (_isOrganizer && !_didLoadParticipants) {
          _didLoadParticipants = true;
          _loadParticipants();
        }
      }
    } catch (e) {
      // Ignore errors in organizer check
    }
  }

  Future<void> _loadParticipants() async {
    if (!_canViewParticipants) return;
    try {
      setState(() => _isLoading = true);
      final participants = await widget.apiClient.getVolunteerParticipants(
        context,
        _opportunity.id,
      );
      if (mounted) {
        setState(() {
          _participants = participants;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        GlassmorphicUI.showGlassSnackBar(
          context,
          e.toString(),
          isError: true,
        );
      }
    }
  }

  Future<void> _loadAttachments() async {
    try {
      setState(() => _loadingAttachments = true);
      final items = await widget.apiClient
          .getVolunteerAttachments(context, _opportunity.id);
      if (mounted) {
        VolunteerAttachment? firstImage;
        for (final a in items) {
          if (a.isImage) {
            firstImage = a;
            break;
          }
        }
        setState(() {
          _attachments = items;
          _opportunity = _opportunity.copyWith(
            attachments: items,
            attachmentCount: items.length,
            coverAttachmentUrl: firstImage != null && firstImage.isImage
                ? firstImage.fileUrl
                : _opportunity.coverAttachmentUrl,
          );
          _loadingAttachments = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingAttachments = false);
        GlassmorphicUI.showGlassSnackBar(
          context,
          e.toString(),
          isError: true,
        );
      }
    }
  }

  Future<void> _loadReflectionPreview() async {
    try {
      setState(() => _loadingReflections = true);
      final reflections = await widget.apiClient.getVolunteerReflections(
        context,
        _opportunity.id,
      );
      if (!mounted) return;
      final latest = reflections.isNotEmpty ? reflections.first : null;
      setState(() {
        _loadingReflections = false;
        _reflectionImages = latest?.images ?? [];
        if (latest != null) {
          _opportunity = _opportunity.copyWith(
            reflectionCount: 1,
            latestReflectionAt: latest.createdAt,
            latestReflectionTitle: latest.title,
            latestReflectionExcerpt: latest.body,
            latestReflectionImages: latest.images,
            status: 'completed',
          );
        }
      });
    } catch (_) {
      if (mounted) setState(() => _loadingReflections = false);
      // Soft-fail; reflection preview is not critical for the details page.
    }
  }

  Future<void> _applyToOpportunity() async {
    final appliedMessage = widget.experience.applied(context);
    try {
      setState(() => _isLoading = true);
      await widget.apiClient
          .applyToVolunteerOpportunity(context, _opportunity.id);

      if (mounted) {
        final newCount = _opportunity.participantCount + 1;
        int? newSpots;
        var isNowFull = _opportunity.isFull;
        if (_opportunity.requiredParticipants != null) {
          newSpots = _opportunity.requiredParticipants! - newCount;
          if (newSpots < 0) newSpots = 0;
          isNowFull =
              isNowFull || newCount >= _opportunity.requiredParticipants!;
        }
        setState(() {
          _opportunity = _opportunity.copyWith(
            isParticipant: true,
            participantStatus: 'applied',
            participantCount: newCount,
            spotsRemaining: newSpots ?? _opportunity.spotsRemaining,
            isFull: isNowFull,
          );
          _isLoading = false;
        });

        GlassmorphicUI.showGlassSnackBar(
          context,
          appliedMessage,
        );

        _loadParticipants();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        GlassmorphicUI.showGlassSnackBar(
          context,
          e.toString(),
          isError: true,
        );
      }
    }
  }

  Future<void> _cancelApplication() async {
    try {
      setState(() => _isLoading = true);
      await widget.apiClient
          .cancelVolunteerApplication(context, _opportunity.id);

      if (mounted) {
        final newCount = (_opportunity.participantCount - 1) < 0
            ? 0
            : _opportunity.participantCount - 1;
        int? newSpots = _opportunity.spotsRemaining;
        if (_opportunity.requiredParticipants != null) {
          newSpots = _opportunity.requiredParticipants! - newCount;
          if (newSpots < 0) newSpots = 0;
        }
        setState(() {
          _opportunity = _opportunity.copyWith(
            isParticipant: true,
            participantStatus: 'cancelled',
            participantCount: newCount,
            spotsRemaining: newSpots,
            isFull: false,
          );
          _isLoading = false;
        });

        GlassmorphicUI.showGlassSnackBar(
          context,
          AppLocalizations.of(context)!.applicationCancelled,
        );

        _loadParticipants();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        GlassmorphicUI.showGlassSnackBar(
          context,
          e.toString(),
          isError: true,
        );
      }
    }
  }

  Future<void> _updateParticipantStatus(
      int participantUserId, String status) async {
    try {
      setState(() => _isLoading = true);
      await widget.apiClient.updateParticipantStatus(
        context,
        opportunityId: _opportunity.id,
        userId: participantUserId,
        status: status,
      );

      if (mounted) {
        GlassmorphicUI.showGlassSnackBar(
          context,
          AppLocalizations.of(context)!.participantStatusUpdated,
        );
        _loadParticipants();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        GlassmorphicUI.showGlassSnackBar(
          context,
          e.toString(),
          isError: true,
        );
      }
    }
  }

  String _getStatusText(String status) {
    final l10n = AppLocalizations.of(context)!;
    switch (status) {
      case 'open':
        return l10n.opportunityOpen;
      case 'filled':
        return l10n.opportunityFilled;
      case 'completed':
        return l10n.volunteerCompleted;
      case 'cancelled':
        return l10n.volunteerCancelled;
      default:
        return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'open':
        return Colors.green;
      case 'filled':
        return Colors.orange;
      case 'completed':
        return Colors.blue;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _availabilityLabel() {
    final l10n = AppLocalizations.of(context)!;
    if (_opportunity.requiredParticipants == null) {
      return widget.experience.unlimited(context);
    }
    if (_opportunity.isFull || _opportunity.spotsRemaining == 0) {
      return l10n.opportunityFilled;
    }
    final remaining = _opportunity.spotsRemaining ??
        (_opportunity.requiredParticipants! - _opportunity.participantCount);
    final safeRemaining = remaining < 0 ? 0 : remaining;
    return widget.experience.spotsRemaining(context, safeRemaining);
  }

  Color _availabilityColor() {
    if (_opportunity.isFull || _opportunity.spotsRemaining == 0) {
      return Colors.redAccent;
    }
    if (_opportunity.requiredParticipants == null) {
      return Colors.blueAccent;
    }
    return Colors.green;
  }

  String _participantStatusText(String status) {
    final l10n = AppLocalizations.of(context)!;
    switch (status) {
      case 'applied':
        return widget.experience.applied(context);
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

  Future<void> _openLink(LinkableElement link) async {
    final uri = Uri.parse(link.url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _openAttachment(VolunteerAttachment attachment) async {
    if (attachment.isImage) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => FullScreenImagePage(imageUrl: attachment.fileUrl),
        ),
      );
      return;
    }

    final uri = Uri.parse(attachment.fileUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (!mounted) return;
      GlassmorphicUI.showGlassSnackBar(
        context,
        AppLocalizations.of(context)!.errorOccurred,
        isError: true,
      );
    }
  }

  Future<void> _reportOpportunity() async {
    final result = await GlassmorphicUI.showDialog<ReportContentResult>(
      context: context,
      width: 360,
      child: const ReportContentDialog(),
    );
    if (result == null || !mounted) return;

    try {
      await widget.apiClient.reportContent(
        context,
        entityType: 'volunteer_opportunity',
        entityId: _opportunity.id,
        reason: result.reason,
        details: result.details,
      );
      if (!mounted) return;
      GlassmorphicUI.showGlassSnackBar(context, 'Report submitted');
    } catch (e) {
      if (!mounted) return;
      GlassmorphicUI.showGlassSnackBar(
        context,
        e.toString(),
        isError: true,
      );
    }
  }

  Future<void> _openReflections() async {
    final updated = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VolunteerReflectionViewPage(
          apiClient: widget.apiClient,
          opportunity: _opportunity,
          experience: widget.experience,
        ),
      ),
    );
    if (updated is VolunteerOpportunity && mounted) {
      setState(() => _opportunity = updated);
    }
  }

  Widget _glassCard({
    required Widget child,
    EdgeInsets padding = const EdgeInsets.all(24),
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: double.infinity,
          padding: padding,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.background.withOpacity(0.2),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.3),
            ),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildReflectionPreview(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final hasReflection = _opportunity.reflectionCount > 0 ||
        _opportunity.latestReflectionAt != null;
    final latestTitle =
        _opportunity.latestReflectionTitle?.trim().isNotEmpty == true
            ? _opportunity.latestReflectionTitle!
            : l10n.recentReflection;
    final latestExcerpt = _opportunity.latestReflectionExcerpt ?? '';
    final dateText = _opportunity.latestReflectionAt != null
        ? DateFormat.yMMMd(Localizations.localeOf(context).languageCode)
            .format(_opportunity.latestReflectionAt!)
        : null;

    return _glassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_stories,
                  color: Theme.of(context).colorScheme.onPrimary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.reflectionBodyLabel,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (!hasReflection) ...[
            Text(
              l10n.noReflectionsYet,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              l10n.noReflectionsHint,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.8),
              ),
            ),
          ] else ...[
            Text(
              latestTitle,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (dateText != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  dateText,
                  style: TextStyle(
                    color: Theme.of(context)
                        .colorScheme
                        .onPrimary
                        .withOpacity(0.75),
                    fontSize: 12,
                  ),
                ),
              ),
            const SizedBox(height: 6),
            Text(
              latestExcerpt,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onPrimary,
                height: 1.4,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            if (_reflectionImages.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _reflectionImages
                    .map(
                      (img) => ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(
                          img.fileUrl,
                          width: 64,
                          height: 64,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 64,
                            height: 64,
                            color: Colors.white24,
                            child: const Icon(Icons.broken_image, size: 18),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
          ],
          if (hasReflection) ...[
            const SizedBox(height: 14),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton.icon(
                onPressed: _openReflections,
                icon: Icon(Icons.chrome_reader_mode,
                    color: Theme.of(context).colorScheme.onPrimary),
                label: Text(
                  l10n.readFullReflection,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    color: Theme.of(context)
                        .colorScheme
                        .onPrimary
                        .withOpacity(0.4),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButton() {
    final l10n = AppLocalizations.of(context)!;

    if (_isLoading) {
      return const SizedBox(
        height: 48,
        child: Center(
          child: SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: Colors.white,
            ),
          ),
        ),
      );
    }

    final isOrganizerView = _isOrganizer || _opportunity.canManageDetails;

    if (isOrganizerView) {
      return OutlinedButton.icon(
        onPressed: null,
        icon: const Icon(Icons.verified_user, color: Colors.white),
        label: Text(
          l10n.volunteerOrganizer,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Colors.white70),
          minimumSize: const Size.fromHeight(48),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          disabledForegroundColor: Colors.white,
          disabledBackgroundColor: Colors.white.withOpacity(0.06),
        ),
      );
    }

    // Handle cancelled applications - allow reapplication
    if (_opportunity.isParticipant &&
        _opportunity.participantStatus == 'cancelled') {
      if (_opportunity.canApply) {
        return ElevatedButton(
          onPressed: _applyToOpportunity,
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.secondary,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            minimumSize: const Size.fromHeight(48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25),
            ),
          ),
          child: Text(
            widget.experience.apply(context),
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSecondary,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      }
    }

    if (_opportunity.isParticipant &&
        _opportunity.participantStatus != 'cancelled') {
      return Column(
        children: [
          SizedBox(
            height: 48,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.2),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: Colors.green),
              ),
              child: Center(
                child: Text(
                  _opportunity.participantStatus == 'applied'
                      ? widget.experience.applied(context)
                      : _opportunity.participantStatus == 'approved'
                          ? l10n.volunteerApproved
                          : _opportunity.participantStatus == 'completed'
                              ? l10n.volunteerCompleted
                              : l10n.volunteerCancelled,
                  style: const TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          if (_opportunity.participantStatus == 'applied') ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: _cancelApplication,
              child: Text(
                l10n.cancelApplication,
                style: TextStyle(color: Colors.red[300]),
              ),
            ),
          ],
        ],
      );
    }

    if (!_opportunity.canApply) {
      return SizedBox(
        height: 48,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.2),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(color: Colors.grey),
          ),
          child: Center(
            child: Text(
              _opportunity.isFilled
                  ? l10n.opportunityFilled
                  : _getStatusText(_opportunity.status),
              style: const TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      );
    }

    return ElevatedButton(
      onPressed: _applyToOpportunity,
      style: ElevatedButton.styleFrom(
        backgroundColor: Theme.of(context).colorScheme.secondary,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(25),
        ),
      ),
      child: Text(
        widget.experience.apply(context),
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSecondary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final dateFormat =
        DateFormat.yMMMMd(Localizations.localeOf(context).languageCode);

    return Stack(
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
        Scaffold(
          backgroundColor: Colors.transparent,
          body: Column(
            children: [
              Container(
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 8,
                  left: 12,
                  right: 12,
                  bottom: 12,
                ),
                child: Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .background
                            .withOpacity(0.25),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: Theme.of(context)
                                .colorScheme
                                .onPrimary
                                .withOpacity(0.25)),
                      ),
                      child: IconButton(
                        icon: Icon(Icons.arrow_back,
                            color: Theme.of(context).colorScheme.onPrimary),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _opportunity.title,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w700),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .background
                            .withOpacity(0.25),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Theme.of(context)
                              .colorScheme
                              .onPrimary
                              .withOpacity(0.25),
                        ),
                      ),
                      child: IconButton(
                        tooltip: 'Report',
                        icon: Icon(
                          Icons.flag_outlined,
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                        onPressed: _reportOpportunity,
                      ),
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
                          _glassCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 20,
                                      backgroundColor: Theme.of(context)
                                          .colorScheme
                                          .background
                                          .withOpacity(0.25),
                                      child: _opportunity.organizerAvatar !=
                                              null
                                          ? ClipOval(
                                              child: Image.network(
                                                _opportunity.organizerAvatar!,
                                                width: 40,
                                                height: 40,
                                                fit: BoxFit.cover,
                                              ),
                                            )
                                          : Icon(
                                              Icons.person,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onPrimary
                                                  .withOpacity(0.7),
                                            ),
                                    ),
                                    const SizedBox(width: 12),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          l10n.volunteerOrganizer,
                                          style: TextStyle(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onPrimary
                                                .withOpacity(0.7),
                                            fontSize: 12,
                                          ),
                                        ),
                                        Text(
                                          _opportunity.organizerName ??
                                              'Unknown',
                                          style: TextStyle(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onPrimary,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const Spacer(),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .background
                                            .withOpacity(0.18),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                            color: _getStatusColor(
                                                _opportunity.status)),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(Icons.event_available,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onPrimary
                                                  .withOpacity(0.9),
                                              size: 16),
                                          const SizedBox(width: 6),
                                          Text(
                                            _getStatusText(_opportunity.status),
                                            style: TextStyle(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onPrimary,
                                                fontWeight: FontWeight.w700,
                                                fontSize: 12),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 18),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.location_on,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onPrimary
                                                    .withOpacity(0.7),
                                                size: 16,
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                l10n.opportunityLocation,
                                                style: TextStyle(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onPrimary
                                                      .withOpacity(0.7),
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            _opportunity.location,
                                            style: TextStyle(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onPrimary,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.people,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onPrimary
                                                    .withOpacity(0.7),
                                                size: 16,
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                widget.experience
                                                    .participants(context),
                                                style: TextStyle(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onPrimary
                                                      .withOpacity(0.7),
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            _opportunity.requiredParticipants !=
                                                    null
                                                ? '${_opportunity.participantCount}/${_opportunity.requiredParticipants}'
                                                : _opportunity.participantCount
                                                    .toString(),
                                            style: TextStyle(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onPrimary,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 10, vertical: 6),
                                            decoration: BoxDecoration(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .background
                                                  .withOpacity(0.16),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              border: Border.all(
                                                  color: _availabilityColor()
                                                      .withOpacity(0.8)),
                                            ),
                                            child: Text(
                                              _availabilityLabel(),
                                              style: TextStyle(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onPrimary,
                                                fontWeight: FontWeight.w700,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.calendar_today,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onPrimary
                                              .withOpacity(0.7),
                                          size: 16,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          l10n.eventDate,
                                          style: TextStyle(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onPrimary
                                                .withOpacity(0.7),
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      dateFormat.format(_opportunity.date),
                                      style: TextStyle(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onPrimary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    if (_opportunity.startTime != null &&
                                        _opportunity.endTime != null)
                                      Text(
                                        '${DateFormat('HH:mm').format(_opportunity.startTime!)} - ${DateFormat('HH:mm').format(_opportunity.endTime!)}',
                                        style: TextStyle(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onPrimary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                  ],
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(top: 16),
                                  child: Row(
                                    children: [
                                      Expanded(child: _buildActionButton()),
                                      if (_isOrganizer ||
                                          _opportunity.canManageDetails ||
                                          _opportunity
                                              .canManageParticipants) ...[
                                        const SizedBox(width: 8),
                                        OutlinedButton.icon(
                                          onPressed: () async {
                                            final updated =
                                                await Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    VolunteerAdminPage(
                                                  apiClient: widget.apiClient,
                                                  opportunity: _opportunity,
                                                  experience: widget.experience,
                                                ),
                                              ),
                                            );
                                            if (updated
                                                    is VolunteerOpportunity &&
                                                mounted) {
                                              setState(
                                                  () => _opportunity = updated);
                                            }
                                          },
                                          icon: Icon(Icons.admin_panel_settings,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onPrimary),
                                          label: Text(
                                            'Manage',
                                            style: TextStyle(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onPrimary,
                                                fontWeight: FontWeight.bold),
                                          ),
                                          style: OutlinedButton.styleFrom(
                                            side: BorderSide(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onPrimary
                                                    .withOpacity(0.7)),
                                            minimumSize: const Size(140, 48),
                                            shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(24)),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          _glassCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.opportunityDescription,
                                  style: TextStyle(
                                    color:
                                        Theme.of(context).colorScheme.onPrimary,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Linkify(
                                  text: _opportunity.description,
                                  style: TextStyle(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onPrimary
                                        .withOpacity(0.9),
                                    fontSize: 16,
                                    height: 1.5,
                                  ),
                                  linkStyle: TextStyle(
                                    color:
                                        Theme.of(context).colorScheme.secondary,
                                    decoration: TextDecoration.underline,
                                  ),
                                  onOpen: _openLink,
                                ),
                              ],
                            ),
                          ),
                          if (_loadingAttachments) ...[
                            const SizedBox(height: 16),
                            Center(
                              child: SizedBox(
                                width: 28,
                                height: 28,
                                child: CircularProgressIndicator(
                                  strokeWidth: 3,
                                  color:
                                      Theme.of(context).colorScheme.onPrimary,
                                ),
                              ),
                            ),
                          ] else if (_attachments.isNotEmpty) ...[
                            const SizedBox(height: 24),
                            _glassCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.attachment,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onPrimary),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Attachments',
                                        style: TextStyle(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onPrimary,
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const Spacer(),
                                      if (_attachments.isNotEmpty)
                                        Text(
                                          '${_attachments.length}',
                                          style: TextStyle(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onPrimary
                                                  .withOpacity(0.7)),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Wrap(
                                    spacing: 12,
                                    runSpacing: 12,
                                    children: [
                                      ..._attachments
                                          .where((a) => a.isImage)
                                          .map(
                                            (a) => GestureDetector(
                                              onTap: () => _openAttachment(a),
                                              child: ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                child: Hero(
                                                  tag: a.fileUrl,
                                                  child: Image.network(
                                                    a.fileUrl,
                                                    width: 110,
                                                    height: 110,
                                                    fit: BoxFit.cover,
                                                    errorBuilder:
                                                        (_, __, ___) =>
                                                            Container(
                                                      width: 110,
                                                      height: 110,
                                                      color: Colors.white24,
                                                      child: const Icon(
                                                          Icons.broken_image),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                      ..._attachments
                                          .where((a) => !a.isImage)
                                          .map(
                                            (a) => InkWell(
                                              onTap: () => _openAttachment(a),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              child: Container(
                                                width: 220,
                                                padding:
                                                    const EdgeInsets.all(12),
                                                decoration: BoxDecoration(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .background
                                                      .withOpacity(0.12),
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  border: Border.all(
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .onPrimary
                                                          .withOpacity(0.12)),
                                                ),
                                                child: Row(
                                                  children: [
                                                    Icon(
                                                      a.isPdf
                                                          ? Icons.picture_as_pdf
                                                          : Icons
                                                              .insert_drive_file,
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .onPrimary,
                                                    ),
                                                    const SizedBox(width: 12),
                                                    Expanded(
                                                      child: Text(
                                                        a.fileName,
                                                        style: TextStyle(
                                                          color:
                                                              Theme.of(context)
                                                                  .colorScheme
                                                                  .onPrimary,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                        maxLines: 2,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 24),
                          _buildReflectionPreview(context),
                          if (_participants != null &&
                              _participants!.isNotEmpty) ...[
                            const SizedBox(height: 24),
                            _glassCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${widget.experience.participants(context)} (${_participants!.length})',
                                    style: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onPrimary,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  ..._participants!
                                      .map((participant) => Padding(
                                            padding: const EdgeInsets.only(
                                                bottom: 12),
                                            child: Container(
                                              padding: const EdgeInsets.all(12),
                                              decoration: BoxDecoration(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .background
                                                    .withOpacity(0.12),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                border: Border.all(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onPrimary
                                                      .withOpacity(0.12),
                                                ),
                                              ),
                                              child: Column(
                                                children: [
                                                  Row(
                                                    children: [
                                                      CircleAvatar(
                                                        radius: 16,
                                                        backgroundColor:
                                                            Theme.of(context)
                                                                .colorScheme
                                                                .background
                                                                .withOpacity(
                                                                    0.25),
                                                        child: participant
                                                                    .userAvatar !=
                                                                null
                                                            ? ClipOval(
                                                                child: Image
                                                                    .network(
                                                                  participant
                                                                      .userAvatar!,
                                                                  width: 32,
                                                                  height: 32,
                                                                  fit: BoxFit
                                                                      .cover,
                                                                ),
                                                              )
                                                            : Icon(
                                                                Icons.person,
                                                                color: Theme.of(
                                                                        context)
                                                                    .colorScheme
                                                                    .onPrimary
                                                                    .withOpacity(
                                                                        0.7),
                                                                size: 16,
                                                              ),
                                                      ),
                                                      const SizedBox(width: 12),
                                                      Expanded(
                                                        child: Text(
                                                          participant.userName,
                                                          style: TextStyle(
                                                            color: Theme.of(
                                                                    context)
                                                                .colorScheme
                                                                .onPrimary,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                        ),
                                                      ),
                                                      Container(
                                                        padding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                                horizontal: 8,
                                                                vertical: 4),
                                                        decoration:
                                                            BoxDecoration(
                                                          color:
                                                              Theme.of(context)
                                                                  .colorScheme
                                                                  .background
                                                                  .withOpacity(
                                                                      0.16),
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(10),
                                                          border: Border.all(
                                                              color: _participantStatusColor(
                                                                      participant
                                                                          .status)
                                                                  .withOpacity(
                                                                      0.7)),
                                                        ),
                                                        child: Text(
                                                          _participantStatusText(
                                                              participant
                                                                  .status),
                                                          style: TextStyle(
                                                            color: Theme.of(
                                                                    context)
                                                                .colorScheme
                                                                .onPrimary,
                                                            fontSize: 12,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 6),
                                                  Row(
                                                    children: [
                                                      if (participant.role !=
                                                              null &&
                                                          participant
                                                              .role!.isNotEmpty)
                                                        Container(
                                                          padding:
                                                              const EdgeInsets
                                                                  .symmetric(
                                                                  horizontal: 8,
                                                                  vertical: 4),
                                                          margin:
                                                              const EdgeInsets
                                                                  .only(
                                                                  right: 8),
                                                          decoration:
                                                              BoxDecoration(
                                                            color: Theme.of(
                                                                    context)
                                                                .colorScheme
                                                                .background
                                                                .withOpacity(
                                                                    0.1),
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        10),
                                                            border: Border.all(
                                                                color: Theme.of(
                                                                        context)
                                                                    .colorScheme
                                                                    .onPrimary
                                                                    .withOpacity(
                                                                        0.15)),
                                                          ),
                                                          child: Text(
                                                            '${AppLocalizations.of(context)!.role}: ${participant.role}',
                                                            style: TextStyle(
                                                                color: Theme.of(
                                                                        context)
                                                                    .colorScheme
                                                                    .onPrimary
                                                                    .withOpacity(
                                                                        0.9),
                                                                fontSize: 12),
                                                          ),
                                                        ),
                                                      if (participant
                                                              .hoursCompleted !=
                                                          null)
                                                        Container(
                                                          padding:
                                                              const EdgeInsets
                                                                  .symmetric(
                                                                  horizontal: 8,
                                                                  vertical: 4),
                                                          decoration:
                                                              BoxDecoration(
                                                            color: Theme.of(
                                                                    context)
                                                                .colorScheme
                                                                .background
                                                                .withOpacity(
                                                                    0.1),
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        10),
                                                            border: Border.all(
                                                                color: Theme.of(
                                                                        context)
                                                                    .colorScheme
                                                                    .onPrimary
                                                                    .withOpacity(
                                                                        0.15)),
                                                          ),
                                                          child: Text(
                                                            '${AppLocalizations.of(context)!.hoursCompleted}: ${participant.hoursCompleted!.toStringAsFixed(1)}',
                                                            style: TextStyle(
                                                                color: Theme.of(
                                                                        context)
                                                                    .colorScheme
                                                                    .onPrimary
                                                                    .withOpacity(
                                                                        0.9),
                                                                fontSize: 12),
                                                          ),
                                                        ),
                                                      if (participant
                                                          .certificateIssued) ...[
                                                        const SizedBox(
                                                            width: 8),
                                                        Icon(Icons.verified,
                                                            color: Colors
                                                                .lightGreenAccent
                                                                .shade100,
                                                            size: 18),
                                                      ],
                                                    ],
                                                  ),
                                                  if (_isOrganizer &&
                                                      participant.status ==
                                                          'applied') ...[
                                                    const SizedBox(height: 8),
                                                    Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .spaceEvenly,
                                                      children: [
                                                        Expanded(
                                                          child: ElevatedButton
                                                              .icon(
                                                            onPressed: () =>
                                                                _updateParticipantStatus(
                                                                    participant
                                                                        .userId,
                                                                    'approved'),
                                                            icon: const Icon(
                                                                Icons.check,
                                                                size: 16),
                                                            label: Text(l10n
                                                                .approveParticipant),
                                                            style:
                                                                ElevatedButton
                                                                    .styleFrom(
                                                              backgroundColor:
                                                                  Colors.green,
                                                              foregroundColor:
                                                                  Colors.white,
                                                              padding:
                                                                  const EdgeInsets
                                                                      .symmetric(
                                                                      vertical:
                                                                          8),
                                                              shape: RoundedRectangleBorder(
                                                                  borderRadius:
                                                                      BorderRadius
                                                                          .circular(
                                                                              12)),
                                                            ),
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                            width: 8),
                                                        Expanded(
                                                          child: ElevatedButton
                                                              .icon(
                                                            onPressed: () =>
                                                                _updateParticipantStatus(
                                                                    participant
                                                                        .userId,
                                                                    'cancelled'),
                                                            icon: const Icon(
                                                                Icons.close,
                                                                size: 16),
                                                            label: Text(l10n
                                                                .rejectParticipant),
                                                            style:
                                                                ElevatedButton
                                                                    .styleFrom(
                                                              backgroundColor:
                                                                  Colors.red,
                                                              foregroundColor:
                                                                  Colors.white,
                                                              padding:
                                                                  const EdgeInsets
                                                                      .symmetric(
                                                                      vertical:
                                                                          8),
                                                              shape: RoundedRectangleBorder(
                                                                  borderRadius:
                                                                      BorderRadius
                                                                          .circular(
                                                                              12)),
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ],
                                              ),
                                            ),
                                          ))
                                      .toList(),
                                ],
                              ),
                            ),
                          ],
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
}
