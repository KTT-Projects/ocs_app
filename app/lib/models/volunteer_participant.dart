const String _hostUrl = 'https://ocs.kttprojects.com';

class VolunteerParticipant {
  final int opportunityId;
  final int userId;
  final String userName;
  final String? userAvatar;
  final String? userGrade;
  final String? userInstitution;
  final String status; // 'applied', 'approved', 'completed', 'cancelled'
  final double? hoursCompleted;
  final bool certificateIssued;
  final DateTime createdAt;
  final DateTime updatedAt;

  VolunteerParticipant({
    required this.opportunityId,
    required this.userId,
    required this.userName,
    this.userAvatar,
    this.userGrade,
    this.userInstitution,
    required this.status,
    this.hoursCompleted,
    this.certificateIssued = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory VolunteerParticipant.fromJson(Map<String, dynamic> json) {
    String? avatarUrl = json['user_avatar'];
    if (avatarUrl != null && avatarUrl.startsWith('/')) {
      avatarUrl = '$_hostUrl$avatarUrl';
    }

    return VolunteerParticipant(
      opportunityId: int.parse(json['opportunity_id']),
      userId: int.parse(json['user_id']),
      userName: json['user_name'] ?? '',
      userAvatar: avatarUrl,
      userGrade: json['user_grade'],
      userInstitution: json['user_institution'],
      status: json['status'] ?? 'applied',
      hoursCompleted: json['hours_completed'] != null ? double.parse(json['hours_completed']) : null,
      certificateIssued: json['certificate_issued'] == '1' || json['certificate_issued'] == 1 || json['certificate_issued'] == true,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'opportunity_id': opportunityId,
      'user_id': userId,
      'user_name': userName,
      'user_avatar': userAvatar,
      'user_grade': userGrade,
      'user_institution': userInstitution,
      'status': status,
      'hours_completed': hoursCompleted,
      'certificate_issued': certificateIssued,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  VolunteerParticipant copyWith({
    int? opportunityId,
    int? userId,
    String? userName,
    String? userAvatar,
    String? userGrade,
    String? userInstitution,
    String? status,
    double? hoursCompleted,
    bool? certificateIssued,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return VolunteerParticipant(
      opportunityId: opportunityId ?? this.opportunityId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userAvatar: userAvatar ?? this.userAvatar,
      userGrade: userGrade ?? this.userGrade,
      userInstitution: userInstitution ?? this.userInstitution,
      status: status ?? this.status,
      hoursCompleted: hoursCompleted ?? this.hoursCompleted,
      certificateIssued: certificateIssued ?? this.certificateIssued,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get isApplied => status == 'applied';
  bool get isApproved => status == 'approved';
  bool get isCompleted => status == 'completed';
  bool get isCancelled => status == 'cancelled';
}
