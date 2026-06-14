import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math' as math;
import '../l10n/app_localizations.dart';
import '../models/opportunity_experience.dart';
import '../models/volunteer_opportunity.dart';
import '../services/api_client.dart';
import '../widgets/volunteer_opportunity_list_item.dart';
// cSpell:ignore glassmorphic Glassmorphic
import '../widgets/glassmorphic_ui.dart';
import '../widgets/volunteer_sort_dialog.dart';
import '../widgets/volunteer_filter_dialog.dart';
import 'create_volunteer_opportunity_page.dart';
import 'volunteer_opportunity_details_page.dart';
import 'opportunity_schedule_page.dart';

class VolunteerPage extends StatefulWidget {
  final ApiClient apiClient;
  final OpportunityExperience experience;
  final String? initialOpportunityType;
  final bool showTypeFilter;

  const VolunteerPage({
    super.key,
    required this.apiClient,
    this.experience = OpportunityExperience.volunteer,
    this.initialOpportunityType,
    this.showTypeFilter = false,
  });

  @override
  State<VolunteerPage> createState() => _VolunteerPageState();
}

class _VolunteerPageState extends State<VolunteerPage> {
  bool _isLoading = true;
  String? _error;
  List<VolunteerOpportunity>? _opportunities;
  bool _didLoadOpportunities = false;
  Timer? _refreshTimer;
  String _sortBy = 'newest'; // 'newest', 'oldest', 'upcoming'
  String? _statusFilter; // null for all, 'open', 'filled', etc.
  String? _typeFilter;
  String? _currentToken;

  OpportunityExperience get _selectedExperience =>
      _typeFilter == OpportunityExperience.volunteer.apiType
          ? OpportunityExperience.volunteer
          : OpportunityExperience.event;

  @override
  void initState() {
    super.initState();
    _typeFilter = widget.showTypeFilter
        ? widget.initialOpportunityType
        : widget.experience.apiType;
    _currentToken = widget.apiClient.token;
    widget.apiClient.addListener(_onApiClientChanged);
    _startPeriodicRefresh();
  }

