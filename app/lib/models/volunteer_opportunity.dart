import 'volunteer_attachment.dart';
import 'volunteer_reflection.dart';

const String _hostUrl = 'https://ocs.kttprojects.com';

class VolunteerOpportunity {
  final int id;
  final String title;
  final String description;
  final int organizerId;
  final String? organizerName;
  final String? organizerAvatar;
  final String location;
  final DateTime date; // Single date for the volunteer event
  final DateTime? startTime; // Optional start time
  final DateTime? endTime; // Optional end time
  final int? requiredParticipants;
  final String status; // 'open', 'filled', 'completed', 'cancelled'
  final DateTime createdAt;
  final DateTime updatedAt;
  final int participantCount;
  final bool isFull;
  final int? spotsRemaining;
  final bool isParticipant;
  final String?
      participantStatus; // 'applied', 'approved', 'completed', 'cancelled'
  final String? participantRole; // 'member', 'coordinator', 'admin'
  final double? hoursCompleted;
  final bool? certificateIssued;
  final int attachmentCount;
  final String? coverAttachmentUrl;
  final List<VolunteerAttachment> attachments;
  final int reflectionCount;
  final DateTime? latestReflectionAt;
  final String? latestReflectionTitle;
  final String? latestReflectionExcerpt;
  final List<VolunteerReflectionImage> latestReflectionImages;

  VolunteerOpportunity({
    required this.id,
    required this.title,
    required this.description,
    required this.organizerId,
    this.organizerName,
    this.organizerAvatar,
    required this.location,
    required this.date,
    this.startTime,
    this.endTime,
    this.requiredParticipants,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.participantCount = 0,
    this.isFull = false,
    this.spotsRemaining,
    this.isParticipant = false,
    this.participantStatus,
    this.participantRole,
    this.hoursCompleted,
    this.certificateIssued,
    this.attachmentCount = 0,
    this.coverAttachmentUrl,
    this.attachments = const [],
    this.reflectionCount = 0,
    this.latestReflectionAt,
    this.latestReflectionTitle,
    this.latestReflectionExcerpt,
    this.latestReflectionImages = const [],
  });

  factory VolunteerOpportunity.fromJson(Map<String, dynamic> json) {
    String? avatarUrl = json['organizer_avatar'];
    if (avatarUrl != null && avatarUrl.startsWith('/')) {
      avatarUrl = '$_hostUrl$avatarUrl';
    }

    final dateStr = json['date'] ??
        json['start_date']; // Support both formats during migration
    final date = DateTime.parse(dateStr);

    final startTimeStr = json['start_time'];
    final endTimeStr = json['end_time'];

    int? _parseIntNullable(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v);
      return null;
    }

    int _parseInt(dynamic v, {required int defaultValue}) {
      return _parseIntNullable(v) ?? defaultValue;
    }

