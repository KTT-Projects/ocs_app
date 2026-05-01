import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

enum OpportunityExperienceType {
  volunteer,
  event,
}

class OpportunityExperience {
  final OpportunityExperienceType type;

  const OpportunityExperience._(this.type);

  static const volunteer =
      OpportunityExperience._(OpportunityExperienceType.volunteer);
  static const event = OpportunityExperience._(OpportunityExperienceType.event);

  bool get isEvent => type == OpportunityExperienceType.event;

  String get apiType => isEvent ? 'event' : 'volunteer';

  IconData get emptyIcon =>
      isEvent ? Icons.event_busy : Icons.volunteer_activism_outlined;

  IconData get createIcon =>
      isEvent ? Icons.event_available : Icons.volunteer_activism;

  String featureTitle(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return isEvent ? l10n.eventsFeature : l10n.volunteerFeature;
  }

  String listTitle(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return isEvent
        ? _localized(context, 'Events', 'イベント')
        : l10n.volunteerOpportunities;
  }

  String createAction(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return isEvent
        ? _localized(context, 'Create Event', 'イベントを作成')
        : l10n.createVolunteerOpportunity;
  }

  String createPageTitle(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return isEvent
        ? _localized(context, 'Create Event', 'イベントを作成')
        : l10n.createOpportunity;
  }

  String createdMessage(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return isEvent
        ? _localized(context, 'Event created successfully!', 'イベントを作成しました')
        : l10n.volunteerOpportunityCreated;
  }

  String titleLabel(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return isEvent
        ? _localized(context, 'Event Title', 'イベント名')
        : l10n.opportunityTitle;
  }

  String titleHint(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return isEvent
        ? _localized(context, 'Enter event title', 'イベント名を入力')
        : l10n.enterOpportunityTitle;
  }

  String descriptionLabel(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return isEvent
        ? _localized(context, 'Event Description', 'イベント説明')
        : l10n.opportunityDescription;
  }

  String descriptionHint(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return isEvent
        ? _localized(context, 'Describe the event', 'イベントの内容を入力')
        : l10n.describeOpportunity;
  }

  String locationLabel(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return isEvent
        ? _localized(context, 'Event Location', 'イベント会場')
        : l10n.opportunityLocation;
  }

  String requiredParticipantsLabel(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return isEvent
        ? _localized(context, 'Participant Limit', '参加人数')
        : l10n.requiredParticipants;
  }

  String noOpportunities(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return isEvent
        ? _localized(context, 'No events yet.', 'イベントはまだありません')
        : l10n.noVolunteerOpportunities;
  }

  String participants(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return isEvent
        ? _localized(context, 'participants', '参加者')
        : l10n.volunteerParticipants;
  }

  String apply(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return isEvent ? _localized(context, 'Join', '参加') : l10n.volunteerApply;
  }

  String applied(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return isEvent
        ? _localized(context, 'Joined', '参加中')
        : l10n.volunteerApplied;
  }

  String manage(BuildContext context) {
    return isEvent ? _localized(context, 'Manage Event', 'イベント管理') : 'Manage';
  }

  String unlimited(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return isEvent
        ? _localized(context, 'No limit', '制限なし')
        : l10n.volunteerNoLimit;
  }

  String spotsRemaining(BuildContext context, int count) {
    final l10n = AppLocalizations.of(context)!;
    return isEvent
        ? _localized(context, '$count spots remaining', '残り$count名')
        : l10n.volunteerSpotsRemaining(count);
  }

  String _localized(BuildContext context, String en, String ja) {
    return Localizations.localeOf(context).languageCode == 'ja' ? ja : en;
  }
}
