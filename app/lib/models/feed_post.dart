const String _hostUrl = 'https://ocs.kttprojects.com';

class FeedPost {
  final int id;
  final int feedId;
  final int userId;
  final String title;
  final String content;
  final String? mediaUrl;
  final String? mediaType;
  int upvotes;
  int downvotes;
  double score;
  final bool isPinned;
  final bool isLocked;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String email;
  final String displayName;
  final String? avatarUrl;
  final int commentCount;
  final String? feedName;
  final String? feedDisplayName;

  FeedPost({
    required this.id,
    required this.feedId,
    required this.userId,
    required this.title,
    required this.content,
    this.mediaUrl,
    this.mediaType,
    required this.upvotes,
    required this.downvotes,
    required this.score,
    required this.isPinned,
    required this.isLocked,
    required this.createdAt,
    required this.updatedAt,
    required this.email,
    required this.displayName,
    this.avatarUrl,
    required this.commentCount,
    this.feedName,
    this.feedDisplayName,
  });

  factory FeedPost.fromJson(Map<String, dynamic> json) {
    int _parseInt(dynamic value) {
      if (value is int) return value;
      return int.tryParse(value?.toString() ?? '') ?? 0;
    }

    double _parseDouble(dynamic value) {
      if (value is double) return value;
      if (value is int) return value.toDouble();
      return double.tryParse(value?.toString() ?? '') ?? 0;
    }

    bool _parseBool(dynamic value) {
      return value == 1 || value == '1' || value == true;
    }

    return FeedPost(
      id: _parseInt(json['id']),
      feedId: _parseInt(json['feed_id']),
      userId: _parseInt(json['user_id']),
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      mediaUrl: json['media_url'],
      mediaType: json['media_type'],
      upvotes: _parseInt(json['upvotes']),
      downvotes: _parseInt(json['downvotes']),
      score: _parseDouble(json['score']),
      isPinned: _parseBool(json['is_pinned']),
      isLocked: _parseBool(json['is_locked']),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      email: json['email'],
      displayName: json['display_name'],
      avatarUrl: _formatAvatarUrl(json['avatar_url']),
      commentCount: _parseInt(json['comment_count']),
      feedName: json['feed_name'],
      feedDisplayName: json['feed_display_name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'feed_id': feedId,
      'user_id': userId,
      'title': title,
      'content': content,
      'media_url': mediaUrl,
      'media_type': mediaType,
      'upvotes': upvotes,
      'downvotes': downvotes,
      'score': score,
      'is_pinned': isPinned ? 1 : 0,
      'is_locked': isLocked ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'email': email,
      'display_name': displayName,
      'avatar_url': avatarUrl,
      'comment_count': commentCount,
      'feed_name': feedName,
      'feed_display_name': feedDisplayName,
    };
  }

  static String? _formatAvatarUrl(dynamic url) {
    if (url == null) return null;
    String avatar = url.toString();
    if (avatar.startsWith('/')) {
      avatar = '$_hostUrl$avatar';
    }
    return avatar;
  }

  String getTimeAgo() {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()}y';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()}mo';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'now';
    }
  }
}
