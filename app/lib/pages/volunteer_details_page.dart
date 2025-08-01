import 'package:flutter/material.dart';
import 'package:ocs_app/l10n/app_localizations.dart';
import '../models/volunteer_opportunity.dart';
import '../services/api_client.dart';
import '../widgets/glassmorphic_ui.dart';
import 'volunteer_history_page.dart';

class VolunteerDetailsPage extends StatefulWidget {
  final VolunteerOpportunity opportunity;
  final ApiClient apiClient;

  const VolunteerDetailsPage({
    super.key,
    required this.opportunity,
    required this.apiClient,
  });

  @override
  State<VolunteerDetailsPage> createState() => _VolunteerDetailsPageState();
}

class _VolunteerDetailsPageState extends State<VolunteerDetailsPage> {
  bool _isLoading = false;
  bool _isRegistered = false;
  bool _isOrganizer = false;
  VolunteerOpportunity? _opportunity;

  @override
  void initState() {
    super.initState();
    _opportunity = widget.opportunity;
    _checkRegistrationStatus();
  }

  Future<void> _checkRegistrationStatus() async {
    try {
      // For now, assume user is not registered and not organizer
      // In a real app, you would check this with an API call
      setState(() {
        _isRegistered = false;
        _isOrganizer = false;
      });
    } catch (e) {
      print('Error checking registration status: $e');
    }
  }

  Future<void> _registerForOpportunity() async {
    final l10n = AppLocalizations.of(context)!;
    
    setState(() {
      _isLoading = true;
    });

    try {
      await widget.apiClient.registerForVolunteerOpportunity(context, _opportunity!.id);
      
      setState(() {
        _isRegistered = true;
        _isLoading = false;
      });

      if (mounted) {
        GlassmorphicUI.showGlassSnackBar(
          context,
          l10n.volunteerRegistrationSuccess,
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        GlassmorphicUI.showGlassSnackBar(
          context,
          e.toString(),
          isError: true,
        );
      }
    }
  }

  Future<void> _unregisterFromOpportunity() async {
    final l10n = AppLocalizations.of(context)!;
    
    setState(() {
      _isLoading = true;
    });

    try {
      await widget.apiClient.unregisterFromVolunteerOpportunity(context, _opportunity!.id);
      
      setState(() {
        _isRegistered = false;
        _isLoading = false;
      });

      if (mounted) {
        GlassmorphicUI.showGlassSnackBar(
          context,
          l10n.volunteerUnregistrationSuccess,
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        GlassmorphicUI.showGlassSnackBar(
          context,
          e.toString(),
          isError: true,
        );
      }
    }
  }

  Future<void> _downloadCertificate() async {
    final l10n = AppLocalizations.of(context)!;
    
    setState(() {
      _isLoading = true;
    });

    try {
      final certificateUrl = await widget.apiClient.downloadVolunteerCertificate(
        context,
        _opportunity!.id,
      );
      
      // In a real app, you would handle the certificate download
      // For now, just show a success message
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        GlassmorphicUI.showGlassSnackBar(
          context,
          l10n.certificateDownloadSuccess,
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        GlassmorphicUI.showGlassSnackBar(
          context,
          e.toString(),
          isError: true,
        );
      }
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      extendBodyBehindAppBar: true,
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
              IconButton(
                icon: Icon(
                  Icons.arrow_back,
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
                onPressed: () => Navigator.pop(context),
              ),
              Expanded(
                child: Text(
                  _opportunity!.title,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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
          else if (_opportunity != null)
            SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getStatusColor().withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _getStatusColor().withOpacity(0.5),
                      ),
                    ),
                    child: Text(
                      _getStatusText(),
                      style: TextStyle(
                        color: _getStatusColor(),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Image
                  if (_opportunity!.imageUrl != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        _opportunity!.imageUrl!,
                        width: double.infinity,
                        height: 200,
                        fit: BoxFit.cover,
                      ),
                    ),
                  const SizedBox(height: 16),
                  
                  // Description
                  Text(
                    l10n.description,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.7),
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _opportunity!.description,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimary,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Details
                  _buildDetailCard(
                    icon: Icons.location_on,
                    title: l10n.location,
                    value: _opportunity!.location,
                  ),
                  const SizedBox(height: 16),
                  
                  _buildDetailCard(
                    icon: Icons.calendar_today,
                    title: l10n.startDate,
                    value: _formatDateTime(_opportunity!.startDate),
                  ),
                  const SizedBox(height: 16),
                  
                  if (_opportunity!.endDate != null)
                    _buildDetailCard(
                      icon: Icons.date_range,
                      title: l10n.endDate,
                      value: _formatDateTime(_opportunity!.endDate!),
                    ),
                  const SizedBox(height: 16),
                  
                  _buildDetailCard(
                    icon: Icons.group,
                    title: l10n.maxParticipants,
                    value: '${_opportunity!.registeredCount}/${_opportunity!.maxParticipants}',
                  ),
                  const SizedBox(height: 16),
                  
                  _buildDetailCard(
                    icon: Icons.person,
                    title: l10n.organizer,
                    value: _opportunity!.organizer,
                  ),
                  const SizedBox(height: 16),
                  
                  if (_opportunity!.organizerContact != null)
                    _buildDetailCard(
                      icon: Icons.contact_mail,
                      title: l10n.organizerContact,
                      value: _opportunity!.organizerContact!,
                    ),
                  const SizedBox(height: 24),
                  
                  // Tags
                  if (_opportunity!.tags != null && _opportunity!.tags!.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.tags,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.7),
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _opportunity!.tags!.map((tag) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              tag,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onPrimary,
                              ),
                            ),
                          )).toList(),
                        ),
                      ],
                    ),
                  const SizedBox(height: 32),
                  
