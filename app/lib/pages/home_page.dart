import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'dart:ui';
import '../services/api_client.dart';
import 'login_page.dart';

class CommunityFeature {
  final IconData icon;
  final String title;
  final String description;
  final Color color;

  CommunityFeature({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });
}

class LocalNews {
  final String title;
  final String date;
  final String description;

  LocalNews({
    required this.title,
    required this.date,
    required this.description,
  });
}

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

  List<CommunityFeature> _features = [];
  List<LocalNews> _news = [];

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final l10n = AppLocalizations.of(context)!;
      setState(() {
        _features = [
          CommunityFeature(
            icon: Icons.event,
            title: l10n.eventsFeature,
            description: l10n.eventsDescription,
            color: Colors.blue.shade300,
          ),
          CommunityFeature(
            icon: Icons.people,
            title: l10n.groupsFeature,
            description: l10n.groupsDescription,
            color: Colors.green.shade300,
          ),
          CommunityFeature(
            icon: Icons.business,
            title: l10n.businessFeature,
            description: l10n.businessDescription,
            color: Colors.orange.shade300,
          ),
          CommunityFeature(
            icon: Icons.volunteer_activism,
            title: l10n.volunteerFeature,
            description: l10n.volunteerDescription,
            color: Colors.purple.shade300,
          ),
        ];
        // TODO: Replace with localized strings when regenerated
        _news = [
          LocalNews(
            title: 'New Community Center Opening',
            date: '2025/04/20',
            description: 'The new community center will open next week with various facilities.',
          ),
          LocalNews(
            title: 'Beach Cleanup Event',
            date: '2025/04/25',
            description: 'Join us for the monthly beach cleanup activity.',
          ),
          LocalNews(
            title: 'Summer Festival Planning',
            date: '2025/05/01',
            description: 'Planning meeting for this year\'s summer festival.',
          ),
        ];
      });
    });
  }

  Widget _buildGlassCard({
    required Widget child,
    EdgeInsets padding = const EdgeInsets.all(16),
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white.withOpacity(0.2),
                Colors.white.withOpacity(0.1),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
            ),
          ),
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = screenWidth > 600 ? 3 : 2;
    final childAspectRatio = screenWidth > 600 ? 1.3 : 1.1;

    Widget buildContent() {
      if (_isLoading) {
        return const Center(child: CircularProgressIndicator());
      }

      if (_error != null) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _error!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadProfile,
                // TODO: Use l10n.retry when localization is regenerated
                child: Text('Retry'),
              ),
            ],
          ),
        );
      }

      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue.shade100.withOpacity(0.5),
              Colors.purple.shade100.withOpacity(0.5),
            ],
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Welcome Section
            _buildGlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.welcomeUser(_profile?['name'] ?? 'User'),
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.communityHub,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Features Grid
            Text(
              l10n.communityFeatures,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: childAspectRatio,
              ),
              itemCount: _features.length,
              itemBuilder: (context, index) {
                final feature = _features[index];
                return _buildGlassCard(
                  padding: const EdgeInsets.all(12),
                  child: InkWell(
                    onTap: () {
                      // TODO: Navigate to feature
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          feature.icon,
                          size: 32,
                          color: feature.color,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          feature.title,
                          style: Theme.of(context).textTheme.titleMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          feature.description,
                          style: Theme.of(context).textTheme.bodySmall,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),

            // News Section
            Text(
              l10n.localNews,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _news.length,
              itemBuilder: (context, index) {
                final news = _news[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildGlassCard(
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(
                              news.title,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                          Text(
                            news.date,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(news.description),
                      ),
                      onTap: () {
                        // TODO: Navigate to news detail
                      },
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.2),
                    Colors.white.withOpacity(0.1),
                  ],
                ),
              ),
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              // TODO: Show notifications
            },
          ),
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () {
              // TODO: Show profile
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
            ),
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                DrawerHeader(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.blue.shade300.withOpacity(0.7),
                        Colors.purple.shade300.withOpacity(0.7),
                      ],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const CircleAvatar(
                        radius: 32,
                        child: Icon(Icons.person, size: 32),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _profile?['name'] ?? 'User',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Colors.white,
                            ),
                      ),
                    ],
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.home_outlined),
                  title: const Text('Home'),
                  selected: true,
                  onTap: () {
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.event_outlined),
                  title: Text(l10n.eventsFeature),
                  onTap: () {
                    Navigator.pop(context);
                    // TODO: Navigate to events
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.groups_outlined),
                  title: Text(l10n.groupsFeature),
                  onTap: () {
                    Navigator.pop(context);
                    // TODO: Navigate to groups
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.storefront_outlined),
                  title: Text(l10n.businessFeature),
                  onTap: () {
                    Navigator.pop(context);
                    // TODO: Navigate to business
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.volunteer_activism_outlined),
                  title: Text(l10n.volunteerFeature),
                  onTap: () {
                    Navigator.pop(context);
                    // TODO: Navigate to volunteer
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.settings_outlined),
                  title: Text(l10n.settings),
                  onTap: () {
                    Navigator.pop(context);
                    // TODO: Navigate to settings
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.logout),
                  title: Text(l10n.logout),
                  onTap: () {
                    Navigator.pop(context);
                    // Clear profile data and token before logout
                    setState(() {
                      _profile = null;
                      _error = null;
                    });
                    widget.apiClient.clearToken();
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => LoginPage(apiClient: ApiClient()),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      body: buildContent(),
    );
  }
}
