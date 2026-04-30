import 'dart:ui';
import 'dart:async';
import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../models/feed.dart';
import '../services/api_client.dart';
import '../widgets/glassmorphic_ui.dart';

class FeedDetailsPage extends StatefulWidget {
  final ApiClient apiClient;
  final Feed feed;

  const FeedDetailsPage({Key? key, required this.apiClient, required this.feed})
    : super(key: key);

  @override
  State<FeedDetailsPage> createState() => _FeedDetailsPageState();
}

class _FeedDetailsPageState extends State<FeedDetailsPage> {
  bool _isLoadingMembers = true;
  String? _error;
  List<Map<String, dynamic>>? _members;
  static const String _hostUrl = 'https://ocs.kttprojects.com';
  Timer? _refreshTimer;
  bool _isFetchingMembers = false;
  static final Map<int, List<Map<String, dynamic>>> _memberCache = {};

  Widget _buildAvatar({
    required String? imageUrl,
    required String displayName,
    double radius = 16,
  }) {
    final fallback = displayName.isNotEmpty ? displayName[0] : '?';
    String? resolvedUrl = imageUrl;
    if (resolvedUrl != null && resolvedUrl.startsWith('/')) {
      resolvedUrl = '$_hostUrl$resolvedUrl';
    }
    return CircleAvatar(
      radius: radius,
      backgroundColor: Theme.of(context).colorScheme.secondary.withOpacity(0.3),
      child: resolvedUrl != null && resolvedUrl.isNotEmpty
          ? ClipOval(
              child: Image.network(
                resolvedUrl,
                width: radius * 2,
                height: radius * 2,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Center(
                  child: Text(
                    fallback,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSecondary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            )
          : Text(
              fallback,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSecondary,
                fontWeight: FontWeight.bold,
              ),
            ),
    );
  }

  @override
  void initState() {
    super.initState();
    if (_memberCache.containsKey(widget.feed.id)) {
      _members = _memberCache[widget.feed.id];
      _isLoadingMembers = false;
    }
    _startPeriodicRefresh();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadMembers(showLoading: _members == null));
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _startPeriodicRefresh() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _loadMembers(showLoading: false);
    });
  }

  Future<void> _loadMembers({bool showLoading = true}) async {
    if (_isFetchingMembers) return;
    _isFetchingMembers = true;
    try {
      if (showLoading) {
        setState(() {
          _isLoadingMembers = true;
          _error = null;
        });
      }

      final members = await widget.apiClient.getFeedMembers(
        context,
        widget.feed.id,
      );
      if (!mounted) return;
      setState(() {
        _members = members;
        if (showLoading) _isLoadingMembers = false;
      });
      _memberCache[widget.feed.id] = members;
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = showLoading ? e.toString() : _error;
        if (showLoading) _isLoadingMembers = false;
      });
    } finally {
      _isFetchingMembers = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          children: [
            _buildAvatar(
              imageUrl: widget.feed.iconUrl,
              displayName: widget.feed.displayName,
              radius: 16,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                widget.feed.displayName,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        leading: GlassmorphicUI.buildAppBarIconButton(
          context: context,
          icon: Icons.arrow_back,
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
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
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.background.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: Theme.of(
                          context,
                        ).colorScheme.onPrimary.withOpacity(0.3),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Center(
                              child: _buildAvatar(
                                imageUrl: widget.feed.iconUrl,
                                displayName: widget.feed.displayName,
                                radius: 40,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Center(
                              child: Text(
                                widget.feed.displayName,
                                style: Theme.of(context).textTheme.headlineMedium
                                    ?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onPrimary,
                                    ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              l10n.feedDescription,
                              style: TextStyle(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onPrimary.withOpacity(0.7),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              widget.feed.description,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onPrimary,
                              ),
                            ),
                            if (widget.feed.rules != null &&
                                widget.feed.rules!.isNotEmpty) ...[
                              const SizedBox(height: 24),
                              Text(
                                l10n.feedRules,
                                style: TextStyle(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onPrimary.withOpacity(0.7),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                widget.feed.rules!,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.onPrimary,
                                ),
                              ),
                            ],
                            const SizedBox(height: 24),
                            Text(
                              l10n.members,
                              style: TextStyle(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onPrimary.withOpacity(0.7),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (_isLoadingMembers)
                              Center(
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Theme.of(context).colorScheme.onPrimary,
                                  ),
                                ),
                              )
                            else if (_error != null)
                              Text(
                                _error!,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.error,
                                ),
                              )
                            else if (_members != null && _members!.isNotEmpty)
                          Column(
                            children: _members!
                                .map(
                                  (m) => Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 4,
                                    ),
                                    child: Row(
                                      children: [
                                        _buildAvatar(
                                          imageUrl: (m['avatar_url'] as String?),
                                          displayName: (m['display_name'] ?? '').toString(),
                                          radius: 16,
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            m['display_name'] ?? '',
                                            style: TextStyle(
                                              color: Theme.of(
                                                context,
                                              ).colorScheme.onPrimary,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        if (m['role'] != null && (m['role'] as String).isNotEmpty)
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: Theme.of(context).colorScheme.background.withOpacity(0.18),
                                              borderRadius: BorderRadius.circular(10),
                                              border: Border.all(
                                                color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.2),
                                              ),
                                            ),
                                            child: Text(
                                              m['role'],
                                              style: TextStyle(
                                                color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.8),
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                )
                                .toList(),
                          )
                            else
                              Text(
                                '-',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.onPrimary,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
