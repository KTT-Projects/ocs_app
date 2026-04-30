import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';

class VolunteerSortMenuItem extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const VolunteerSortMenuItem({
    super.key,
    required this.value,
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Container(
        decoration: BoxDecoration(
          color: selected ? Theme.of(context).colorScheme.secondary : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: selected ? Theme.of(context).colorScheme.onSecondary : Theme.of(context).colorScheme.onPrimary,
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: selected ? Theme.of(context).colorScheme.onSecondary : Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class VolunteerSortDialog extends StatelessWidget {
  final String currentSort;
  final Function(String) onSortChanged;

  const VolunteerSortDialog({
    super.key,
    required this.currentSort,
    required this.onSortChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
          child: Text(
            l10n.sortVolunteerBy,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onPrimary,
              fontSize: 18,
            ),
          ),
        ),
        VolunteerSortMenuItem(
          value: 'newest',
          label: l10n.volunteerNewest,
          icon: Icons.new_releases,
          selected: currentSort == 'newest',
          onTap: () => onSortChanged('newest'),
        ),
        VolunteerSortMenuItem(
          value: 'oldest',
          label: l10n.volunteerOldest,
          icon: Icons.history,
          selected: currentSort == 'oldest',
          onTap: () => onSortChanged('oldest'),
        ),
        VolunteerSortMenuItem(
          value: 'upcoming',
          label: l10n.volunteerUpcoming,
          icon: Icons.schedule,
          selected: currentSort == 'upcoming',
          onTap: () => onSortChanged('upcoming'),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
