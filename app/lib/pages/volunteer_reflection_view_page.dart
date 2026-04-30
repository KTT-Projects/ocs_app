import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/app_localizations.dart';
import '../models/volunteer_opportunity.dart';
import '../models/volunteer_reflection.dart';
import '../services/api_client.dart';
import '../widgets/glassmorphic_ui.dart';
import 'full_screen_image_page.dart';

class VolunteerReflectionViewPage extends StatefulWidget {
  final ApiClient apiClient;
  final VolunteerOpportunity opportunity;

  const VolunteerReflectionViewPage({
    super.key,
    required this.apiClient,
    required this.opportunity,
  });

  @override
  State<VolunteerReflectionViewPage> createState() =>
      _VolunteerReflectionViewPageState();
}

class _VolunteerReflectionViewPageState
    extends State<VolunteerReflectionViewPage> {
  bool _loading = true;
  String? _error;
  List<VolunteerReflection> _reflections = [];
  late VolunteerOpportunity _opportunity;
  bool _didLoad = false;

  @override
  void initState() {
    super.initState();
    _opportunity = widget.opportunity;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didLoad) {
      _didLoad = true;
      _loadReflections();
    }
  }

  Future<void> _loadReflections() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await widget.apiClient
          .getVolunteerReflections(context, _opportunity.id);
      if (!mounted) return;
      setState(() {
        _reflections = list;
        _loading = false;
        if (list.isNotEmpty) {
          final latest = list.first;
          _opportunity = _opportunity.copyWith(
            reflectionCount: list.length,
            latestReflectionAt: latest.createdAt,
            latestReflectionTitle: latest.title,
            latestReflectionExcerpt: latest.body,
            latestReflectionImages: latest.images,
            status: 'completed',
          );
        } else {
          _opportunity = _opportunity.copyWith(
            reflectionCount: 0,
            latestReflectionImages: const [],
          );
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  String _statusText(String status) {
    final l10n = AppLocalizations.of(context)!;
    switch (status) {
      case 'open':
        return l10n.opportunityOpen;
      case 'filled':
        return l10n.opportunityFilled;
      case 'completed':
        return l10n.volunteerCompleted;
      case 'cancelled':
        return l10n.volunteerCancelled;
      default:
        return status;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'open':
        return Colors.green;
      case 'filled':
        return Colors.orange;
      case 'completed':
        return Colors.blue;
      case 'cancelled':
        return Colors.grey;
      default:
        return Theme.of(context).colorScheme.primary;
    }
  }

  Widget _glassPanel({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.background.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.3),
            ),
          ),
          child: child,
        ),
      ),
    );
  }

  Future<void> _openLink(LinkableElement link) async {
    final uri = Uri.parse(link.url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _openImage(String url) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FullScreenImagePage(imageUrl: url),
      ),
    );
  }

  Widget _buildHeaderCard() {
    final l10n = AppLocalizations.of(context)!;
    final statusColor = _statusColor(_opportunity.status);
    return _glassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _opportunity.title,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.event_available,
                color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.8),
                size: 18,
              ),
              const SizedBox(width: 6),
              Text(
                _statusText(_opportunity.status),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .background
                      .withOpacity(0.18),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: statusColor),
                ),
                child: Row(
                  children: [
                    Icon(Icons.auto_stories,
                        color: Theme.of(context)
                            .colorScheme
                            .onPrimary
                            .withOpacity(0.9),
                        size: 16),
                    const SizedBox(width: 6),
                    Text(
                      l10n.reflectionBodyLabel,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_opportunity.latestReflectionAt != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                DateFormat.yMMMd(Localizations.localeOf(context).languageCode)
                    .format(_opportunity.latestReflectionAt!),
                style: TextStyle(
                  color:
                      Theme.of(context).colorScheme.onPrimary.withOpacity(0.75),
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildReflectionCard(VolunteerReflection reflection, bool isLatest) {
    final l10n = AppLocalizations.of(context)!;
    final images = reflection.images.where((img) => img.isImage).toList();
    final dateText =
        DateFormat.yMMMd(Localizations.localeOf(context).languageCode)
            .add_jm()
            .format(reflection.createdAt);

    return _glassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            reflection.title.isNotEmpty
                ? reflection.title
                : l10n.recentReflection,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            dateText,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.7),
              fontSize: 12,
            ),
          ),
          if (reflection.authorName != null || reflection.authorAvatar != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: Theme.of(context)
                        .colorScheme
                        .background
                        .withOpacity(0.25),
                    child: reflection.authorAvatar != null
                        ? ClipOval(
                            child: Image.network(
                              reflection.authorAvatar!,
                              width: 28,
                              height: 28,
                              fit: BoxFit.cover,
                            ),
                          )
                        : Text(
                            (reflection.authorName ?? 'A')[0],
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      reflection.authorName ?? '',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 12),
          Linkify(
            text: reflection.body,
            onOpen: _openLink,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onPrimary,
              fontSize: 15,
              height: 1.5,
            ),
            linkStyle: TextStyle(
              color: Theme.of(context).colorScheme.secondary,
              decoration: TextDecoration.underline,
            ),
          ),
          if (images.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: images
                  .map(
                    (img) => GestureDetector(
                      onTap: () => _openImage(img.fileUrl),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Hero(
                          tag: img.fileUrl,
                          child: Image.network(
                            img.fileUrl,
                            width: 120,
                            height: 120,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              width: 120,
                              height: 120,
                              color: Colors.white24,
                              child: const Icon(Icons.broken_image),
                            ),
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBody() {
    final l10n = AppLocalizations.of(context)!;

    Widget content;
    if (_loading) {
      content = Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Center(
          child: CircularProgressIndicator(
            color: Theme.of(context).colorScheme.onPrimary,
          ),
        ),
      );
    } else if (_error != null) {
      content = _glassPanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.errorOccurred,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: _loadReflections,
                icon: const Icon(Icons.refresh),
                label: Text(l10n.retry),
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
            )
          ],
        ),
      );
    } else if (_reflections.isEmpty) {
      content = _glassPanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.noReflectionsYet,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.noReflectionsHint,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.8),
              ),
            ),
          ],
        ),
      );
    } else {
      content = Column(
        children: [
          ..._reflections.asMap().entries.map((entry) {
            final idx = entry.key;
            final reflection = entry.value;
            return Padding(
              padding: EdgeInsets.only(top: idx == 0 ? 0 : 12),
              child: _buildReflectionCard(reflection, idx == 0),
            );
          }),
        ],
      );
    }

    return RefreshIndicator(
      color: Theme.of(context).colorScheme.onPrimary,
      onRefresh: _loadReflections,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeaderCard(),
                  const SizedBox(height: 12),
                  content,
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final title = l10n.reflectionBodyLabel;
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
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            titleSpacing: 0,
            leading: GlassmorphicUI.buildAppBarIconButton(
              context: context,
              icon: Icons.arrow_back,
              onPressed: () => Navigator.pop(context, _opportunity),
            ),
            title: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          body: SafeArea(child: _buildBody()),
        ),
      ],
    );
  }
}
