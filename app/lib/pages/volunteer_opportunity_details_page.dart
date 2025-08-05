import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../models/volunteer_opportunity.dart';
import '../models/volunteer_participant.dart';
import '../services/api_client.dart';
import '../widgets/glassmorphic_ui.dart';
import 'package:intl/intl.dart';

class VolunteerOpportunityDetailsPage extends StatefulWidget {
  final ApiClient apiClient;
  final VolunteerOpportunity opportunity;

  const VolunteerOpportunityDetailsPage({
    super.key,
    required this.apiClient,
    required this.opportunity,
  });

  @override
  State<VolunteerOpportunityDetailsPage> createState() => _VolunteerOpportunityDetailsPageState();
}

class _VolunteerOpportunityDetailsPageState extends State<VolunteerOpportunityDetailsPage> {
  bool _isLoading = false;
  bool _didLoadParticipants = false;
  List<VolunteerParticipant>? _participants;
  late VolunteerOpportunity _opportunity;
  bool _isOrganizer = false;

  @override
  void initState() {
    super.initState();
    _opportunity = widget.opportunity;
    _checkOrganizerStatus();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didLoadParticipants) {
      _didLoadParticipants = true;
      _loadParticipants();
    }
  }

  Future<void> _checkOrganizerStatus() async {
    try {
      final userId = await widget.apiClient.getCurrentUserId(context);
      if (userId != null) {
        setState(() {
          _isOrganizer = _opportunity.isOrganizer(userId);
        });
      }
    } catch (e) {
      // Ignore errors in organizer check
    }
  }

  Future<void> _loadParticipants() async {
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

  Future<void> _applyToOpportunity() async {
    try {
      setState(() => _isLoading = true);
      await widget.apiClient.applyToVolunteerOpportunity(context, _opportunity.id);

      if (mounted) {
        setState(() {
          _opportunity = _opportunity.copyWith(
            isParticipant: true,
            participantStatus: 'applied',
            participantCount: _opportunity.participantCount + 1,
          );
          _isLoading = false;
        });

        GlassmorphicUI.showGlassSnackBar(
          context,
          AppLocalizations.of(context)!.volunteerApplied,
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
      await widget.apiClient.cancelVolunteerApplication(context, _opportunity.id);

      if (mounted) {
        setState(() {
          _opportunity = _opportunity.copyWith(
            isParticipant: false,
            participantStatus: null,
            participantCount: _opportunity.participantCount - 1,
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

  Future<void> _updateParticipantStatus(int participantUserId, String status) async {
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

  Widget _buildActionButton() {
    final l10n = AppLocalizations.of(context)!;

    if (_isLoading) {
      return const CircularProgressIndicator(color: Colors.white);
    }

    // Handle cancelled applications - allow reapplication
    if (_opportunity.isParticipant && _opportunity.participantStatus == 'cancelled') {
      if (_opportunity.canApply) {
        return ElevatedButton(
          onPressed: _applyToOpportunity,
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.secondary,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25),
            ),
          ),
          child: Text(
            l10n.volunteerApply,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSecondary,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      }
    }

    if (_opportunity.isParticipant && _opportunity.participantStatus != 'cancelled') {
      return Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.2),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(color: Colors.green),
            ),
            child: Text(
              _opportunity.participantStatus == 'applied'
                  ? l10n.volunteerApplied
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
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.2),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: Colors.grey),
        ),
        child: Text(
          _opportunity.isFilled ? l10n.opportunityFilled : _getStatusText(_opportunity.status),
          style: const TextStyle(
            color: Colors.grey,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    return ElevatedButton(
      onPressed: _applyToOpportunity,
      style: ElevatedButton.styleFrom(
        backgroundColor: Theme.of(context).colorScheme.secondary,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(25),
        ),
      ),
      child: Text(
        l10n.volunteerApply,
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
    final dateFormat = DateFormat.yMMMMd(Localizations.localeOf(context).languageCode);

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
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              _opportunity.title,
              style: const TextStyle(color: Colors.white),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Main info card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title and status
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _opportunity.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: _getStatusColor(_opportunity.status).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(
                                color: _getStatusColor(_opportunity.status),
                              ),
                            ),
                            child: Text(
                              _getStatusText(_opportunity.status),
                              style: TextStyle(
                                color: _getStatusColor(_opportunity.status),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Organizer
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: Colors.white.withOpacity(0.2),
                            child: _opportunity.organizerAvatar != null
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
                                    color: Colors.white.withOpacity(0.7),
                                  ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.volunteerOrganizer,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                _opportunity.organizerName ?? 'Unknown',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Details grid
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.location_on,
                                      color: Colors.white.withOpacity(0.7),
                                      size: 16,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      l10n.opportunityLocation,
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.7),
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _opportunity.location,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.people,
                                      color: Colors.white.withOpacity(0.7),
                                      size: 16,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      l10n.volunteerParticipants,
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.7),
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _opportunity.requiredParticipants != null ? '${_opportunity.participantCount}/${_opportunity.requiredParticipants}' : _opportunity.participantCount.toString(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Dates
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_today,
                                color: Colors.white.withOpacity(0.7),
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                l10n.eventDate,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            dateFormat.format(_opportunity.date),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (_opportunity.startTime != null && _opportunity.endTime != null)
                            Text(
                              '${DateFormat('HH:mm').format(_opportunity.startTime!)} - ${DateFormat('HH:mm').format(_opportunity.endTime!)}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Action button
                      Center(child: _buildActionButton()),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Description
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.opportunityDescription,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _opportunity.description,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 16,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),

                if (_participants != null && _participants!.isNotEmpty) ...[
                  const SizedBox(height: 24),

                  // Participants
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${l10n.volunteerParticipants} (${_participants!.length})',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ..._participants!
                            .map((participant) => Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.05),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.1),
                                      ),
                                    ),
                                    child: Column(
                                      children: [
                                        Row(
                                          children: [
                                            CircleAvatar(
                                              radius: 16,
                                              backgroundColor: Colors.white.withOpacity(0.2),
                                              child: participant.userAvatar != null
                                                  ? ClipOval(
                                                      child: Image.network(
                                                        participant.userAvatar!,
                                                        width: 32,
                                                        height: 32,
                                                        fit: BoxFit.cover,
                                                      ),
                                                    )
                                                  : Icon(
                                                      Icons.person,
                                                      color: Colors.white.withOpacity(0.7),
                                                      size: 16,
                                                    ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Text(
                                                participant.userName,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: participant.status == 'approved'
                                                    ? Colors.green.withOpacity(0.2)
                                                    : participant.status == 'applied'
                                                        ? Colors.orange.withOpacity(0.2)
                                                        : Colors.red.withOpacity(0.2),
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                              child: Text(
                                                _getStatusText(participant.status),
                                                style: TextStyle(
                                                  color: participant.status == 'approved'
                                                      ? Colors.green
                                                      : participant.status == 'applied'
                                                          ? Colors.orange
                                                          : Colors.red,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (_isOrganizer && participant.status == 'applied') ...[
                                          const SizedBox(height: 8),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                            children: [
                                              Expanded(
                                                child: ElevatedButton.icon(
                                                  onPressed: () => _updateParticipantStatus(participant.userId, 'approved'),
                                                  icon: const Icon(Icons.check, size: 16),
                                                  label: Text(l10n.approveParticipant),
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: Colors.green,
                                                    foregroundColor: Colors.white,
                                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: ElevatedButton.icon(
                                                  onPressed: () => _updateParticipantStatus(participant.userId, 'rejected'),
                                                  icon: const Icon(Icons.close, size: 16),
                                                  label: Text(l10n.rejectParticipant),
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: Colors.red,
                                                    foregroundColor: Colors.white,
                                                    padding: const EdgeInsets.symmetric(vertical: 8),
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

                const SizedBox(height: 100), // Bottom padding for floating action button
              ],
            ),
          ),
        ),
      ],
    );
  }
}
