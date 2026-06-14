import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/app_localizations.dart';
import '../models/app_notification.dart';
import '../models/notification_preference.dart';
import '../models/opportunity_experience.dart';
import 'api_client.dart';
import 'push_registration_service.dart';
import 'system_notification_service.dart';

class AppNotificationService extends ChangeNotifier {
  AppNotificationService({
    required ApiClient apiClient,
    PushRegistrationService? pushRegistrationService,
    SystemNotificationService? systemNotificationService,
  })  : _apiClient = apiClient,
        _pushRegistrationService = pushRegistrationService,
        _systemNotificationService =
            systemNotificationService ?? SystemNotificationService();

  static const _readIdsKey = 'app_notification_read_ids';
  static const _announcedIdsKey = 'app_notification_announced_ids';
  static const _systemEnabledKey = 'app_notification_system_enabled';
  static const _pollInterval = Duration(seconds: 30);

  final ApiClient _apiClient;
  final PushRegistrationService? _pushRegistrationService;
  final SystemNotificationService _systemNotificationService;

  SharedPreferences? _prefs;
  Timer? _timer;
  bool _initialized = false;
  bool _started = false;
  bool _isLoading = false;
  bool _isLoadingPreferences = false;
  bool _hasLoadedBaseline = false;
  bool _preferencesLoaded = false;
  String? _error;
  String? _preferencesError;
  bool _systemNotificationsEnabled = true;
  SystemNotificationPermission _permission =
      SystemNotificationPermission.prompt;
  final Set<String> _readIds = <String>{};
  final Set<String> _announcedIds = <String>{};
  List<AppNotification> _notifications = <AppNotification>[];
  List<NotificationPreference> _preferences = _defaultNotificationPreferences();

  List<AppNotification> get notifications => List.unmodifiable(_notifications);
  List<NotificationPreference> get preferences =>
      List.unmodifiable(_preferences);
  bool get isLoading => _isLoading;
  bool get isLoadingPreferences => _isLoadingPreferences;
  String? get error => _error;
  String? get preferencesError => _preferencesError;
  bool get systemNotificationsEnabled => _systemNotificationsEnabled;
  SystemNotificationPermission get permission => _permission;
  int get unreadCount =>
      _notifications.where((item) => !_readIds.contains(item.id)).length;

  Future<void> initialize() async {
    if (_initialized) return;
    _prefs = await SharedPreferences.getInstance();
    _readIds.addAll(_prefs?.getStringList(_readIdsKey) ?? const <String>[]);
    _announcedIds
        .addAll(_prefs?.getStringList(_announcedIdsKey) ?? const <String>[]);
    _systemNotificationsEnabled = _prefs?.getBool(_systemEnabledKey) ?? true;
    await _systemNotificationService.initialize();
    _permission = await _systemNotificationService.permissionStatus();
    _initialized = true;
    notifyListeners();
  }

  Future<void> start(BuildContext context) async {
    if (_started) return;
    _started = true;
    await initialize();
    if (!context.mounted) return;
    _permission = await _systemNotificationService.permissionStatus();
    if (_permission == SystemNotificationPermission.granted) {
      await _registerPushDevice(context, requestPermission: false);
    }
    if (!context.mounted) return;
    await loadPreferences(context);
    if (!context.mounted) return;
    await refresh(context, announceNew: false);
    _timer = Timer.periodic(_pollInterval, (_) {
      unawaited(refresh(context, announceNew: true, showLoading: false));
    });
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    _started = false;
  }

