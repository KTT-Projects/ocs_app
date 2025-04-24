import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../models/feed.dart';
import '../services/api_client.dart';
import 'create_feed_page.dart';
import 'feed_posts_page.dart';

class FeedsPage extends StatefulWidget {
  final ApiClient apiClient;

  const FeedsPage({
    super.key,
    required this.apiClient,
  });

  @override
  State<FeedsPage> createState() => _FeedsPageState();
}

class _FeedsPageState extends State<FeedsPage> {
  bool _isLoading = true;
  String? _error;
  List<Feed>? _feeds;

  @override
  void initState() {
    super.initState();
    _loadFeeds();
  }

  Future<void> _loadFeeds() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final feeds = await widget.apiClient.getFeeds(context);

      if (mounted) {
        setState(() {
          _feeds = feeds;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          l10n.feed,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onPrimary,
          ),
        ),
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.background.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.3),
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: IconButton(
                icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.onPrimary),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.background.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.3),
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: IconButton(
                  icon: Icon(Icons.add, color: Theme.of(context).colorScheme.onPrimary),
                  onPressed: () async {
                    final feedId = await Navigator.push<int>(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CreateFeedPage(
                          apiClient: widget.apiClient,
                        ),
                      ),
                    );
                    if (feedId != null && mounted) {
                      _loadFeeds();
                    }
                  },
                ),
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.secondary,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          if (_isLoading)
            Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).colorScheme.onPrimary,
                ),
              ),
            )
          else if (_error != null)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.refresh),
                    label: Text(l10n.retry),
                    onPressed: _loadFeeds,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.errorContainer,
                      foregroundColor: Theme.of(context).colorScheme.onErrorContainer,
                    ),
                  ),
                ],
              ),
            )
          else if (_feeds != null)
            ListView.builder(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + AppBar().preferredSize.height + 8,
                bottom: 8,
                left: 8,
                right: 8,
              ),
              itemCount: _feeds!.length,
              itemBuilder: (context, index) {
                final feed = _feeds![index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  color: Theme.of(context).colorScheme.background.withOpacity(0.2),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => FeedPostsPage(
                                apiClient: widget.apiClient,
                                feed: feed,
                              ),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(16),
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
                                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                                color: Theme.of(context).colorScheme.onPrimary,
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
                                ],
                              ),
                              if (feed.description.isNotEmpty) ...[
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
              },
            ),
        ],
      ),
    );
  }
}
