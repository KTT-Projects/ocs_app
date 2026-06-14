class NotificationPreference {
  final String category;
  final bool inAppEnabled;
  final bool pushEnabled;

  const NotificationPreference({
    required this.category,
    required this.inAppEnabled,
    required this.pushEnabled,
  });

  NotificationPreference copyWith({
    bool? inAppEnabled,
    bool? pushEnabled,
  }) {
    return NotificationPreference(
      category: category,
      inAppEnabled: inAppEnabled ?? this.inAppEnabled,
      pushEnabled: pushEnabled ?? this.pushEnabled,
    );
  }

  factory NotificationPreference.fromJson(Map<String, dynamic> json) {
    return NotificationPreference(
      category: json['category']?.toString() ?? '',
      inAppEnabled: _parseBool(json['in_app_enabled']),
      pushEnabled: _parseBool(json['push_enabled']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'category': category,
      'in_app_enabled': inAppEnabled,
      'push_enabled': pushEnabled,
    };
  }

  static bool _parseBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      return value == '1' || value.toLowerCase() == 'true';
    }
    return true;
  }
}

class NotificationPreferenceCategories {
  static const feedPosts = 'feed_posts';
  static const feedComments = 'feed_comments';
  static const events = 'events';
  static const volunteerOpportunities = 'volunteer_opportunities';
  static const opportunityApplications = 'opportunity_applications';
  static const studyQuestions = 'study_questions';
  static const studyAnswers = 'study_answers';
  static const studyBestAnswers = 'study_best_answers';

  static const all = <String>[
    feedPosts,
    feedComments,
    events,
    volunteerOpportunities,
    opportunityApplications,
    studyQuestions,
    studyAnswers,
    studyBestAnswers,
  ];
}
