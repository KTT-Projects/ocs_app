import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';

class SortMenuItem extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const SortMenuItem({
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
          color: selected
              ? Theme.of(context).colorScheme.secondary
              : Colors.transparent,
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
                  color: selected
                      ? Theme.of(context).colorScheme.onSecondary
                      : Theme.of(context).colorScheme.onPrimary,
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: selected
                        ? Theme.of(context).colorScheme.onSecondary
                        : Theme.of(context).colorScheme.onPrimary,
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

class SortMenuDialog extends StatelessWidget {
  final String currentSort;
  final Function(String) onSortChanged;

  const SortMenuDialog({
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
            l10n.sortBy,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onPrimary,
              fontSize: 18,
            ),
          ),
        ),
        SortMenuItem(
          value: 'default',
          label: l10n.defaultSort,
          icon: Icons.auto_awesome,
          selected: currentSort == 'default',
          onTap: () => onSortChanged('default'),
        ),
        SortMenuItem(
          value: 'latest',
          label: l10n.latest,
          icon: Icons.access_time,
          selected: currentSort == 'latest',
          onTap: () => onSortChanged('latest'),
        ),
        SortMenuItem(
          value: 'popular',
          label: l10n.popular,
          icon: Icons.trending_up,
          selected: currentSort == 'popular',
          onTap: () => onSortChanged('popular'),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
