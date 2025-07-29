import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:async';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/feed_post.dart';

class PostListItem extends StatefulWidget {
  final FeedPost post;
  final Function(FeedPost, String) onVote;
  final void Function(FeedPost)? onComments;
  final void Function(int userId)? onUserTap;
  final bool showFeedName;

  const PostListItem({
    super.key,
    required this.post,
    required this.onVote,
    this.onComments,
    this.onUserTap,
    this.showFeedName = false,
  });

  @override
  State<PostListItem> createState() => _PostListItemState();
}

class _PostListItemState extends State<PostListItem> {
  Timer? _timer;
  bool _expanded = false;
  static const int _collapsedLines = 5;
  static const int _lengthThreshold = 200;

  bool get _shouldShowToggle {
    final lineCount = widget.post.content.split('\n').length;
    return lineCount > _collapsedLines || widget.post.content.length > _lengthThreshold;
  }

  @override
  void initState() {
    super.initState();
    // Update time labels every minute
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final width = maxWidth > 600 ? 600.0 : maxWidth;
        return Center(
            child: Container(
          width: width,
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
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: widget.onUserTap == null ? null : () => widget.onUserTap!(widget.post.userId),
                        child: CircleAvatar(
                          radius: 16,
                          backgroundColor: Theme.of(context).colorScheme.secondary,
                          child: widget.post.avatarUrl != null
                              ? ClipOval(
                                  child: Image.network(
                                    widget.post.avatarUrl!,
                                    width: 32,
                                    height: 32,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : Text(
                                  widget.post.displayName[0],
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Theme.of(context).colorScheme.onSecondary,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.post.displayName,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              widget.post.getTimeAgo(),
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.7),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (widget.showFeedName && widget.post.feedDisplayName != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      widget.post.feedDisplayName!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.secondary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Text(
                    widget.post.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Linkify(
                    text: widget.post.content,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                    linkStyle: TextStyle(
                      color: Theme.of(context).colorScheme.secondary,
                      decoration: TextDecoration.underline,
                    ),
                    maxLines: _expanded ? null : _collapsedLines,
                    overflow: _expanded ? TextOverflow.visible : TextOverflow.ellipsis,
                    onOpen: (link) async {
                      final uri = Uri.parse(link.url);
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri);
                      }
                    },
                  ),
                  if (_shouldShowToggle)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: GestureDetector(
                        onTap: () => setState(() => _expanded = !_expanded),
                        child: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            _expanded ? 'Show less' : 'Show more',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.secondary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  if (widget.post.mediaUrl != null) ...[
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 300),
                        child: Image.network(
                          widget.post.mediaUrl!,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.arrow_upward,
                          color: widget.post.userVote == 'upvote' ? Theme.of(context).colorScheme.secondary : Theme.of(context).colorScheme.onPrimary.withOpacity(0.7),
                        ),
                        onPressed: () => widget.onVote(widget.post, 'upvote'),
                      ),
                      Text(
                        widget.post.upvotes.toString(),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(width: 16),
                      IconButton(
                        icon: Icon(
                          Icons.arrow_downward,
                          color: widget.post.userVote == 'downvote' ? Theme.of(context).colorScheme.secondary : Theme.of(context).colorScheme.onPrimary.withOpacity(0.7),
                        ),
                        onPressed: () => widget.onVote(widget.post, 'downvote'),
                      ),
                      const Spacer(),
                      InkWell(
                        onTap: widget.onComments == null
                            ? null
                            : () => widget.onComments!(widget.post),
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 8),
                          child: Row(
                            children: [
                              Icon(
                                Icons.comment,
                                size: 16,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onPrimary
                                    .withOpacity(0.7),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                widget.post.commentCount.toString(),
                                style: TextStyle(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onPrimary
                                      .withOpacity(0.7),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ));
      },
    );
  }
}
