import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../models/feed.dart';

class FeedSelectionDialog extends StatelessWidget {
  final List<Feed> feeds;
  final Function(Feed) onFeedSelected;

  const FeedSelectionDialog({
    super.key,
    required this.feeds,
    required this.onFeedSelected,
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
            l10n.chooseFeed,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onPrimary,
              fontSize: 18,
            ),
          ),
        ),
        Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.5,
          ),
          child: SingleChildScrollView(
            child: Column(
              children: feeds.map((feed) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => onFeedSelected(feed),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          if (feed.iconUrl != null) ...[
                            ClipOval(
                              child: Image.network(
                                feed.iconUrl!,
                                width: 32,
                                height: 32,
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(width: 12),
                          ],
                          Expanded(
                            child: Text(
                              feed.displayName,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onPrimary,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              )).toList(),
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
