import 'package:flutter/material.dart';
import 'package:ocs_app/l10n/app_localizations.dart';

enum StudyBadgeTier {
  none,
  bronze,
  silver,
  gold,
  platinum,
}

class StudyBadgeInfo {
  final StudyBadgeTier tier;
  final String label;
  final Color color;

  const StudyBadgeInfo({
    required this.tier,
    required this.label,
    required this.color,
  });

  bool get hasBadge => tier != StudyBadgeTier.none;
}

class StudyBadgePolicy {
  // Keep thresholds centralized so they can be tuned later.
  static const int bronzeMinPoints = 100;
  static const int silverMinPoints = 300;
  static const int goldMinPoints = 800;
  static const int platinumMinPoints = 2000;

  static StudyBadgeInfo resolve(AppLocalizations l10n, int points) {
    if (points >= platinumMinPoints) {
      return StudyBadgeInfo(
        tier: StudyBadgeTier.platinum,
        label: l10n.studyBadgePlatinum,
        color: Colors.lightBlueAccent.shade100,
      );
    }
    if (points >= goldMinPoints) {
      return StudyBadgeInfo(
        tier: StudyBadgeTier.gold,
        label: l10n.studyBadgeGold,
        color: Colors.amber.shade200,
      );
    }
    if (points >= silverMinPoints) {
      return StudyBadgeInfo(
        tier: StudyBadgeTier.silver,
        label: l10n.studyBadgeSilver,
        color: Colors.blueGrey.shade100,
      );
    }
    if (points >= bronzeMinPoints) {
      return StudyBadgeInfo(
        tier: StudyBadgeTier.bronze,
        label: l10n.studyBadgeBronze,
        color: Colors.brown.shade200,
      );
    }
    return StudyBadgeInfo(
      tier: StudyBadgeTier.none,
      label: l10n.studyBadgeNone,
      color: Colors.grey.shade400,
    );
  }
}
