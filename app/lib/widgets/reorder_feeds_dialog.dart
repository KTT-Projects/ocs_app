import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../models/feed.dart';

class ReorderFeedsDialog extends StatefulWidget {
  final List<Feed> feeds;
  final Function(List<Feed> reorderedFeeds) onReorder;

  const ReorderFeedsDialog({
    super.key,
    required this.feeds,
    required this.onReorder,
  });

  @override
  State<ReorderFeedsDialog> createState() => _ReorderFeedsDialogState();
}

class _ReorderFeedsDialogState extends State<ReorderFeedsDialog> {
  late List<Feed> _feeds;

  @override
  void initState() {
    super.initState();
    _feeds = List.from(widget.feeds);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
          child: Text(
            l10n.reorderFeeds,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onPrimary,
              fontSize: 18,
            ),
          ),
        ),
        ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.6,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: ReorderableListView.builder(
              shrinkWrap: true,
              itemCount: _feeds.length,
              onReorder: (oldIndex, newIndex) {
                setState(() {
                  if (newIndex > oldIndex) {
                    newIndex -= 1;
                  }
                  final feed = _feeds.removeAt(oldIndex);
                  _feeds.insert(newIndex, feed);
                });
              },
              itemBuilder: (context, index) {
                final feed = _feeds[index];
                return Container(
                  key: ValueKey(feed.id),
                  margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 0),
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    leading: SizedBox(
                      width: 32,
                      height: 32,
                      child: feed.iconUrl != null
                          ? ClipOval(
                              child: Image.network(
                                feed.iconUrl!,
                                width: 32,
                                height: 32,
                                fit: BoxFit.cover,
                              ),
                            )
                          : Icon(
                              Icons.dynamic_feed,
                              color: Theme.of(context).colorScheme.onPrimary,
                            ),
                    ),
                    title: Text(
                      feed.displayName,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),
                    trailing: Icon(
                      Icons.drag_handle,
                      color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.5),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  l10n.cancel,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  widget.onReorder(_feeds);
                },
                child: Text(
                  l10n.save,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.secondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
