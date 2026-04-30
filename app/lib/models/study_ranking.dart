const String _hostUrl = 'https://ocs.kttprojects.com';

class StudyRankingItem {
  final int rank;
  final int userId;
  final String displayName;
  final String? avatarUrl;
  final int points;
  final String? badge;

  StudyRankingItem({
    required this.rank,
    required this.userId,
    required this.displayName,
    this.avatarUrl,
    required this.points,
    this.badge,
  });

  factory StudyRankingItem.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic value) {
      if (value is int) return value;
      return int.tryParse(value?.toString() ?? '') ?? 0;
    }

    return StudyRankingItem(
      rank: parseInt(json['rank']),
      userId: parseInt(json['user_id']),
      displayName: json['display_name'] ?? '',
      avatarUrl: _formatAvatarUrl(json['avatar_url']),
      points: parseInt(json['points']),
      badge: json['badge']?.toString(),
    );
  }
}

class StudyRankingResponse {
  final List<StudyRankingItem> items;
  final int page;
  final int limit;
  final int totalUsers;
  final bool hasMore;
  final StudyRankingItem? myRank;

  StudyRankingResponse({
    required this.items,
    required this.page,
    required this.limit,
    required this.totalUsers,
    required this.hasMore,
    this.myRank,
  });

  factory StudyRankingResponse.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic value) {
      if (value is int) return value;
      return int.tryParse(value?.toString() ?? '') ?? 0;
    }

    final rawItems = json['items'] as List? ?? [];
    final items = rawItems
        .map((item) => StudyRankingItem.fromJson(item as Map<String, dynamic>))
        .toList();
    final myRankJson = json['my_rank'];

    return StudyRankingResponse(
      items: items,
      page: parseInt(json['page']),
      limit: parseInt(json['limit']),
      totalUsers: parseInt(json['total_users']),
      hasMore: json['has_more'] == true ||
          json['has_more'] == 1 ||
          json['has_more'] == '1',
      myRank: myRankJson is Map<String, dynamic>
          ? StudyRankingItem.fromJson(myRankJson)
          : null,
    );
  }
}

String? _formatAvatarUrl(dynamic url) {
  if (url == null) return null;
  String avatar = url.toString();
  if (avatar.startsWith('/')) {
    avatar = '$_hostUrl$avatar';
  }
  return avatar;
}
