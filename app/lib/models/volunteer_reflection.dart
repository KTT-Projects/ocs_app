const String _hostUrl = 'https://kamilander.com';

class VolunteerReflectionImage {
  final int id;
  final int reflectionId;
  final String fileName;
  final String fileUrl;
  final String mimeType;
  final int? fileSize;
  final int uploadedBy;
  final DateTime createdAt;

  const VolunteerReflectionImage({
    required this.id,
    required this.reflectionId,
    required this.fileName,
    required this.fileUrl,
    required this.mimeType,
    this.fileSize,
    required this.uploadedBy,
    required this.createdAt,
  });

  bool get isImage => mimeType.startsWith('image/');

  factory VolunteerReflectionImage.fromJson(Map<String, dynamic> json) {
    String url = json['file_url'] ?? '';
    if (url.startsWith('/')) {
      url = '$_hostUrl$url';
    }

    int _parseInt(dynamic value) {
      if (value is int) return value;
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    int? _parseIntNullable(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value);
      return null;
    }

    return VolunteerReflectionImage(
      id: _parseInt(json['id']),
      reflectionId: _parseInt(json['reflection_id'] ?? json['reflectionId']),
      fileName: json['file_name'] ?? '',
      fileUrl: url,
      mimeType: json['mime_type'] ?? '',
      fileSize: _parseIntNullable(json['file_size']),
      uploadedBy: _parseInt(json['uploaded_by'] ?? 0),
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

class VolunteerReflection {
  final int id;
  final int opportunityId;
  final String title;
  final String body;
  final int createdBy;
  final String? authorName;
  final String? authorAvatar;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<VolunteerReflectionImage> images;

  VolunteerReflection({
    required this.id,
    required this.opportunityId,
    required this.title,
    required this.body,
    required this.createdBy,
    this.authorName,
    this.authorAvatar,
    required this.createdAt,
    required this.updatedAt,
    this.images = const [],
  });

  VolunteerReflection copyWith({
    int? id,
    int? opportunityId,
    String? title,
    String? body,
    int? createdBy,
    String? authorName,
    String? authorAvatar,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<VolunteerReflectionImage>? images,
  }) {
    return VolunteerReflection(
      id: id ?? this.id,
      opportunityId: opportunityId ?? this.opportunityId,
      title: title ?? this.title,
      body: body ?? this.body,
      createdBy: createdBy ?? this.createdBy,
      authorName: authorName ?? this.authorName,
      authorAvatar: authorAvatar ?? this.authorAvatar,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      images: images ?? this.images,
    );
  }

  factory VolunteerReflection.fromJson(Map<String, dynamic> json) {
    String? avatar = json['author_avatar'];
    if (avatar != null && avatar.startsWith('/')) {
      avatar = '$_hostUrl$avatar';
    }

    int _parseInt(dynamic value) {
      if (value is int) return value;
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    DateTime _parseDateTime(dynamic value) {
      if (value is DateTime) return value;
      return DateTime.parse(value.toString());
    }

    List<VolunteerReflectionImage> images = [];
    if (json['images'] is List) {
      images = (json['images'] as List)
          .map((img) =>
              VolunteerReflectionImage.fromJson(Map<String, dynamic>.from(img)))
          .toList();
    }

    return VolunteerReflection(
      id: _parseInt(json['id']),
      opportunityId: _parseInt(json['opportunity_id']),
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      createdBy: _parseInt(json['created_by'] ?? json['author_id']),
      authorName: json['author_name'],
      authorAvatar: avatar,
      createdAt: _parseDateTime(json['created_at']),
      updatedAt: _parseDateTime(json['updated_at']),
      images: images,
    );
  }
}
