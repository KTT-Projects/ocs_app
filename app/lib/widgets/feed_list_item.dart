import 'package:flutter/material.dart';
import 'dart:ui';
import '../l10n/app_localizations.dart';
import '../models/feed.dart';

class FeedListItem extends StatelessWidget {
  final Feed feed;
  final VoidCallback onJoin;
  final bool showDescription;

  const FeedListItem({
    super.key,
    required this.feed,
    required this.onJoin,
    this.showDescription = true,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.background.withOpacity(0.2),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: InkWell(
            onTap: onJoin,
            borderRadius: BorderRadius.circular(24),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: Theme.of(context).colorScheme.secondary,
                        child: feed.iconUrl != null
                            ? ClipOval(
                                child: Image.network(
                                  feed.iconUrl!,
                                  width: 48,
                                  height: 48,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : Text(
                                feed.displayName[0],
                                style: TextStyle(
                                  fontSize: 24,
                                  color: Theme.of(context).colorScheme.onSecondary,
                                ),
                              ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              feed.displayName,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onPrimary,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.people,
                                  size: 16,
                                  color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.7),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  feed.memberCount.toString(),
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.7),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Icon(
                                  Icons.article,
                                  size: 16,
                                  color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.7),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  feed.postCount.toString(),
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.7),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.secondary,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          l10n.join,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSecondary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (showDescription && feed.description.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      feed.description,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
