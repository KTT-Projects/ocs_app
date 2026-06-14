import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/notification_preference.dart';
import '../services/app_notification_service.dart';
import '../services/system_notification_service.dart';

class NotificationSettingsPage extends StatelessWidget {
  const NotificationSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final service = context.watch<AppNotificationService>();
    final colorScheme = Theme.of(context).colorScheme;
    final bottomPadding = MediaQuery.of(context).padding.bottom + 24;

    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                colorScheme.primary,
                colorScheme.secondary,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            foregroundColor: colorScheme.onPrimary,
            title: Text(
              _localized(
                context,
                'Notification settings',
                '通知設定',
              ),
            ),
          ),
          body: SafeArea(
            top: false,
            child: RefreshIndicator(
              onRefresh: () => service.loadPreferences(context),
              color: colorScheme.primary,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(16, 8, 16, bottomPadding),
                children: [
                  _DeviceAlertsSection(service: service),
                  const SizedBox(height: 12),
                  _PreferenceHeader(),
                  const SizedBox(height: 8),
                  if (service.isLoadingPreferences)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            colorScheme.onPrimary,
                          ),
                        ),
                      ),
                    )
                  else ...[
                    if (service.preferencesError != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _GlassPanel(
                          child: Text(
                            service.preferencesError!,
                            style: TextStyle(
                              color: colorScheme.onPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ...service.preferences.map(
                      (preference) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _PreferenceRow(preference: preference),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DeviceAlertsSection extends StatelessWidget {
  final AppNotificationService service;

  const _DeviceAlertsSection({required this.service});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final enabled = service.systemNotificationsEnabled &&
        service.permission == SystemNotificationPermission.granted;
    final unsupported =
        service.permission == SystemNotificationPermission.unsupported;

    final status = unsupported
        ? _localized(context, 'Not supported', '非対応')
        : enabled
            ? _localized(context, 'Enabled', '有効')
            : service.permission == SystemNotificationPermission.denied
                ? _localized(context, 'Blocked', 'ブロック済み')
                : _localized(context, 'Off', 'オフ');

    return _GlassPanel(
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: colorScheme.secondary.withOpacity(0.9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.notifications_active_outlined,
              color: colorScheme.onSecondary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _localized(context, 'Device alerts', 'デバイス通知'),
                  style: TextStyle(
                    color: colorScheme.onPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  status,
                  style: TextStyle(
                    color: colorScheme.onPrimary.withOpacity(0.75),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: enabled,
            activeColor: colorScheme.secondary,
            onChanged: unsupported
                ? null
                : (value) => service.setSystemNotificationsEnabled(value),
          ),
        ],
      ),
    );
  }
}

class _PreferenceHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              _localized(context, 'Categories', 'カテゴリー'),
              style: TextStyle(
                color: colorScheme.onPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          SizedBox(
            width: 58,
            child: Text(
              _localized(context, 'Page', 'ページ'),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colorScheme.onPrimary.withOpacity(0.85),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          SizedBox(
            width: 58,
            child: Text(
              'Push',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colorScheme.onPrimary.withOpacity(0.85),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PreferenceRow extends StatelessWidget {
  final NotificationPreference preference;

  const _PreferenceRow({required this.preference});

  @override
  Widget build(BuildContext context) {
    final service = context.read<AppNotificationService>();
    final colorScheme = Theme.of(context).colorScheme;
    final meta = _PreferenceMeta.forCategory(context, preference.category);

    return _GlassPanel(
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: meta.color.withOpacity(0.9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              meta.icon,
              color: Colors.black.withOpacity(0.72),
              size: 21,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  meta.title,
                  style: TextStyle(
                    color: colorScheme.onPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  meta.subtitle,
                  style: TextStyle(
                    color: colorScheme.onPrimary.withOpacity(0.74),
                    fontSize: 12,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          SizedBox(
            width: 58,
            child: Switch(
              value: preference.inAppEnabled,
              activeColor: colorScheme.secondary,
              onChanged: (value) => service.setNotificationPreference(
                context,
                preference.category,
                inAppEnabled: value,
              ),
            ),
          ),
          SizedBox(
            width: 58,
            child: Switch(
              value: preference.pushEnabled,
              activeColor: colorScheme.secondary,
              onChanged: (value) => service.setNotificationPreference(
                context,
                preference.category,
                pushEnabled: value,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassPanel extends StatelessWidget {
  final Widget child;

  const _GlassPanel({required this.child});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: colorScheme.background.withOpacity(0.2),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: colorScheme.onPrimary.withOpacity(0.3),
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _PreferenceMeta {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _PreferenceMeta({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  static _PreferenceMeta forCategory(BuildContext context, String category) {
    switch (category) {
      case NotificationPreferenceCategories.feedPosts:
        return _PreferenceMeta(
          title: _localized(context, 'Feed posts', 'フィード投稿'),
          subtitle: _localized(
            context,
            'New posts in feeds you joined',
            '参加中フィードの新規投稿',
          ),
          icon: Icons.feed_outlined,
          color: const Color(0xFFA7D8FF),
        );
      case NotificationPreferenceCategories.feedComments:
        return _PreferenceMeta(
          title: _localized(context, 'Feed comments', 'フィードコメント'),
          subtitle: _localized(
            context,
            'Replies and comments on your posts',
            '自分の投稿への返信とコメント',
          ),
          icon: Icons.mode_comment_outlined,
          color: const Color(0xFFB8E3FF),
        );
      case NotificationPreferenceCategories.events:
        return _PreferenceMeta(
          title: _localized(context, 'Events', 'イベント'),
          subtitle: _localized(
            context,
            'New community events',
            '新しい地域イベント',
          ),
          icon: Icons.event_note_outlined,
          color: const Color(0xFFFFD48A),
        );
      case NotificationPreferenceCategories.volunteerOpportunities:
        return _PreferenceMeta(
          title: _localized(context, 'Volunteer opportunities', 'ボランティア募集'),
          subtitle: _localized(
            context,
            'New volunteer listings',
            '新しいボランティア情報',
          ),
          icon: Icons.volunteer_activism_outlined,
          color: const Color(0xFFA7F3C1),
        );
      case NotificationPreferenceCategories.opportunityApplications:
        return _PreferenceMeta(
          title: _localized(context, 'Applications', '応募'),
          subtitle: _localized(
            context,
            'People joining your events or opportunities',
            '自分の募集への参加と応募',
          ),
          icon: Icons.assignment_ind_outlined,
          color: const Color(0xFFB7F0D2),
        );
      case NotificationPreferenceCategories.studyQuestions:
        return _PreferenceMeta(
          title: _localized(context, 'Study questions', '学習質問'),
          subtitle: _localized(
            context,
            'New questions from students',
            '学生からの新しい質問',
          ),
          icon: Icons.school_outlined,
          color: const Color(0xFFD8C7FF),
        );
      case NotificationPreferenceCategories.studyAnswers:
        return _PreferenceMeta(
          title: _localized(context, 'Study answers', '学習回答'),
          subtitle: _localized(
            context,
            'Answers to your questions',
            '自分の質問への回答',
          ),
          icon: Icons.question_answer_outlined,
          color: const Color(0xFFE0D4FF),
        );
      case NotificationPreferenceCategories.studyBestAnswers:
        return _PreferenceMeta(
          title: _localized(context, 'Best answers', 'ベスト回答'),
          subtitle: _localized(
            context,
            'Your answer being selected',
            '自分の回答が選ばれたとき',
          ),
          icon: Icons.verified_outlined,
          color: const Color(0xFFE8DDFF),
        );
      default:
        return _PreferenceMeta(
          title: category,
          subtitle: '',
          icon: Icons.notifications_outlined,
          color: const Color(0xFFE0E0E0),
        );
    }
  }
}

String _localized(BuildContext context, String en, String ja) {
  return Localizations.localeOf(context).languageCode == 'ja' ? ja : en;
}
