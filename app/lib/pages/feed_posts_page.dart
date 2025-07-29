import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:async';
import '../l10n/app_localizations.dart';
import '../models/feed.dart';
import '../models/feed_post.dart';
import '../services/api_client.dart';
import '../widgets/create_post_dialog.dart';
import '../widgets/glassmorphic_ui.dart';
import '../widgets/post_list_item.dart';
import 'post_details_page.dart';
import 'user_profile_page.dart';

class FeedPostsPage extends StatefulWidget {
  final ApiClient apiClient;
  final Feed feed;

  const FeedPostsPage({
    super.key,
    required this.apiClient,
    required this.feed,
  });

  @override
  State<FeedPostsPage> createState() => _FeedPostsPageState();
}

class _FeedPostsPageState extends State<FeedPostsPage> {
  bool _isLoading = true;
  String? _error;
  List<FeedPost>? _posts;
  bool _didLoadPosts = false;

  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _startPeriodicRefresh();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _startPeriodicRefresh() {
    // Refresh every 5 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _loadPosts();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didLoadPosts) {
      _didLoadPosts = true;
      _loadPosts();
    }
  }

  Future<void> _loadPosts() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final posts = await widget.apiClient.getFeedPosts(
        context,
        widget.feed.id,
        sort: 'default',
      );

      if (mounted) {
        setState(() {
          _posts = posts;
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

  Future<void> _vote(FeedPost post, String voteType) async {
    try {
      await widget.apiClient.votePost(
        context,
        postId: post.id,
        voteType: voteType,
      );

      // Optimistically update the UI with toggle behaviour
      setState(() {
        if (post.userVote == voteType) {
          // Remove existing vote
          if (voteType == 'upvote') {
            post.upvotes -= 1;
          } else {
            post.downvotes -= 1;
          }
          post.userVote = null;
        } else {
          // Switch or add vote
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: Theme.of(context).colorScheme.secondary,
              child: widget.feed.iconUrl != null
                  ? ClipOval(
                      child: Image.network(
                        widget.feed.iconUrl!,
                        width: 32,
                        height: 32,
                        fit: BoxFit.cover,
                      ),
                    )
                  : Text(
                      widget.feed.displayName[0],
                      style: TextStyle(
                        fontSize: 16,
                        color: Theme.of(context).colorScheme.onSecondary,
                      ),
                    ),
            ),
            const SizedBox(width: 8),
            Text(
              widget.feed.displayName,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
          ],
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
              child: IconButton(
                icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.onPrimary),
                onPressed: () => Navigator.pop(context),
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
                child: IconButton(
                  icon: Icon(Icons.add, color: Theme.of(context).colorScheme.onPrimary),
                  onPressed: () async {
                    final postId = await showDialog<int>(
                      context: context,
                      builder: (context) => CreatePostDialog(
                        apiClient: widget.apiClient,
                        feed: widget.feed,
                    );
                    if (postId != null && mounted) {
                      _loadPosts();
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
                    onPressed: _loadPosts,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.errorContainer,
                      foregroundColor: Theme.of(context).colorScheme.onErrorContainer,
                    ),
                  ),
                ],
              ),
            )
          else if (_posts != null)
            ListView.builder(
padding: EdgeInsets.only(
  top: MediaQuery.of(context).padding.top + AppBar().preferredSize.height + 8,
  bottom: 8,
  left: 8,
  right: 8,
),
              itemCount: _posts!.length,
              itemBuilder: (context, index) {
                final post = _posts![index];
                return PostListItem(
                  post: post,
                  onVote: _vote,
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
                );
              },
            ),
        ],
      ),
    );
  }
}
