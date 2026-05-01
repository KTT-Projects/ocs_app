import 'package:flutter/material.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:ui';
import '../models/opportunity_experience.dart';
import '../models/volunteer_opportunity.dart';
import '../models/volunteer_reflection.dart';
import '../pages/volunteer_opportunity_details_page.dart';
import '../pages/volunteer_admin_page.dart';
import '../pages/volunteer_reflection_view_page.dart';
import '../services/api_client.dart';
import '../l10n/app_localizations.dart';
import '../widgets/glassmorphic_ui.dart';

class VolunteerOpportunityListItem extends StatelessWidget {
  final VolunteerOpportunity opportunity;
  final VoidCallback? onTap;
  final bool showFullDetails;
  final bool showDescription;
  final ApiClient? apiClient;
  final OpportunityExperience experience;
  final Function(VolunteerOpportunity)? onOpportunityUpdated;

  const VolunteerOpportunityListItem({
    Key? key,
    required this.opportunity,
    this.onTap,
    this.showFullDetails = true,
    this.showDescription = true,
    this.apiClient,
    this.experience = OpportunityExperience.volunteer,
    this.onOpportunityUpdated,
  }) : super(key: key);

  String _getStatusText(BuildContext context, String status) {
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

  Color _getStatusColor(BuildContext context, String status) {
    switch (status) {
      case 'open':
        return Colors.green;
      case 'filled':
        return Colors.orange;
      case 'completed':
        return Colors.blue;
      case 'cancelled':
        return Colors.grey;
      default:
        return Theme.of(context).colorScheme.primary;
    }
  }

  String _getParticipantStatusText(BuildContext context, String status) {
    final l10n = AppLocalizations.of(context)!;
    switch (status) {
      case 'applied':
        return experience.applied(context);
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

  Color _getParticipantStatusColor(String status) {
    switch (status) {
      case 'applied':
        return Colors.orange;
      case 'approved':
        return Colors.green;
      case 'completed':
        return Colors.blue;
      case 'cancelled':
        return Colors.grey;
      default:
        return Colors.blueGrey;
    }
  }

  String _formatDate(BuildContext context, DateTime date) {
    final l10n = AppLocalizations.of(context)!;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final inputDate = DateTime(date.year, date.month, date.day);

    if (inputDate == today) {
      return l10n.today;
    } else if (inputDate == tomorrow) {
      return l10n.tomorrow;
    } else {
      return DateFormat.Md(Localizations.localeOf(context).languageCode)
          .format(date);
    }
  }

  String _formatTimeRange(VolunteerOpportunity opportunity) {
    if (opportunity.startTime != null && opportunity.endTime != null) {
      final startTime = DateFormat('HH:mm').format(opportunity.startTime!);
      final endTime = DateFormat('HH:mm').format(opportunity.endTime!);
      return '$startTime - $endTime';
    }
    return '';
  }

  String _availabilityLabel(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (opportunity.requiredParticipants == null) {
      return experience.unlimited(context);
    }

    if (opportunity.isFull || opportunity.spotsRemaining == 0) {
      return l10n.opportunityFilled;
    }

    final remaining = opportunity.spotsRemaining ??
        (opportunity.requiredParticipants! - opportunity.participantCount);
    final safeRemaining = remaining < 0 ? 0 : remaining;
    return experience.spotsRemaining(context, safeRemaining);
  }

  Color _availabilityColor(BuildContext context) {
    if (opportunity.isFull || opportunity.spotsRemaining == 0) {
      return Colors.redAccent;
    }
    if (opportunity.requiredParticipants == null) {
      return Theme.of(context).colorScheme.secondary;
    }
    return Colors.green;
  }

  Future<void> _openLink(LinkableElement link) async {
    final uri = Uri.parse(link.url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Widget _buildStatusChip(
    BuildContext context, {
    required Color borderColor,
    required IconData icon,
    required String label,
    Color? iconColor,
  }) {
    final resolvedIconColor = (iconColor ?? borderColor).withOpacity(0.9);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.background.withOpacity(0.18),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: borderColor,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: resolvedIconColor, size: 16),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onPrimary,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final computedStatus =
        opportunity.reflectionCount > 0 ? 'completed' : opportunity.status;
    final timeRange = _formatTimeRange(opportunity);
    final l10n = AppLocalizations.of(context)!;
    final availabilityColor = _availabilityColor(context);
    final statusColor = _getStatusColor(context, computedStatus);
    final participantStatusValue = opportunity.participantStatus;
    final participantStatusText =
        opportunity.isParticipant && participantStatusValue != null
            ? _getParticipantStatusText(context, participantStatusValue)
            : null;
    final participantStatusColor = participantStatusText != null
        ? _getParticipantStatusColor(participantStatusValue!)
        : null;
    final canApply = computedStatus == 'open' && opportunity.canApply;
    final buttonShape =
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(24));
    final viewDetailsStyle = TextButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      shape: buttonShape,
      minimumSize: const Size(0, 44),
    );
    final manageButtonStyle = OutlinedButton.styleFrom(
      side: BorderSide(
          color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.4)),
      shape: buttonShape,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      minimumSize: const Size(0, 44),
    );
    final secondaryButtonStyle = ElevatedButton.styleFrom(
      backgroundColor: Theme.of(context).colorScheme.secondary,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      shape: buttonShape,
      minimumSize: const Size(0, 44),
    );
    final cancelButtonStyle = TextButton.styleFrom(
      foregroundColor: Colors.red[300],
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      shape: buttonShape,
      minimumSize: const Size(0, 44),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final width = maxWidth > 600 ? 600.0 : maxWidth;
        return Center(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                width: width,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color:
                      Theme.of(context).colorScheme.background.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Theme.of(context)
                        .colorScheme
                        .onPrimary
                        .withOpacity(0.3),
                  ),
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  opportunity.title,
                                  style: TextStyle(
                                    color:
                                        Theme.of(context).colorScheme.onPrimary,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              if (opportunity.organizerAvatar != null &&
                                  opportunity.organizerAvatar!.isNotEmpty)
                                Container(
                                  width: 20,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    image: DecorationImage(
                                      image: NetworkImage(
                                          opportunity.organizerAvatar!),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                )
                              else
                                Container(
                                  width: 20,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onPrimary
                                        .withOpacity(0.3),
                                  ),
                                  child: Icon(
                                    Icons.person,
                                    size: 12,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onPrimary
                                        .withOpacity(0.7),
                                  ),
                                ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  opportunity.organizerName ?? l10n.organizer,
                                  style: TextStyle(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onPrimary
                                        .withOpacity(0.7),
                                    fontSize: 14,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (showFullDetails)
                                Flexible(
                                  child: Align(
                                    alignment: Alignment.centerRight,
                                    child: Wrap(
                                      spacing: 6,
                                      runSpacing: 6,
                                      crossAxisAlignment:
                                          WrapCrossAlignment.center,
                                      alignment: WrapAlignment.end,
                                      children: [
                                        _buildStatusChip(
                                          context,
                                          borderColor: statusColor,
                                          icon: Icons.event_available,
                                          label: _getStatusText(
                                              context, computedStatus),
                                        ),
                                        if (participantStatusText != null &&
                                            participantStatusColor != null)
                                          _buildStatusChip(
                                            context,
                                            borderColor: participantStatusColor,
                                            icon: Icons.verified_user,
                                            label: participantStatusText,
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (opportunity.attachmentCount > 0) ...[
                            Row(
                              children: [
                                Icon(Icons.attachment,
                                    size: 16,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onPrimary
                                        .withOpacity(0.7)),
                                const SizedBox(width: 6),
                                Text(
                                  '${opportunity.attachmentCount} attachment${opportunity.attachmentCount == 1 ? '' : 's'}',
                                  style: TextStyle(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onPrimary
                                        .withOpacity(0.7),
                                    fontSize: 13,
                                  ),
                                ),
                                if (opportunity.coverAttachmentUrl != null) ...[
                                  const SizedBox(width: 8),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(6),
                                    child: Image.network(
                                      opportunity.coverAttachmentUrl!,
                                      width: 32,
                                      height: 32,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) =>
                                          const SizedBox.shrink(),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 8),
                          ],
                          if (showDescription &&
                              opportunity.description.isNotEmpty) ...[
                            Linkify(
                              text: opportunity.description,
                              style: TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onPrimary
                                    .withOpacity(0.8),
                                fontSize: 14,
                              ),
                              linkStyle: TextStyle(
                                color: Theme.of(context).colorScheme.secondary,
                                decoration: TextDecoration.underline,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              onOpen: _openLink,
                            ),
                            const SizedBox(height: 12),
                          ],
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
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  opportunity.location,
                                  style: TextStyle(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onPrimary
                                        .withOpacity(0.7),
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (opportunity.reflectionCount > 0) ...[
                            _ReflectionPreviewCard(
                              opportunity: opportunity,
                              apiClient: apiClient,
                              experience: experience,
                              onOpportunityUpdated: onOpportunityUpdated,
                            ),
                            const SizedBox(height: 8),
                          ],
                          Row(
                            children: [
                              Icon(
                                Icons.people_alt,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onPrimary
                                    .withOpacity(0.7),
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                opportunity.requiredParticipants != null
                                    ? '${opportunity.participantCount}/${opportunity.requiredParticipants}'
                                    : '${opportunity.participantCount} ${experience.participants(context)}',
                                style: TextStyle(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onPrimary
                                      .withOpacity(0.7),
                                  fontSize: 14,
                                ),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .background
                                      .withOpacity(0.16),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color:
                                          availabilityColor.withOpacity(0.8)),
                                ),
                                child: Text(
                                  _availabilityLabel(context),
                                  style: TextStyle(
                                    color:
                                        Theme.of(context).colorScheme.onPrimary,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
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
                              const SizedBox(width: 4),
                              Text(
                                _formatDate(context, opportunity.date),
                                style: TextStyle(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onPrimary
                                      .withOpacity(0.7),
                                  fontSize: 14,
                                ),
                              ),
                              if (timeRange.isNotEmpty) ...[
                                const SizedBox(width: 16),
                                Icon(
                                  Icons.access_time,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onPrimary
                                      .withOpacity(0.7),
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  timeRange,
                                  style: TextStyle(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onPrimary
                                        .withOpacity(0.7),
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 8),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                    if (apiClient != null) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .background
                              .withOpacity(0.08),
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(24),
                            bottomRight: Radius.circular(24),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextButton(
                                onPressed: onTap != null
                                    ? onTap
                                    : () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                VolunteerOpportunityDetailsPage(
                                              apiClient: apiClient!,
                                              opportunity: opportunity,
                                              experience: experience,
                                            ),
                                          ),
                                        ).then((_) {
                                          if (onOpportunityUpdated != null) {
                                            onOpportunityUpdated!(opportunity);
                                          }
                                        });
                                      },
                                style: viewDetailsStyle,
                                child: Text(
                                  l10n.viewDetails,
                                  style: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onPrimary),
                                ),
                              ),
                            ),
                            if ((opportunity.participantRole == 'admin' ||
                                opportunity.participantRole ==
                                    'coordinator')) ...[
                              const SizedBox(width: 8),
                              OutlinedButton.icon(
                                onPressed: () async {
                                  final updated = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => VolunteerAdminPage(
                                        apiClient: apiClient!,
                                        opportunity: opportunity,
                                        experience: experience,
                                      ),
                                    ),
                                  );
                                  if (updated is VolunteerOpportunity &&
                                      onOpportunityUpdated != null) {
                                    onOpportunityUpdated!(updated);
                                  }
                                },
                                icon: Icon(Icons.admin_panel_settings,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onPrimary),
                                label: Text(experience.manage(context),
                                    style: TextStyle(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onPrimary)),
                                style: manageButtonStyle,
                              ),
                            ],
                            if (opportunity.isParticipant &&
                                opportunity.participantStatus == 'applied') ...[
                              const SizedBox(width: 8),
                              TextButton(
                                onPressed: () async {
                                  try {
                                    await apiClient!.cancelVolunteerApplication(
                                        context, opportunity.id);

                                    final updatedOpportunity =
                                        opportunity.copyWith(
                                      participantStatus: 'cancelled',
                                      isParticipant: true,
                                    );

                                    if (onOpportunityUpdated != null) {
                                      onOpportunityUpdated!(updatedOpportunity);
                                    }
                                    GlassmorphicUI.showGlassSnackBar(
                                      context,
                                      l10n.applicationCancelled,
                                    );
                                  } catch (e) {
                                    GlassmorphicUI.showGlassSnackBar(
                                      context,
                                      e.toString(),
                                      isError: true,
                                    );
                                  }
                                },
                                style: cancelButtonStyle,
                                child: Text(
                                  l10n.cancelApplication,
                                  style: TextStyle(
                                      color:
                                          Theme.of(context).colorScheme.error),
                                ),
                              ),
                            ],
                            if (opportunity.isParticipant &&
                                opportunity.participantStatus ==
                                    'cancelled') ...[
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: () async {
                                  final appliedMessage =
                                      experience.applied(context);
                                  try {
                                    await apiClient!
                                        .applyToVolunteerOpportunity(
                                            context, opportunity.id);

                                    final updatedOpportunity =
                                        opportunity.copyWith(
                                      participantStatus: 'applied',
                                      isParticipant: true,
                                    );

                                    if (onOpportunityUpdated != null) {
                                      onOpportunityUpdated!(updatedOpportunity);
                                    }
                                    GlassmorphicUI.showGlassSnackBar(
                                      context,
                                      appliedMessage,
                                    );
                                  } catch (e) {
                                    GlassmorphicUI.showGlassSnackBar(
                                      context,
                                      e.toString(),
                                      isError: true,
                                    );
                                  }
                                },
                                style: secondaryButtonStyle,
                                child: Text(
                                  l10n.reapply,
                                  style: TextStyle(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSecondary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                            if (!opportunity.isParticipant && canApply) ...[
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: () async {
                                  final appliedMessage =
                                      experience.applied(context);
                                  try {
                                    await apiClient!
                                        .applyToVolunteerOpportunity(
                                            context, opportunity.id);

                                    final updatedOpportunity =
                                        opportunity.copyWith(
                                      participantStatus: 'applied',
                                      isParticipant: true,
                                    );

                                    if (onOpportunityUpdated != null) {
                                      onOpportunityUpdated!(updatedOpportunity);
                                    }
                                    GlassmorphicUI.showGlassSnackBar(
                                      context,
                                      appliedMessage,
                                    );
                                  } catch (e) {
                                    GlassmorphicUI.showGlassSnackBar(
                                      context,
                                      e.toString(),
                                      isError: true,
                                    );
                                  }
                                },
                                style: secondaryButtonStyle,
                                child: Text(
                                  experience.apply(context),
                                  style: TextStyle(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSecondary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ] else ...[
                      InkWell(
                        onTap: onTap ??
                            () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      VolunteerOpportunityDetailsPage(
                                    opportunity: opportunity,
                                    apiClient: ApiClient(),
                                    experience: experience,
                                  ),
                                ),
                              );
                            },
                        borderRadius: BorderRadius.circular(24),
                        child: const SizedBox(
                          height: 50,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ReflectionPreviewCard extends StatefulWidget {
  final VolunteerOpportunity opportunity;
  final ApiClient? apiClient;
  final OpportunityExperience experience;
  final Function(VolunteerOpportunity)? onOpportunityUpdated;

  const _ReflectionPreviewCard({
    required this.opportunity,
    required this.apiClient,
    required this.experience,
    required this.onOpportunityUpdated,
  });

  @override
  State<_ReflectionPreviewCard> createState() => _ReflectionPreviewCardState();
}

class _ReflectionPreviewCardState extends State<_ReflectionPreviewCard> {
  late String _title;
  late String _excerpt;
  late List<VolunteerReflectionImage> _images;
  bool _didRequestPreview = false;

  @override
  void initState() {
    super.initState();
    _syncFromOpportunity();
  }

  @override
  void didUpdateWidget(covariant _ReflectionPreviewCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.opportunity != widget.opportunity) {
      _syncFromOpportunity();
      _didRequestPreview = false;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadPreviewIfNeeded();
  }

  void _syncFromOpportunity() {
    _title = widget.opportunity.latestReflectionTitle ?? '';
    _excerpt = widget.opportunity.latestReflectionExcerpt ?? '';
    _images = widget.opportunity.latestReflectionImages;
  }

  bool get _shouldFetchPreview {
    if (_didRequestPreview || widget.apiClient == null) return false;
    if (widget.opportunity.reflectionCount <= 0) return false;
    final hasImages = _images.any((img) => img.isImage);
    return !hasImages;
  }

  Future<void> _loadPreviewIfNeeded() async {
    if (!_shouldFetchPreview) return;
    _didRequestPreview = true;

    try {
      final reflections = await widget.apiClient!
          .getVolunteerReflections(context, widget.opportunity.id);
      if (!mounted || reflections.isEmpty) return;

      final latest = reflections.first;
      final updatedOpportunity = widget.opportunity.copyWith(
        latestReflectionTitle: latest.title,
        latestReflectionExcerpt: latest.body,
        latestReflectionAt: latest.createdAt,
        latestReflectionImages: latest.images,
      );

      setState(() {
        _title = latest.title;
        _excerpt = latest.body;
        _images = latest.images;
      });

      widget.onOpportunityUpdated?.call(updatedOpportunity);
    } catch (_) {
      // Keep the existing card text if preview hydration fails.
    }
  }

  Future<void> _openReflectionView() async {
    if (widget.apiClient == null) return;

    final updated = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VolunteerReflectionViewPage(
          apiClient: widget.apiClient!,
          experience: widget.experience,
          opportunity: widget.opportunity.copyWith(
            latestReflectionTitle: _title,
            latestReflectionExcerpt: _excerpt,
            latestReflectionImages: _images,
          ),
        ),
      ),
    );

    if (updated is VolunteerOpportunity &&
        widget.onOpportunityUpdated != null) {
      widget.onOpportunityUpdated!(updated);
    }
  }

  Widget _buildReflectionImageTile({
    required String imageUrl,
    required BorderRadius borderRadius,
    int? overlayCount,
  }) {
    return ClipRRect(
      borderRadius: borderRadius,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            imageUrl,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              color: Colors.white24,
              alignment: Alignment.center,
              child: const Icon(Icons.broken_image, size: 18),
            ),
          ),
          if (overlayCount != null && overlayCount > 0)
            Container(
              color: Colors.black.withOpacity(0.45),
              alignment: Alignment.center,
              child: Text(
                '+$overlayCount',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimary,
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildReflectionMediaPreview() {
    final images = _images.where((img) => img.isImage).toList(growable: false);
    if (images.isEmpty) return const SizedBox.shrink();

    final previewImages = images.take(3).toList(growable: false);
    final extraCount = images.length - previewImages.length;

    return LayoutBuilder(
      builder: (context, constraints) {
        final useHighlightLayout =
            constraints.maxWidth >= 420 && previewImages.length > 1;

        if (!useHighlightLayout) {
          return SizedBox(
            height: 88,
            child: Row(
              children: previewImages.asMap().entries.map((entry) {
                final index = entry.key;
                final img = entry.value;
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: index == previewImages.length - 1 ? 0 : 8,
                    ),
                    child: _buildReflectionImageTile(
                      imageUrl: img.fileUrl,
                      borderRadius: BorderRadius.circular(12),
                      overlayCount:
                          index == previewImages.length - 1 ? extraCount : null,
                    ),
                  ),
                );
              }).toList(),
            ),
          );
        }

        return SizedBox(
          height: 138,
          child: Row(
            children: [
              Expanded(
                flex: 7,
                child: _buildReflectionImageTile(
                  imageUrl: previewImages.first.fileUrl,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 4,
                child: Column(
                  children: [
                    Expanded(
                      child: _buildReflectionImageTile(
                        imageUrl: previewImages[1].fileUrl,
                        borderRadius: BorderRadius.circular(14),
                        overlayCount:
                            previewImages.length == 2 ? extraCount : null,
                      ),
                    ),
                    if (previewImages.length > 2) ...[
                      const SizedBox(height: 8),
                      Expanded(
                        child: _buildReflectionImageTile(
                          imageUrl: previewImages[2].fileUrl,
                          borderRadius: BorderRadius.circular(14),
                          overlayCount: extraCount,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final hasImages = _images.any((img) => img.isImage);
    final title = _title.trim().isNotEmpty ? _title : l10n.recentReflection;
    final excerpt = _excerpt.trim();

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: widget.apiClient == null ? null : _openReflectionView,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.background.withOpacity(0.14),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.15),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.auto_stories,
                  size: 16,
                  color:
                      Theme.of(context).colorScheme.onPrimary.withOpacity(0.8),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    l10n.reflectionBodyLabel,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  size: 18,
                  color:
                      Theme.of(context).colorScheme.onPrimary.withOpacity(0.55),
                ),
              ],
            ),
            if (hasImages) ...[
              const SizedBox(height: 10),
              _buildReflectionMediaPreview(),
            ],
            SizedBox(height: hasImages ? 10 : 6),
            Text(
              title,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (excerpt.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  excerpt,
                  maxLines: hasImages ? 3 : 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Theme.of(context)
                        .colorScheme
                        .onPrimary
                        .withOpacity(0.85),
                    height: 1.35,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
