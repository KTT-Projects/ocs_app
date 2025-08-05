import 'package:flutter/material.dart';
import 'dart:async';
import '../l10n/app_localizations.dart';
import '../models/volunteer_opportunity.dart';
import '../services/api_client.dart';
import 'volunteer_opportunity_details_page.dart';
import 'package:intl/intl.dart';

class EnhancedVolunteerSchedulePage extends StatefulWidget {
  final ApiClient apiClient;

  const EnhancedVolunteerSchedulePage({
    super.key,
    required this.apiClient,
  });

  @override
  State<EnhancedVolunteerSchedulePage> createState() => _EnhancedVolunteerSchedulePageState();
}

class _EnhancedVolunteerSchedulePageState extends State<EnhancedVolunteerSchedulePage> with TickerProviderStateMixin {
  bool _isLoading = true;
  String? _error;
  List<VolunteerOpportunity> _myOpportunities = [];
  bool _didLoadOpportunities = false;
  Timer? _refreshTimer;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  late TabController _tabController;

  final PageController _calendarController = PageController();
  final ScrollController _listController = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _startPeriodicRefresh();
    _selectedDay = DateTime.now();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _tabController.dispose();
    _calendarController.dispose();
    _listController.dispose();
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
          _myOpportunities = opportunities.where((o) => o.participantStatus == 'approved' || o.participantStatus == 'completed' || o.participantStatus == 'applied').toList();
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

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'approved':
        return Colors.green;
      case 'applied':
        return Colors.orange;
      case 'completed':
        return Colors.blue;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatTime(DateTime? time) {
    if (time == null) return '';
    return DateFormat('HH:mm').format(time);
  }

