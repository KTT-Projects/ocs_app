const String _hostUrl = 'https://ocs.kttprojects.com';

class StudyQuestion {
  final int id;
  final int authorUserId;
  final String title;
  final String body;
  final String category;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String authorDisplayName;
  final String? authorAvatarUrl;

  StudyQuestion({
    required this.id,
    required this.authorUserId,
    required this.title,
    required this.body,
    required this.category,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.authorDisplayName,
    this.authorAvatarUrl,
  });

  bool get isResolved => status == 'resolved';

  factory StudyQuestion.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic value) {
      if (value is int) return value;
      return int.tryParse(value?.toString() ?? '') ?? 0;
    }

    return StudyQuestion(
      id: parseInt(json['id']),
      authorUserId: parseInt(json['author_user_id']),
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      category: json['category'] ?? '',
      status: json['status'] ?? 'open',
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      authorDisplayName: json['display_name'] ?? '',
      authorAvatarUrl: _formatAvatarUrl(json['avatar_url']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'author_user_id': authorUserId,
      'title': title,
      'body': body,
      'category': category,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'display_name': authorDisplayName,
      'avatar_url': authorAvatarUrl,
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
