import 'package:flutter/material.dart';
import 'package:ocs_app/l10n/app_localizations.dart';
import 'package:ocs_app/models/study_answer.dart';
import 'package:ocs_app/models/study_question.dart';
import 'package:ocs_app/pages/user_profile_page.dart';
import 'package:ocs_app/services/api_client.dart';
import 'package:ocs_app/widgets/glassmorphic_ui.dart';

class StudyQuestionDetailsPage extends StatefulWidget {
  final ApiClient apiClient;
  final int questionId;

  const StudyQuestionDetailsPage({
    super.key,
    required this.apiClient,
    required this.questionId,
  });

  @override
  State<StudyQuestionDetailsPage> createState() =>
      _StudyQuestionDetailsPageState();
}

class _StudyQuestionDetailsPageState extends State<StudyQuestionDetailsPage> {
  bool _isLoading = true;
  String? _error;
  StudyQuestion? _question;
  List<StudyAnswer> _answers = [];
  bool _didLoad = false;
  bool _isSubmittingAnswer = false;
  final _answerController = TextEditingController();

  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didLoad) {
      _didLoad = true;
      _loadData();
    }
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final results = await Future.wait([
        widget.apiClient.getStudyQuestionDetail(context, widget.questionId),
        widget.apiClient.getStudyAnswers(context, widget.questionId),
      ]);

      final question = results[0] as StudyQuestion;
      final answers = results[1] as List<StudyAnswer>;
      answers.sort((a, b) {
        if (a.isBest == b.isBest) {
          return a.createdAt.compareTo(b.createdAt);
        }
        return a.isBest ? -1 : 1;
      });

      if (mounted) {
        setState(() {
          _question = question;
          _answers = answers;
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

  Future<void> _submitAnswer() async {
    final l10n = AppLocalizations.of(context)!;
    final body = _answerController.text.trim();
    if (body.isEmpty) {
      GlassmorphicUI.showGlassSnackBar(
        context,
        l10n.answerBodyRequired,
        isError: true,
      );
      return;
    }
    if (body.length > 5000) {
      GlassmorphicUI.showGlassSnackBar(
        context,
        l10n.answerBodyTooLong,
        isError: true,
      );
      return;
    }
    if (_isSubmittingAnswer || _question == null) return;

    try {
      setState(() {
        _isSubmittingAnswer = true;
      });

      await widget.apiClient.createStudyAnswer(
        context,
        questionId: _question!.id,
        body: body,
      );
      _answerController.clear();
      await _loadData();
    } catch (e) {
      if (mounted) {
        GlassmorphicUI.showGlassSnackBar(
          context,
          e.toString(),
          isError: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmittingAnswer = false;
        });
      }
    }
  }

  Future<void> _markAsBest(StudyAnswer answer) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      await widget.apiClient.markStudyAnswerAsBest(
        context,
        answerId: answer.id,
      );
      if (mounted) {
        GlassmorphicUI.showGlassSnackBar(
          context,
          l10n.bestAnswerSelectedSuccess,
        );
      }
      await _loadData();
    } catch (e) {
      if (mounted) {
        GlassmorphicUI.showGlassSnackBar(
          context,
          e.toString(),
          isError: true,
        );
      }
    }
  }

  bool get _hasBestAnswer => _answers.any((a) => a.isBest);

  String _formatDate(DateTime dateTime) {
    final local = dateTime.toLocal();
    final y = local.year.toString().padLeft(4, '0');
    final m = local.month.toString().padLeft(2, '0');
    final d = local.day.toString().padLeft(2, '0');
    final hh = local.hour.toString().padLeft(2, '0');
    final mm = local.minute.toString().padLeft(2, '0');
    return '$y-$m-$d $hh:$mm';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          l10n.questionDetails,
          style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
        ),
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.background.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.3),
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: IconButton(
              icon: Icon(
                Icons.arrow_back,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
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
            child: Column(
              children: [
                Expanded(
                  child: _buildContent(context, l10n),
                ),
                _buildAnswerComposer(context, l10n),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, AppLocalizations l10n) {
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
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          _error!,
          style: TextStyle(
            color: Theme.of(context).colorScheme.error,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }
    if (_question == null) {
      return const SizedBox.shrink();
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          _buildQuestionCard(context, l10n),
          const SizedBox(height: 16),
          Text(
            l10n.studyAnswers,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          if (_answers.isEmpty)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color:
                    Theme.of(context).colorScheme.background.withOpacity(0.2),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color:
                      Theme.of(context).colorScheme.onPrimary.withOpacity(0.25),
                ),
              ),
              child: Text(
                l10n.noStudyAnswers,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
            )
          else
            ..._answers
                .map((answer) => _buildAnswerCard(context, l10n, answer)),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(BuildContext context, AppLocalizations l10n) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.background.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.25),
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _question!.title,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onPrimary,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _chip(
                context,
                _question!.category,
                Theme.of(context).colorScheme.onPrimary,
              ),
              _chip(
                context,
                _question!.status == 'resolved'
                    ? l10n.questionStatusResolved
                    : l10n.questionStatusOpen,
                _question!.status == 'resolved'
                    ? Colors.greenAccent.shade100
                    : Colors.orangeAccent.shade100,
              ),
            ],
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => UserProfilePage(
                    apiClient: widget.apiClient,
                    userId: _question!.authorUserId,
                  ),
                ),
              );
            },
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: Theme.of(context).colorScheme.secondary,
                    backgroundImage: _question!.authorAvatarUrl != null
                        ? NetworkImage(_question!.authorAvatarUrl!)
                        : null,
                    child: _question!.authorAvatarUrl == null
                        ? Text(
                            _question!.authorDisplayName.isEmpty
                                ? '?'
                                : _question!.authorDisplayName[0],
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSecondary,
                              fontWeight: FontWeight.w700,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '${l10n.questionAuthor}: ${_question!.authorDisplayName.isEmpty ? l10n.noName : _question!.authorDisplayName}',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${l10n.questionCreatedAt}: ${_formatDate(_question!.createdAt)}',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.85),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            _question!.body,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onPrimary,
              fontSize: 16,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnswerCard(
    BuildContext context,
    AppLocalizations l10n,
    StudyAnswer answer,
  ) {
    final canMarkBest = _question != null &&
        _question!.canMarkBest &&
        !_hasBestAnswer &&
        !answer.isBest;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: answer.isBest
            ? Colors.amber.withOpacity(0.15)
            : Theme.of(context).colorScheme.background.withOpacity(0.2),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: answer.isBest
              ? Colors.amber.withOpacity(0.65)
              : Theme.of(context).colorScheme.onPrimary.withOpacity(0.25),
          width: answer.isBest ? 1.2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => UserProfilePage(
                    apiClient: widget.apiClient,
                    userId: answer.authorUserId,
                  ),
                ),
              );
            },
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: Theme.of(context).colorScheme.secondary,
                    backgroundImage: answer.authorAvatarUrl != null
                        ? NetworkImage(answer.authorAvatarUrl!)
                        : null,
                    child: answer.authorAvatarUrl == null
                        ? Text(
                            answer.authorDisplayName.isEmpty
                                ? '?'
                                : answer.authorDisplayName[0],
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSecondary,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      answer.authorDisplayName.isEmpty
                          ? l10n.noName
                          : answer.authorDisplayName,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (answer.isBest)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        l10n.bestAnswerLabel,
                        style: const TextStyle(
                          color: Colors.amber,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            answer.body,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onPrimary,
              fontSize: 15,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                answer.getTimeAgo(),
                style: TextStyle(
                  color:
                      Theme.of(context).colorScheme.onPrimary.withOpacity(0.75),
                  fontSize: 12,
                ),
              ),
              const Spacer(),
              if (canMarkBest)
                TextButton.icon(
                  onPressed: () => _markAsBest(answer),
                  icon: const Icon(Icons.emoji_events_outlined, size: 16),
                  label: Text(l10n.markAsBest),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.amber.shade200,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAnswerComposer(BuildContext context, AppLocalizations l10n) {
    if (_question == null || _isLoading) {
      return const SizedBox.shrink();
    }

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 4, 10, 8),
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color:
                      Theme.of(context).colorScheme.background.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Theme.of(context)
                        .colorScheme
                        .onPrimary
                        .withOpacity(0.3),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: TextField(
                    controller: _answerController,
                    maxLength: 5000,
                    maxLines: null,
                    minLines: 1,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText: l10n.answerInputHint,
                      hintStyle: TextStyle(
                        color: Theme.of(context)
                            .colorScheme
                            .onPrimary
                            .withOpacity(0.7),
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      counterText: '',
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(
                color:
                    Theme.of(context).colorScheme.background.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color:
                      Theme.of(context).colorScheme.onPrimary.withOpacity(0.3),
                ),
              ),
              child: IconButton(
                onPressed: _isSubmittingAnswer ? null : _submitAnswer,
                icon: _isSubmittingAnswer
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Theme.of(context).colorScheme.onPrimary,
                          ),
                        ),
                      )
                    : Icon(
                        Icons.send,
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(BuildContext context, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.18),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
