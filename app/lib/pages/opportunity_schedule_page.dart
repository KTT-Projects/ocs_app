import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../models/opportunity_experience.dart';
import '../models/volunteer_opportunity.dart';
import '../services/api_client.dart';
import 'volunteer_opportunity_details_page.dart';
import 'package:intl/intl.dart';
import '../widgets/glassmorphic_ui.dart';

class OpportunitySchedulePage extends StatefulWidget {
  final ApiClient apiClient;
  final String? opportunityType;

  const OpportunitySchedulePage({
    super.key,
    required this.apiClient,
    this.opportunityType,
  });

  @override
  State<OpportunitySchedulePage> createState() =>
      _OpportunitySchedulePageState();
}

class _OpportunitySchedulePageState extends State<OpportunitySchedulePage>
    with TickerProviderStateMixin {
  static const double _maxContentWidth = 1180;

  bool _isLoading = true;
  String? _error;
  List<VolunteerOpportunity> _myOpportunities = [];
  bool _didLoadOpportunities = false;
  Timer? _refreshTimer;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  late TabController _tabController;

  final ScrollController _listController = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
    _startPeriodicRefresh();
    _selectedDay = DateTime.now();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _tabController.dispose();
    _listController.dispose();
    super.dispose();
  }

  void _startPeriodicRefresh() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (_) {
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

      final opportunities = await _fetchMyOpportunities();

      if (mounted) {
        setState(() {
          _myOpportunities = opportunities
              .where((o) =>
                  o.participantStatus == 'approved' ||
                  o.participantStatus == 'completed' ||
                  o.participantStatus == 'applied')
              .toList();
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

  Future<List<VolunteerOpportunity>> _fetchMyOpportunities() async {
    if (widget.opportunityType != null) {
      return widget.apiClient.getMyVolunteerOpportunities(
        context,
        status: null,
        opportunityType: widget.opportunityType,
      );
    }

    final results = await Future.wait([
      widget.apiClient.getMyVolunteerOpportunities(
        context,
        status: null,
        opportunityType: OpportunityExperience.event.apiType,
      ),
      widget.apiClient.getMyVolunteerOpportunities(
        context,
        status: null,
        opportunityType: OpportunityExperience.volunteer.apiType,
      ),
    ]);

    return [
      ...results[0],
      ...results[1],
    ]..sort((a, b) {
        final dateComparison = a.date.compareTo(b.date);
        if (dateComparison != 0) return dateComparison;
        final aStart = a.startTime ?? a.date;
        final bStart = b.startTime ?? b.date;
        return aStart.compareTo(bStart);
      });
  }

  List<VolunteerOpportunity> _getEventsForDay(DateTime day) {
    return _myOpportunities.where((opportunity) {
      return _isSameDay(opportunity.date, day);
    }).toList();
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _localized(String english, String japanese) {
    return Localizations.localeOf(context).languageCode == 'ja'
        ? japanese
        : english;
  }

  String get _scheduleTitle => _localized('My Schedule', '予定');
  String get _opportunitiesLabel => _localized('Opportunities', '募集・イベント');
  String get _noOpportunitiesLabel =>
      _localized('No opportunities scheduled', '予定されている募集・イベントはありません');

  void _openOpportunityDetails(VolunteerOpportunity opportunity) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VolunteerOpportunityDetailsPage(
          apiClient: widget.apiClient,
          opportunity: opportunity,
          experience: opportunity.experience,
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

  void _changeMonth(int delta) {
    setState(() {
      _focusedDay = DateTime(_focusedDay.year, _focusedDay.month + delta, 1);
      _selectedDay = DateTime(_focusedDay.year, _focusedDay.month, 1);
    });
  }

  void _goToToday() {
    final now = DateTime.now();
    setState(() {
      _focusedDay = DateTime(now.year, now.month, 1);
      _selectedDay = now;
    });
  }

  Widget _glassCard({
    required Widget child,
    EdgeInsets padding = const EdgeInsets.all(16),
    double radius = 16,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: colorScheme.background.withOpacity(0.18),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: colorScheme.onPrimary.withOpacity(0.15)),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildStatusChip(String? status) {
    final color = _getStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.14),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.6)),
      ),
      child: Text(
        _getStatusDisplayName(context, status ?? 'unknown'),
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildTabSwitcher() {
    final l10n = AppLocalizations.of(context)!;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          GlassmorphicUI.buildTab(
            context: context,
            icon: Icons.calendar_month,
            label: l10n.calendarTab,
            selected: _tabController.index == 0,
            onTap: () => _tabController.animateTo(0),
          ),
          GlassmorphicUI.buildTab(
            context: context,
            icon: Icons.list,
            label: l10n.listTab,
            selected: _tabController.index == 1,
            onTap: () => _tabController.animateTo(1),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusLegend() {
    const statuses = ['approved', 'applied', 'completed', 'cancelled'];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: statuses
          .map(
            (status) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: _getStatusColor(status).withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: _getStatusColor(status).withOpacity(0.45)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _getStatusColor(status),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _getStatusDisplayName(context, status),
                    style: TextStyle(
                      color: _getStatusColor(status),
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildHeader() {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final localeCode = Localizations.localeOf(context).languageCode;
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompactLayout = screenWidth < 420;
    final monthEvents = _myOpportunities
        .where((o) =>
            o.date.year == _focusedDay.year &&
            o.date.month == _focusedDay.month)
        .length;

    return Padding(
      padding: EdgeInsets.fromLTRB(
          16, MediaQuery.of(context).padding.top + 8, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GlassmorphicUI.buildAppBarIconButton(
                context: context,
                icon: Icons.arrow_back,
                margin: EdgeInsets.zero,
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _scheduleTitle,
                  style: TextStyle(
                    color: colorScheme.onPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildTabSwitcher(),
          if (_tabController.index == 0) ...[
            const SizedBox(height: 10),
            _glassCard(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: isCompactLayout
                  ? Column(
                      children: [
                        Row(
                          children: [
                            GlassmorphicUI.buildAppBarIconButton(
                              context: context,
                              icon: Icons.chevron_left,
                              size: 40,
                              margin: EdgeInsets.zero,
                              onPressed: () => _changeMonth(-1),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildMonthSummary(
                                monthEvents: monthEvents,
                                monthLabel: DateFormat.MMMM(localeCode)
                                    .format(_focusedDay),
                              ),
                            ),
                            const SizedBox(width: 8),
                            GlassmorphicUI.buildAppBarIconButton(
                              context: context,
                              icon: Icons.chevron_right,
                              size: 40,
                              margin: EdgeInsets.zero,
                              onPressed: () => _changeMonth(1),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: _buildTodayButton(l10n, colorScheme),
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        GlassmorphicUI.buildAppBarIconButton(
                          context: context,
                          icon: Icons.chevron_left,
                          size: 42,
                          margin: EdgeInsets.zero,
                          onPressed: () => _changeMonth(-1),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildMonthSummary(
                            monthEvents: monthEvents,
                            monthLabel:
                                DateFormat.MMMM(localeCode).format(_focusedDay),
                          ),
                        ),
                        _buildTodayButton(l10n, colorScheme),
                        const SizedBox(width: 8),
                        GlassmorphicUI.buildAppBarIconButton(
                          context: context,
                          icon: Icons.chevron_right,
                          size: 42,
                          margin: EdgeInsets.zero,
                          onPressed: () => _changeMonth(1),
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: 10),
            _buildStatusLegend(),
          ],
        ],
      ),
    );
  }

  Widget _buildMonthSummary({
    required int monthEvents,
    required String monthLabel,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          monthLabel,
          style: TextStyle(
            color: colorScheme.onPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event,
              size: 14,
              color: colorScheme.onPrimary.withOpacity(0.65),
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                '$monthEvents $_opportunitiesLabel',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colorScheme.onPrimary.withOpacity(0.75),
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTodayButton(AppLocalizations l10n, ColorScheme colorScheme) {
    return GestureDetector(
      onTap: _goToToday,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: colorScheme.secondary.withOpacity(0.18),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: colorScheme.onPrimary.withOpacity(0.15),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.my_location,
              size: 16,
              color: colorScheme.onPrimary,
            ),
            const SizedBox(width: 6),
            Text(
              l10n.today,
              style: TextStyle(
                color: colorScheme.onPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarView() {
    final l10n = AppLocalizations.of(context)!;
    final selectedEvents = _selectedDay != null
        ? _getEventsForDay(_selectedDay!)
        : <VolunteerOpportunity>[];
    final localeCode = Localizations.localeOf(context).languageCode;
    final colorScheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).padding.bottom + 24,
        top: 4,
      ),
      child: Column(
        children: [
          _glassCard(
            padding: const EdgeInsets.all(10),
            child: _buildCalendarGrid(),
          ),
          const SizedBox(height: 14),
          _glassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: colorScheme.secondary.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.event_available,
                        color: colorScheme.onPrimary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _selectedDay != null
                                ? DateFormat.MMMMEEEEd(localeCode)
                                    .format(_selectedDay!)
                                : l10n.calendarTab,
                            style: TextStyle(
                              color: colorScheme.onPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _opportunitiesLabel,
                            style: TextStyle(
                              color: colorScheme.onPrimary.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: colorScheme.background.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: colorScheme.onPrimary.withOpacity(0.2),
                        ),
                      ),
                      child: Text(
                        '${selectedEvents.length}',
                        style: TextStyle(
                          color: colorScheme.onPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (selectedEvents.isNotEmpty)
                  ...selectedEvents
                      .map((opportunity) => _buildEventCard(opportunity))
                else
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        _noOpportunitiesLabel,
                        style: TextStyle(
                          color: colorScheme.onPrimary.withOpacity(0.7),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarGrid() {
    final firstDayOfMonth = DateTime(_focusedDay.year, _focusedDay.month, 1);
    final lastDayOfMonth = DateTime(_focusedDay.year, _focusedDay.month + 1, 0);
    final firstWeekday = firstDayOfMonth.weekday % 7;
    final rowCount = ((firstWeekday + lastDayOfMonth.day) / 7).ceil();
    final colorScheme = Theme.of(context).colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompactLayout = screenWidth < 420;
    final gridSpacing = isCompactLayout ? 6.0 : 8.0;
    final dayFontSize = isCompactLayout ? 18.0 : 15.0;
    final markerSize = isCompactLayout ? 6.0 : 7.0;
    final markerMargin = isCompactLayout ? 1.5 : 2.0;
    final localeCode = Localizations.localeOf(context).languageCode;

    final weekdays = List.generate(7, (index) {
      final day = DateTime(2025, 1, 5 + index);
      final label = DateFormat.E(localeCode).format(day);
      return label.length > 2 ? label.substring(0, 2) : label;
    });

    final days = <Widget>[];
    for (int i = 0; i < firstWeekday; i++) {
      days.add(Container());
    }

    for (int day = 1; day <= lastDayOfMonth.day; day++) {
      final dayDate = DateTime(_focusedDay.year, _focusedDay.month, day);
      final eventsForDay = _getEventsForDay(dayDate);
      final isSelected =
          _selectedDay != null && _isSameDay(dayDate, _selectedDay!);
      final isToday = _isSameDay(dayDate, DateTime.now());
      final highlightColor =
          isSelected ? colorScheme.secondary : colorScheme.onPrimary;

      days.add(
        GestureDetector(
          onTap: () {
            setState(() {
              _selectedDay = dayDate;
            });
          },
          child: Container(
            decoration: BoxDecoration(
              color: isSelected
                  ? colorScheme.secondary.withOpacity(0.28)
                  : eventsForDay.isNotEmpty
                      ? colorScheme.background.withOpacity(0.2)
                      : colorScheme.background.withOpacity(0.10),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected
                    ? colorScheme.onPrimary.withOpacity(0.55)
                    : isToday
                        ? colorScheme.onPrimary.withOpacity(0.6)
                        : colorScheme.onPrimary.withOpacity(0.08),
                width: isSelected || isToday ? 1.4 : 1,
              ),
              boxShadow: isSelected || eventsForDay.isNotEmpty
                  ? [
                      BoxShadow(
                        color: (isSelected
                                ? colorScheme.secondary
                                : colorScheme.background)
                            .withOpacity(0.18),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      )
                    ]
                  : null,
            ),
            child: Stack(
              children: [
                if (isToday)
                  Positioned(
                    top: isCompactLayout ? 8 : 10,
                    right: isCompactLayout ? 8 : 10,
                    child: isCompactLayout
                        ? Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: colorScheme.onPrimary.withOpacity(0.75),
                              shape: BoxShape.circle,
                            ),
                          )
                        : Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: colorScheme.onPrimary.withOpacity(0.14),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              AppLocalizations.of(context)!.today,
                              style: TextStyle(
                                color: colorScheme.onPrimary.withOpacity(0.7),
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                  ),
                Positioned.fill(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                        isCompactLayout ? 8 : 9,
                        isCompactLayout ? 8 : 9,
                        isCompactLayout ? 8 : 9,
                        isCompactLayout ? 8 : 9),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          day.toString(),
                          style: TextStyle(
                            color: highlightColor,
                            fontWeight:
                                isSelected ? FontWeight.w800 : FontWeight.w700,
                            fontSize: dayFontSize,
                          ),
                        ),
                        const Spacer(),
                        if (eventsForDay.isNotEmpty)
                          Row(
                            children: [
                              ...eventsForDay.take(3).map((event) {
                                return Container(
                                  width: markerSize,
                                  height: markerSize,
                                  margin: EdgeInsets.only(right: markerMargin),
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(
                                        event.participantStatus),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: colorScheme.background
                                          .withOpacity(0.4),
                                    ),
                                  ),
                                );
                              }),
                              if (eventsForDay.length > 3) ...[
                                const SizedBox(width: 4),
                                Text(
                                  '+${eventsForDay.length - 3}',
                                  style: TextStyle(
                                    color:
                                        colorScheme.onPrimary.withOpacity(0.7),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ],
                          )
                        else
                          Container(
                            width: 20,
                            height: 2,
                            decoration: BoxDecoration(
                              color: colorScheme.onPrimary.withOpacity(0.14),
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final layoutWidth = constraints.maxWidth;
        final isWideLayout = layoutWidth >= 960;
        final tileWidth =
            ((constraints.maxWidth - (gridSpacing * 6)) / 7).toDouble();
        final cellHeight = (tileWidth *
                (isCompactLayout
                    ? 1.02
                    : isWideLayout
                        ? 0.68
                        : 0.82))
            .clamp(72.0, isWideLayout ? 104.0 : 116.0)
            .toDouble();
        final gridHeight =
            (rowCount * cellHeight) + ((rowCount - 1) * gridSpacing);

        return Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: colorScheme.background.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: weekdays
                    .map(
                      (weekDay) => Expanded(
                        child: Center(
                          child: Text(
                            weekDay,
                            style: TextStyle(
                              color: colorScheme.onPrimary.withOpacity(0.78),
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: gridHeight,
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                itemCount: days.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  mainAxisSpacing: gridSpacing,
                  crossAxisSpacing: gridSpacing,
                  mainAxisExtent: cellHeight,
                ),
                itemBuilder: (context, index) => days[index],
              ),
            ),
          ],
        );
      },
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
              _noOpportunitiesLabel,
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

    final orderedStatuses = [
      'approved',
      'applied',
      'completed',
      'cancelled',
      'unknown'
    ];
    final keys = groupedOpportunities.keys.toList()
      ..sort((a, b) =>
          orderedStatuses.indexOf(a).compareTo(orderedStatuses.indexOf(b)));

    return ListView.builder(
      controller: _listController,
      padding: EdgeInsets.fromLTRB(
          16, 8, 16, MediaQuery.of(context).padding.bottom + 24),
      itemCount: keys.length,
      itemBuilder: (context, index) {
        final status = keys[index];
        final opportunities = groupedOpportunities[status]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: _getStatusColor(status),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _getStatusDisplayName(context, status),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${opportunities.length} $_opportunitiesLabel',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...opportunities.map(
              (opportunity) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: _buildListEventCard(opportunity),
              ),
            ),
            const SizedBox(height: 12),
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
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: _glassCard(
        padding: const EdgeInsets.all(12),
        radius: 14,
        child: InkWell(
          onTap: () => _openOpportunityDetails(opportunity),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _getStatusColor(opportunity.participantStatus)
                      .withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  opportunity.experience.createIcon,
                  color: _getStatusColor(opportunity.participantStatus),
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            opportunity.title,
                            style: TextStyle(
                              color: colorScheme.onPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        _buildStatusChip(opportunity.participantStatus),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 14,
                          color: colorScheme.onPrimary.withOpacity(0.7),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${_formatTime(opportunity.startTime)} - ${_formatTime(opportunity.endTime)}',
                          style: TextStyle(
                            color: colorScheme.onPrimary.withOpacity(0.75),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 14,
                          color: colorScheme.onPrimary.withOpacity(0.7),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            opportunity.location,
                            style: TextStyle(
                              color: colorScheme.onPrimary.withOpacity(0.75),
                              fontSize: 13,
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
        ),
      ),
    );
  }

  Widget _buildListEventCard(VolunteerOpportunity opportunity) {
    final colorScheme = Theme.of(context).colorScheme;
    return _glassCard(
      padding: const EdgeInsets.all(14),
      radius: 18,
      child: InkWell(
        onTap: () => _openOpportunityDetails(opportunity),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _getStatusColor(opportunity.participantStatus)
                        .withOpacity(0.22),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    opportunity.experience.createIcon,
                    color: _getStatusColor(opportunity.participantStatus),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              opportunity.title,
                              style: TextStyle(
                                color: colorScheme.onPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          _buildStatusChip(opportunity.participantStatus),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        opportunity.organizerName ??
                            AppLocalizations.of(context)!.organizer,
                        style: TextStyle(
                          color: colorScheme.onPrimary.withOpacity(0.7),
                          fontSize: 13,
                        ),
                      ),
                    ],
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
                  color: colorScheme.onPrimary.withOpacity(0.7),
                ),
                const SizedBox(width: 6),
                Text(
                  DateFormat.yMMMd(Localizations.localeOf(context).languageCode)
                      .format(opportunity.date),
                  style: TextStyle(
                    color: colorScheme.onPrimary.withOpacity(0.8),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(width: 14),
                Icon(
                  Icons.access_time,
                  size: 16,
                  color: colorScheme.onPrimary.withOpacity(0.7),
                ),
                const SizedBox(width: 6),
                Text(
                  '${_formatTime(opportunity.startTime)} - ${_formatTime(opportunity.endTime)}',
                  style: TextStyle(
                    color: colorScheme.onPrimary.withOpacity(0.8),
                    fontSize: 13,
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
                  color: colorScheme.onPrimary.withOpacity(0.7),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    opportunity.location,
                    style: TextStyle(
                      color: colorScheme.onPrimary.withOpacity(0.8),
                      fontSize: 13,
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

    Widget content;
    if (_isLoading) {
      content = Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(
            Theme.of(context).colorScheme.onPrimary,
          ),
        ),
      );
    } else if (_error != null) {
      content = Center(
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
      );
    } else {
      content = TabBarView(
        controller: _tabController,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _buildCalendarView(),
          _buildListView(),
        ],
      );
    }

    return Stack(
      children: [
        Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(-0.8, -0.95),
                  radius: 1.25,
                  colors: [
                    Theme.of(context).colorScheme.onPrimary.withOpacity(0.12),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ),
        Positioned(
          top: 112,
          right: -28,
          child: IgnorePointer(
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color:
                    Theme.of(context).colorScheme.background.withOpacity(0.10),
              ),
            ),
          ),
        ),
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
          body: LayoutBuilder(
            builder: (context, constraints) {
              final contentWidth = constraints.maxWidth > _maxContentWidth
                  ? _maxContentWidth
                  : constraints.maxWidth;

              return Align(
                alignment: Alignment.topCenter,
                child: SizedBox(
                  width: contentWidth,
                  child: Column(
                    children: [
                      _buildHeader(),
                      Expanded(child: content),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