  Future<void> refresh(
    BuildContext context, {
    bool announceNew = false,
    bool showLoading = true,
  }) async {
    await initialize();
    if (!context.mounted) return;
    if (_apiClient.token == null) return;
    if (!_preferencesLoaded) {
      await loadPreferences(context);
      if (!context.mounted) return;
    }

    if (showLoading) {
      _isLoading = true;
      _error = null;
      notifyListeners();
    }

    try {
      final fetched = await _fetchNotifications(context);
      final previousIds = _notifications.map((item) => item.id).toSet();
      final newItems = fetched
          .where((item) =>
              !previousIds.contains(item.id) &&
              !_announcedIds.contains(item.id))
          .toList();

      _notifications = fetched;
      _error = null;
      _isLoading = false;

      if (!_hasLoadedBaseline) {
        _hasLoadedBaseline = true;
        _announcedIds.addAll(fetched.map((item) => item.id));
        _readIds.addAll(fetched.map((item) => item.id));
        await _persistState();
      } else if (announceNew && newItems.isNotEmpty) {
        for (final item in newItems.take(3)) {
          _announcedIds.add(item.id);
          await _showSystemNotification(item);
        }
        _trimIds(_announcedIds);
        await _persistState();
      }

      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<SystemNotificationPermission> requestSystemPermission() async {
    await initialize();
    _permission = await _systemNotificationService.requestPermission();
    _systemNotificationsEnabled =
        _permission == SystemNotificationPermission.granted;
    await _prefs?.setBool(_systemEnabledKey, _systemNotificationsEnabled);
    if (_systemNotificationsEnabled) {
      unawaited(_pushRegistrationService?.registerCurrentDevice());
    }
    notifyListeners();
    return _permission;
  }

  Future<void> setSystemNotificationsEnabled(bool enabled) async {
    await initialize();
    _systemNotificationsEnabled = enabled;
    await _prefs?.setBool(_systemEnabledKey, enabled);
    if (enabled) {
      if (_permission != SystemNotificationPermission.granted) {
        _permission = await _systemNotificationService.requestPermission();
        if (_permission != SystemNotificationPermission.granted) {
          _systemNotificationsEnabled = false;
          await _prefs?.setBool(_systemEnabledKey, false);
        }
      }
      if (_systemNotificationsEnabled) {
        unawaited(_pushRegistrationService?.registerCurrentDevice());
      }
    } else {
      unawaited(_pushRegistrationService?.unregisterCurrentDevice());
    }
    notifyListeners();
  }

  Future<void> loadPreferences(BuildContext context) async {
    await initialize();
    if (!context.mounted || _apiClient.token == null) return;

    _isLoadingPreferences = true;
    _preferencesError = null;
    notifyListeners();

    try {
      _preferences = await _apiClient.getNotificationPreferences(context);
      _preferencesLoaded = true;
      _preferencesError = null;
    } catch (e) {
      _preferencesError = e.toString();
      _preferencesLoaded = true;
    } finally {
      _isLoadingPreferences = false;
      notifyListeners();
    }
  }

  Future<void> setNotificationPreference(
    BuildContext context,
    String category, {
    bool? inAppEnabled,
    bool? pushEnabled,
  }) async {
    await initialize();
    if (!context.mounted) return;
    final index = _preferences.indexWhere((item) => item.category == category);
    if (index < 0) return;

    final previous = List<NotificationPreference>.from(_preferences);
    _preferences[index] = _preferences[index].copyWith(
      inAppEnabled: inAppEnabled,
      pushEnabled: pushEnabled,
    );
    _preferencesError = null;
    notifyListeners();

    try {
      _preferences =
          await _apiClient.updateNotificationPreferences(context, _preferences);
      if (inAppEnabled == true && context.mounted) {
        await refresh(context, announceNew: false, showLoading: false);
      } else {
        _notifications = _notifications
            .where((item) =>
                _isInAppCategoryEnabled(_categoryForNotification(item)))
            .toList();
      }
      _preferencesLoaded = true;
      _preferencesError = null;
    } catch (e) {
      _preferences = previous;
      _preferencesError = e.toString();
    }
    notifyListeners();
  }

  Future<void> markRead(String id) async {
    await initialize();
    _readIds.add(id);
    await _persistState();
    notifyListeners();
  }

  Future<void> markAllRead() async {
    await initialize();
    _readIds.addAll(_notifications.map((item) => item.id));
    _trimIds(_readIds);
    await _persistState();
    notifyListeners();
  }

  bool isRead(AppNotification notification) =>
      _readIds.contains(notification.id);

  Future<List<AppNotification>> _fetchNotifications(
      BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final localeCode = Localizations.localeOf(context).languageCode;

    final feedPostsFuture =
        _emptyListOnFailure(_apiClient.getHomeFeed(context, sort: 'latest'));
    final eventsFuture = _emptyListOnFailure(
      _apiClient.getVolunteerOpportunities(
        context,
        sort: 'newest',
        opportunityType: OpportunityExperience.event.apiType,
      ),
    );
    final volunteerFuture = _emptyListOnFailure(
      _apiClient.getVolunteerOpportunities(
        context,
        sort: 'newest',
        opportunityType: OpportunityExperience.volunteer.apiType,
      ),
    );
    final questionsFuture = _emptyListOnFailure(
      _apiClient.getStudyQuestions(context, sort: 'latest'),
    );

    final feedPosts = await feedPostsFuture;
    final events = await eventsFuture;
    final volunteerOpportunities = await volunteerFuture;
    final questions = await questionsFuture;

    final notifications = <AppNotification>[];

    for (final post in feedPosts) {
      final feedName = post.feedDisplayName ?? post.feedName ?? l10n.feed;
      notifications.add(
        AppNotification(
          id: 'feed:${post.id}',
          type: AppNotificationType.feed,
          title: post.title,
          body: localeCode == 'ja'
              ? '$feedNameに${post.displayName}さんが投稿しました'
              : '${post.displayName} posted in $feedName',
          createdAt: post.createdAt,
          feedPost: post,
        ),
      );
    }

    for (final opportunity in events) {
      notifications.add(
        AppNotification(
          id: 'event:${opportunity.id}',
          type: AppNotificationType.event,
          title: opportunity.title,
          body: localeCode == 'ja'
              ? '${opportunity.location}で新しいイベントがあります'
              : 'New event at ${opportunity.location}',
          createdAt: opportunity.createdAt,
          opportunity: opportunity,
        ),
      );
    }

    for (final opportunity in volunteerOpportunities) {
      notifications.add(
        AppNotification(
          id: 'volunteer:${opportunity.id}',
          type: AppNotificationType.volunteer,
          title: opportunity.title,
          body: localeCode == 'ja'
              ? '${opportunity.location}で新しいボランティア募集があります'
              : 'New volunteer opportunity at ${opportunity.location}',
          createdAt: opportunity.createdAt,
          opportunity: opportunity,
        ),
      );
    }

    for (final question in questions) {
      notifications.add(
        AppNotification(
          id: 'study:${question.id}',
          type: AppNotificationType.study,
          title: question.title,
          body: localeCode == 'ja'
              ? '${question.authorDisplayName}さんが質問しました'
              : '${question.authorDisplayName} asked a question',
          createdAt: question.createdAt,
          studyQuestion: question,
        ),
      );
    }

    notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return notifications
        .where(
            (item) => _isInAppCategoryEnabled(_categoryForNotification(item)))
        .take(60)
        .toList();
  }

  Future<List<T>> _emptyListOnFailure<T>(Future<List<T>> future) async {
    try {
      return await future;
    } catch (_) {
      return <T>[];
    }
  }

  Future<void> _showSystemNotification(AppNotification notification) async {
    if (!_systemNotificationsEnabled) return;
    if (!_isPushCategoryEnabled(_categoryForNotification(notification))) return;
    if (_permission == SystemNotificationPermission.unsupported ||
        _permission == SystemNotificationPermission.denied) {
      return;
    }

    await _systemNotificationService.show(
      id: notification.id.hashCode & 0x7fffffff,
      title: notification.title,
      body: notification.body,
      payload: notification.id,
    );
    _permission = await _systemNotificationService.permissionStatus();
  }

  Future<void> _registerPushDevice(
    BuildContext context, {
    bool requestPermission = true,
  }) async {
    if (!_systemNotificationsEnabled || _pushRegistrationService == null) {
      return;
    }
    final locale = Localizations.localeOf(context).toLanguageTag();
    await _pushRegistrationService.registerCurrentDevice(
      locale: locale,
      requestPermission: requestPermission,
    );
  }

  Future<void> _persistState() async {
    _trimIds(_readIds);
    _trimIds(_announcedIds);
    await _prefs?.setStringList(_readIdsKey, _readIds.toList());
    await _prefs?.setStringList(_announcedIdsKey, _announcedIds.toList());
  }

  void _trimIds(Set<String> ids) {
    if (ids.length <= 200) return;
    final overflow = ids.length - 200;
    ids.removeAll(ids.take(overflow));
  }

  String _categoryForNotification(AppNotification notification) {
    switch (notification.type) {
      case AppNotificationType.feed:
        return NotificationPreferenceCategories.feedPosts;
      case AppNotificationType.event:
        return NotificationPreferenceCategories.events;
      case AppNotificationType.volunteer:
        return NotificationPreferenceCategories.volunteerOpportunities;
      case AppNotificationType.study:
        return NotificationPreferenceCategories.studyQuestions;
    }
  }

  bool _isInAppCategoryEnabled(String category) {
    return _preferenceForCategory(category).inAppEnabled;
  }

  bool _isPushCategoryEnabled(String category) {
    return _preferenceForCategory(category).pushEnabled;
  }

  NotificationPreference _preferenceForCategory(String category) {
    return _preferences.firstWhere(
      (item) => item.category == category,
      orElse: () => NotificationPreference(
        category: category,
        inAppEnabled: true,
        pushEnabled: true,
      ),
    );
  }

  static List<NotificationPreference> _defaultNotificationPreferences() {
    return NotificationPreferenceCategories.all
        .map(
          (category) => NotificationPreference(
            category: category,
            inAppEnabled: true,
            pushEnabled: true,
          ),
        )
        .toList();
  }

  @override
  void dispose() {
    stop();
    super.dispose();
  }
}
