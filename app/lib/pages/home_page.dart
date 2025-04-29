// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../services/api_client.dart';
import 'login_page.dart';
import '../widgets/circle_nav_bar.dart';
import 'profile_page.dart';
import 'feed_page.dart';
import 'events_page.dart';
import 'volunteer_page.dart';
import 'study_page.dart';

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
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _profile;
  bool _initialized = false;
  int _currentIndex = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _loadProfile();
        }
      });
      _initialized = true;
    }
  }

  Future<void> _loadProfile() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      widget.apiClient.setToken(widget.token);
      final profile = await widget.apiClient.getProfile(context);

      if (mounted) {
        setState(() {
          _profile = profile;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      FeedPage(),
      EventsPage(),
      VolunteerPage(),
      StudyPage(),
      ProfilePage(apiClient: widget.apiClient),
    ];
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: pages[_currentIndex],
      extendBody: true,
      bottomNavigationBar: CircleNavBar(
        activeIcons: [
          Icon(Icons.feed, color: Colors.white, size: 28),
          Icon(Icons.event_note, color: Colors.white, size: 28),
          Icon(Icons.volunteer_activism, color: Colors.white, size: 28),
          Icon(Icons.school, color: Colors.white, size: 28),
          Icon(Icons.account_circle, color: Colors.white, size: 28),
        ],
        inactiveIcons: [
          Column(children: [
            Icon(Icons.feed_outlined, color: Colors.blue, size: 28),
            Text(l10n.feedFeature, style: TextStyle(color: Colors.blue, fontSize: 12, fontWeight: FontWeight.bold))
          ]),
          Column(children: [
            Icon(Icons.event_note_outlined, color: Colors.blue, size: 28),
            Text(l10n.eventsFeature, style: TextStyle(color: Colors.blue, fontSize: 12, fontWeight: FontWeight.bold))
          ]),
          Column(children: [
            Icon(Icons.volunteer_activism_outlined, color: Colors.blue, size: 28),
            Text(l10n.volunteerFeature, style: TextStyle(color: Colors.blue, fontSize: 12, fontWeight: FontWeight.bold))
          ]),
          Column(children: [
            Icon(Icons.school_outlined, color: Colors.blue, size: 28),
            Text(l10n.studyFeature, style: TextStyle(color: Colors.blue, fontSize: 12, fontWeight: FontWeight.bold))
          ]),
          Column(children: [
            Icon(Icons.account_circle, color: Colors.blue, size: 28),
            Text(l10n.profile, style: TextStyle(color: Colors.blue, fontSize: 12, fontWeight: FontWeight.bold))
          ]),
        ],
        color: Colors.white,
        height: 60,
        circleWidth: 40,
        padding: EdgeInsets.only(left: 16, right: 16, bottom: 20),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white,
            Colors.white.withValues(alpha: 0.8),
          ],
        ),
        activeIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        cornerRadius: const BorderRadius.all(Radius.circular(30)),
        shadowColor: Colors.black.withValues(alpha: 0.4),
        elevation: 10,
        circleGradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.blue.withValues(alpha: 0.8),
            Colors.blue.withValues(alpha: 0.8),
          ],
        ),
        circleShadowColor: Colors.blue.withValues(alpha: 0.8),
      ),
    );
  }
}