    double? _parseDoubleNullable(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v);
      return null;
    }

    DateTime? _parseTime(String? value) {
      if (value == null) return null;
      final timeParts = value.split(':');
      if (timeParts.length < 2) return null;
      return DateTime(
        date.year,
        date.month,
        date.day,
        int.tryParse(timeParts[0]) ?? 0,
        int.tryParse(timeParts[1]) ?? 0,
      );
    }

    final startTime = _parseTime(startTimeStr);
    final endTime = _parseTime(endTimeStr);

    bool _parseBool(dynamic value) {
      return value == true || value == 1 || value == '1';
    }

    DateTime? _parseDateTime(dynamic value) {
      if (value == null) return null;
      try {
        return DateTime.parse(value.toString());
      } catch (_) {
        return null;
      }
    }

    final parsedSpots = _parseIntNullable(json['spots_remaining']);

    int attachmentCount = _parseInt(json['attachment_count'], defaultValue: 0);
    String? coverAttachmentUrl = json['cover_attachment_url'];
    if (coverAttachmentUrl != null && coverAttachmentUrl.startsWith('/')) {
      coverAttachmentUrl = '$_hostUrl$coverAttachmentUrl';
    }

    List<VolunteerAttachment> attachments = [];
    if (json['attachments'] is List) {
      attachments = (json['attachments'] as List)
          .map((a) => VolunteerAttachment.fromJson(
              Map<String, dynamic>.from(a), _hostUrl))
          .toList();
      if (attachmentCount == 0) {
        attachmentCount = attachments.length;
      }
    }

    List<VolunteerReflectionImage> latestReflectionImages = [];
    if (json['latest_reflection_images'] is List) {
      latestReflectionImages = (json['latest_reflection_images'] as List)
          .map((img) =>
              VolunteerReflectionImage.fromJson(Map<String, dynamic>.from(img)))
          .toList();
    }

    return VolunteerOpportunity(
      id: _parseInt(json['id'], defaultValue: 0),
      title: json['title'],
      description: json['description'],
      organizerId: _parseInt(json['organizer_id'], defaultValue: 0),
      organizerName: json['organizer_name'],
      organizerAvatar: avatarUrl,
      location: json['location'],
      date: date,
      startTime: startTime,
      endTime: endTime,
      requiredParticipants: _parseIntNullable(json['required_participants']),
      status: json['status'] ?? 'open',
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      participantCount: _parseInt(json['participant_count'], defaultValue: 0),
      isFull: _parseBool(json['is_full'] ?? false),
      spotsRemaining: parsedSpots != null && parsedSpots < 0 ? 0 : parsedSpots,
      isParticipant: _parseBool(json['is_participant']),
      participantStatus: json['participant_status'],
      participantRole: json['participant_role'],
      hoursCompleted: _parseDoubleNullable(json['hours_completed']),
      certificateIssued: _parseBool(json['certificate_issued']),
      attachmentCount: attachmentCount,
      coverAttachmentUrl: coverAttachmentUrl,
      attachments: attachments,
      reflectionCount: _parseInt(json['reflection_count'], defaultValue: 0),
      latestReflectionAt: _parseDateTime(json['latest_reflection_at']),
      latestReflectionTitle: json['latest_reflection_title'],
      latestReflectionExcerpt: json['latest_reflection_excerpt'],
      latestReflectionImages: latestReflectionImages,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'organizer_id': organizerId,
      'organizer_name': organizerName,
      'organizer_avatar': organizerAvatar,
      'location': location,
      'date': date.toIso8601String(),
      'start_time': startTime != null
          ? '${startTime!.hour.toString().padLeft(2, '0')}:${startTime!.minute.toString().padLeft(2, '0')}'
          : null,
      'end_time': endTime != null
          ? '${endTime!.hour.toString().padLeft(2, '0')}:${endTime!.minute.toString().padLeft(2, '0')}'
          : null,
      'required_participants': requiredParticipants,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'participant_count': participantCount,
      'is_full': isFull,
      'spots_remaining': spotsRemaining,
      'is_participant': isParticipant,
      'participant_status': participantStatus,
      'participant_role': participantRole,
      'hours_completed': hoursCompleted,
      'certificate_issued': certificateIssued,
      'attachment_count': attachmentCount,
      'cover_attachment_url': coverAttachmentUrl,
      'attachments': attachments
          .map((a) => {
                'id': a.id,
                'opportunity_id': a.opportunityId,
                'file_name': a.fileName,
                'file_url': a.fileUrl,
                'mime_type': a.mimeType,
                'file_size': a.fileSize,
                'uploaded_by': a.uploadedBy,
                'created_at': a.createdAt.toIso8601String(),
              })
          .toList(),
      'reflection_count': reflectionCount,
      'latest_reflection_at': latestReflectionAt?.toIso8601String(),
      'latest_reflection_title': latestReflectionTitle,
      'latest_reflection_excerpt': latestReflectionExcerpt,
      'latest_reflection_images': latestReflectionImages
          .map((img) => {
                'id': img.id,
                'reflection_id': img.reflectionId,
                'file_name': img.fileName,
                'file_url': img.fileUrl,
                'mime_type': img.mimeType,
                'file_size': img.fileSize,
                'uploaded_by': img.uploadedBy,
                'created_at': img.createdAt.toIso8601String(),
              })
          .toList(),
    };
  }

  VolunteerOpportunity copyWith({
    int? id,
    String? title,
    String? description,
    int? organizerId,
    String? organizerName,
    String? organizerAvatar,
    String? location,
    DateTime? date,
    DateTime? startTime,
    DateTime? endTime,
    int? requiredParticipants,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? participantCount,
    bool? isFull,
    int? spotsRemaining,
    bool? isParticipant,
    String? participantStatus,
    String? participantRole,
    double? hoursCompleted,
    bool? certificateIssued,
    int? attachmentCount,
    String? coverAttachmentUrl,
    List<VolunteerAttachment>? attachments,
    int? reflectionCount,
    DateTime? latestReflectionAt,
    String? latestReflectionTitle,
    String? latestReflectionExcerpt,
    List<VolunteerReflectionImage>? latestReflectionImages,
  }) {
    return VolunteerOpportunity(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      organizerId: organizerId ?? this.organizerId,
      organizerName: organizerName ?? this.organizerName,
      organizerAvatar: organizerAvatar ?? this.organizerAvatar,
      location: location ?? this.location,
      date: date ?? this.date,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      requiredParticipants: requiredParticipants ?? this.requiredParticipants,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      participantCount: participantCount ?? this.participantCount,
      isFull: isFull ?? this.isFull,
      spotsRemaining: spotsRemaining ?? this.spotsRemaining,
      isParticipant: isParticipant ?? this.isParticipant,
      participantStatus: participantStatus ?? this.participantStatus,
      participantRole: participantRole ?? this.participantRole,
      hoursCompleted: hoursCompleted ?? this.hoursCompleted,
      certificateIssued: certificateIssued ?? this.certificateIssued,
      attachmentCount: attachmentCount ?? this.attachmentCount,
      coverAttachmentUrl: coverAttachmentUrl ?? this.coverAttachmentUrl,
      attachments: attachments ?? this.attachments,
      reflectionCount: reflectionCount ?? this.reflectionCount,
      latestReflectionAt: latestReflectionAt ?? this.latestReflectionAt,
      latestReflectionTitle:
          latestReflectionTitle ?? this.latestReflectionTitle,
      latestReflectionExcerpt:
          latestReflectionExcerpt ?? this.latestReflectionExcerpt,
      latestReflectionImages:
          latestReflectionImages ?? this.latestReflectionImages,
    );
  }

  bool get isOpen => status == 'open';
  bool get isFilled => status == 'filled';
  bool get isCompleted => status == 'completed';
  bool get isCancelled => status == 'cancelled';

  bool get canApply {
    final fullByCount = requiredParticipants != null &&
        participantCount >= requiredParticipants!;
    final fullByFlag = isFull || spotsRemaining == 0;
    return isOpen &&
        (!isParticipant || participantStatus == 'cancelled') &&
        !fullByCount &&
        !fullByFlag;
  }

  bool isOrganizer(int userId) => organizerId == userId;

  bool get isUpcoming => date.isAfter(DateTime.now());
  bool get isOngoing {
    if (startTime == null || endTime == null) return false;
    final now = DateTime.now();
    final todayStart = DateTime(
        date.year, date.month, date.day, startTime!.hour, startTime!.minute);
    final todayEnd = DateTime(
        date.year, date.month, date.day, endTime!.hour, endTime!.minute);
    return now.isAfter(todayStart) && now.isBefore(todayEnd);
  }

  bool get isPast {
    if (endTime == null) return date.isBefore(DateTime.now());
    final todayEnd = DateTime(
        date.year, date.month, date.day, endTime!.hour, endTime!.minute);
    return todayEnd.isBefore(DateTime.now());
  }

  String get statusColor {
    switch (status) {
      case 'open':
        return 'green';
      case 'filled':
        return 'orange';
      case 'completed':
        return 'blue';
      case 'cancelled':
        return 'red';
      default:
        return 'grey';
    }
  }

  // Permissions (client can add organizer checks separately)
  bool get canManageDetails => participantRole == 'admin';
  bool get canManageParticipants =>
      participantRole == 'admin' || participantRole == 'coordinator';
}
