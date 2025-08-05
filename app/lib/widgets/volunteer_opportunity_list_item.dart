import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:ui';
import '../models/volunteer_opportunity.dart';
import '../pages/volunteer_opportunity_details_page.dart';
import '../services/api_client.dart';
import '../l10n/app_localizations.dart';

class VolunteerOpportunityListItem extends StatelessWidget {
  final VolunteerOpportunity opportunity;
  final VoidCallback? onTap;
  final bool showFullDetails;
  final bool showDescription;

  const VolunteerOpportunityListItem({
    Key? key,
    required this.opportunity,
    this.onTap,
    this.showFullDetails = false,
    this.showDescription = true,
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

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final width = maxWidth > 600 ? 600.0 : maxWidth;
        return Center(
          child: Container(
            width: width,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.background.withOpacity(0.2),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.3),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: InkWell(
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
                child: Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title and organizer row
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  opportunity.title,
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.onPrimary,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
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
                                        opportunity.organizerName ?? AppLocalizations.of(context)!.organizer,
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
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Location row
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 16,
                            color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.7),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              opportunity.location,
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
                      const SizedBox(height: 8),
                      // Date and time row
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 16,
                            color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.7),
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
                              size: 16,
                              color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.7),
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
                      // Participants and status row
                      Row(
                        children: [
                          Icon(
                            Icons.people,
                            size: 16,
                            color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.7),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            opportunity.requiredParticipants != null ? '${opportunity.participantCount}/${opportunity.requiredParticipants}' : opportunity.participantCount.toString(),
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.7),
                              fontSize: 14,
                            ),
                          ),
                          const Spacer(),
                          if (showFullDetails)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: _getStatusColor(context, opportunity.status).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _getStatusColor(context, opportunity.status),
                                  width: 1,
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
                      if (showDescription && opportunity.description.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(
                          opportunity.description,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onPrimary,
                            fontSize: 14,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
