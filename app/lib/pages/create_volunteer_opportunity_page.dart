import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../services/api_client.dart';
import '../widgets/glassmorphic_ui.dart';
import 'package:intl/intl.dart';

class CreateVolunteerOpportunityPage extends StatefulWidget {
  final ApiClient apiClient;

  const CreateVolunteerOpportunityPage({
    super.key,
    required this.apiClient,
  });

  @override
  State<CreateVolunteerOpportunityPage> createState() => _CreateVolunteerOpportunityPageState();
}

class _CreateVolunteerOpportunityPageState extends State<CreateVolunteerOpportunityPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _requiredParticipantsController = TextEditingController();

  DateTime? _selectedDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _requiredParticipantsController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context, bool isStartTime) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStartTime ? (_startTime ?? TimeOfDay.now()) : (_endTime ?? TimeOfDay.now()),
    );

    if (picked != null) {
      setState(() {
        if (isStartTime) {
          _startTime = picked;
          // If end time is before start time, reset it
          if (_endTime != null && _endTime!.hour < picked.hour || (_endTime!.hour == picked.hour && _endTime!.minute <= picked.minute)) {
            _endTime = null;
          }
        } else {
          _endTime = picked;
        }
      });
    }
  }

  Future<void> _createOpportunity() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDate == null) {
      GlassmorphicUI.showGlassSnackBar(
        context,
        AppLocalizations.of(context)!.pleaseSelectDate,
        isError: true,
      );
      return;
    }
    if (_startTime == null || _endTime == null) {
      GlassmorphicUI.showGlassSnackBar(
        context,
        AppLocalizations.of(context)!.pleaseSelectTimes,
        isError: true,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final requiredParticipants = _requiredParticipantsController.text.isEmpty ? null : int.tryParse(_requiredParticipantsController.text);

      // Create DateTime objects for start and end times
      final startDateTime = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _startTime!.hour,
        _startTime!.minute,
      );

      final endDateTime = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _endTime!.hour,
        _endTime!.minute,
      );

      await widget.apiClient.createVolunteerOpportunity(
        context,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        location: _locationController.text.trim(),
        date: _selectedDate!,
        startTime: startDateTime,
        endTime: endDateTime,
        requiredParticipants: requiredParticipants,
      );

      if (mounted) {
        GlassmorphicUI.showGlassSnackBar(
          context,
          AppLocalizations.of(context)!.volunteerOpportunityCreated,
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        GlassmorphicUI.showGlassSnackBar(
          context,
          e.toString(),
          isError: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final dateFormat = DateFormat.yMMMd(Localizations.localeOf(context).languageCode);

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
              l10n.createOpportunity,
              style: const TextStyle(color: Colors.white),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title field
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.opportunityTitle,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _titleController,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: AppLocalizations.of(context)!.enterOpportunityTitle,
                            hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Colors.white),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return AppLocalizations.of(context)!.titleRequired;
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Description field
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
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
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _descriptionController,
                          style: const TextStyle(color: Colors.white),
                          maxLines: 4,
                          decoration: InputDecoration(
                            hintText: AppLocalizations.of(context)!.describeOpportunity,
                            hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Colors.white),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return AppLocalizations.of(context)!.descriptionRequired;
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Location field
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.opportunityLocation,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _locationController,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: AppLocalizations.of(context)!.enterLocation,
                            hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Colors.white),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return AppLocalizations.of(context)!.locationRequired;
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  const SizedBox(height: 16),

                  // Date selection
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.of(context)!.eventDate,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: () => _selectDate(context),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.white.withOpacity(0.3)),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.calendar_today,
                                  color: Colors.white.withOpacity(0.7),
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _selectedDate != null ? dateFormat.format(_selectedDate!) : AppLocalizations.of(context)!.selectDate,
                                  style: TextStyle(
                                    color: _selectedDate != null ? Colors.white : Colors.white.withOpacity(0.7),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Time selection
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppLocalizations.of(context)!.startTime,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              InkWell(
                                onTap: () => _selectTime(context, true),
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.white.withOpacity(0.3)),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.access_time,
                                        color: Colors.white.withOpacity(0.7),
                                        size: 16,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        _startTime != null ? _startTime!.format(context) : AppLocalizations.of(context)!.selectTime,
                                        style: TextStyle(
                                          color: _startTime != null ? Colors.white : Colors.white.withOpacity(0.7),
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
                      const SizedBox(width: 16),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppLocalizations.of(context)!.endTime,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              InkWell(
                                onTap: () => _selectTime(context, false),
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.white.withOpacity(0.3)),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.access_time,
                                        color: Colors.white.withOpacity(0.7),
                                        size: 16,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        _endTime != null ? _endTime!.format(context) : AppLocalizations.of(context)!.selectTime,
                                        style: TextStyle(
                                          color: _endTime != null ? Colors.white : Colors.white.withOpacity(0.7),
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
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Required participants field
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              l10n.requiredParticipants,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '(Optional)',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _requiredParticipantsController,
                          style: const TextStyle(color: Colors.white),
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            hintText: AppLocalizations.of(context)!.leaveEmptyForUnlimited,
                            hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Colors.white),
                            ),
                          ),
                          validator: (value) {
                            if (value != null && value.isNotEmpty) {
                              final number = int.tryParse(value);
                              if (number == null || number <= 0) {
                                return AppLocalizations.of(context)!.invalidGrade;
                              }
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Create button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _createOpportunity,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.secondary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                              l10n.createOpportunity,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSecondary,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
