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
  final bool isMember;

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
    this.isMember = false,
  });

  factory Feed.fromJson(Map<String, dynamic> json) {
    return Feed(
      id: int.parse(json['id']),
      name: json['name'],
      displayName: json['display_name'],
      description: json['description'],
      createdBy: int.parse(json['created_by']),
      rules: json['rules'],
      bannerUrl: json['banner_url'],
      iconUrl: json['icon_url'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      memberCount: int.parse(json['member_count'] ?? '0'),
      postCount: int.parse(json['post_count'] ?? '0'),
      isMember: json['is_member'] == '1' ||
          json['is_member'] == 1 ||
          json['is_member'] == true,
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
      'is_member': isMember,
    };
  }

  Feed copyWith({
    int? id,
    String? name,
    String? displayName,
    String? description,
    int? createdBy,
    String? rules,
    String? bannerUrl,
    String? iconUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? memberCount,
    int? postCount,
    bool? isMember,
  }) {
    return Feed(
      id: id ?? this.id,
      name: name ?? this.name,
      displayName: displayName ?? this.displayName,
      description: description ?? this.description,
      createdBy: createdBy ?? this.createdBy,
      rules: rules ?? this.rules,
      bannerUrl: bannerUrl ?? this.bannerUrl,
      iconUrl: iconUrl ?? this.iconUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      memberCount: memberCount ?? this.memberCount,
      postCount: postCount ?? this.postCount,
      isMember: isMember ?? this.isMember,
    );
  }
}
