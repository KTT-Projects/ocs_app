import 'package:flutter/material.dart';
import 'dart:async';
import 'package:intl/intl.dart';
import '../l10n/app_localizations.dart';
import '../models/volunteer_opportunity.dart';
import '../services/api_client.dart';
import '../widgets/glassmorphic_ui.dart';
import '../widgets/my_activities_filter_dialog.dart';
import 'volunteer_opportunity_details_page.dart';

class MyVolunteerActivitiesPage extends StatefulWidget {
  final ApiClient apiClient;

  const MyVolunteerActivitiesPage({
    super.key,
    required this.apiClient,
  });

  @override
  State<MyVolunteerActivitiesPage> createState() => _MyVolunteerActivitiesPageState();
}

class _MyVolunteerActivitiesPageState extends State<MyVolunteerActivitiesPage> {
  bool _isLoading = true;
  String? _error;
  List<VolunteerOpportunity> _myOpportunities = [];
  bool _didLoadOpportunities = false;
  String? _statusFilter; // null for all, 'applied', 'approved', 'completed', 'cancelled'
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _startPeriodicRefresh();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _startPeriodicRefresh() {
    // Refresh every 30 seconds for new activities
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _loadNewOpportunities();
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
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final opportunities = await widget.apiClient.getMyVolunteerOpportunities(
        context,
        status: _statusFilter,
      );

      if (mounted) {
        setState(() {
          _myOpportunities = opportunities;
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
    // Only load new opportunities if we're not currently loading and have existing data
    if (_isLoading || _myOpportunities.isEmpty) return;

    try {
      final opportunities = await widget.apiClient.getMyVolunteerOpportunities(
        context,
        status: _statusFilter,
      );

      if (mounted) {
        setState(() {
          // Only update if there are new or updated opportunities
          bool hasChanges = false;

          // Check if the list size changed
          if (opportunities.length != _myOpportunities.length) {
            hasChanges = true;
          } else {
            // Check if any opportunity status has changed
            for (int i = 0; i < opportunities.length; i++) {
              if (i < _myOpportunities.length && (opportunities[i].participantStatus != _myOpportunities[i].participantStatus || opportunities[i].status != _myOpportunities[i].status || opportunities[i].certificateIssued != _myOpportunities[i].certificateIssued)) {
                hasChanges = true;
                break;
              }
            }
          }

          if (hasChanges) {
            _myOpportunities = opportunities;
          }
        });
      }
    } catch (e) {
      // Silently ignore errors during background refresh to avoid disrupting the user
      // Could optionally log the error or show a subtle indicator
    }
  }

  Future<void> _reapplyToOpportunity(VolunteerOpportunity opportunity) async {
    try {
      await widget.apiClient.applyToVolunteerOpportunity(context, opportunity.id);

      if (mounted) {
        GlassmorphicUI.showGlassSnackBar(
          context,
          AppLocalizations.of(context)!.volunteerApplied,
        );
        _loadNewOpportunities(); // Use incremental update
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

  Future<void> _cancelApplication(VolunteerOpportunity opportunity) async {
    try {
      await widget.apiClient.cancelVolunteerApplication(context, opportunity.id);

      if (mounted) {
        GlassmorphicUI.showGlassSnackBar(
          context,
          AppLocalizations.of(context)!.applicationCancelled,
        );
        _loadNewOpportunities(); // Use incremental update instead of full reload
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

  Future<void> _downloadCertificate(VolunteerOpportunity opportunity) async {
    try {
      await widget.apiClient.downloadVolunteerCertificate(
        context,
        opportunity.id,
      );

      if (mounted) {
        GlassmorphicUI.showGlassSnackBar(
          context,
          AppLocalizations.of(context)!.certificateDownloaded,
        );
        // Here you would typically save the certificate to device storage
        // or share it using platform-specific code
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
        builder: (context) => VolunteerOpportunityDetailsPage(
          apiClient: widget.apiClient,
          opportunity: opportunity,
        ),
      ),
    ).then((_) => _loadNewOpportunities()); // Use incremental update
  }

  void _showFilterDialog() {
    GlassmorphicUI.showDialog<void>(
      context: context,
      width: 320,
      child: MyActivitiesFilterDialog(
        currentFilter: _statusFilter,
        onFilterChanged: (value) {
          setState(() => _statusFilter = value);
          Navigator.pop(context);
          _loadMyOpportunities(); // Need full reload when filter changes
        },
      ),
    );
  }

  Widget _buildOpportunityCard(VolunteerOpportunity opportunity) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
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
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _getStatusColor(opportunity.participantStatus).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
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
                  ],
                ),
                const SizedBox(height: 8),
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
                    if (opportunity.hoursCompleted != null) ...[
                      Icon(
                        Icons.schedule,
                        color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.7),
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${opportunity.hoursCompleted}${AppLocalizations.of(context)!.hoursUnit}',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.7),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                // Date information with support for one-day volunteers
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.7),
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatDate(opportunity.date),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.7),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                // Time information for single-day events
                if (_formatTimeRange(opportunity).isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.7),
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatTimeRange(opportunity),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.7),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // Action buttons
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
                    onPressed: () => _openOpportunityDetails(opportunity),
                    child: Text(
                      l10n.viewDetails,
                      style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
                    ),
                  ),
                ),
                if (opportunity.participantStatus == 'applied') ...[
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () => _cancelApplication(opportunity),
                    child: Text(
                      l10n.cancelApplication,
                      style: TextStyle(color: Theme.of(context).colorScheme.error),
                    ),
                  ),
                ],
                if (opportunity.participantStatus == 'cancelled' && opportunity.isOpen) ...[
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () => _reapplyToOpportunity(opportunity),
                    child: Text(
                      l10n.reapply,
                      style: TextStyle(color: Colors.green),
                    ),
                  ),
                ],
                if (opportunity.participantStatus == 'completed' && opportunity.certificateIssued == true) ...[
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => _downloadCertificate(opportunity),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    child: Text(
                      l10n.certificateButton,
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
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

  String _formatTimeRange(VolunteerOpportunity opportunity) {
    if (opportunity.startTime != null && opportunity.endTime != null) {
      final startTime = '${opportunity.startTime!.hour.toString().padLeft(2, '0')}:${opportunity.startTime!.minute.toString().padLeft(2, '0')}';
      final endTime = '${opportunity.endTime!.hour.toString().padLeft(2, '0')}:${opportunity.endTime!.minute.toString().padLeft(2, '0')}';
      return '$startTime - $endTime';
    }
    return '';
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final inputDate = DateTime(date.year, date.month, date.day);

    if (inputDate == today) {
      return AppLocalizations.of(context)!.today;
    } else if (inputDate == tomorrow) {
      return AppLocalizations.of(context)!.tomorrow;
    } else {
      return DateFormat.Md(Localizations.localeOf(context).languageCode).format(date);
    }
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
                        l10n.myVolunteerActivities,
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
                  ],
                ),
              ),
              // Main content
              Expanded(
                child: _buildBody(),
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

    if (_myOpportunities.isEmpty) {
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
              l10n.noVolunteerActivities,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.7),
                fontSize: 18,
              ),
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
        onRefresh: _loadMyOpportunities,
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: _myOpportunities.length,
          itemBuilder: (context, index) {
            final opportunity = _myOpportunities[index];
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: _buildOpportunityCard(opportunity),
            );
          },
        ),
      ),
    );
  }
}
