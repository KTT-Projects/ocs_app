import 'package:flutter/material.dart';
import 'dart:async';
import '../l10n/app_localizations.dart';
import '../models/volunteer_opportunity.dart';
import '../services/api_client.dart';
import '../widgets/volunteer_opportunity_list_item.dart';
import '../widgets/glassmorphic_ui.dart';
import '../widgets/volunteer_sort_dialog.dart';
import '../widgets/volunteer_filter_dialog.dart';
import 'create_volunteer_opportunity_page.dart';
import 'volunteer_opportunity_details_page.dart';
import 'my_volunteer_activities_page.dart';
import '../pages/enhanced_volunteer_schedule_page.dart';

class VolunteerPage extends StatefulWidget {
  final ApiClient apiClient;

  const VolunteerPage({
    super.key,
    required this.apiClient,
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
  String? _currentToken;

  @override
  void initState() {
    super.initState();
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
    // Refresh every 30 seconds for new opportunities, like feeds
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
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
      final opportunities = await widget.apiClient.getVolunteerOpportunities(
        context,
        status: _statusFilter,
        sort: _sortBy,
      );

      if (mounted) {
        setState(() {
          _opportunities = opportunities;
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
      final newOpportunities = await widget.apiClient.getVolunteerOpportunities(
        context,
        sort: _sortBy,
        status: _statusFilter,
      );

      if (mounted) {
        setState(() {
          // Only update if there are changes
          bool hasChanges = false;

          // Check if the list size changed
          if (newOpportunities.length != _opportunities!.length) {
            hasChanges = true;
          } else {
            // Check if any opportunity has changed
            for (int i = 0; i < newOpportunities.length; i++) {
              if (i < _opportunities!.length && (newOpportunities[i].status != _opportunities![i].status || newOpportunities[i].participantCount != _opportunities![i].participantCount || newOpportunities[i].isParticipant != _opportunities![i].isParticipant || newOpportunities[i].participantStatus != _opportunities![i].participantStatus)) {
                hasChanges = true;
                break;
              }
            }
          }

          if (hasChanges) {
            _opportunities = newOpportunities;
          }
        });
      }
    } catch (e) {
      // Silently ignore errors during background refresh to avoid disrupting the user
    }
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
    ).then((_) => _loadNewOpportunities());
  }

  void _openCreateOpportunity() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateVolunteerOpportunityPage(
          apiClient: widget.apiClient,
        ),
      ),
    ).then((_) => _loadNewOpportunities());
  }

  void _openMyActivities() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MyVolunteerActivitiesPage(
          apiClient: widget.apiClient,
        ),
      ),
    );
  }

  void _openSchedule() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EnhancedVolunteerSchedulePage(
          apiClient: widget.apiClient,
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
        onFilterChanged: (value) {
          setState(() => _statusFilter = value);
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
          body: Column(
            children: [
              // Custom AppBar with glassmorphic style similar to feeds page
              Container(
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 8,
                  left: 16,
                  right: 16,
                  bottom: 8,
                ),
                child: Row(
                  children: [
                    // Title
                    Expanded(
                      child: Text(
                        l10n.volunteerFeature,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    // Filter button
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
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
                            Icons.filter_list,
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                          onPressed: _showFilterDialog,
                        ),
                      ),
                    ),
                    // Sort button
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
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
                            Icons.sort,
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                          onPressed: _showSortDialog,
                        ),
                      ),
                    ),
                    // My Activities button
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
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
                            Icons.history,
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                          onPressed: _openMyActivities,
                        ),
                      ),
                    ),
                    // Schedule button
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
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
                            Icons.calendar_today,
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                          onPressed: _openSchedule,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Main content
              Expanded(
                child: Stack(
                  children: [
                    _buildBody(),
                    // Glassmorphic floating button
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
                            l10n.createVolunteerOpportunity,
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
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBody() {
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
              onPressed: _loadOpportunities,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.errorContainer,
                foregroundColor: Theme.of(context).colorScheme.onErrorContainer,
              ),
            ),
          ],
        ),
      );
    }

    if (_opportunities == null || _opportunities!.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.volunteer_activism_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.7),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.noVolunteerOpportunities,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.7),
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _openCreateOpportunity,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.secondary,
                foregroundColor: Colors.white,
              ),
              child: Text(l10n.createOpportunity),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.only(
        left: 8,
        right: 8,
        bottom: MediaQuery.of(context).padding.bottom + 24,
      ),
      child: RefreshIndicator(
        onRefresh: _loadOpportunities,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _opportunities!.length,
              itemBuilder: (context, index) {
                final opportunity = _opportunities![index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: VolunteerOpportunityListItem(
                    opportunity: opportunity,
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
      ),
    );
  }
}
