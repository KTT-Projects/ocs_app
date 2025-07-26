import 'package:flutter/material.dart';
import 'dart:ui';
import '../l10n/app_localizations.dart';
import '../models/feed.dart';
import 'feed_list_item.dart';

class DiscoverFeedSection extends StatelessWidget {
  final List<Feed> feeds;
  final String searchQuery;
  final String sortBy;
  final Function(String) onSearchChanged;
  final Function(String) onSortChanged;
  final Function(Feed) onJoinFeed;

  const DiscoverFeedSection({
    super.key,
    required this.feeds,
    required this.searchQuery,
    required this.sortBy,
    required this.onSearchChanged,
    required this.onSortChanged,
    required this.onJoinFeed,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Stack(
      children: [
        Container(
          padding: EdgeInsets.only(
            top: 0,
            bottom: MediaQuery.of(context).padding.bottom + 24,
            left: 8,
            right: 8,
          ),
          child: Column(
            children: [
              // Search field
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.background.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.3),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: l10n.searchFeeds,
                        prefixIcon: Icon(
                          Icons.search,
                          color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.7),
                        ),
                        hintStyle: TextStyle(
                          color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.7),
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                      onChanged: onSearchChanged,
                    ),
                  ),
                ),
              ),
              // Sort buttons
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: sortBy == 'population'
                            ? Theme.of(context).colorScheme.secondary
                            : Theme.of(context).colorScheme.background.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.3),
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: InkWell(
                            onTap: () => onSortChanged('population'),
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.people,
                                    size: 16,
                                    color: sortBy == 'population'
                                        ? Theme.of(context).colorScheme.onSecondary
                                        : Theme.of(context).colorScheme.onPrimary,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    l10n.population,
                                    style: TextStyle(
                                      color: sortBy == 'population'
                                          ? Theme.of(context).colorScheme.onSecondary
                                          : Theme.of(context).colorScheme.onPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: sortBy == 'activity'
                            ? Theme.of(context).colorScheme.secondary
                            : Theme.of(context).colorScheme.background.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.3),
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: InkWell(
                            onTap: () => onSortChanged('activity'),
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.flash_on,
                                    size: 16,
                                    color: sortBy == 'activity'
                                        ? Theme.of(context).colorScheme.onSecondary
                                        : Theme.of(context).colorScheme.onPrimary,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    l10n.latestActivity,
                                    style: TextStyle(
                                      color: sortBy == 'activity'
                                          ? Theme.of(context).colorScheme.onSecondary
                                          : Theme.of(context).colorScheme.onPrimary,
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
                ),
              ),
              Expanded(
                child: Builder(
                  builder: (context) {
                    var filteredFeeds = feeds;
                    if (searchQuery.isNotEmpty) {
                      filteredFeeds = feeds.where((feed) =>
                        feed.displayName.toLowerCase().contains(searchQuery.toLowerCase()) ||
                        feed.description.toLowerCase().contains(searchQuery.toLowerCase())
                      ).toList();
                    }
                    if (sortBy == 'population') {
                      filteredFeeds.sort((a, b) => b.memberCount.compareTo(a.memberCount));
                    } else {
                      filteredFeeds.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
                    }
                    if (filteredFeeds.isEmpty) {
                      return Center(
                        child: Text(
                          l10n.noFeedsFound,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                        ),
                      );
                    }
                    return ListView.builder(
                      itemCount: filteredFeeds.length,
                      itemBuilder: (context, index) {
                        return FeedListItem(
                          feed: filteredFeeds[index],
                          onJoin: () => onJoinFeed(filteredFeeds[index]),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
