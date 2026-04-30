import 'dart:ui';

import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../services/api_client.dart';
import '../utils/layout_constants.dart';
import '../widgets/glassmorphic_ui.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

class CreateVolunteerOpportunityPage extends StatefulWidget {
  final ApiClient apiClient;

  const CreateVolunteerOpportunityPage({
    super.key,
    required this.apiClient,
  });

  @override
  State<CreateVolunteerOpportunityPage> createState() =>
      _CreateVolunteerOpportunityPageState();
}

class _CreateVolunteerOpportunityPageState
    extends State<CreateVolunteerOpportunityPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _requiredParticipantsController = TextEditingController();
  final List<PlatformFile> _attachments = [];

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
    final theme = Theme.of(context);
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: theme.copyWith(
            colorScheme: theme.colorScheme.copyWith(
              primary: theme.colorScheme.secondary,
              onPrimary: Colors.white,
              surface: theme.colorScheme.background,
              onSurface: theme.colorScheme.onBackground,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: theme.colorScheme.secondary,
                textStyle: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );

    if (picked != null && mounted) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context, bool isStartTime) async {
    final theme = Theme.of(context);
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStartTime
          ? (_startTime ?? TimeOfDay.now())
          : (_endTime ?? TimeOfDay.now()),
      builder: (context, child) {
        return Theme(
          data: theme.copyWith(
            colorScheme: theme.colorScheme.copyWith(
              primary: theme.colorScheme.secondary,
              onPrimary: Colors.white,
              surface: theme.colorScheme.background,
              onSurface: theme.colorScheme.onBackground,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: theme.colorScheme.secondary,
                textStyle: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );

    if (picked != null && mounted) {
      setState(() {
        if (isStartTime) {
          _startTime = picked;
          // If end time is before or equal to start time, reset it
          if (_endTime != null &&
              (_endTime!.hour < picked.hour ||
                  (_endTime!.hour == picked.hour &&
                      _endTime!.minute <= picked.minute))) {
            _endTime = null;
          }
        } else {
          _endTime = picked;
        }
      });
    }
  }

  Future<void> _pickAttachment() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
        withData: kIsWeb,
      );
      if (result != null && result.files.isNotEmpty) {
        setState(() {
          // Append to existing selections instead of replacing, and de-dupe by name + size.
          for (final file in result.files) {
            final alreadyHas = _attachments
                .any((f) => f.name == file.name && f.size == file.size);
            if (!alreadyHas) {
              _attachments.add(file);
            }
          }
        });
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

  String? _inferMime(PlatformFile file) {
    final ext = (file.extension ?? '').toLowerCase();
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'pdf':
        return 'application/pdf';
      default:
        return null;
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
      final requiredParticipants = _requiredParticipantsController.text.isEmpty
          ? null
          : int.tryParse(_requiredParticipantsController.text);

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

      final opportunityId = await widget.apiClient.createVolunteerOpportunity(
        context,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        location: _locationController.text.trim(),
        date: _selectedDate!,
        startTime: startDateTime,
        endTime: endDateTime,
        requiredParticipants: requiredParticipants,
      );

      if (!mounted) return;

      for (final file in _attachments) {
        try {
          await widget.apiClient.uploadVolunteerAttachment(
            context,
            opportunityId: opportunityId,
            filePath: kIsWeb ? null : file.path,
            webBytes: kIsWeb ? file.bytes : null,
            fileName: file.name,
            mimeType: _inferMime(file),
          );
        } catch (e) {
          if (!mounted) return;
          GlassmorphicUI.showGlassSnackBar(
            context,
            AppLocalizations.of(
              context,
            )!.failedToUploadFile(file.name, e.toString()),
            isError: true,
          );
        }
      }

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

  Widget _buildGlassCard({
    required BuildContext context,
    required Widget child,
    EdgeInsets padding = const EdgeInsets.all(24),
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          width: double.infinity,
          padding: padding,
          decoration: BoxDecoration(
            color: colorScheme.background.withOpacity(0.2),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: colorScheme.onPrimary.withOpacity(0.24),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.10),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildSectionTitle(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? trailing,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: colorScheme.background.withOpacity(0.16),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: colorScheme.onPrimary.withOpacity(0.16),
            ),
          ),
          child: Icon(
            icon,
            color: colorScheme.onPrimary,
            size: 18,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              color: colorScheme.onPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        if (trailing != null)
          Text(
            trailing,
            style: TextStyle(
              color: colorScheme.onPrimary.withOpacity(0.68),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
      ],
    );
  }

  InputDecoration _buildInputDecoration(
    BuildContext context, {
    required String hintText,
    Widget? prefixIcon,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final borderColor = colorScheme.onPrimary.withOpacity(0.18);

    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(
        color: colorScheme.onPrimary.withOpacity(0.55),
      ),
      prefixIcon: prefixIcon,
      filled: false,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: colorScheme.onPrimary.withOpacity(0.55)),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: colorScheme.error.withOpacity(0.7)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: colorScheme.error),
      ),
    );
  }

  Widget _buildPickerField(
    BuildContext context, {
    required String label,
    required IconData icon,
    required String value,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: colorScheme.onPrimary.withOpacity(isSelected ? 0.32 : 0.18),
          ),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 40,
              height: 40,
              child: Icon(
                icon,
                color: colorScheme.onPrimary.withOpacity(isSelected ? 1 : 0.72),
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: colorScheme.onPrimary.withOpacity(0.62),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: TextStyle(
                      color: colorScheme.onPrimary
                          .withOpacity(isSelected ? 1 : 0.82),
                      fontSize: 15,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Icon(
              Icons.chevron_right_rounded,
              color: colorScheme.onPrimary.withOpacity(0.62),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentRow(BuildContext context, PlatformFile file) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final extension = (file.extension ?? '').toLowerCase();
    final isPdf = extension == 'pdf';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: colorScheme.onPrimary.withOpacity(0.14),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            height: 40,
            child: Icon(
              isPdf ? Icons.picture_as_pdf_rounded : Icons.image_outlined,
              color: colorScheme.onPrimary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  file.name,
                  style: TextStyle(
                    color: colorScheme.onPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.fileSizeKilobytes((file.size / 1024).ceil()),
                  style: TextStyle(
                    color: colorScheme.onPrimary.withOpacity(0.56),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              setState(() {
                _attachments.remove(file);
              });
            },
            icon: Icon(
              Icons.close_rounded,
              color: colorScheme.onPrimary.withOpacity(0.72),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final dateFormat =
        DateFormat.yMMMd(Localizations.localeOf(context).languageCode);
    final colorScheme = Theme.of(context).colorScheme;
    final hasDate = _selectedDate != null;
    final hasStartTime = _startTime != null;
    final hasEndTime = _endTime != null;
    final dateText =
        hasDate ? dateFormat.format(_selectedDate!) : l10n.selectDate;
    final startTimeText =
        hasStartTime ? _startTime!.format(context) : l10n.selectTime;
    final endTimeText =
        hasEndTime ? _endTime!.format(context) : l10n.selectTime;

    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                colorScheme.primary,
                colorScheme.secondary,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        Positioned(
          top: -140,
          right: -80,
          child: IgnorePointer(
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.white.withOpacity(0.14),
                    Colors.white.withOpacity(0),
                  ],
                ),
              ),
            ),
          ),
        ),
        Positioned(
          left: -80,
          bottom: 100,
          child: IgnorePointer(
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    colorScheme.onPrimary.withOpacity(0.08),
                    colorScheme.onPrimary.withOpacity(0),
                  ],
                ),
              ),
            ),
          ),
        ),
        Scaffold(
          backgroundColor: Colors.transparent,
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            leading: GlassmorphicUI.buildAppBarIconButton(
              context: context,
              icon: Icons.arrow_back,
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              l10n.createOpportunity,
              style: TextStyle(
                color: colorScheme.onPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            centerTitle: true,
          ),
          body: SingleChildScrollView(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: MediaQuery.of(context).padding.top + kToolbarHeight + 12,
              bottom: 24 + MediaQuery.of(context).padding.bottom,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: kWideFormMaxWidth),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildGlassCard(
                        context: context,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionTitle(
                              context,
                              icon: Icons.edit_outlined,
                              title: l10n.opportunityTitle,
                            ),
                            const SizedBox(height: 18),
                            TextFormField(
                              controller: _titleController,
                              style: TextStyle(color: colorScheme.onPrimary),
                              decoration: _buildInputDecoration(
                                context,
                                hintText: l10n.enterOpportunityTitle,
                                prefixIcon: Icon(
                                  Icons.title_rounded,
                                  color:
                                      colorScheme.onPrimary.withOpacity(0.64),
                                ),
                              ),
                              onChanged: (_) => setState(() {}),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return l10n.titleRequired;
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 18),
                            Text(
                              l10n.opportunityDescription,
                              style: TextStyle(
                                color: colorScheme.onPrimary,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _descriptionController,
                              style: TextStyle(color: colorScheme.onPrimary),
                              maxLines: 5,
                              decoration: _buildInputDecoration(
                                context,
                                hintText: l10n.describeOpportunity,
                                prefixIcon: Padding(
                                  padding: const EdgeInsets.only(bottom: 76),
                                  child: Icon(
                                    Icons.notes_rounded,
                                    color:
                                        colorScheme.onPrimary.withOpacity(0.64),
                                  ),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return l10n.descriptionRequired;
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 18),
                            Text(
                              l10n.opportunityLocation,
                              style: TextStyle(
                                color: colorScheme.onPrimary,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _locationController,
                              style: TextStyle(color: colorScheme.onPrimary),
                              decoration: _buildInputDecoration(
                                context,
                                hintText: l10n.enterLocation,
                                prefixIcon: Icon(
                                  Icons.place_outlined,
                                  color:
                                      colorScheme.onPrimary.withOpacity(0.64),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return l10n.locationRequired;
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      _buildGlassCard(
                        context: context,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionTitle(
                              context,
                              icon: Icons.calendar_month_outlined,
                              title: l10n.eventDate,
                            ),
                            const SizedBox(height: 18),
                            _buildPickerField(
                              context,
                              label: l10n.eventDate,
                              icon: Icons.calendar_today_outlined,
                              value: dateText,
                              isSelected: hasDate,
                              onTap: () => _selectDate(context),
                            ),
                            const SizedBox(height: 16),
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final useColumn = constraints.maxWidth < 640;
                                final startField = _buildPickerField(
                                  context,
                                  label: l10n.startTime,
                                  icon: Icons.schedule_outlined,
                                  value: startTimeText,
                                  isSelected: hasStartTime,
                                  onTap: () => _selectTime(context, true),
                                );
                                final endField = _buildPickerField(
                                  context,
                                  label: l10n.endTime,
                                  icon: Icons.schedule_outlined,
                                  value: endTimeText,
                                  isSelected: hasEndTime,
                                  onTap: () => _selectTime(context, false),
                                );

                                if (useColumn) {
                                  return Column(
                                    children: [
                                      SizedBox(
                                        width: double.infinity,
                                        child: startField,
                                      ),
                                      const SizedBox(height: 12),
                                      SizedBox(
                                        width: double.infinity,
                                        child: endField,
                                      ),
                                    ],
                                  );
                                }

                                return Row(
                                  children: [
                                    Expanded(child: startField),
                                    const SizedBox(width: 12),
                                    Expanded(child: endField),
                                  ],
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      _buildGlassCard(
                        context: context,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionTitle(
                              context,
                              icon: Icons.group_outlined,
                              title: l10n.requiredParticipants,
                              trailing: l10n.optionalLabel,
                            ),
                            const SizedBox(height: 18),
                            TextFormField(
                              controller: _requiredParticipantsController,
                              style: TextStyle(color: colorScheme.onPrimary),
                              keyboardType: TextInputType.number,
                              onChanged: (_) => setState(() {}),
                              decoration: _buildInputDecoration(
                                context,
                                hintText: l10n.leaveEmptyForUnlimited,
                                prefixIcon: Icon(
                                  Icons.numbers_rounded,
                                  color:
                                      colorScheme.onPrimary.withOpacity(0.64),
                                ),
                              ),
                              validator: (value) {
                                if (value != null && value.isNotEmpty) {
                                  final number = int.tryParse(value);
                                  if (number == null || number <= 0) {
                                    return AppLocalizations.of(context)!
                                        .invalidGrade;
                                  }
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      _buildGlassCard(
                        context: context,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionTitle(
                              context,
                              icon: Icons.attach_file_rounded,
                              title: l10n.attachments,
                              trailing: l10n.optionalLabel,
                            ),
                            const SizedBox(height: 18),
                            InkWell(
                              onTap: _pickAttachment,
                              borderRadius: BorderRadius.circular(20),
                              child: Ink(
                                padding: const EdgeInsets.all(18),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color:
                                        colorScheme.onPrimary.withOpacity(0.18),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.add_rounded,
                                      color: colorScheme.onPrimary,
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Text(
                                        l10n.addFiles,
                                        style: TextStyle(
                                          color: colorScheme.onPrimary,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            if (_attachments.isEmpty)
                              Text(
                                l10n.attachmentsHelperText,
                                style: TextStyle(
                                  color:
                                      colorScheme.onPrimary.withOpacity(0.68),
                                  height: 1.4,
                                ),
                              )
                            else
                              ..._attachments.map(
                                  (file) => _buildAttachmentRow(context, file)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _createOpportunity,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorScheme.secondary,
                            foregroundColor: colorScheme.onSecondary,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                            elevation: 0,
                          ),
                          child: _isLoading
                              ? SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      colorScheme.onSecondary,
                                    ),
                                  ),
                                )
                              : Text(
                                  l10n.createOpportunity,
                                  style: TextStyle(
                                    color: colorScheme.onSecondary,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
