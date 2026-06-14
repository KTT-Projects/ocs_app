import 'dart:ui';
import 'dart:async';
import 'package:flutter/material.dart';
import '../models/feed_post.dart';
import '../models/comment.dart';
import '../services/api_client.dart';
import '../widgets/post_list_item.dart';
import '../widgets/comment_list_item.dart';
import '../widgets/glassmorphic_ui.dart';
import '../widgets/report_content_dialog.dart';
import 'user_profile_page.dart';

class PostDetailsPage extends StatefulWidget {
  final ApiClient apiClient;
  final FeedPost post;

  const PostDetailsPage(
      {super.key, required this.apiClient, required this.post});

  @override
  State<PostDetailsPage> createState() => _PostDetailsPageState();
}

class _PostDetailsPageState extends State<PostDetailsPage> {
  bool _isLoading = true;
  String? _error;
  List<Comment>? _comments;
  final _controller = TextEditingController();
  Timer? _refreshTimer;
  bool _isFetching = false;
  static final Map<int, List<Comment>> _commentsCache = {};

  @override
  void initState() {
    super.initState();
    if (_commentsCache.containsKey(widget.post.id)) {
      _comments = _commentsCache[widget.post.id];
      _isLoading = false;
    }
    _startPeriodicRefresh();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_comments == null) {
      _loadComments();
    }
  }

  void _startPeriodicRefresh() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _loadComments(showLoading: false);
    });
  }

  Future<void> _loadComments({bool showLoading = true}) async {
    if (_isFetching) return;
    _isFetching = true;
    if (_isLoading && !showLoading) {
      _isFetching = false;
      return;
    }
    try {
      if (showLoading) {
        setState(() {
          _isLoading = true;
          _error = null;
        });
      }
      final comments =
          await widget.apiClient.getComments(context, widget.post.id);
      if (mounted) {
        setState(() {
          _comments = comments;
          if (showLoading) _isLoading = false;
        });
      }
      _commentsCache[widget.post.id] = comments;
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = showLoading ? e.toString() : _error;
          if (showLoading) _isLoading = false;
        });
      }
    } finally {
      _isFetching = false;
    }
  }

  Future<void> _submit() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    try {
      await widget.apiClient.createComment(
        context,
        postId: widget.post.id,
        content: text,
      );
      _controller.clear();
      await _loadComments();
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

  Future<void> _reportContent(String entityType, int entityId) async {
    final result = await GlassmorphicUI.showDialog<ReportContentResult>(
      context: context,
      width: 360,
      child: const ReportContentDialog(),
    );
    if (result == null || !mounted) return;

    try {
      await widget.apiClient.reportContent(
        context,
        entityType: entityType,
        entityId: entityId,
        reason: result.reason,
        details: result.details,
      );
      if (!mounted) return;
      GlassmorphicUI.showGlassSnackBar(context, 'Report submitted');
    } catch (e) {
      if (!mounted) return;
      GlassmorphicUI.showGlassSnackBar(
        context,
        e.toString(),
        isError: true,
      );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: GlassmorphicUI.buildAppBarIconButton(
          context: context,
          icon: Icons.arrow_back,
          onPressed: () => Navigator.pop(context),
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
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      PostListItem(
                        post: widget.post,
                        onVote: _vote,
                        onUserTap: _openUserProfile,
                        onReport: (post) => _reportContent(
                          'feed_post',
                          post.id,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (_isLoading)
                        Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Theme.of(context).colorScheme.onPrimary,
                            ),
                          ),
                        )
                      else if (_error != null)
                        Text(
                          _error!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        )
                      else if (_comments != null)
                        ..._comments!.map(
                          (c) => CommentListItem(
                            comment: c,
                            onUserTap: _openUserProfile,
                            onReport: (comment) => _reportContent(
                              'comment',
                              comment.id,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final maxWidth = constraints.maxWidth;
                        final width = maxWidth > 600 ? 600.0 : maxWidth;
                        return Center(
                          child: SizedBox(
                            width: width,
                            child: Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .background
                                          .withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onPrimary
                                            .withOpacity(0.3),
                                      ),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(20),
                                      child: TextField(
                                        controller: _controller,
                                        decoration: InputDecoration(
                                          hintText: 'Add a comment...',
                                          hintStyle: TextStyle(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onPrimary
                                                .withOpacity(0.7),
                                          ),
                                          border: InputBorder.none,
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 14,
                                          ),
                                        ),
                                        style: TextStyle(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onPrimary,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  decoration: BoxDecoration(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .background
                                        .withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onPrimary
                                          .withOpacity(0.3),
                                    ),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(20),
                                    child: IconButton(
                                      icon: Icon(
                                        Icons.send,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onPrimary,
                                      ),
                                      onPressed: _submit,
                                      constraints: const BoxConstraints(
                                          minWidth: 48, minHeight: 48),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
