import 'package:flutter/material.dart';

class FeedMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const FeedMenuItem({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                color: Theme.of(context).colorScheme.onPrimary,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class FeedMenuDialog extends StatelessWidget {
  final VoidCallback onCreateFeed;
  final VoidCallback onReorderFeeds;

  const FeedMenuDialog({
    super.key,
    required this.onCreateFeed,
    required this.onReorderFeeds,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
          child: Text(
            'Feed options',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onPrimary,
              fontSize: 18,
            ),
          ),
        ),
        FeedMenuItem(
          icon: Icons.add,
          label: 'Create new feed',
          onTap: () {
            Navigator.pop(context);
            onCreateFeed();
          },
        ),
        FeedMenuItem(
          icon: Icons.reorder,
          label: 'Reorder feeds',
          onTap: () {
            Navigator.pop(context);
            onReorderFeeds();
          },
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
