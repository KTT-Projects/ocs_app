const String _hostUrl = 'https://ocs.kttprojects.com';

class VolunteerParticipant {
  final int opportunityId;
  final int userId;
  final String userName;
  final String? userAvatar;
  final String? userGrade;
  final String? userInstitution;
  final String status; // 'applied', 'approved', 'completed', 'cancelled'
  final String? role; // 'member','coordinator','admin'
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
    this.role,
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

    int _parseInt(dynamic value) {
      if (value is int) return value;
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    double? _parseDouble(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value);
      return null;
    }

    bool _parseBool(dynamic value) {
      return value == true || value == 1 || value == '1';
    }

    return VolunteerParticipant(
      opportunityId: _parseInt(json['opportunity_id']),
      userId: _parseInt(json['user_id']),
      userName: (json['user_name'] ?? '').toString(),
      userAvatar: avatarUrl,
      userGrade: json['user_grade'],
      userInstitution: json['user_institution'],
      status: json['status'] ?? 'applied',
      role: json['role'],
      hoursCompleted: _parseDouble(json['hours_completed']),
      certificateIssued: _parseBool(json['certificate_issued']),
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
      'role': role,
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
    String? role,
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
      role: role ?? this.role,
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
