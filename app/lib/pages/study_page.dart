import 'package:flutter/material.dart';
import 'package:ocs_app/l10n/app_localizations.dart';
import 'package:ocs_app/models/study_question.dart';
import 'package:ocs_app/pages/create_study_question_page.dart';
import 'package:ocs_app/pages/study_ranking_page.dart';
import 'package:ocs_app/pages/study_question_details_page.dart';
import 'package:ocs_app/services/api_client.dart';
import 'package:ocs_app/widgets/glassmorphic_ui.dart';

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
  bool _isLoading = true;
  String? _error;
  List<StudyQuestion>? _questions;
  bool _didLoad = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _tagFilter = '';
  bool _unresolvedOnly = false;
  String _sort = 'latest';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didLoad) {
      _didLoad = true;
      _loadQuestions();
    }
  }

  Future<void> _loadQuestions() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final questions = await widget.apiClient.getStudyQuestions(
        context,
        q: _searchQuery,
        tag: _tagFilter,
        status: _unresolvedOnly ? 'open' : null,
        sort: _sort,
      );

      if (mounted) {
        setState(() {
          _questions = questions;
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

  bool get _hasActiveFilters => _tagFilter.isNotEmpty || _unresolvedOnly;

  String _sortLabel(AppLocalizations l10n) {
    switch (_sort) {
      case 'answers':
        return l10n.studySortAnswers;
      case 'unresolved':
        return l10n.studySortUnresolvedFirst;
      case 'newest':
      case 'latest':
      default:
        return l10n.studySortNewest;
    }
  }

  Future<void> _applySearch() async {
    final next = _searchController.text.trim();
    if (next == _searchQuery) return;
    setState(() {
      _searchQuery = next;
    });
    await _loadQuestions();
  }

  Future<void> _clearSearch() async {
    if (_searchQuery.isEmpty && _searchController.text.isEmpty) return;
    _searchController.clear();
    setState(() {
      _searchQuery = '';
    });
    await _loadQuestions();
  }

  Future<void> _openSortDialog() async {
    final selected = await GlassmorphicUI.showDialog<String>(
      context: context,
      width: 300,
      child: _StudySortDialog(
        currentSort: _sort,
        onSortChanged: (value) => Navigator.pop(context, value),
      ),
    );
    if (selected != null && selected != _sort) {
      setState(() {
        _sort = selected;
      });
      await _loadQuestions();
    }
  }

  Future<void> _openFilterDialog() async {
    final result = await GlassmorphicUI.showDialog<_StudyFilterResult>(
      context: context,
      width: 320,
      child: _StudyFilterDialog(
        initialTag: _tagFilter,
        initialUnresolvedOnly: _unresolvedOnly,
      ),
    );
    if (result == null) return;
    final changed =
        result.tag != _tagFilter || result.unresolvedOnly != _unresolvedOnly;
    if (!changed) return;
    setState(() {
      _tagFilter = result.tag;
      _unresolvedOnly = result.unresolvedOnly;
    });
    await _loadQuestions();
  }

  Future<void> _openCreateQuestionPage() async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) =>
            CreateStudyQuestionPage(apiClient: widget.apiClient),
      ),
    );

    if (created == true && mounted) {
      await _loadQuestions();
    }
  }

  Future<void> _openQuestionDetail(StudyQuestion question) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StudyQuestionDetailsPage(
          apiClient: widget.apiClient,
          questionId: question.id,
        ),
      ),
    );
    if (mounted) {
      await _loadQuestions();
    }
  }

  Future<void> _openRankingPage() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StudyRankingPage(apiClient: widget.apiClient),
      ),
    );
  }

  Color _statusColor(String status) {
    if (status == 'resolved') {
      return Colors.greenAccent.shade100;
    }
    return Colors.orangeAccent.shade100;
  }

  String _statusText(AppLocalizations l10n, String status) {
    if (status == 'resolved') {
      return l10n.questionStatusResolved;
    }
    return l10n.questionStatusOpen;
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
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Row(
                    children: [
                      Icon(
                        Icons.school_outlined,
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        l10n.studyQuestions,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onPrimary,
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .background
                              .withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Theme.of(context)
                                .colorScheme
                                .onPrimary
                                .withOpacity(0.3),
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: IconButton(
                            tooltip: l10n.studyRanking,
                            iconSize: 20,
                            onPressed: _openRankingPage,
                            icon: Icon(
                              Icons.emoji_events_outlined,
                              color: Theme.of(context).colorScheme.onPrimary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .background
                                .withOpacity(0.2),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onPrimary
                                  .withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              const SizedBox(width: 10),
                              Icon(
                                Icons.search,
                                size: 18,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onPrimary
                                    .withOpacity(0.8),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  controller: _searchController,
                                  textInputAction: TextInputAction.search,
                                  onChanged: (_) {
                                    setState(() {});
                                  },
                                  onSubmitted: (_) => _applySearch(),
                                  style: TextStyle(
                                    color:
                                        Theme.of(context).colorScheme.onPrimary,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: l10n.studySearchHint,
                                    hintStyle: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onPrimary
                                          .withOpacity(0.7),
                                    ),
                                    border: InputBorder.none,
                                    isDense: true,
                                  ),
                                ),
                              ),
                              if (_searchQuery.isNotEmpty ||
                                  _searchController.text.isNotEmpty)
                                IconButton(
                                  iconSize: 18,
                                  onPressed: _clearSearch,
                                  icon: Icon(
                                    Icons.close,
                                    color:
                                        Theme.of(context).colorScheme.onPrimary,
                                  ),
                                )
                              else
                                IconButton(
                                  iconSize: 18,
                                  onPressed: _applySearch,
                                  icon: Icon(
                                    Icons.arrow_forward,
                                    color:
                                        Theme.of(context).colorScheme.onPrimary,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .background
                              .withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _hasActiveFilters
                                ? Theme.of(context).colorScheme.secondary
                                : Theme.of(context)
                                    .colorScheme
                                    .onPrimary
                                    .withOpacity(0.3),
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: IconButton(
                            tooltip: l10n.studyFilterTitle,
                            iconSize: 20,
                            onPressed: _openFilterDialog,
                            icon: Icon(
                              _hasActiveFilters
                                  ? Icons.filter_alt
                                  : Icons.filter_alt_outlined,
                              color: Theme.of(context).colorScheme.onPrimary,
                            ),
                          ),
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .background
                              .withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Theme.of(context)
                                .colorScheme
                                .onPrimary
                                .withOpacity(0.3),
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: IconButton(
                            tooltip: '${l10n.sortBy}: ${_sortLabel(l10n)}',
                            iconSize: 20,
                            onPressed: _openSortDialog,
                            icon: Icon(
                              Icons.sort,
                              color: Theme.of(context).colorScheme.onPrimary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _loadQuestions,
                    child: Builder(
                      builder: (_) {
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

                        if (_questions == null || _questions!.isEmpty) {
                          return ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 48,
                                ),
                                child: Text(
                                  l10n.noStudyQuestions,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onPrimary
                                        .withOpacity(0.9),
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ],
                          );
                        }

                        return ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(12, 8, 12, 96),
                          itemCount: _questions!.length,
                          itemBuilder: (context, index) {
                            final question = _questions![index];
                            final statusColor = _statusColor(question.status);
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: () => _openQuestionDetail(question),
                                child: Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .background
                                        .withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onPrimary
                                          .withOpacity(0.25),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        question.title,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onPrimary,
                                          fontSize: 17,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      if (question.mediaUrls.isNotEmpty) ...[
                                        const SizedBox(height: 10),
                                        ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          child: Image.network(
                                            question.mediaUrls.first,
                                            height: 140,
                                            width: double.infinity,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      ],
                                      const SizedBox(height: 10),
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        children: [
                                          ...question.tags.map(
                                            (tag) => Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 10,
                                                vertical: 5,
                                              ),
                                              decoration: BoxDecoration(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onPrimary
                                                    .withOpacity(0.16),
                                                borderRadius:
                                                    BorderRadius.circular(999),
                                              ),
                                              child: Text(
                                                tag,
                                                style: TextStyle(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onPrimary,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 5,
                                            ),
                                            decoration: BoxDecoration(
                                              color:
                                                  statusColor.withOpacity(0.22),
                                              borderRadius:
                                                  BorderRadius.circular(999),
                                            ),
                                            child: Text(
                                              _statusText(
                                                  l10n, question.status),
                                              style: TextStyle(
                                                color: statusColor,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.access_time,
                                            size: 14,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onPrimary
                                                .withOpacity(0.75),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            question.getTimeAgo(),
                                            style: TextStyle(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onPrimary
                                                  .withOpacity(0.75),
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          GlassmorphicUI.buildFloatingButton(
            context: context,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.add_comment,
                  size: 20,
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
                const SizedBox(width: 8),
                Text(
                  l10n.createQuestion,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
              ],
            ),
            onTap: _openCreateQuestionPage,
          ),
        ],
      ),
    );
  }
}

class _StudyFilterResult {
  final String tag;
  final bool unresolvedOnly;

  const _StudyFilterResult({
    required this.tag,
    required this.unresolvedOnly,
  });
}

class _StudySortDialog extends StatelessWidget {
  final String currentSort;
  final Function(String) onSortChanged;

  const _StudySortDialog({
    required this.currentSort,
    required this.onSortChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
          child: Text(
            l10n.sortBy,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        _StudySortItem(
          selected: currentSort == 'latest' || currentSort == 'newest',
          label: l10n.studySortNewest,
          icon: Icons.access_time,
          onTap: () => onSortChanged('latest'),
        ),
        _StudySortItem(
          selected: currentSort == 'answers',
          label: l10n.studySortAnswers,
          icon: Icons.question_answer_outlined,
          onTap: () => onSortChanged('answers'),
        ),
        _StudySortItem(
          selected: currentSort == 'unresolved',
          label: l10n.studySortUnresolvedFirst,
          icon: Icons.priority_high,
          onTap: () => onSortChanged('unresolved'),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _StudySortItem extends StatelessWidget {
  final bool selected;
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _StudySortItem({
    required this.selected,
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Container(
        decoration: BoxDecoration(
          color: selected
              ? Theme.of(context).colorScheme.secondary
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: selected
                      ? Theme.of(context).colorScheme.onSecondary
                      : Theme.of(context).colorScheme.onPrimary,
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: selected
                        ? Theme.of(context).colorScheme.onSecondary
                        : Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StudyFilterDialog extends StatefulWidget {
  final String initialTag;
  final bool initialUnresolvedOnly;

  const _StudyFilterDialog({
    required this.initialTag,
    required this.initialUnresolvedOnly,
  });

  @override
  State<_StudyFilterDialog> createState() => _StudyFilterDialogState();
}

class _StudyFilterDialogState extends State<_StudyFilterDialog> {
  late TextEditingController _tagController;
  late bool _unresolvedOnly;

  @override
  void initState() {
    super.initState();
    _tagController = TextEditingController(text: widget.initialTag);
    _unresolvedOnly = widget.initialUnresolvedOnly;
  }

  @override
  void dispose() {
    _tagController.dispose();
    super.dispose();
  }

  void _apply() {
    Navigator.pop(
      context,
      _StudyFilterResult(
        tag: _tagController.text.trim(),
        unresolvedOnly: _unresolvedOnly,
      ),
    );
  }

  void _reset() {
    Navigator.pop(
      context,
      const _StudyFilterResult(
        tag: '',
        unresolvedOnly: false,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.studyFilterTitle,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _tagController,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onPrimary,
            ),
            decoration: InputDecoration(
              labelText: l10n.studyFilterTag,
              labelStyle: TextStyle(
                color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.8),
              ),
              hintText: l10n.questionTagsHint,
              hintStyle: TextStyle(
                color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.6),
              ),
              filled: true,
              fillColor:
                  Theme.of(context).colorScheme.background.withOpacity(0.2),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color:
                      Theme.of(context).colorScheme.onPrimary.withOpacity(0.25),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            value: _unresolvedOnly,
            onChanged: (value) {
              setState(() {
                _unresolvedOnly = value;
              });
            },
            title: Text(
              l10n.studyFilterUnresolvedOnly,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
            activeColor: Theme.of(context).colorScheme.secondary,
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: _reset,
                child: Text(
                  l10n.studyFilterReset,
                  style: TextStyle(
                    color: Theme.of(context)
                        .colorScheme
                        .onPrimary
                        .withOpacity(0.8),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _apply,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.secondary,
                  foregroundColor: Theme.of(context).colorScheme.onSecondary,
                ),
                child: Text(l10n.studyFilterApply),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
