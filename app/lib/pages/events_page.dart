import 'package:flutter/material.dart';
import '../models/opportunity_experience.dart';
import '../services/api_client.dart';
import 'volunteer_page.dart';

class EventsPage extends StatelessWidget {
  final ApiClient apiClient;

  const EventsPage({
    super.key,
    required this.apiClient,
  });

  @override
  Widget build(BuildContext context) {
    return VolunteerPage(
      apiClient: apiClient,
      experience: OpportunityExperience.event,
    );
  }
}
