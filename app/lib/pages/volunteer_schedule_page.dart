import 'package:flutter/material.dart';
import 'dart:async';
import '../l10n/app_localizations.dart';
import '../models/volunteer_opportunity.dart';
import '../services/api_client.dart';
import 'volunteer_opportunity_details_page.dart';
import 'package:intl/intl.dart';

class VolunteerSchedulePage extends StatefulWidget {
  final ApiClient apiClient;

  const VolunteerSchedulePage({
    super.key,
    required this.apiClient,
  });

  @override
  State<VolunteerSchedulePage> createState() => _VolunteerSchedulePageState();
}

class _VolunteerSchedulePageState extends State<VolunteerSchedulePage> {
  bool _isLoading = true;
  String? _error;
  List<VolunteerOpportunity> _myOpportunities = [];
  bool _didLoadOpportunities = false;
  Timer? _refreshTimer;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _startPeriodicRefresh();
    _selectedDay = DateTime.now();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _startPeriodicRefresh() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _loadMyOpportunities();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didLoadOpportunities) {
      _didLoadOpportunities = true;
      _loadMyOpportunities();
    }
  }

  Future<void> _loadMyOpportunities() async {
    try {
      if (_isLoading) {
        setState(() {
          _error = null;
        });
      }

      final opportunities = await widget.apiClient.getMyVolunteerOpportunities(
        context,
        status: null, // Get all my opportunities
      );

      if (mounted) {
        setState(() {
          _myOpportunities = opportunities.where((o) => o.participantStatus == 'approved' || o.participantStatus == 'completed').toList();
          _error = null;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  List<VolunteerOpportunity> _getEventsForDay(DateTime day) {
    return _myOpportunities.where((opportunity) {
      return _isSameDay(opportunity.date, day);
    }).toList();
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  void _openOpportunityDetails(VolunteerOpportunity opportunity) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VolunteerOpportunityDetailsPage(
          apiClient: widget.apiClient,
          opportunity: opportunity,
        ),
      ),
    );
  }

  Widget _buildEventCard(VolunteerOpportunity opportunity) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.background.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.3),
        ),
      ),
      child: ListTile(
        onTap: () => _openOpportunityDetails(opportunity),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _getStatusColor(opportunity.participantStatus).withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.volunteer_activism,
            color: _getStatusColor(opportunity.participantStatus),
            size: 20,
          ),
        ),
        title: Text(
          opportunity.title,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (opportunity.startTime != null && opportunity.endTime != null)
              Text(
                '${_formatTime(opportunity.startTime!)} - ${_formatTime(opportunity.endTime!)}',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.7),
                ),
              ),
            Text(
              opportunity.location,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.7),
              ),
            ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _getStatusColor(opportunity.participantStatus).withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _getStatusColor(opportunity.participantStatus),
            ),
          ),
          child: Text(
            _getLocalizedStatus(opportunity.participantStatus, l10n),
            style: TextStyle(
              color: _getStatusColor(opportunity.participantStatus),
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      case 'approved':
        return Colors.blue;
      case 'applied':
      default:
        return Colors.orange;
    }
  }

  String _getLocalizedStatus(String? status, AppLocalizations l10n) {
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
        return l10n.statusUnknown;
    }
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildSimpleCalendar() {
    final now = DateTime.now();
    final firstDay = DateTime(now.year, now.month, 1);
    final lastDay = DateTime(now.year, now.month + 1, 0);
    final daysInMonth = lastDay.day;
    final firstWeekday = firstDay.weekday;

    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.background.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.3),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: () {
                    setState(() {
                      _focusedDay = DateTime(_focusedDay.year, _focusedDay.month - 1);
                    });
                  },
                  icon: Icon(
                    Icons.chevron_left,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
                Text(
                  '${_focusedDay.year}/${_focusedDay.month}',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: () {
                    setState(() {
                      _focusedDay = DateTime(_focusedDay.year, _focusedDay.month + 1);
                    });
                  },
                  icon: Icon(
                    Icons.chevron_right,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Days of week
            Row(
              children: List.generate(7, (index) {
                final day = DateTime(2025, 1, 5 + index); // 2025-01-05 is a Sunday
                return DateFormat.E().format(day).substring(0, 1); // Get first letter of weekday
              })
                  .map(
                    (day) => Expanded(
                      child: Center(
                        child: Text(
                          day,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.7),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 8),
            // Calendar grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                childAspectRatio: 1,
              ),
              itemCount: 42, // 6 weeks
              itemBuilder: (context, index) {
                final dayNumber = index - (firstWeekday - 2);
                final isValidDay = dayNumber >= 1 && dayNumber <= daysInMonth;
                final currentDate = isValidDay ? DateTime(_focusedDay.year, _focusedDay.month, dayNumber) : null;
                final hasEvents = currentDate != null && _getEventsForDay(currentDate).isNotEmpty;
                final isSelected = currentDate != null && _selectedDay != null && _isSameDay(currentDate, _selectedDay!);
                final isToday = currentDate != null && _isSameDay(currentDate, DateTime.now());

                if (!isValidDay) {
                  return const SizedBox();
                }

                return GestureDetector(
                  onTap: () {
                    if (currentDate != null) {
                      setState(() {
                        _selectedDay = currentDate;
                      });
                    }
                  },
                  child: Container(
                    margin: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Theme.of(context).colorScheme.secondary
                          : isToday
                              ? Theme.of(context).colorScheme.primary.withOpacity(0.7)
                              : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: hasEvents
                          ? Border.all(
                              color: Colors.orange,
                              width: 2,
                            )
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        dayNumber.toString(),
                        style: TextStyle(
                          color: isSelected || isToday ? Colors.white : Theme.of(context).colorScheme.onPrimary,
                          fontWeight: hasEvents ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final selectedEvents = _selectedDay != null ? _getEventsForDay(_selectedDay!) : <VolunteerOpportunity>[];

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
              // Custom AppBar
              Container(
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 8,
                  left: 16,
                  right: 16,
                  bottom: 8,
                ),
                child: Row(
                  children: [
                    // Back button
                    Container(
                      margin: const EdgeInsets.only(right: 16),
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
                          iconSize: 20,
                          icon: Icon(
                            Icons.arrow_back,
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                    ),
                    // Title
                    Expanded(
                      child: Text(
                        l10n.myVolunteerActivities, // Use existing key for now
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Main content
              Expanded(
                child: _buildBody(selectedEvents),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBody(List<VolunteerOpportunity> selectedEvents) {
    final l10n = AppLocalizations.of(context)!;

    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(
            Theme.of(context).colorScheme.onPrimary,
          ),
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _error!,
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: Text(l10n.retry),
              onPressed: _loadMyOpportunities,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.errorContainer,
                foregroundColor: Theme.of(context).colorScheme.onErrorContainer,
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        children: [
          // Calendar
          _buildSimpleCalendar(),
          const SizedBox(height: 16),
          // Selected day events
          Expanded(
            child: selectedEvents.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.event_busy,
                          size: 64,
                          color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.7),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _selectedDay != null && _isSameDay(_selectedDay!, DateTime.now()) ? l10n.noVolunteerActivities : l10n.noVolunteerActivities,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.7),
                            fontSize: 16,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).padding.bottom + 24,
                    ),
                    itemCount: selectedEvents.length,
                    itemBuilder: (context, index) {
                      return _buildEventCard(selectedEvents[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