  Widget _buildCalendarView() {
    return Column(
      children: [
        // Calendar header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: () {
                  setState(() {
                    _focusedDay = DateTime(_focusedDay.year, _focusedDay.month - 1);
                  });
                },
                icon: const Icon(Icons.chevron_left, color: Colors.white),
              ),
              Text(
                DateFormat.yMMMM(Localizations.localeOf(context).languageCode).format(_focusedDay),
                style: const TextStyle(
                  color: Colors.white,
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
                icon: const Icon(Icons.chevron_right, color: Colors.white),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Custom calendar grid
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
              ),
            ),
            child: _buildCalendarGrid(),
          ),
        ),

        // Selected day events
        if (_selectedDay != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${AppLocalizations.of(context)!.volunteerOpportunities} ${DateFormat.yMMMd(Localizations.localeOf(context).languageCode).format(_selectedDay!)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                ..._getEventsForDay(_selectedDay!).map(
                  (opportunity) => _buildEventCard(opportunity),
                ),
                if (_getEventsForDay(_selectedDay!).isEmpty)
                  Text(
                    AppLocalizations.of(context)!.noVolunteerOpportunities,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCalendarGrid() {
    final firstDayOfMonth = DateTime(_focusedDay.year, _focusedDay.month, 1);
    final lastDayOfMonth = DateTime(_focusedDay.year, _focusedDay.month + 1, 0);
    final firstWeekday = firstDayOfMonth.weekday % 7;

    final days = <Widget>[];

    // Week day headers
    final weekdays = List.generate(7, (index) {
      final day = DateTime(2025, 1, 5 + index); // 2025-01-05 is a Sunday
      return DateFormat.E().format(day).substring(0, 1); // Get first letter of weekday
    });
    for (final weekDay in weekdays) {
      days.add(
        Container(
          height: 32,
          alignment: Alignment.center,
          child: Text(
            weekDay,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }

    // Empty cells for days before month start
    for (int i = 0; i < firstWeekday; i++) {
      days.add(Container());
    }

    // Days of the month
    for (int day = 1; day <= lastDayOfMonth.day; day++) {
      final dayDate = DateTime(_focusedDay.year, _focusedDay.month, day);
      final eventsForDay = _getEventsForDay(dayDate);
      final isSelected = _selectedDay != null && _isSameDay(dayDate, _selectedDay!);
      final isToday = _isSameDay(dayDate, DateTime.now());

      days.add(
        GestureDetector(
          onTap: () {
            setState(() {
              _selectedDay = dayDate;
            });
          },
          child: Container(
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: isSelected
                  ? Colors.white.withOpacity(0.3)
                  : isToday
                      ? Colors.white.withOpacity(0.1)
                      : null,
              borderRadius: BorderRadius.circular(8),
              border: isToday ? Border.all(color: Colors.white.withOpacity(0.5)) : null,
            ),
            child: Stack(
              children: [
                Container(
                  height: 40,
                  alignment: Alignment.center,
                  child: Text(
                    day.toString(),
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
                if (eventsForDay.isNotEmpty)
                  Positioned(
                    bottom: 2,
                    right: 2,
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: _getStatusColor(eventsForDay.first.participantStatus),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    }

    return GridView.count(
      crossAxisCount: 7,
      children: days,
    );
  }

  Widget _buildListView() {
    if (_myOpportunities.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 64,
              color: Colors.white.withOpacity(0.7),
            ),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)!.noVolunteerActivities,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 18,
              ),
            ),
          ],
        ),
      );
    }

    // Group opportunities by status
    final groupedOpportunities = <String, List<VolunteerOpportunity>>{};
    for (final opportunity in _myOpportunities) {
      final status = opportunity.participantStatus ?? 'unknown';
      groupedOpportunities.putIfAbsent(status, () => []).add(opportunity);
    }

    return ListView.builder(
      controller: _listController,
      padding: const EdgeInsets.all(16),
      itemCount: groupedOpportunities.length,
      itemBuilder: (context, index) {
        final status = groupedOpportunities.keys.elementAt(index);
        final opportunities = groupedOpportunities[status]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                _getStatusDisplayName(context, status),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ...opportunities.map((opportunity) => _buildListEventCard(opportunity)),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }

  String _getStatusDisplayName(BuildContext context, String status) {
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
        return l10n.statusUnknown;
    }
  }

  Widget _buildEventCard(VolunteerOpportunity opportunity) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getStatusColor(opportunity.participantStatus).withOpacity(0.5),
        ),
      ),
      child: InkWell(
        onTap: () => _openOpportunityDetails(opportunity),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _getStatusColor(opportunity.participantStatus).withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.volunteer_activism,
                color: _getStatusColor(opportunity.participantStatus),
                size: 16,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    opportunity.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    '${_formatTime(opportunity.startTime)} - ${_formatTime(opportunity.endTime)}',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListEventCard(VolunteerOpportunity opportunity) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
        ),
      ),
      child: InkWell(
        onTap: () => _openOpportunityDetails(opportunity),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
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
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        opportunity.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        opportunity.organizerName ?? AppLocalizations.of(context)!.organizer,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(opportunity.participantStatus).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getStatusDisplayName(context, opportunity.participantStatus ?? 'unknown'),
                    style: TextStyle(
                      color: _getStatusColor(opportunity.participantStatus),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: Colors.white.withOpacity(0.7),
                ),
                const SizedBox(width: 6),
                Text(
                  DateFormat.yMMMd(Localizations.localeOf(context).languageCode).format(opportunity.date),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: 16),
                Icon(
                  Icons.access_time,
                  size: 16,
                  color: Colors.white.withOpacity(0.7),
                ),
                const SizedBox(width: 6),
                Text(
                  '${_formatTime(opportunity.startTime)} - ${_formatTime(opportunity.endTime)}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.location_on,
                  size: 16,
                  color: Colors.white.withOpacity(0.7),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    opportunity.location,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

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
              AppLocalizations.of(context)!.myVolunteerSchedule,
              style: const TextStyle(color: Colors.white),
            ),
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white.withOpacity(0.7),
              tabs: [
                Tab(text: AppLocalizations.of(context)!.calendarTab, icon: const Icon(Icons.calendar_month)),
                Tab(text: AppLocalizations.of(context)!.listTab, icon: const Icon(Icons.list)),
              ],
            ),
          ),
          body: _isLoading
              ? Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                )
              : _error != null
                  ? Center(
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
                          ),
                        ],
                      ),
                    )
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: _buildCalendarView(),
                        ),
                        _buildListView(),
                      ],
                    ),
        ),
      ],
    );
  }
}
