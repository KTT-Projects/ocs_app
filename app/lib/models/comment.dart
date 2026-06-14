const String _hostUrl = 'https://kamilander.com';

class Comment {
  final int id;
  final int postId;
  final int userId;
  final int? parentCommentId;
  final String content;
  final int upvotes;
  final int downvotes;
  final double score;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String displayName;
  final String? avatarUrl;

  Comment({
    required this.id,
    required this.postId,
    required this.userId,
    this.parentCommentId,
    required this.content,
    required this.upvotes,
    required this.downvotes,
    required this.score,
    required this.createdAt,
    required this.updatedAt,
    required this.displayName,
    this.avatarUrl,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    int _parseInt(dynamic value) {
      if (value is int) return value;
      return int.tryParse(value?.toString() ?? '') ?? 0;
    }

    double _parseDouble(dynamic value) {
      if (value is double) return value;
      if (value is int) return value.toDouble();
      return double.tryParse(value?.toString() ?? '') ?? 0;
    }

    return Comment(
      id: _parseInt(json['id']),
      postId: _parseInt(json['post_id']),
      userId: _parseInt(json['user_id']),
      parentCommentId: json['parent_comment_id'] != null
          ? _parseInt(json['parent_comment_id'])
          : null,
      content: json['content'] ?? '',
      upvotes: _parseInt(json['upvotes']),
      downvotes: _parseInt(json['downvotes']),
      score: _parseDouble(json['score']),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      displayName: json['display_name'] ?? '',
      avatarUrl: _formatAvatarUrl(json['avatar_url']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'post_id': postId,
      'user_id': userId,
      'parent_comment_id': parentCommentId,
      'content': content,
      'upvotes': upvotes,
      'downvotes': downvotes,
      'score': score,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'display_name': displayName,
      'avatar_url': avatarUrl,
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
