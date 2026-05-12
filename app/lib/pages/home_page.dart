// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables

import 'package:flutter/material.dart';
import 'package:ocs_app/l10n/app_localizations.dart' show AppLocalizations;
import 'package:provider/provider.dart';
import '../models/app_notification.dart';
import '../models/opportunity_experience.dart';
import '../services/api_client.dart';
import '../services/app_notification_service.dart';
import '../widgets/circle_nav_bar.dart';
// import '../widgets/circle_nav_bar_arc.dart';
import 'profile_page.dart';
import 'feeds_page.dart';
import 'events_page.dart';
import 'notifications_page.dart';
import 'post_details_page.dart';
import 'volunteer_page.dart';
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
        VolunteerPage(apiClient: widget.apiClient),
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
    if (!_startedNotifications) {
      _startedNotifications = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _notificationService?.start(context);
        }
      });
    }
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
        return 1;
      case AppNotificationType.volunteer:
        return 2;
      case AppNotificationType.study:
        return 3;
    }
  }

  Widget _navIcon(
    IconData icon, {
    required bool active,
    int unreadCount = 0,
  }) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(icon, color: Colors.white, size: active ? 28 : 26),
        if (unreadCount > 0)
          Positioned(
            right: -8,
            top: -8,
            child: Container(
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              padding: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondary,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white, width: 1),
              ),
              child: Text(
                unreadCount > 99 ? '99+' : unreadCount.toString(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSecondary,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  height: 1.3,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _inactiveNavItem(IconData icon, String label, {int unreadCount = 0}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _navIcon(icon, active: false, unreadCount: unreadCount),
        const SizedBox(height: 2),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              maxLines: 1,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final unreadCount = context.watch<AppNotificationService>().unreadCount;

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      extendBody: true,
      bottomNavigationBar: CircleNavBar(
        activeIcons: [
          _navIcon(Icons.feed, active: true),
          _navIcon(Icons.event_note, active: true),
          _navIcon(Icons.volunteer_activism, active: true),
          _navIcon(Icons.school, active: true),
          _navIcon(
            Icons.notifications,
            active: true,
            unreadCount: unreadCount,
          ),
          _navIcon(Icons.account_circle, active: true),
        ],
        inactiveIcons: [
          _inactiveNavItem(Icons.feed_outlined, l10n.feed),
          _inactiveNavItem(Icons.event_note_outlined, l10n.eventsFeature),
          _inactiveNavItem(
            Icons.volunteer_activism_outlined,
            l10n.volunteerFeature,
          ),
          _inactiveNavItem(Icons.school_outlined, l10n.studyFeature),
          _inactiveNavItem(
            Icons.notifications_outlined,
            l10n.notifications,
            unreadCount: unreadCount,
          ),
          _inactiveNavItem(Icons.account_circle, l10n.profile),
        ],
        color: Theme.of(context).colorScheme.background.withOpacity(0.2),
        // circleColor: Theme.of(context).colorScheme.secondary,
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
