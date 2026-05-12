import 'feed_post.dart';
import 'study_question.dart';
import 'volunteer_opportunity.dart';

enum AppNotificationType {
  feed,
  event,
  volunteer,
  study,
}

class AppNotification {
  final String id;
  final AppNotificationType type;
  final String title;
  final String body;
  final DateTime createdAt;
  final FeedPost? feedPost;
  final VolunteerOpportunity? opportunity;
  final StudyQuestion? studyQuestion;

  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.createdAt,
    this.feedPost,
    this.opportunity,
    this.studyQuestion,
  });
}
