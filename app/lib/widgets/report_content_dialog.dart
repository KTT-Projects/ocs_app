import 'package:flutter/material.dart';

class ReportContentResult {
  final String reason;
  final String details;

  const ReportContentResult({
    required this.reason,
    required this.details,
  });
}

class ReportContentDialog extends StatefulWidget {
  const ReportContentDialog({super.key});

  @override
  State<ReportContentDialog> createState() => _ReportContentDialogState();
}

class _ReportContentDialogState extends State<ReportContentDialog> {
  final TextEditingController _detailsController = TextEditingController();
  String _reason = 'other';

  static const List<Map<String, String>> _reasons = [
    {'value': 'harassment', 'label': 'Harassment'},
    {'value': 'hate', 'label': 'Hate or discrimination'},
    {'value': 'sexual', 'label': 'Sexual content'},
    {'value': 'violence', 'label': 'Violence or threat'},
    {'value': 'self_harm', 'label': 'Self-harm'},
    {'value': 'privacy', 'label': 'Private information'},
    {'value': 'spam', 'label': 'Spam'},
    {'value': 'other', 'label': 'Other'},
  ];

  @override
  void dispose() {
    _detailsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.flag_outlined, color: colorScheme.onPrimary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Report content',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: colorScheme.onPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _reason,
            dropdownColor: colorScheme.surface,
            decoration: InputDecoration(
              labelText: 'Reason',
              labelStyle: TextStyle(color: colorScheme.onPrimary),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: colorScheme.onPrimary.withOpacity(0.28),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: colorScheme.secondary),
              ),
            ),
            items: _reasons
                .map(
                  (reason) => DropdownMenuItem<String>(
                    value: reason['value'],
                    child: Text(reason['label']!),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value == null) return;
              setState(() => _reason = value);
            },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _detailsController,
            minLines: 3,
            maxLines: 5,
            style: TextStyle(color: colorScheme.onPrimary),
            decoration: InputDecoration(
              labelText: 'Details',
              alignLabelWithHint: true,
              labelStyle: TextStyle(color: colorScheme.onPrimary),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: colorScheme.onPrimary.withOpacity(0.28),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: colorScheme.secondary),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Cancel',
                    style: TextStyle(color: colorScheme.onPrimary),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.pop(
                      context,
                      ReportContentResult(
                        reason: _reason,
                        details: _detailsController.text.trim(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.flag_outlined),
                  label: const Text('Report'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
