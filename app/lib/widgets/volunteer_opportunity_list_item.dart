import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:ui';
import '../models/volunteer_opportunity.dart';
import '../pages/volunteer_opportunity_details_page.dart';
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
      case 'approved':
        return l10n.volunteerApproved;
      case 'pending':
        return l10n.volunteerApplied; // Using applied as pending equivalent
      case 'rejected':
        return l10n.rejectParticipant;
      case 'cancelled':
        return l10n.volunteerCancelled;
      default:
        return status;
    }
  }

  Color _getStatusColor(BuildContext context, String status) {
    switch (status) {
      case 'approved':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'rejected':
        return Colors.red;
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

  @override
  Widget build(BuildContext context) {
    final timeRange = _formatTimeRange(opportunity);
    final l10n = AppLocalizations.of(context)!;

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final width = maxWidth > 600 ? 600.0 : maxWidth;
        return Center(
          child: Container(
            width: width,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.background.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.3),
              ),
            ),
            child: Column(
              children: [
                // Main content
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title and organizer row
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
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: _getStatusColor(context, opportunity.status).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _getStatusColor(context, opportunity.status),
                                ),
                              ),
                              child: Text(
                                _getStatusText(context, opportunity.status),
                                style: TextStyle(
                                  color: _getStatusColor(context, opportunity.status),
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
                          // Organizer avatar - small size next to name
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
                      // Description
                      if (showDescription && opportunity.description.isNotEmpty) ...[
                        Text(
                          opportunity.description,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.8),
                            fontSize: 14,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 12),
                      ],
                      // Location row
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
                      // Date and time row
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
                      // Participants row
                      Row(
                        children: [
                          Icon(
                            Icons.people,
                            color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.7),
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            opportunity.requiredParticipants != null 
                                ? '${opportunity.participantCount}/${opportunity.requiredParticipants}' 
                                : opportunity.participantCount.toString(),
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

                // Action buttons
                if (apiClient != null) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.background.withOpacity(0.05),
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(20),
                        bottomRight: Radius.circular(20),
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
                            child: Text(
                              l10n.viewDetails,
                              style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
                            ),
                          ),
                        ),
                        if (opportunity.isParticipant && opportunity.participantStatus == 'applied') ...[
                          const SizedBox(width: 8),
                          TextButton(
                            onPressed: () async {
                              try {
                                await apiClient!.cancelVolunteerApplication(context, opportunity.id);
                                
                                // Create a copy of the opportunity with updated status
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
                                
                                // Create a copy of the opportunity with updated status
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
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            ),
                            child: Text(
                              l10n.reapply,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
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
                                
                                // Create a copy of the opportunity with updated status
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
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).colorScheme.secondary,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            ),
                            child: Text(
                              l10n.volunteerApply,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ] else ...[
                  // Tap to view details if no API client provided
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
                    borderRadius: BorderRadius.circular(20),
                    child: const SizedBox(
                      height: 50,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
