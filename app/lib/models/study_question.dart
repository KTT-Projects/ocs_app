const String _hostUrl = 'https://kamilander.com';

class StudyQuestion {
  final int id;
  final int authorUserId;
  final String title;
  final String body;
  final List<String> tags;
  final String category;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String authorDisplayName;
  final String? authorAvatarUrl;
  final String? mediaUrl;
  final List<String> mediaUrls;
  final int answerCount;
  final int? bestAnswerId;
  final bool canMarkBest;

  StudyQuestion({
    required this.id,
    required this.authorUserId,
    required this.title,
    required this.body,
    required this.tags,
    required this.category,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.authorDisplayName,
    this.authorAvatarUrl,
    this.mediaUrl,
    this.mediaUrls = const [],
    this.answerCount = 0,
    this.bestAnswerId,
    this.canMarkBest = false,
  });

  bool get isResolved => status == 'resolved';

  factory StudyQuestion.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic value) {
      if (value is int) return value;
      return int.tryParse(value?.toString() ?? '') ?? 0;
    }

    List<String> parseTags(dynamic rawTags, String fallbackCategory) {
      final values = <String>[];
      if (rawTags is List) {
        for (final item in rawTags) {
          final text = item?.toString().trim() ?? '';
          if (text.isNotEmpty) {
            values.add(text);
          }
        }
      } else if (rawTags is String && rawTags.trim().isNotEmpty) {
        values.addAll(
          rawTags
              .split(RegExp(r'[,、]'))
              .map((tag) => tag.trim())
              .where((tag) => tag.isNotEmpty),
        );
      }

      if (values.isEmpty && fallbackCategory.trim().isNotEmpty) {
        values.addAll(
          fallbackCategory
              .split(RegExp(r'[,、]'))
              .map((tag) => tag.trim())
              .where((tag) => tag.isNotEmpty),
        );
      }

      if (values.isEmpty && fallbackCategory.trim().isNotEmpty) {
        values.add(fallbackCategory.trim());
      }

      final normalized = <String>[];
      final seen = <String>{};
      for (final value in values) {
        final key = value.toLowerCase();
        if (seen.contains(key)) continue;
        seen.add(key);
        normalized.add(value);
      }
      return normalized;
    }

    final fallbackCategory = json['category']?.toString() ?? '';
    final parsedTags = parseTags(json['tags'], fallbackCategory);
    final primaryCategory =
        parsedTags.isNotEmpty ? parsedTags.first : fallbackCategory;
    final parsedMediaUrls = _parseMediaUrls(
        json['media_urls'], _formatServerUrl(json['media_url']));

    return StudyQuestion(
      id: parseInt(json['id']),
      authorUserId: parseInt(json['author_user_id']),
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      tags: parsedTags,
      category: primaryCategory,
      status: json['status'] ?? 'open',
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      authorDisplayName: json['display_name'] ?? '',
      authorAvatarUrl: _formatAvatarUrl(json['avatar_url']),
      mediaUrl: parsedMediaUrls.isNotEmpty ? parsedMediaUrls.first : null,
      mediaUrls: parsedMediaUrls,
      answerCount: parseInt(json['answer_count']),
      bestAnswerId: json['best_answer_id'] != null
          ? parseInt(json['best_answer_id'])
          : null,
      canMarkBest: json['can_mark_best'] == 1 ||
          json['can_mark_best'] == '1' ||
          json['can_mark_best'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'author_user_id': authorUserId,
      'title': title,
      'body': body,
      'tags': tags,
      'category': category,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'display_name': authorDisplayName,
      'avatar_url': authorAvatarUrl,
      'media_url': mediaUrl,
      'media_urls': mediaUrls,
      'answer_count': answerCount,
      'best_answer_id': bestAnswerId,
      'can_mark_best': canMarkBest,
    };
  }

  static String? _formatAvatarUrl(dynamic url) {
    return _formatServerUrl(url);
  }

  static String? _formatServerUrl(dynamic url) {
    if (url == null) return null;
    String value = url.toString();
    if (value.startsWith('/')) {
      value = '$_hostUrl$value';
    }
    return value;
  }

  static List<String> _parseMediaUrls(dynamic raw, String? fallbackUrl) {
    final urls = <String>[];
    if (raw is List) {
      for (final item in raw) {
        final formatted = _formatServerUrl(item);
        if (formatted != null && formatted.isNotEmpty) {
          urls.add(formatted);
        }
      }
    } else if (raw is String && raw.trim().isNotEmpty) {
      for (final part in raw.split(',')) {
        final formatted = _formatServerUrl(part.trim());
        if (formatted != null && formatted.isNotEmpty) {
          urls.add(formatted);
        }
      }
    }

    if (urls.isEmpty && fallbackUrl != null && fallbackUrl.isNotEmpty) {
      urls.add(fallbackUrl);
    }

    final unique = <String>[];
    final seen = <String>{};
    for (final url in urls) {
      if (seen.contains(url)) continue;
      seen.add(url);
      unique.add(url);
    }
    return unique;
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
