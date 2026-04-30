import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';

class VolunteerFilterMenuItem extends StatelessWidget {
  final String? value;
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const VolunteerFilterMenuItem({
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

class VolunteerFilterDialog extends StatelessWidget {
  final String? currentFilter;
  final Function(String?) onFilterChanged;

  const VolunteerFilterDialog({
    super.key,
    required this.currentFilter,
    required this.onFilterChanged,
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
            l10n.filterByVolunteerStatus,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onPrimary,
              fontSize: 18,
            ),
          ),
        ),
        VolunteerFilterMenuItem(
          value: null,
          label: l10n.allVolunteerStatuses,
          icon: Icons.all_inclusive,
          selected: currentFilter == null,
          onTap: () => onFilterChanged(null),
        ),
        VolunteerFilterMenuItem(
          value: 'open',
          label: l10n.opportunityOpen,
          icon: Icons.door_front_door,
          selected: currentFilter == 'open',
          onTap: () => onFilterChanged('open'),
        ),
        VolunteerFilterMenuItem(
          value: 'filled',
          label: l10n.opportunityFilled,
          icon: Icons.people,
          selected: currentFilter == 'filled',
          onTap: () => onFilterChanged('filled'),
        ),
        VolunteerFilterMenuItem(
          value: 'completed',
          label: l10n.volunteerCompleted,
          icon: Icons.check_circle,
          selected: currentFilter == 'completed',
          onTap: () => onFilterChanged('completed'),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
