import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/app_notification.dart';
import '../services/app_notification_service.dart';
import '../services/api_client.dart';
import '../services/system_notification_service.dart';
import '../widgets/glassmorphic_ui.dart';

class NotificationsPage extends StatefulWidget {
  final ApiClient apiClient;
  final ValueChanged<AppNotification>? onNotificationSelected;

  const NotificationsPage({
    super.key,
    required this.apiClient,
    this.onNotificationSelected,
  });

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  bool _didRefresh = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didRefresh) {
      _didRefresh = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context
            .read<AppNotificationService>()
            .refresh(context, announceNew: false);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final service = context.watch<AppNotificationService>();
    final mediaQuery = MediaQuery.of(context);
    final bottomPadding = mediaQuery.padding.bottom + 108;

    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primary,
                Theme.of(context).colorScheme.secondary,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        Scaffold(
          backgroundColor: Colors.transparent,
          extendBody: true,
          body: SafeArea(
            bottom: false,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Row(
                    children: [
                      Icon(
                        Icons.notifications_outlined,
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        l10n.notifications,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onPrimary,
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (service.unreadCount > 0) ...[
                        const SizedBox(width: 10),
                        _UnreadBadge(count: service.unreadCount),
                      ],
                      const Spacer(),
                      GlassmorphicUI.buildAppBarIconButton(
                        context: context,
                        icon: Icons.done_all,
                        size: 38,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        onPressed: service.notifications.isEmpty
                            ? null
                            : service.markAllRead,
                      ),
                      GlassmorphicUI.buildAppBarIconButton(
                        context: context,
                        icon: Icons.refresh,
                        size: 38,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        onPressed: () => service.refresh(
                          context,
                          announceNew: false,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () =>
                        service.refresh(context, announceNew: false),
                    color: Theme.of(context).colorScheme.primary,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(16, 4, 16, bottomPadding),
                      children: [
                        _SystemNotificationCard(service: service),
                        const SizedBox(height: 12),
                        if (service.isLoading && service.notifications.isEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 80),
                            child: Center(
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Theme.of(context).colorScheme.onPrimary,
                                ),
                              ),
                            ),
                          )
                        else if (service.error != null &&
                            service.notifications.isEmpty)
                          _EmptyState(
                            icon: Icons.error_outline,
                            title: service.error!,
                          )
                        else if (service.notifications.isEmpty)
                          _EmptyState(
                            icon: Icons.notifications_none,
                            title: _localized(
                              context,
                              'No notifications yet',
                              '通知はまだありません',
                            ),
                          )
                        else
                          ...service.notifications.map(
                            (notification) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _NotificationTile(
                                notification: notification,
                                read: service.isRead(notification),
                                onTap: () async {
                                  await service.markRead(notification.id);
                                  widget.onNotificationSelected
                                      ?.call(notification);
                                },
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SystemNotificationCard extends StatelessWidget {
  final AppNotificationService service;

  const _SystemNotificationCard({required this.service});

  @override
  Widget build(BuildContext context) {
    final enabled = service.systemNotificationsEnabled &&
        service.permission == SystemNotificationPermission.granted;
    final unsupported =
        service.permission == SystemNotificationPermission.unsupported;
    final colorScheme = Theme.of(context).colorScheme;

    final status = unsupported
        ? _localized(context, 'Not supported', '非対応')
        : enabled
            ? _localized(context, 'Enabled', '有効')
            : service.permission == SystemNotificationPermission.denied
                ? _localized(context, 'Blocked', 'ブロック済み')
                : _localized(context, 'Off', 'オフ');

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
                      _localized(
                        context,
                        'Device alerts',
                        'デバイス通知',
                      ),
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
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final AppNotification notification;
  final bool read;
  final VoidCallback onTap;

  const _NotificationTile({
    required this.notification,
    required this.read,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final typeColor = _typeColor(notification.type);

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: colorScheme.background.withOpacity(read ? 0.16 : 0.28),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: read
                      ? colorScheme.onPrimary.withOpacity(0.22)
                      : colorScheme.onPrimary.withOpacity(0.38),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: typeColor.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          _typeIcon(notification.type),
                          color: Colors.black.withOpacity(0.75),
                          size: 22,
                        ),
                      ),
                      if (!read)
                        Positioned(
                          right: -2,
                          top: -2,
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(5),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                _typeLabel(context, notification.type),
                                style: TextStyle(
                                  color:
                                      colorScheme.onPrimary.withOpacity(0.75),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _formatTime(context, notification.createdAt),
                              style: TextStyle(
                                color: colorScheme.onPrimary.withOpacity(0.65),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 5),
                        Text(
                          notification.title,
                          style: TextStyle(
                            color: colorScheme.onPrimary,
                            fontSize: 15,
                            fontWeight:
                                read ? FontWeight.w600 : FontWeight.w800,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          notification.body,
                          style: TextStyle(
                            color: colorScheme.onPrimary.withOpacity(0.78),
                            fontSize: 13,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _UnreadBadge extends StatelessWidget {
  final int count;

  const _UnreadBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    final text = count > 99 ? '99+' : count.toString();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;

  const _EmptyState({
    required this.icon,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(top: 80),
      child: Column(
        children: [
          Icon(
            icon,
            color: colorScheme.onPrimary.withOpacity(0.8),
            size: 42,
          ),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colorScheme.onPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

IconData _typeIcon(AppNotificationType type) {
  switch (type) {
    case AppNotificationType.feed:
      return Icons.feed_outlined;
    case AppNotificationType.event:
      return Icons.event_note_outlined;
    case AppNotificationType.volunteer:
      return Icons.volunteer_activism_outlined;
    case AppNotificationType.study:
      return Icons.school_outlined;
  }
}

Color _typeColor(AppNotificationType type) {
  switch (type) {
    case AppNotificationType.feed:
      return const Color(0xFFA7D8FF);
    case AppNotificationType.event:
      return const Color(0xFFFFD48A);
    case AppNotificationType.volunteer:
      return const Color(0xFFA7F3C1);
    case AppNotificationType.study:
      return const Color(0xFFD8C7FF);
  }
}

String _typeLabel(BuildContext context, AppNotificationType type) {
  final l10n = AppLocalizations.of(context)!;
  switch (type) {
    case AppNotificationType.feed:
      return l10n.feed;
    case AppNotificationType.event:
      return l10n.eventsFeature;
    case AppNotificationType.volunteer:
      return l10n.volunteerFeature;
    case AppNotificationType.study:
      return l10n.studyFeature;
  }
}

String _formatTime(BuildContext context, DateTime dateTime) {
  final now = DateTime.now();
  final difference = now.difference(dateTime);

  if (difference.inMinutes < 1) {
    return _localized(context, 'Now', '今');
  }
  if (difference.inHours < 1) {
    return _localized(
        context, '${difference.inMinutes}m', '${difference.inMinutes}分');
  }
  if (difference.inDays < 1) {
    return _localized(
        context, '${difference.inHours}h', '${difference.inHours}時間');
  }
  if (difference.inDays < 7) {
    return _localized(
        context, '${difference.inDays}d', '${difference.inDays}日');
  }

  return DateFormat.MMMd(Localizations.localeOf(context).languageCode)
      .format(dateTime);
}

String _localized(BuildContext context, String en, String ja) {
  return Localizations.localeOf(context).languageCode == 'ja' ? ja : en;
}
