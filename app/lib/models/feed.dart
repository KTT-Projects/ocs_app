class Feed {
  final int id;
  final String name;
  final String displayName;
  final String description;
  final int createdBy;
  final String? rules;
  final String? bannerUrl;
  final String? iconUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int memberCount;
  final int postCount;

  Feed({
    required this.id,
    required this.name,
    required this.displayName,
    required this.description,
    required this.createdBy,
    this.rules,
    this.bannerUrl,
    this.iconUrl,
    required this.createdAt,
    required this.updatedAt,
    required this.memberCount,
    required this.postCount,
  });

  factory Feed.fromJson(Map<String, dynamic> json) {
    return Feed(
      id: json['id'],
      name: json['name'],
      displayName: json['display_name'],
      description: json['description'],
      createdBy: json['created_by'],
      rules: json['rules'],
      bannerUrl: json['banner_url'] != null 
          ? (json['banner_url'].toString().startsWith('/') 
              ? 'https://ocs.kttprojects.com${json['banner_url']}'
              : json['banner_url'])
          : null,
      iconUrl: json['icon_url'] != null 
          ? (json['icon_url'].toString().startsWith('/') 
              ? 'https://ocs.kttprojects.com${json['icon_url']}'
              : json['icon_url'])
          : null,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      memberCount: json['member_count'] ?? 0,
      postCount: json['post_count'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'display_name': displayName,
      'description': description,
      'created_by': createdBy,
      'rules': rules,
      'banner_url': bannerUrl,
      'icon_url': iconUrl,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'member_count': memberCount,
      'post_count': postCount,
    };
  }
}
