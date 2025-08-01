import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:ui';
import '../l10n/app_localizations.dart';
import '../models/volunteer_opportunity.dart';
import '../services/api_client.dart';
import '../widgets/glassmorphic_ui.dart';
import '../widgets/confirm_dialog.dart';
import 'create_volunteer_opportunity_page.dart';
import 'volunteer_details_page.dart';
import 'volunteer_history_page.dart';

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
  String _sortBy = 'newest'; // 'newest', 'oldest', 'popular', 'upcoming'
  String _statusFilter = 'all'; // 'all', 'open', 'full', 'completed', 'cancelled'
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    widget.apiClient.addListener(_onApiClientChanged);
    _startPeriodicRefresh();
  }

  @override
  void dispose() {
    widget.apiClient.removeListener(_onApiClientChanged);
    _refreshTimer?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _startPeriodicRefresh() {
    // Refresh every 30 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _loadOpportunities();
    });
  }

  void _onApiClientChanged() {
    _didLoadOpportunities = false;
    _opportunities = null;
    _loadOpportunities();
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
      sortBy: _sortBy,
      status: _statusFilter == 'all' ? null : _statusFilter,
      searchQuery: _searchQuery.isEmpty ? null : _searchQuery,
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

  Future<void> _refreshOpportunities() async {
    try {
      final opportunities = await widget.apiClient.getVolunteerOpportunities(
        context,
        sortBy: _sortBy,
        status: _statusFilter == 'all' ? null : _statusFilter,
        searchQuery: _searchQuery.isEmpty ? null : _searchQuery,
      );
      if (mounted) {
        setState(() {
          _opportunities = opportunities;
        });
      }
    } catch (_) {
      // Ignore refresh errors
    }
  }

  Future<void> _registerForOpportunity(VolunteerOpportunity opportunity) async {
    try {
      await widget.apiClient.registerForVolunteerOpportunity(
        context,
        opportunity.id,
      );
      if (mounted) {
        setState(() {
          final index = _opportunities!.indexWhere((o) => o.id == opportunity.id);
          if (index != -1) {
            final updated = _opportunities![index].copyWith(
              isRegistered: true,
              registeredCount: _opportunities![index].registeredCount + 1,
            );
            _opportunities![index] = updated;
          }
        });
        GlassmorphicUI.showGlassSnackBar(
          context,
          AppLocalizations.of(context)!.volunteerRegistrationSuccess,
        );
      }
    } catch (e) {
      if (mounted) {
        GlassmorphicUI.showGlassSnackBar(
          context,
          e.toString(),
          isError: true,
        );
      }
    }
  }

  Future<void> _unregisterFromOpportunity(VolunteerOpportunity opportunity) async {
    try {
      await widget.apiClient.unregisterFromVolunteerOpportunity(
        context,
        opportunity.id,
      );
      if (mounted) {
        setState(() {
          final index = _opportunities!.indexWhere((o) => o.id == opportunity.id);
          if (index != -1) {
            final updated = _opportunities![index].copyWith(
              isRegistered: false,
              registeredCount: _opportunities![index].registeredCount - 1,
            );
            _opportunities![index] = updated;
          }
        });
        GlassmorphicUI.showGlassSnackBar(
          context,
          AppLocalizations.of(context)!.volunteerUnregistrationSuccess,
        );
      }
    } catch (e) {
      if (mounted) {
        GlassmorphicUI.showGlassSnackBar(
          context,
          e.toString(),
          isError: true,
        );
      }
    }
  }

  void _openOpportunityDetails(VolunteerOpportunity opportunity) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VolunteerDetailsPage(
          apiClient: widget.apiClient,
          opportunity: opportunity,
        ),
      ),
    ).then((_) {
      _loadOpportunities();
    });
  }

  void _openCreateOpportunity() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => CreateVolunteerOpportunityPage(apiClient: widget.apiClient),
      ),
    );
    if (result == true && mounted) {
      _loadOpportunities();
    }
  }

  void _openVolunteerHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VolunteerHistoryPage(apiClient: widget.apiClient),
      ),
    ).then((_) {
      _loadOpportunities();
    });
  }

  void _onSearchChanged(String value) {
    setState(() {
      _searchQuery = value;
    });
  }

  void _onSearchSubmitted() {
    _loadOpportunities();
    _searchFocusNode.unfocus();
  }

  void _clearSearch() {
    setState(() {
      _searchQuery = '';
      _searchController.clear();
    });
    _loadOpportunities();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final filteredOpportunities = _opportunities ?? [];

    return Scaffold(
      extendBodyBehindAppBar: true,
      extendBody: true,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        toolbarHeight: 48,
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 0,
        title: Container(
          height: 42,
          margin: const EdgeInsets.only(top: 4),
          child: Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: 2,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return GlassmorphicUI.buildTab(
                          context: context,
                          icon: Icons.volunteer_activism,
                          label: l10n.volunteerOpportunities,
                          selected: true,
                          onTap: () {},
                        );
                      } else {
                        return GlassmorphicUI.buildTab(
                          context: context,
                          icon: Icons.history,
                          label: l10n.volunteerMyHistory,
                          selected: false,
                          onTap: _openVolunteerHistory,
                        );
                      }
                    },
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
                    onPressed: () async {
                      final String? selectedStatus = await GlassmorphicUI.showDialog<String>(
                        context: context,
                        width: 320,
                        child: _buildStatusFilterDialog(),
                      );
                      if (selectedStatus != null) {
                        setState(() {
                          _statusFilter = selectedStatus;
                        });
                        _loadOpportunities();
                      }
                    },
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
                    onPressed: () async {
                      final String? selected = await GlassmorphicUI.showDialog<String>(
                        context: context,
                        width: 320,
                        child: _buildSortMenuDialog(),
                      );
                      if (selected != null) {
                        setState(() {
                          _sortBy = selected;
                        });
                        _loadOpportunities();
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: Stack(
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
          if (_isLoading)
            Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).colorScheme.onPrimary,
                ),
              ),
            )
          else if (_error != null)
            Center(
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
            )
          else
            Column(
              children: [
                // Search bar
                Padding(
                  padding: EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top + 56,
                    left: 16,
                    right: 16,
                    bottom: 16,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.background.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 12),
                        Icon(
                          Icons.search,
                          color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.7),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            focusNode: _searchFocusNode,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onPrimary,
                            ),
                            decoration: InputDecoration(
                              hintText: l10n.volunteerSearch,
                              hintStyle: TextStyle(
                                color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.5),
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            onChanged: _onSearchChanged,
                            onSubmitted: (_) => _onSearchSubmitted(),
                          ),
                        ),
                        if (_searchQuery.isNotEmpty)
                          IconButton(
                            icon: Icon(
                              Icons.clear,
                              color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.7),
                              size: 20,
                            ),
                            onPressed: _clearSearch,
                          ),
                      ],
                    ),
                  ),
                ),
                // Opportunities list
                Expanded(
                  child: filteredOpportunities.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.volunteer_activism,
                                size: 64,
                                color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.3),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                l10n.volunteerNoOpportunities,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.onPrimary,
                                  fontSize: 18,
                                ),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _refreshOpportunities,
                          child: ListView.builder(
                            padding: const EdgeInsets.only(
                              left: 16,
                              right: 16,
                              bottom: 80,
                            ),
                            itemCount: filteredOpportunities.length,
                            itemBuilder: (context, index) {
                              final opportunity = filteredOpportunities[index];
                              return _buildOpportunityCard(opportunity);
                            },
                          ),
                        ),
                ),
              ],
            ),
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
    );
  }

  Widget _buildOpportunityCard(VolunteerOpportunity opportunity) {
    final l10n = AppLocalizations.of(context)!;
    final isFull = opportunity.registeredCount >= opportunity.maxParticipants;
    final isRegistered = opportunity.isRegistered ?? false;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.background.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.3),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _openOpportunityDetails(opportunity),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with title and status
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
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getStatusColor(opportunity.status).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _getStatusColor(opportunity.status),
                          ),
                        ),
                        child: Text(
                          _getStatusText(opportunity.status),
                          style: TextStyle(
                            color: _getStatusColor(opportunity.status),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Description
                  Text(
                    opportunity.description,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.8),
                      fontSize: 14,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  // Footer with details and actions
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.7),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          _formatDate(opportunity.startDate),
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.7),
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Icon(
                        Icons.people,
                        size: 16,
                        color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.7),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${opportunity.registeredCount}/${opportunity.maxParticipants}',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.7),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Action buttons
                  Row(
                    children: [
                      if (isRegistered)
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: Icon(
                              Icons.cancel,
                              size: 16,
                              color: Theme.of(context).colorScheme.error,
                            ),
                            label: Text(
                              l10n.volunteerUnregister,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                            onPressed: () => _unregisterFromOpportunity(opportunity),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                          ),
                        )
                      else if (isFull)
                        Expanded(
                          child: Text(
                            l10n.volunteerFull,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        )
                      else
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: Icon(
                              Icons.how_to_reg,
                              size: 16,
                              color: Theme.of(context).colorScheme.onPrimary,
                            ),
                            label: Text(
                              l10n.volunteerRegister,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onPrimary,
                              ),
                            ),
                            onPressed: () => _registerForOpportunity(opportunity),
                          ),
                        ),
                      const SizedBox(width: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.background.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: IconButton(
                          icon: Icon(
                            Icons.info_outline,
                            size: 20,
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                          onPressed: () => _openOpportunityDetails(opportunity),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusFilterDialog() {
    final l10n = AppLocalizations.of(context)!;
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            l10n.volunteerStatus,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const Divider(),
        _buildStatusFilterOption('all', l10n.volunteerStatusOpen),
        _buildStatusFilterOption('open', l10n.volunteerStatusOpen),
        _buildStatusFilterOption('full', l10n.volunteerStatusFull),
        _buildStatusFilterOption('completed', l10n.volunteerStatusCompleted),
        _buildStatusFilterOption('cancelled', l10n.volunteerStatusCancelled),
      ],
    );
  }

  Widget _buildStatusFilterOption(String value, String label) {
    final isSelected = _statusFilter == value;
    
    return ListTile(
      title: Text(
        label,
        style: TextStyle(
          color: Theme.of(context).colorScheme.onPrimary,
        ),
      ),
      trailing: isSelected
          ? Icon(
              Icons.check,
              color: Theme.of(context).colorScheme.primary,
            )
          : null,
      onTap: () => Navigator.pop(context, value),
    );
  }

  Widget _buildSortMenuDialog() {
    final l10n = AppLocalizations.of(context)!;
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            l10n.volunteerSortBy,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const Divider(),
        _buildSortOption('newest', l10n.volunteerSortNewest),
        _buildSortOption('oldest', l10n.volunteerSortOldest),
        _buildSortOption('popular', l10n.volunteerSortPopular),
        _buildSortOption('upcoming', l10n.volunteerSortUpcoming),
      ],
    );
  }

  Widget _buildSortOption(String value, String label) {
    final isSelected = _sortBy == value;
    
    return ListTile(
      title: Text(
        label,
        style: TextStyle(
          color: Theme.of(context).colorScheme.onPrimary,
        ),
      ),
      trailing: isSelected
          ? Icon(
              Icons.check,
              color: Theme.of(context).colorScheme.primary,
            )
          : null,
      onTap: () => Navigator.pop(context, value),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'open':
        return Colors.green;
      case 'full':
        return Colors.orange;
      case 'completed':
        return Colors.blue;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String? status) {
    final l10n = AppLocalizations.of(context)!;
    switch (status?.toLowerCase()) {
      case 'open':
        return l10n.volunteerStatusOpen;
      case 'full':
        return l10n.volunteerStatusFull;
      case 'completed':
        return l10n.volunteerStatusCompleted;
      case 'cancelled':
        return l10n.volunteerStatusCancelled;
      default:
        return l10n.volunteerStatusOpen;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = date.difference(now);
    
    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()}y';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()}mo';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'now';
    }
  }
}
