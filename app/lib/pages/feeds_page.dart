import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:async';
import '../l10n/app_localizations.dart';
import '../models/feed.dart';
import '../models/feed_post.dart';
import '../services/api_client.dart';
import '../widgets/feed_list_item.dart';
import '../widgets/post_list_item.dart';
import '../widgets/glassmorphic_ui.dart';
import '../widgets/discover_feed_section.dart';
import '../widgets/sort_menu_dialog.dart';
import '../widgets/feed_selection_dialog.dart';
import '../widgets/feed_menu_dialog.dart';
import '../widgets/reorder_feeds_dialog.dart';
import 'create_feed_page.dart';
import 'feed_details_page.dart';
import 'feed_settings_page.dart';
import 'post_details_page.dart';
import '../widgets/create_post_dialog.dart';
import 'user_profile_page.dart';
import '../widgets/user_selection_dialog.dart';
import '../widgets/confirm_dialog.dart';

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
  List<FeedPost>? _posts;
  bool _didLoadFeeds = false;
  Timer? _refreshTimer;
  String _sortBy = 'default'; // 'default', 'latest', or 'popular'
  Feed? _selectedFeed; // Currently selected feed, null means home feed
  String? _currentToken;

  String _discoverSort = 'population';
  String _discoverSearch = '';

  @override
  void initState() {
    super.initState();
    _currentToken = widget.apiClient.token;
    widget.apiClient.addListener(_onApiClientChanged);
    _startPeriodicRefresh();
  }

  @override
  void dispose() {
    widget.apiClient.removeListener(_onApiClientChanged);
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _startPeriodicRefresh() {
    // Refresh every 5 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _refreshJoinedFeeds();
      _loadPosts();
    });
  }

  void _onApiClientChanged() {
    if (widget.apiClient.token != _currentToken) {
      _currentToken = widget.apiClient.token;
      _didLoadFeeds = false;
      _feeds = null;
      _selectedFeed = null;
      _loadFeeds();
      _loadPosts();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didLoadFeeds) {
      _didLoadFeeds = true;
      _loadFeeds();
      _loadPosts();
    }
  }

  Future<void> _loadFeeds() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }
    try {
      // Fetch non-joined feeds and joined feeds separately. The joined feeds
      // endpoint returns them in the user’s preferred order, so we need to
      // combine the two results manually.
      final results = await Future.wait([
        widget.apiClient.getFeeds(context),
        widget.apiClient.getJoinedFeeds(context),
      ]);
      if (mounted) {
        final nonJoinedFeeds = results[0];
        final joinedFeeds = results[1];

        final Map<int, Feed> feedMap = {};
        for (final feed in joinedFeeds) {
          feedMap[feed.id] = feed;
        }
        for (final feed in nonJoinedFeeds) {
          feedMap.putIfAbsent(feed.id, () => feed);
        }
        setState(() {
          _feeds = feedMap.values.toList();
          if (_selectedFeed != null) {
            _selectedFeed = feedMap[_selectedFeed!.id] ?? _selectedFeed;
          }
          _error = null;
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

  Future<void> _refreshJoinedFeeds() async {
    try {
      final results = await Future.wait([
        widget.apiClient.getFeeds(context),
        widget.apiClient.getJoinedFeeds(context),
      ]);

      if (mounted) {
        final nonJoinedFeeds = results[0];
        final joinedFeeds = results[1];

        final Map<int, Feed> feedMap = {};
        for (final feed in joinedFeeds) {
          feedMap[feed.id] = feed;
        }
        for (final feed in nonJoinedFeeds) {
          feedMap.putIfAbsent(feed.id, () => feed);
        }

        if (_feeds == null || feedMap.length != _feeds!.length) {
          setState(() {
            _feeds = feedMap.values.toList();
            if (_selectedFeed != null) {
              _selectedFeed = feedMap[_selectedFeed!.id] ?? _selectedFeed;
            }
          });
        } else {
          bool changed = false;
          final List<Feed> updated = [];
          for (final feed in feedMap.values) {
            final existing = _feeds!.firstWhere((f) => f.id == feed.id);
            if (existing.isMember != feed.isMember || existing.displayName != feed.displayName || existing.description != feed.description || existing.rules != feed.rules || existing.iconUrl != feed.iconUrl || existing.role != feed.role) {
              changed = true;
              updated.add(feed);
            } else {
              updated.add(existing);
            }
          }
          if (changed) {
            setState(() {
              _feeds = updated;
              if (_selectedFeed != null) {
                final updatedSelected = updated.firstWhere((f) => f.id == _selectedFeed!.id, orElse: () => _selectedFeed!);
                _selectedFeed = updatedSelected;
              }
            });
          }
        }
      }
    } catch (_) {
      // Ignore refresh errors
    }
  }

  Future<void> _loadPosts() async {
    try {
      final posts = _selectedFeed == null
          ? _sortBy == 'discover'
              ? await widget.apiClient.getDiscoverFeed(context)
              : await widget.apiClient.getHomeFeed(context, sort: _sortBy)
          : await widget.apiClient.getFeedPosts(
              context,
              _selectedFeed!.id,
              sort: _sortBy,
            );
      if (mounted) {
        setState(() {
          _posts = posts;
        });
      }
    } catch (e) {
      print('Failed to load posts: $e');
    }
  }

  Future<void> _vote(FeedPost post, String voteType) async {
    try {
      await widget.apiClient.votePost(
        context,
        postId: post.id,
        voteType: voteType,
      );

      setState(() {
        if (post.userVote == voteType) {
          if (voteType == 'upvote') {
            post.upvotes -= 1;
          } else {
            post.downvotes -= 1;
          }
          post.userVote = null;
        } else {
          if (post.userVote == 'upvote') {
            post.upvotes -= 1;
          } else if (post.userVote == 'downvote') {
            post.downvotes -= 1;
          }

          if (voteType == 'upvote') {
            post.upvotes += 1;
          } else {
            post.downvotes += 1;
          }
          post.userVote = voteType;
        }
      });
    } catch (e) {
      if (mounted) {
        GlassmorphicUI.showGlassSnackBar(
          context,
          e.toString(),
          isError: true,
        );
      }
    }
  }

  void _openFeedDetails(Feed feed) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FeedDetailsPage(
          apiClient: widget.apiClient,
          feed: feed,
        ),
      ),
    );
  }

  void _openUserProfile(int userId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserProfilePage(
          apiClient: widget.apiClient,
          userId: userId,
        ),
      ),
    );
  }

  void _onNewPostPressed(List<Feed> joinedFeeds) async {
    if (_selectedFeed != null) {
      final resultId = await showDialog<int>(
        context: context,
        builder: (context) => CreatePostDialog(
          apiClient: widget.apiClient,
          feed: _selectedFeed!,
        ),
      );
      if (resultId != null && mounted) {
        _loadPosts();
      }
    } else {
      // Show glassmorphic feed selection dialog for the Home tab
      final feed = await GlassmorphicUI.showDialog<Feed>(
        context: context,
        width: 360,
        child: FeedSelectionDialog(
          feeds: joinedFeeds,
          onFeedSelected: (feed) => Navigator.pop(context, feed),
        ),
      );
      if (feed != null && mounted) {
        final resultId = await showDialog<int>(
          context: context,
          builder: (context) => CreatePostDialog(
            apiClient: widget.apiClient,
            feed: feed,
          ),
        );
        if (resultId != null && mounted) {
          _loadPosts();
        }
      }
    }
  }

  Future<void> _leaveSelectedFeed() async {
    if (_selectedFeed == null) return;
    int? newAdminId;
    List<Map<String, dynamic>>? members;
    int? myId;
    // Pre-check if this user is the last remaining member. In this case
    // leaving will delete the feed on the server without any additional
    // confirmation, so show a confirmation dialog beforehand.
    try {
      members = await widget.apiClient.getFeedMembers(
        context,
        _selectedFeed!.id,
      );
      myId = int.parse((await widget.apiClient.getProfile(context))['id'].toString());
      if (members.length == 1 && int.parse(members[0]['id'].toString()) == myId && (members[0]['role'] == 'admin')) {
        final confirmed = await GlassmorphicUI.showDialog<bool>(
          context: context,
          width: 320,
          child: ConfirmDialog(
            message: AppLocalizations.of(context)!.confirmDeleteFeed,
            confirmLabel: AppLocalizations.of(context)!.ok,
          ),
        );
        if (confirmed != true) {
          return;
        }
      }
    } catch (_) {
      // Ignore failures and proceed with the normal flow
    }
    while (true) {
      try {
        await widget.apiClient.leaveFeed(
          context,
          _selectedFeed!.id,
          newAdminId: newAdminId,
        );
        if (!mounted) return;
        setState(() {
          _selectedFeed = null;
        });
        _loadFeeds();
        _loadPosts();
        break;
      } catch (e) {
        final msg = e.toString();
        if (msg.contains('New admin ID required')) {
          members ??= await widget.apiClient.getFeedMembers(
            context,
            _selectedFeed!.id,
          );
          myId ??= int.parse((await widget.apiClient.getProfile(context))['id'].toString());
          final selectable = members!.where((m) => int.parse(m['id'].toString()) != myId).toList();
          if (selectable.isEmpty) {
            final confirmed = await GlassmorphicUI.showDialog<bool>(
              context: context,
              width: 320,
              child: ConfirmDialog(
                message: AppLocalizations.of(context)!.confirmDeleteFeed,
                confirmLabel: AppLocalizations.of(context)!.ok,
              ),
            );
            if (confirmed != true) {
              break;
            }
            // try again without new admin id (will delete feed)
            newAdminId = null;
            continue;
          }

          final selected = await GlassmorphicUI.showDialog<Map<String, dynamic>>(
            context: context,
            width: 320,
            child: UserSelectionDialog(
              title: AppLocalizations.of(context)!.selectNewAdmin,
              users: selectable,
              onUserSelected: (user) => Navigator.pop(context, user),
            ),
          );
          if (selected == null) {
            break;
          }
          newAdminId = int.tryParse(selected['id'].toString());
          continue;
        } else {
          if (mounted) {
            GlassmorphicUI.showGlassSnackBar(
              context,
              msg,
              isError: true,
            );
          }
          break;
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final joinedFeeds = _feeds?.where((feed) => feed.isMember).toList() ?? [];
    final availableFeeds = _feeds?.where((feed) => !feed.isMember).toList() ?? [];

    return Scaffold(
      extendBodyBehindAppBar: true,
      extendBody: true,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        toolbarHeight: 48,
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 0,
        title: Container(
          height: 42,
          margin: const EdgeInsets.only(top: 4),
          child: Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: 2 + (joinedFeeds.length),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return GlassmorphicUI.buildTab(
                          context: context,
                          icon: Icons.explore,
                          label: l10n.discover,
                          selected: _selectedFeed == null && _sortBy == 'discover',
                          onTap: () {
                            setState(() {
                              _selectedFeed = null;
                              _sortBy = 'discover';
                              _discoverSort = 'population';
                              _discoverSearch = '';
                            });
                          },
                        );
                      } else if (index == 1) {
                        return GlassmorphicUI.buildTab(
                          context: context,
                          icon: Icons.home,
                          label: l10n.home,
                          selected: _selectedFeed == null && _sortBy != 'discover',
onTap: () {
  setState(() {
    _selectedFeed = null;
    _sortBy = 'default';
  });
  _loadPosts();
},
                        );
                      } else {
                        final feed = joinedFeeds[index - 2];
                        return GlassmorphicUI.buildTab(
                          context: context,
                          iconWidget: feed.iconUrl != null
                              ? ClipOval(
                                  child: Image.network(
                                    feed.iconUrl!,
                                    width: 20,
                                    height: 20,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : null,
                          label: feed.displayName,
                          selected: _selectedFeed?.id == feed.id,
onTap: () {
  setState(() {
    _selectedFeed = feed;
    _sortBy = 'default';
  });
  _loadPosts();
},
                        );
                      }
                    },
                  ),
                ),
              ),
              // Sort button
              if (!(_sortBy == 'discover' && _selectedFeed == null))
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.background.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.3),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: IconButton(
                      iconSize: 20,
                      icon: Icon(
                        Icons.sort,
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                      onPressed: () async {
                        final String? selected = await GlassmorphicUI.showDialog<String>(
                          context: context,
                          width: 320,
                          child: SortMenuDialog(
                            currentSort: _sortBy,
                            onSortChanged: (value) => Navigator.pop(context, value),
                          ),
                        );
                        if (selected != null) {
                          setState(() {
                            _sortBy = selected;
                          });
                          _loadPosts();
                        }
                      },
                    ),
                  ),
                ),
              // Three-dot menu button
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.background.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.3),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: IconButton(
                    iconSize: 20,
                    icon: Icon(
                      Icons.more_vert,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                    onPressed: () async {
                      await GlassmorphicUI.showDialog<void>(
                        context: context,
                        width: 240,
                        child: FeedMenuDialog(
                          onCreateFeed: () async {
                            final feedId = await Navigator.push<int>(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CreateFeedPage(apiClient: widget.apiClient),
                              ),
                            );
                            if (feedId != null && mounted) {
                              _loadFeeds();
                              _loadPosts();
                            }
                          },
                          onReorderFeeds: () async {
                            final joinedFeeds = _feeds?.where((feed) => feed.isMember).toList() ?? [];
                            await GlassmorphicUI.showDialog<void>(
                              context: context,
                              width: 360,
                              child: ReorderFeedsDialog(
                                feeds: joinedFeeds,
                                onReorder: (reorderedFeeds) async {
                                  try {
                                    final feedOrder = reorderedFeeds.map((feed) => feed.id).toList();
                                    await widget.apiClient.reorderFeeds(
                                      context,
                                      feedOrder: feedOrder,
                                    );
                                    _loadFeeds();
                                  } catch (e) {
                                    if (mounted) {
                                      GlassmorphicUI.showGlassSnackBar(
                                        context,
                                        e.toString(),
                                        isError: true,
                                      );
                                    }
                                  }
                                },
                              ),
                            );
                          },
                          onFeedDetails: _selectedFeed != null && _selectedFeed!.isMember ? () => _openFeedDetails(_selectedFeed!) : null,
                          onFeedSettings: _selectedFeed != null && _selectedFeed!.role == 'admin'
                              ? () async {
                                  final changed = await Navigator.push<bool>(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => FeedSettingsPage(
                                        apiClient: widget.apiClient,
                                        feed: _selectedFeed!,
                                      ),
                                    ),
                                  );
                                  if (changed == true && mounted) {
                                    _loadFeeds();
                                    _loadPosts();
                                  }
                                }
                              : null,
                          onLeaveFeed: _selectedFeed != null && _selectedFeed!.isMember ? _leaveSelectedFeed : null,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
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
            Stack(
              children: [
                if (_sortBy == 'discover' && _selectedFeed == null)
                  Padding(
                    padding: EdgeInsets.only(
                      top: MediaQuery.of(context).padding.top + 56,
                    ),
                    child: DiscoverFeedSection(
                      feeds: availableFeeds,
                      searchQuery: _discoverSearch,
                      sortBy: _discoverSort,
                      onSearchChanged: (value) {
                        setState(() {
                          _discoverSearch = value;
                        });
                      },
                      onSortChanged: (value) {
                        setState(() {
                          _discoverSort = value;
                        });
                      },
                      onJoinFeed: (feed) async {
                        try {
                          await widget.apiClient.joinFeed(context, feed.id);
                          if (mounted) {
                            setState(() {
                              final index = _feeds!.indexWhere((f) => f.id == feed.id);
                              if (index != -1) {
                                final updated = _feeds![index].copyWith(isMember: true);
                                _feeds!.removeAt(index);
                                _feeds!.insert(0, updated);
                              }
                            });
                            _refreshJoinedFeeds();
                          }
                        } catch (e) {
                          if (mounted) {
                            GlassmorphicUI.showGlassSnackBar(
                              context,
                              e.toString(),
                              isError: true,
                            );
                          }
                        }
                      },
                      onFeedTap: _openFeedDetails,
                    ),
                  )
                else
                  Padding(
                    padding: EdgeInsets.only(
                      top: MediaQuery.of(context).padding.top + 56,
                      bottom: MediaQuery.of(context).padding.bottom + 24,
                      left: 8,
                      right: 8,
                    ),
                    child: ListView(
                      padding: const EdgeInsets.only(
                        top: 0,
                        bottom: 56,
                      ),
                      children: [
                        if (_posts != null && _posts!.isNotEmpty) ...[
                          ...(() {
                            final sorted = [..._posts!];
                            sorted.sort((a, b) {
                              if (_sortBy == 'latest') {
                                return b.createdAt.compareTo(a.createdAt);
                              } else if (_sortBy == 'popular') {
                                final aVotes = a.upvotes - a.downvotes;
                                final bVotes = b.upvotes - b.downvotes;
                                final diff = bVotes.compareTo(aVotes);
                                if (diff != 0) return diff;
                                return b.createdAt.compareTo(a.createdAt);
                              } else if (_sortBy == 'default') {
                                return b.score.compareTo(a.score);
                              }
                              return 0;
                            });
                            return sorted.map(
                              (post) => PostListItem(
                                post: post,
                                onVote: _vote,
                                showFeedName: _selectedFeed == null,
                                onUserTap: _openUserProfile,
                                onComments: (p) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => PostDetailsPage(
                                        apiClient: widget.apiClient,
                                        post: p,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            );
                          })(),
                        ],
                        if (availableFeeds.isNotEmpty) ...[
                          const SizedBox(height: 24),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final maxWidth = constraints.maxWidth;
                              final width = maxWidth > 600 ? 600.0 : maxWidth;
                              return Center(
                                child: Container(
                                  width: width,
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    l10n.discoverMoreFeeds,
                                    style: TextStyle(
                                      color: Theme.of(context).colorScheme.onPrimary,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 8),
                          ...availableFeeds.map((feed) => FeedListItem(
                                feed: feed,
                                onJoin: () async {
                                  try {
                                    await widget.apiClient.joinFeed(context, feed.id);
                                    if (mounted) {
                                      setState(() {
                                        final index = _feeds!.indexWhere((f) => f.id == feed.id);
                                        if (index != -1) {
                                          final updated = _feeds![index].copyWith(isMember: true);
                                          _feeds!.removeAt(index);
                                          _feeds!.insert(0, updated);
                                        }
                                      });
                                      _refreshJoinedFeeds();
                                    }
                                  } catch (e) {
                                    if (mounted) {
                                      GlassmorphicUI.showGlassSnackBar(
                                        context,
                                        e.toString(),
                                        isError: true,
                                      );
                                    }
                                  }
                                },
                                onTap: () => _openFeedDetails(feed),
                              )),
                        ],
                      ],
                    ),
                  ),
                // Glassmorphic floating button
                if (_selectedFeed != null || (_sortBy != 'discover' && _selectedFeed == null))
                  GlassmorphicUI.buildFloatingButton(
                    context: context,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.add_comment,
                          size: 20,
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _selectedFeed != null ? l10n.newPost : l10n.newPostTo,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                        ),
                      ],
                    ),
                    onTap: () => _onNewPostPressed(joinedFeeds),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}