  @override
  void dispose() {
    widget.apiClient.removeListener(_onApiClientChanged);
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _startPeriodicRefresh() {
    // Refresh every 10 seconds for new opportunities, like feeds
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _loadNewOpportunities();
    });
  }

  void _onApiClientChanged() {
    if (widget.apiClient.token != _currentToken) {
      _currentToken = widget.apiClient.token;
      _didLoadOpportunities = false;
      _opportunities = null;
      _loadOpportunities();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didLoadOpportunities) {
      _didLoadOpportunities = true;
      _loadOpportunities();
    }
  }

  Future<void> _loadOpportunities() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      final opportunities = await _fetchOpportunities();

      if (mounted) {
        setState(() {
          _opportunities = opportunities.map(_applyReflectionStatus).toList();
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

  Future<void> _loadNewOpportunities() async {
    try {
      final newOpportunities = await _fetchOpportunities();

      if (mounted) {
        final normalized =
            newOpportunities.map(_applyReflectionStatus).toList();
        setState(() {
          // Initialize or only update if there are changes
          if (_opportunities == null) {
            _opportunities = normalized;
            return;
          }
          bool hasChanges = false;
          if (normalized.length != _opportunities!.length) {
            hasChanges = true;
          } else {
            for (int i = 0; i < normalized.length; i++) {
              if (i < _opportunities!.length &&
                  (normalized[i].status != _opportunities![i].status ||
                      normalized[i].participantCount !=
                          _opportunities![i].participantCount ||
                      normalized[i].isParticipant !=
                          _opportunities![i].isParticipant ||
                      normalized[i].participantStatus !=
                          _opportunities![i].participantStatus)) {
                hasChanges = true;
                break;
              }
            }
          }
          if (hasChanges) _opportunities = normalized;
        });
      }
    } catch (e) {
      // Silently ignore errors during background refresh to avoid disrupting the user
    }
  }

  Future<List<VolunteerOpportunity>> _fetchOpportunities() async {
    if (_typeFilter != null) {
      return widget.apiClient.getVolunteerOpportunities(
        context,
        status: _statusFilter,
        sort: _sortBy,
        opportunityType: _typeFilter,
      );
    }

    final results = await Future.wait([
      widget.apiClient.getVolunteerOpportunities(
        context,
        status: _statusFilter,
        sort: _sortBy,
        opportunityType: OpportunityExperience.event.apiType,
      ),
      widget.apiClient.getVolunteerOpportunities(
        context,
        status: _statusFilter,
        sort: _sortBy,
        opportunityType: OpportunityExperience.volunteer.apiType,
      ),
    ]);

    final opportunities = [
      ...results[0],
      ...results[1],
    ];
    opportunities.sort(_compareOpportunities);
    return opportunities;
  }

  int _compareOpportunities(
    VolunteerOpportunity a,
    VolunteerOpportunity b,
  ) {
    switch (_sortBy) {
      case 'oldest':
        return a.createdAt.compareTo(b.createdAt);
      case 'upcoming':
        final dateComparison = a.date.compareTo(b.date);
        if (dateComparison != 0) return dateComparison;
        final aStart = a.startTime ?? a.date;
        final bStart = b.startTime ?? b.date;
        return aStart.compareTo(bStart);
      case 'newest':
      default:
        return b.createdAt.compareTo(a.createdAt);
    }
  }

  VolunteerOpportunity _applyReflectionStatus(VolunteerOpportunity o) {
    if (o.reflectionCount > 0 && o.status != 'completed') {
      return o.copyWith(status: 'completed');
    }
    return o;
  }

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
    ).then((_) => _loadNewOpportunities());
  }

  void _openCreateOpportunity() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateVolunteerOpportunityPage(
          apiClient: widget.apiClient,
          experience: _selectedExperience,
        ),
      ),
    ).then((_) => _loadNewOpportunities());
  }

  void _openSchedule() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OpportunitySchedulePage(
          apiClient: widget.apiClient,
          opportunityType: _typeFilter,
        ),
      ),
    );
  }

  void _showFilterDialog() {
    GlassmorphicUI.showDialog<void>(
      context: context,
      width: 320,
      child: VolunteerFilterDialog(
        currentFilter: _statusFilter,
        currentTypeFilter: widget.showTypeFilter ? _typeFilter : null,
        showTypeFilter: widget.showTypeFilter,
        onFilterChanged: (value) {
          setState(() => _statusFilter = value);
          Navigator.pop(context);
          _loadOpportunities();
        },
        onTypeFilterChanged: (value) {
          setState(() => _typeFilter = value);
          Navigator.pop(context);
          _loadOpportunities();
        },
      ),
    );
  }

  void _showSortDialog() {
    GlassmorphicUI.showDialog<void>(
      context: context,
      width: 320,
      child: VolunteerSortDialog(
        currentSort: _sortBy,
        onSortChanged: (value) {
          setState(() => _sortBy = value);
          Navigator.pop(context);
          _loadOpportunities();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final toolbarHeight = mediaQuery.padding.top + 52;

    return Stack(
      children: [
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
          extendBodyBehindAppBar: true,
          extendBody: true,
          appBar: PreferredSize(
            preferredSize: Size.fromHeight(toolbarHeight),
            child: AppBar(
              automaticallyImplyLeading: false,
              toolbarHeight: toolbarHeight,
              backgroundColor: Colors.transparent,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              scrolledUnderElevation: 0,
              shadowColor: Colors.transparent,
              titleSpacing: 0,
              flexibleSpace: Padding(
                padding: EdgeInsets.only(
                  top: mediaQuery.padding.top + 4,
                  left: 8,
                  right: 8,
                  bottom: 4,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    for (final entry in [
                      {'icon': Icons.filter_list, 'onTap': _showFilterDialog},
                      {'icon': Icons.sort, 'onTap': _showSortDialog},
                      {'icon': Icons.calendar_today, 'onTap': _openSchedule},
                    ]) ...[
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .background
                              .withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Theme.of(context)
                                .colorScheme
                                .onPrimary
                                .withOpacity(0.3),
                          ),
                        ),
                        child: IconButton(
                          iconSize: 20,
                          icon: Icon(entry['icon'] as IconData,
                              color: Theme.of(context).colorScheme.onPrimary),
                          onPressed: entry['onTap'] as void Function()?,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          body: Padding(
            padding: EdgeInsets.only(top: toolbarHeight),
            child: Stack(
              children: [
                _buildBody(),
                // Floating button with a frosted-glass effect
                GlassmorphicUI.buildFloatingButton(
                  context: context,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.add,
                        size: 20,
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _selectedExperience.createAction(context),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                      ),
                    ],
                  ),
                  onTap: _openCreateOpportunity,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBody() {
    final l10n = AppLocalizations.of(context)!;
    final bottomInset = MediaQuery.of(context).padding.bottom;
    const floatingButtonBottomOffset = 32.0;
    const floatingButtonHeight = 52.0;
    const bottomNavHeight = 80.0; // 60px bar + 20px bottom offset in HomePage
    const listBottomSpacing = 24.0;
    final bottomOverlayClearance = math.max(
      bottomNavHeight,
      floatingButtonBottomOffset + floatingButtonHeight,
    );
    final listBottomPadding =
        bottomInset + bottomOverlayClearance + listBottomSpacing;

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
              onPressed: _loadOpportunities,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.errorContainer,
                foregroundColor: Theme.of(context).colorScheme.onErrorContainer,
              ),
            ),
            Icon(
              widget.experience.emptyIcon,
              size: 64,
              color: Theme.of(context)
                  .colorScheme
                  .onPrimary
                  .withValues(alpha: 0.7),
            ),
            const SizedBox(height: 16),
            Text(
              widget.experience.noOpportunities(context),
              style: TextStyle(
                color: Theme.of(context)
                    .colorScheme
                    .onPrimary
                    .withValues(alpha: 0.7),
                fontSize: 18,
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(
        left: 8,
        right: 8,
      ),
      child: ListView.builder(
        padding: EdgeInsets.only(
          top: 8,
          bottom: listBottomPadding,
        ),
        itemCount: _opportunities!.length,
        itemBuilder: (context, index) {
          final opportunity = _opportunities![index];
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: VolunteerOpportunityListItem(
              opportunity: opportunity,
              experience: opportunity.experience,
              showFullDetails: true,
              apiClient: widget.apiClient,
              onTap: () => _openOpportunityDetails(opportunity),
              onOpportunityUpdated: (updatedOpportunity) {
                // Refresh the data from server to ensure consistency
                _loadNewOpportunities();
              },
            ),
          );
        },
      ),
    );
  }
}
