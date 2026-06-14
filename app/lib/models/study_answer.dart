const String _hostUrl = 'https://kamilander.com';

class StudyAnswer {
  final int id;
  final int questionId;
  final int authorUserId;
  final String body;
  final bool isBest;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String authorDisplayName;
  final String? authorAvatarUrl;
  final int totalPoints;

  StudyAnswer({
    required this.id,
    required this.questionId,
    required this.authorUserId,
    required this.body,
    required this.isBest,
    required this.createdAt,
    required this.updatedAt,
    required this.authorDisplayName,
    this.authorAvatarUrl,
    this.totalPoints = 0,
  });

  factory StudyAnswer.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic value) {
      if (value is int) return value;
      return int.tryParse(value?.toString() ?? '') ?? 0;
    }

    bool parseBool(dynamic value) {
      return value == 1 || value == '1' || value == true;
    }

    return StudyAnswer(
      id: parseInt(json['id']),
      questionId: parseInt(json['question_id']),
      authorUserId: parseInt(json['author_user_id']),
      body: json['body'] ?? '',
      isBest: parseBool(json['is_best']),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      authorDisplayName: json['display_name'] ?? '',
      authorAvatarUrl: _formatAvatarUrl(json['avatar_url']),
      totalPoints: parseInt(json['total_points']),
    );
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
