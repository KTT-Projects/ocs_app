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
  final bool isParticipant;
  final String? participantStatus; // 'applied', 'approved', 'completed', 'cancelled'
  final double? hoursCompleted;
  final bool? certificateIssued;

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
    this.isParticipant = false,
    this.participantStatus,
    this.hoursCompleted,
    this.certificateIssued,
  });

  factory VolunteerOpportunity.fromJson(Map<String, dynamic> json) {
    String? avatarUrl = json['organizer_avatar'];
    if (avatarUrl != null && avatarUrl.startsWith('/')) {
      avatarUrl = '$_hostUrl$avatarUrl';
    }

    final dateStr = json['date'] ?? json['start_date']; // Support both formats during migration
    final date = DateTime.parse(dateStr);

    final startTimeStr = json['start_time'];
    final endTimeStr = json['end_time'];

    DateTime? startTime;
    if (startTimeStr != null) {
      final timeParts = startTimeStr.split(':');
      startTime = DateTime(
        date.year,
        date.month,
        date.day,
        int.parse(timeParts[0]),
        int.parse(timeParts[1]),
      );
    }

    DateTime? endTime;
    if (endTimeStr != null) {
      final timeParts = endTimeStr.split(':');
      endTime = DateTime(
        date.year,
        date.month,
        date.day,
        int.parse(timeParts[0]),
        int.parse(timeParts[1]),
      );
    }

    return VolunteerOpportunity(
      id: json['id'] is String ? int.parse(json['id']) : json['id'],
      title: json['title'],
      description: json['description'],
      organizerId: json['organizer_id'] is String ? int.parse(json['organizer_id']) : json['organizer_id'],
      organizerName: json['organizer_name'],
      organizerAvatar: avatarUrl,
      location: json['location'],
      date: date,
      startTime: startTime,
      endTime: endTime,
      requiredParticipants: json['required_participants'] != null ? int.parse(json['required_participants']) : null,
      status: json['status'] ?? 'open',
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      participantCount: int.parse(json['participant_count'] ?? '0'),
      isParticipant: json['is_participant'] == '1' || json['is_participant'] == 1 || json['is_participant'] == true,
      participantStatus: json['participant_status'],
      hoursCompleted: json['hours_completed'] != null ? double.parse(json['hours_completed']) : null,
      certificateIssued: json['certificate_issued'] == '1' || json['certificate_issued'] == 1 || json['certificate_issued'] == true,
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
      'start_time': startTime != null ? '${startTime!.hour.toString().padLeft(2, '0')}:${startTime!.minute.toString().padLeft(2, '0')}' : null,
      'end_time': endTime != null ? '${endTime!.hour.toString().padLeft(2, '0')}:${endTime!.minute.toString().padLeft(2, '0')}' : null,
      'required_participants': requiredParticipants,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'participant_count': participantCount,
      'is_participant': isParticipant,
      'participant_status': participantStatus,
      'hours_completed': hoursCompleted,
      'certificate_issued': certificateIssued,
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
    bool? isParticipant,
    String? participantStatus,
    double? hoursCompleted,
    bool? certificateIssued,
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
      isParticipant: isParticipant ?? this.isParticipant,
      participantStatus: participantStatus ?? this.participantStatus,
      hoursCompleted: hoursCompleted ?? this.hoursCompleted,
      certificateIssued: certificateIssued ?? this.certificateIssued,
    );
  }

  bool get isOpen => status == 'open';
  bool get isFilled => status == 'filled';
  bool get isCompleted => status == 'completed';
  bool get isCancelled => status == 'cancelled';

  bool get canApply => isOpen && (!isParticipant || participantStatus == 'cancelled') && (requiredParticipants == null || participantCount < requiredParticipants!);

  bool isOrganizer(int userId) => organizerId == userId;

  bool get isUpcoming => date.isAfter(DateTime.now());
  bool get isOngoing {
    if (startTime == null || endTime == null) return false;
    final now = DateTime.now();
    final todayStart = DateTime(date.year, date.month, date.day, startTime!.hour, startTime!.minute);
    final todayEnd = DateTime(date.year, date.month, date.day, endTime!.hour, endTime!.minute);
    return now.isAfter(todayStart) && now.isBefore(todayEnd);
  }

  bool get isPast {
    if (endTime == null) return date.isBefore(DateTime.now());
    final todayEnd = DateTime(date.year, date.month, date.day, endTime!.hour, endTime!.minute);
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
}
