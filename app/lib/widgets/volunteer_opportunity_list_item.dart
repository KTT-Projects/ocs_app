import 'package:flutter/material.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:ui';
import '../models/volunteer_opportunity.dart';
import '../pages/volunteer_opportunity_details_page.dart';
import '../pages/volunteer_admin_page.dart';
import '../services/api_client.dart';
import '../l10n/app_localizations.dart';
import '../widgets/glassmorphic_ui.dart';

class VolunteerOpportunityListItem extends StatelessWidget {
  final VolunteerOpportunity opportunity;
  final VoidCallback? onTap;
  final bool showFullDetails;
  final bool showDescription;
  final ApiClient? apiClient;
  final Function(VolunteerOpportunity)? onOpportunityUpdated;

  const VolunteerOpportunityListItem({
    Key? key,
    required this.opportunity,
    this.onTap,
    this.showFullDetails = false,
    this.showDescription = true,
    this.apiClient,
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
      return DateFormat.Md(Localizations.localeOf(context).languageCode).format(date);
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
      return l10n.volunteerNoLimit;
    }

    if (opportunity.isFull || opportunity.spotsRemaining == 0) {
      return l10n.opportunityFilled;
    }

    final remaining = opportunity.spotsRemaining ?? (opportunity.requiredParticipants! - opportunity.participantCount);
    final safeRemaining = remaining < 0 ? 0 : remaining;
    return l10n.volunteerSpotsRemaining(safeRemaining);
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

  @override
  Widget build(BuildContext context) {
    final timeRange = _formatTimeRange(opportunity);
    final l10n = AppLocalizations.of(context)!;
    final availabilityColor = _availabilityColor(context);
    final statusColor = _getStatusColor(context, opportunity.status);
    final buttonShape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(24));
    final viewDetailsStyle = TextButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      shape: buttonShape,
      minimumSize: const Size(0, 44),
    );
    final manageButtonStyle = OutlinedButton.styleFrom(
      side: BorderSide(color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.4)),
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
                  color: Theme.of(context).colorScheme.background.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.3),
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
                                    color: Theme.of(context).colorScheme.onPrimary,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              if (showFullDetails)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.background.withOpacity(0.18),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: statusColor,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.event_available, color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.9), size: 16),
                                      const SizedBox(width: 6),
                                      Text(
                                        _getStatusText(context, opportunity.status),
                                        style: TextStyle(
                                          color: Theme.of(context).colorScheme.onPrimary,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              if (opportunity.organizerAvatar != null && opportunity.organizerAvatar!.isNotEmpty)
                                Container(
                                  width: 20,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    image: DecorationImage(
                                      image: NetworkImage(opportunity.organizerAvatar!),
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
                                    color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.3),
                                  ),
                                  child: Icon(
                                    Icons.person,
                                    size: 12,
                                    color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.7),
                                  ),
                                ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  opportunity.organizerName ?? l10n.organizer,
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.7),
                                    fontSize: 14,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (opportunity.attachmentCount > 0) ...[
                            Row(
                              children: [
                                Icon(Icons.attachment, size: 16, color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.7)),
                                const SizedBox(width: 6),
                                Text(
                                  '${opportunity.attachmentCount} attachment${opportunity.attachmentCount == 1 ? '' : 's'}',
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.7),
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
                                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 8),
                          ],
                          if (showDescription && opportunity.description.isNotEmpty) ...[
                            Linkify(
                              text: opportunity.description,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.8),
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
                                color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.7),
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  opportunity.location,
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.7),
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.people_alt,
                                color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.7),
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                opportunity.requiredParticipants != null
                                    ? '${opportunity.participantCount}/${opportunity.requiredParticipants}'
                                    : '${opportunity.participantCount} ${l10n.volunteerParticipants}',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.7),
                                  fontSize: 14,
                                ),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.background.withOpacity(0.16),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: availabilityColor.withOpacity(0.8)),
                                ),
                                child: Text(
                                  _availabilityLabel(context),
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.onPrimary,
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
                                color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.7),
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _formatDate(context, opportunity.date),
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.7),
                                  fontSize: 14,
                                ),
                              ),
                              if (timeRange.isNotEmpty) ...[
                                const SizedBox(width: 16),
                                Icon(
                                  Icons.access_time,
                                  color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.7),
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  timeRange,
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.7),
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.people,
                                color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.7),
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                opportunity.requiredParticipants != null ? '${opportunity.participantCount}/${opportunity.requiredParticipants}' : opportunity.participantCount.toString(),
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.7),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (apiClient != null) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.background.withOpacity(0.08),
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
                                            builder: (context) => VolunteerOpportunityDetailsPage(
                                              apiClient: apiClient!,
                                              opportunity: opportunity,
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
                                  style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
                                ),
                              ),
                            ),
                            if ((opportunity.participantRole == 'admin' || opportunity.participantRole == 'coordinator')) ...[
                              const SizedBox(width: 8),
                              OutlinedButton.icon(
                                onPressed: () async {
                                  final updated = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => VolunteerAdminPage(
                                        apiClient: apiClient!,
                                        opportunity: opportunity,
                                      ),
                                    ),
                                  );
                                  if (updated is VolunteerOpportunity && onOpportunityUpdated != null) {
                                    onOpportunityUpdated!(updated);
                                  }
                                },
                                icon: Icon(Icons.admin_panel_settings, color: Theme.of(context).colorScheme.onPrimary),
                                label: Text('Manage', style: TextStyle(color: Theme.of(context).colorScheme.onPrimary)),
                                style: manageButtonStyle,
                              ),
                            ],
                            if (opportunity.isParticipant && opportunity.participantStatus == 'applied') ...[
                              const SizedBox(width: 8),
                              TextButton(
                                onPressed: () async {
                                  try {
                                    await apiClient!.cancelVolunteerApplication(context, opportunity.id);

                                    final updatedOpportunity = opportunity.copyWith(
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
                                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                                ),
                              ),
                            ],
                            if (opportunity.isParticipant && opportunity.participantStatus == 'cancelled') ...[
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: () async {
                                  try {
                                    await apiClient!.applyToVolunteerOpportunity(context, opportunity.id);

                                    final updatedOpportunity = opportunity.copyWith(
                                      participantStatus: 'applied',
                                      isParticipant: true,
                                    );

                                    if (onOpportunityUpdated != null) {
                                      onOpportunityUpdated!(updatedOpportunity);
                                    }
                                    GlassmorphicUI.showGlassSnackBar(
                                      context,
                                      l10n.volunteerApplied,
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
                                    color: Theme.of(context).colorScheme.onSecondary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                            if (!opportunity.isParticipant && opportunity.canApply) ...[
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: () async {
                                  try {
                                    await apiClient!.applyToVolunteerOpportunity(context, opportunity.id);

                                    final updatedOpportunity = opportunity.copyWith(
                                      participantStatus: 'applied',
                                      isParticipant: true,
                                    );

                                    if (onOpportunityUpdated != null) {
                                      onOpportunityUpdated!(updatedOpportunity);
                                    }
                                    GlassmorphicUI.showGlassSnackBar(
                                      context,
                                      l10n.volunteerApplied,
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
                                  l10n.volunteerApply,
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.onSecondary,
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
                                  builder: (context) => VolunteerOpportunityDetailsPage(
                                    opportunity: opportunity,
                                    apiClient: ApiClient(),
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
