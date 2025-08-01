const String _hostUrl = 'https://ocs.kttprojects.com';

class VolunteerOpportunity {
  final int id;
  final String title;
  final String description;
  final String location;
  final DateTime startDate;
  final DateTime? endDate;
  final String organizer;
  final String? organizerContact;
  final int maxParticipants;
  final List<String>? tags;
  final String? imageUrl;
  final int createdBy;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int registeredCount;
  final bool isRegistered;

  VolunteerOpportunity({
    required this.id,
    required this.title,
    required this.description,
    required this.location,
    required this.startDate,
    this.endDate,
    required this.organizer,
    this.organizerContact,
    required this.maxParticipants,
    this.tags,
    this.imageUrl,
    required this.createdBy,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.registeredCount,
    required this.isRegistered,
  });

  factory VolunteerOpportunity.fromJson(Map<String, dynamic> json) {
    return VolunteerOpportunity(
      id: int.parse(json['id'].toString()),
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      location: json['location'] ?? '',
      startDate: DateTime.parse(json['start_date']),
      endDate: json['end_date'] != null ? DateTime.parse(json['end_date']) : null,
      organizer: json['organizer'] ?? '',
      organizerContact: json['organizer_contact'],
      maxParticipants: int.parse(json['max_participants'].toString()),
      tags: json['tags'] != null ? List<String>.from(json['tags']) : null,
      imageUrl: _formatImageUrl(json['image_url']),
      createdBy: int.parse(json['created_by'].toString()),
      status: json['status'] ?? 'open',
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      registeredCount: int.parse(json['registered_count'].toString() ?? '0'),
      isRegistered: json['is_registered'] == 1 || json['is_registered'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'location': location,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'organizer': organizer,
      'organizer_contact': organizerContact,
      'max_participants': maxParticipants,
      'tags': tags,
      'image_url': imageUrl,
      'created_by': createdBy,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'registered_count': registeredCount,
      'is_registered': isRegistered,
    };
  }

  VolunteerOpportunity copyWith({
    int? id,
    String? title,
    String? description,
    String? location,
    DateTime? startDate,
    DateTime? endDate,
    String? organizer,
    String? organizerContact,
    int? maxParticipants,
    List<String>? tags,
    String? imageUrl,
    int? createdBy,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? registeredCount,
    bool? isRegistered,
  }) {
    return VolunteerOpportunity(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      location: location ?? this.location,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      organizer: organizer ?? this.organizer,
      organizerContact: organizerContact ?? this.organizerContact,
      maxParticipants: maxParticipants ?? this.maxParticipants,
      tags: tags ?? this.tags,
      imageUrl: imageUrl ?? this.imageUrl,
      createdBy: createdBy ?? this.createdBy,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      registeredCount: registeredCount ?? this.registeredCount,
      isRegistered: isRegistered ?? this.isRegistered,
    );
  }

  static String? _formatImageUrl(dynamic url) {
    if (url == null) return null;
    String imageUrl = url.toString();
    if (imageUrl.startsWith('/')) {
      imageUrl = '$_hostUrl$imageUrl';
    }
    return imageUrl;
  }

  String get formattedStartDate {
    return _formatDateTime(startDate);
  }

  String get formattedEndDate {
    return endDate != null ? _formatDateTime(endDate!) : '';
  }

  String get formattedDuration {
    if (endDate == null) return '';
    final duration = endDate!.difference(startDate);
    if (duration.inDays > 0) {
      return '${duration.inDays} day${duration.inDays > 1 ? 's' : ''}';
    } else if (duration.inHours > 0) {
      return '${duration.inHours} hour${duration.inHours > 1 ? 's' : ''}';
    } else {
      return '${duration.inMinutes} minute${duration.inMinutes > 1 ? 's' : ''}';
    }
  }

  String get participantCountText {
    if (maxParticipants <= 0) {
      return '$registeredCount participants';
    } else {
      return '$registeredCount/$maxParticipants participants';
    }
  }

  int get currentParticipants => registeredCount;

  bool get isFull {
    return maxParticipants > 0 && registeredCount >= maxParticipants;
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

  static String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
