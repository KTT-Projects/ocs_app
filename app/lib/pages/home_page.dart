// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables

import 'package:flutter/material.dart';
import 'package:ocs_app/l10n/app_localizations.dart' show AppLocalizations;
import 'package:provider/provider.dart';
import '../models/app_notification.dart';
import '../models/opportunity_experience.dart';
import '../services/api_client.dart';
import '../services/app_notification_service.dart';
import '../widgets/circle_nav_bar.dart';
import 'profile_page.dart';
import 'feeds_page.dart';
import 'events_page.dart';
import 'notifications_page.dart';
import 'post_details_page.dart';
import 'volunteer_opportunity_details_page.dart';
import 'study_page.dart';
import 'study_question_details_page.dart';

class HomePage extends StatefulWidget {
  final String token;
  final ApiClient apiClient;

  const HomePage({
    super.key,
    required this.token,
    required this.apiClient,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _initialized = false;
  bool _startedNotifications = false;
  AppNotificationService? _notificationService;
  int _currentIndex = 0;
  late final List<Widget> _pages;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _pages = [
        FeedsPage(apiClient: widget.apiClient),
        EventsPage(apiClient: widget.apiClient),
        StudyPage(apiClient: widget.apiClient),
        NotificationsPage(
          apiClient: widget.apiClient,
          onNotificationSelected: _handleNotificationSelected,
        ),
        ProfilePage(apiClient: widget.apiClient),
      ];
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _loadProfile();
        }
      });
      _initialized = true;
    }
    _notificationService ??= context.read<AppNotificationService>();
  }

  @override
  void dispose() {
    _notificationService?.stop();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      await widget.apiClient.setToken(widget.token);
      if (!mounted) return;
      await widget.apiClient.getProfile(context);
      if (!mounted || _startedNotifications) return;
      _startedNotifications = true;
      await _notificationService?.start(context);
    } catch (_) {
      // ApiClient clears invalid tokens and notifies MainPage.
    }
  }

  void _handleNotificationSelected(AppNotification notification) {
    final targetIndex = _targetIndex(notification.type);
    if (targetIndex != null) {
      setState(() {
        _currentIndex = targetIndex;
      });
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      switch (notification.type) {
        case AppNotificationType.feed:
          final post = notification.feedPost;
          if (post == null) return;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PostDetailsPage(
                apiClient: widget.apiClient,
                post: post,
              ),
            ),
          );
          break;
        case AppNotificationType.event:
        case AppNotificationType.volunteer:
          final opportunity = notification.opportunity;
          if (opportunity == null) return;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VolunteerOpportunityDetailsPage(
                apiClient: widget.apiClient,
                opportunity: opportunity,
                experience: notification.type == AppNotificationType.event
                    ? OpportunityExperience.event
                    : OpportunityExperience.volunteer,
              ),
            ),
          );
          break;
        case AppNotificationType.study:
          final question = notification.studyQuestion;
          if (question == null) return;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => StudyQuestionDetailsPage(
                apiClient: widget.apiClient,
                questionId: question.id,
              ),
            ),
          );
          break;
      }
    });
  }

  int? _targetIndex(AppNotificationType type) {
    switch (type) {
      case AppNotificationType.feed:
        return 0;
      case AppNotificationType.event:
      case AppNotificationType.volunteer:
        return 1;
      case AppNotificationType.study:
        return 2;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      extendBody: true,
      bottomNavigationBar: CircleNavBar(
        activeIcons: [
          Icon(Icons.feed, color: Colors.white, size: 28),
          Icon(Icons.event_note, color: Colors.white, size: 28),
          Icon(Icons.school, color: Colors.white, size: 28),
          Icon(Icons.notifications, color: Colors.white, size: 28),
          Icon(Icons.account_circle, color: Colors.white, size: 28),
        ],
        inactiveIcons: [
          Column(children: [
            Icon(Icons.feed_outlined, color: Colors.white, size: 28),
            Text(l10n.feed,
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold))
          ]),
          Column(children: [
            Icon(Icons.event_note_outlined, color: Colors.white, size: 28),
            Text(l10n.eventsFeature,
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold))
          ]),
          Column(children: [
            Icon(Icons.school_outlined, color: Colors.white, size: 28),
            Text(l10n.studyFeature,
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold))
          ]),
          Column(children: [
            Icon(Icons.notifications_outlined, color: Colors.white, size: 28),
            Text(l10n.notifications,
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold))
          ]),
          Column(children: [
            Icon(Icons.account_circle, color: Colors.white, size: 28),
            Text(l10n.profile,
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold))
          ]),
        ],
        color: Theme.of(context).colorScheme.background.withOpacity(0.2),
        height: 60,
        circleWidth: 37,
        padding: EdgeInsets.only(left: 16, right: 16, bottom: 20),
        activeIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        cornerRadius: const BorderRadius.all(Radius.circular(30)),
        elevation: 10,
      ),
    );
  }
}
