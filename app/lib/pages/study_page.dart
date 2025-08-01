import 'package:flutter/material.dart';
import 'package:ocs_app/l10n/app_localizations.dart';
import '../services/api_client.dart';

class StudyPage extends StatefulWidget {
  final ApiClient apiClient;

  const StudyPage({
    super.key,
    required this.apiClient,
  });

  @override
  State<StudyPage> createState() => _StudyPageState();
}

class _StudyPageState extends State<StudyPage> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Stack(children: [
      // Gradient background
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
      Center(child: Text(l10n.studyFeature, style: TextStyle(color: Colors.white))),
    ]);
  }
}