                  // Action buttons
                  if (!_isOrganizer)
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: Icon(
                              _isRegistered ? Icons.logout : Icons.volunteer_activism,
                              color: Theme.of(context).colorScheme.onPrimary,
                            ),
                            label: Text(
                              _isRegistered ? l10n.volunteerUnregister : l10n.volunteerRegister,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onPrimary,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).colorScheme.primary,
                              minimumSize: const Size(0, 48),
                            ),
                            onPressed: _isLoading ? null : (_isRegistered ? _unregisterFromOpportunity : _registerForOpportunity),
                          ),
                        ),
                        const SizedBox(width: 16),
                        if (_isRegistered)
                          Expanded(
                            child: ElevatedButton.icon(
                              icon: Icon(
                                Icons.download,
                                color: Theme.of(context).colorScheme.onPrimary,
                              ),
                              label: Text(
                                l10n.downloadCertificate,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.onPrimary,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).colorScheme.secondary,
                                minimumSize: const Size(0, 48),
                              ),
                              onPressed: _isLoading ? null : _downloadCertificate,
                            ),
                          ),
                      ],
                    ),
                  const SizedBox(height: 16),
                  
                  // View history button
                  if (_isRegistered)
                    Center(
                      child: TextButton(
                        child: Text(
                          l10n.viewMyVolunteerHistory,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.7),
                          ),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => VolunteerHistoryPage(apiClient: widget.apiClient),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailCard({required IconData icon, required String title, required String value}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.background.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.7),
            size: 24,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor() {
    switch (_opportunity!.status) {
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

  String _getStatusText() {
    final l10n = AppLocalizations.of(context)!;
    switch (_opportunity!.status) {
      case 'open':
        return l10n.volunteerStatusOpen;
      case 'full':
        return l10n.volunteerStatusFull;
      case 'completed':
        return l10n.volunteerStatusCompleted;
      case 'cancelled':
        return l10n.volunteerStatusCancelled;
      default:
        return _opportunity!.status;
    }
  }
}
