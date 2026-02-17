import 'package:flutter/material.dart';
import 'package:ocs_app/l10n/app_localizations.dart';
import 'package:ocs_app/models/study_ranking.dart';
import 'package:ocs_app/pages/user_profile_page.dart';
import 'package:ocs_app/services/api_client.dart';
import 'package:ocs_app/utils/study_badge.dart';

class StudyRankingPage extends StatefulWidget {
  final ApiClient apiClient;

  const StudyRankingPage({
    super.key,
    required this.apiClient,
  });

  @override
  State<StudyRankingPage> createState() => _StudyRankingPageState();
}

class _StudyRankingPageState extends State<StudyRankingPage> {
  bool _isLoading = true;
  String? _error;
  List<StudyRankingItem> _items = [];
  StudyRankingItem? _myRank;
  bool _didLoad = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didLoad) {
      _didLoad = true;
      _loadRanking();
    }
  }

  Future<void> _loadRanking() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final response = await widget.apiClient.getStudyRanking(
        context,
        period: 'all',
        page: 1,
        limit: 20,
      );

      if (!mounted) return;
      setState(() {
        _items = response.items;
        _myRank = response.myRank;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Widget _buildMyRankCard(AppLocalizations l10n) {
    if (_myRank == null) return const SizedBox.shrink();

    final isUnranked = _myRank!.rank <= 0;
    final myBadge = StudyBadgePolicy.resolve(l10n, _myRank!.points);
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.16),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.amber.withOpacity(0.55),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.emoji_events,
            color: Colors.amber.shade300,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.studyRankingMyRank,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        _myRank!.displayName.isEmpty
                            ? l10n.noName
                            : _myRank!.displayName,
                        style: TextStyle(
                          color: Theme.of(context)
                              .colorScheme
                              .onPrimary
                              .withOpacity(0.9),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (myBadge.hasBadge) ...[
                      const SizedBox(width: 6),
                      _buildBadgeChip(myBadge),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                isUnranked ? l10n.studyRankingUnranked : '#${_myRank!.rank}',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimary,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
              Text(
                '${_myRank!.points} ${l10n.totalPoints}',
                style: TextStyle(
                  color:
                      Theme.of(context).colorScheme.onPrimary.withOpacity(0.85),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRankingItem(StudyRankingItem item) {
    final isMine = _myRank != null && item.userId == _myRank!.userId;
    final l10n = AppLocalizations.of(context)!;
    final badge = StudyBadgePolicy.resolve(l10n, item.points);
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => UserProfilePage(
              apiClient: widget.apiClient,
              userId: item.userId,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isMine
              ? Colors.lightBlueAccent.withOpacity(0.16)
              : Theme.of(context).colorScheme.background.withOpacity(0.2),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isMine
                ? Colors.lightBlueAccent.withOpacity(0.5)
                : Theme.of(context).colorScheme.onPrimary.withOpacity(0.25),
          ),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 36,
              child: Text(
                '#${item.rank}',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            CircleAvatar(
              radius: 16,
              backgroundColor: Theme.of(context).colorScheme.secondary,
              backgroundImage:
                  item.avatarUrl != null ? NetworkImage(item.avatarUrl!) : null,
              child: item.avatarUrl == null
                  ? Text(
                      item.displayName.isEmpty ? '?' : item.displayName[0],
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSecondary,
                        fontWeight: FontWeight.w700,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      item.displayName.isEmpty ? l10n.noName : item.displayName,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (badge.hasBadge) ...[
                    const SizedBox(width: 6),
                    _buildBadgeChip(badge),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${item.points}',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadgeChip(StudyBadgeInfo badge) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: badge.color.withOpacity(0.25),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: badge.color.withOpacity(0.7),
        ),
      ),
      child: Text(
        badge.label,
        style: TextStyle(
          color: badge.color,
          fontWeight: FontWeight.w700,
          fontSize: 10,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: Colors.transparent,
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
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(
                          Icons.arrow_back,
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(
                        Icons.emoji_events_outlined,
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        l10n.studyRanking,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onPrimary,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _loadRanking,
                    child: Builder(
                      builder: (context) {
                        if (_isLoading) {
                          return Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Theme.of(context).colorScheme.onPrimary,
                              ),
                            ),
                          );
                        }
                        if (_error != null) {
                          return ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Text(
                                  _error!,
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.error,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          );
                        }

                        return ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(14, 6, 14, 18),
                          children: [
                            _buildMyRankCard(l10n),
                            if (_items.isEmpty)
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 18),
                                child: Text(
                                  l10n.noStudyRanking,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onPrimary
                                        .withOpacity(0.9),
                                  ),
                                ),
                              )
                            else
                              ..._items.map(_buildRankingItem),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
