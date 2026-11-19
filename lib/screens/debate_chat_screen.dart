import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/debate_message.dart';
import '../models/debate_session.dart';
import '../models/debate_topic.dart';
import '../services/auth_service.dart';
import '../services/debate_arena_service.dart';
import '../services/exercise_scoring_service.dart';
import '../services/offline_debate_service.dart';
import '../services/progress_service.dart';
import '../utils/app_colors.dart';
import '../widgets/debate_reflection_dialog.dart';
import '../widgets/gym_card.dart';

/// Offline, deterministic Debate Arena chat interface.
/// Provides structured dialectical sparring and transparent rule-based
/// feedback across relevance, reasoning, counterargument structure, and clarity.
class DebateChatScreen extends StatefulWidget {
  final DebateTopic? topic;
  final DebateSide initialUserSide;

  const DebateChatScreen({
    super.key,
    this.topic,
    this.initialUserSide = DebateSide.support,
  });

  @override
  State<DebateChatScreen> createState() => _DebateChatScreenState();
}

class _DebateChatScreenState extends State<DebateChatScreen> {
  final List<DebateMessage> _messages = [];
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  DebateSession? _session;
  bool _isSubmitting = false;

  /// Real session start time used for exercise duration tracking and idempotency.
  final DateTime _sessionStartedAt = DateTime.now();

  @override
  void initState() {
    super.initState();
    _initializeDebateSession();
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// Initializes the debate session and loads the sparring opponent's opening position.
  void _initializeDebateSession() {
    final topic = widget.topic ?? DebateArenaService.getTopicById('topic_02');
    final userSide = widget.initialUserSide;
    final opponentSide = userSide.opposite;

    final session = DebateSession(
      topic: topic,
      userSide: userSide,
      aiSide: opponentSide,
      currentStage: DebateStage.opening,
      currentTurn: 1,
      maxTurns: 3,
      status: DebateStatus.inProgress,
    );

    _session = session;

    // Retrieve offline opening statement directly from curated knowledge base
    final openingText = OfflineDebateService.instance.getOpponentOpeningStatement(
      topic: topic,
      userSide: userSide,
    );

    final openingMessage = DebateMessage(
      id: 'opening_${DateTime.now().millisecondsSinceEpoch}',
      sender: MessageSender.ai,
      senderName: 'Arena Sparring Partner',
      message: openingText,
      timestamp: DateTime.now(),
      type: MessageType.opening,
      stage: DebateStage.opening,
    );

    session.addMessage(openingMessage);
    _messages.clear();
    _messages.add(openingMessage);
  }

  /// Evaluates user counterargument deterministically and advances the debate turn.
  Future<void> _handleSendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty || _isSubmitting || _session == null) return;

    if (_session!.status == DebateStatus.completed) {
      _showReflectionModal();
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final user = AuthService.instance.currentUser;
    final userName = (user?.fullName.trim().isNotEmpty ?? false)
        ? user!.fullName.trim()
        : (user?.username.trim().isNotEmpty ?? false)
            ? user!.username.trim()
            : 'You';

    // 1. Evaluate user argument with transparent, rule-based criteria
    final analysis = OfflineDebateService.instance.evaluateArgument(
      argument: text,
      topic: _session!.topic,
      userSide: _session!.userSide,
      turn: _session!.currentTurn,
    );

    final userMessage = DebateMessage(
      id: 'user_${DateTime.now().millisecondsSinceEpoch}',
      sender: MessageSender.user,
      senderName: userName,
      message: text,
      timestamp: DateTime.now(),
      type: MessageType.text,
      stage: _session!.currentStage,
      analysis: analysis,
    );

    _session!.addMessage(userMessage);
    _textController.clear();

    final currentTurn = _session!.currentTurn;
    final isClosingTurn = currentTurn >= _session!.maxTurns;

    // 2. Generate opponent response immediately without fabricated delay
    final opponentText = isClosingTurn
        ? OfflineDebateService.instance.getOpponentClosing(
            topic: _session!.topic,
            userSide: _session!.userSide,
          )
        : OfflineDebateService.instance.getOpponentRebuttal(
            topic: _session!.topic,
            userSide: _session!.userSide,
            turn: currentTurn + 1,
          );

    final opponentMessage = DebateMessage(
      id: 'opponent_${DateTime.now().millisecondsSinceEpoch}',
      sender: MessageSender.ai,
      senderName: 'Arena Sparring Partner',
      message: opponentText,
      timestamp: DateTime.now(),
      type: isClosingTurn ? MessageType.feedback : MessageType.rebuttal,
      stage: isClosingTurn ? DebateStage.closing : DebateStage.rebuttal,
    );

    _session!.addMessage(opponentMessage);

    if (isClosingTurn) {
      _session!.updateStatus(DebateStatus.completed);
      if (!_session!.hasAwardedRewards) {
        _session!.hasAwardedRewards = true;
        await _completeDebateWithScoring();
      }
    } else {
      _session!.advanceTurn();
    }

    if (mounted) {
      setState(() {
        _messages.clear();
        _messages.addAll(_session!.messages);
        _isSubmitting = false;
      });
      _scrollToBottom();

      if (isClosingTurn) {
        await Future.delayed(const Duration(milliseconds: 300));
        if (mounted) {
          _showReflectionModal();
        }
      }
    }
  }

  /// Calculates final rule-based performance scores and persists session progress.
  Future<void> _completeDebateWithScoring() async {
    final session = _session;
    if (session == null) return;

    final userMessages = session.messages.where((m) => m.isUser).toList();
    if (userMessages.isEmpty) return;

    // Aggregate criteria across all submitted arguments
    int totalRelevance = 0;
    int totalReasoning = 0;
    int totalStructure = 0;
    int totalClarity = 0;
    int totalOverall = 0;

    for (final msg in userMessages) {
      if (msg.analysis != null) {
        totalRelevance += msg.analysis!.relevanceScore;
        totalReasoning += msg.analysis!.reasoningScore;
        totalStructure += msg.analysis!.structureScore;
        totalClarity += msg.analysis!.clarityScore;
        totalOverall += msg.analysis!.totalScore;
      }
    }

    final count = userMessages.length;
    final avgRelevance = (totalRelevance / count).round();
    final avgReasoning = (totalReasoning / count).round();
    final avgStructure = (totalStructure / count).round();
    final avgClarity = (totalClarity / count).round();
    final avgOverall = (totalOverall / count).round().clamp(0, 100);

    session.performanceScore = avgOverall;
    session.relevanceScore = avgRelevance;
    session.reasoningScore = avgReasoning;
    session.structureScore = avgStructure;
    session.clarityScore = avgClarity;

    final durationSeconds = DateTime.now().difference(_sessionStartedAt).inSeconds;
    final idempotencyKey = 'debate_${session.topic.id}_${_sessionStartedAt.millisecondsSinceEpoch}';

    final xpEarned = await ProgressService.instance.recordDebateArenaCompletion(
      performanceScore: avgOverall.toDouble(),
      durationSeconds: durationSeconds,
      idempotencyKey: idempotencyKey,
    );

    session.earnedXp = xpEarned;
    session.logicPointsEarned = ExerciseScoringService.scaledGain(25, avgOverall.toDouble());
  }

  void _showReflectionModal() {
    if (_session == null) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => DebateReflectionDialog(
        session: _session!,
        onComplete: () {
          context.pop();
          context.pop();
        },
      ),
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final topicTitle = widget.topic?.title ?? 'Will AI make humanity more intelligent or more dependent?';
    final topicCategory = widget.topic?.category ?? 'Tech & Future';
    final isCompleted = _session?.status == DebateStatus.completed;
    final userSide = _session?.userSide ?? widget.initialUserSide;

    return Scaffold(
      backgroundColor: isDark ? AppColors.pageBackground : AppColors.groundLight,
      appBar: AppBar(
        title: const Text('Debate Arena'),
        actions: [
          if (isCompleted)
            IconButton(
              icon: const Icon(Icons.workspace_premium_outlined),
              tooltip: 'View reflection',
              onPressed: _showReflectionModal,
            )
          else if (_session != null && _session!.messages.where((m) => m.isUser).isNotEmpty)
            TextButton(
              onPressed: _isSubmitting
                  ? null
                  : () async {
                      _session!.updateStatus(DebateStatus.completed);
                      if (!_session!.hasAwardedRewards) {
                        _session!.hasAwardedRewards = true;
                        await _completeDebateWithScoring();
                      }
                      if (mounted) _showReflectionModal();
                    },
              child: const Text('End debate'),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 1. Topic & Stance Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: GymCard(
                padding: const EdgeInsets.all(12),
                backgroundColor: isDark ? AppColors.surface : Colors.white,
                borderColor: isDark ? AppColors.borderSubtle : AppColors.borderLightClean,
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.surfaceContainerHigh
                            : AppColors.surfaceLightClean,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isDark
                              ? AppColors.borderDark
                              : AppColors.borderLightClean,
                        ),
                      ),
                      child: Icon(
                        widget.topic?.icon ?? Icons.forum_outlined,
                        color: isDark
                            ? AppColors.textSecondary
                            : AppColors.textSecondaryLight,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? AppColors.surfaceContainerHigh
                                      : AppColors.surfaceLightClean,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  topicCategory,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: AppColors.puzzleGreen,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Your stance: ${userSide == DebateSide.support ? "Support" : "Oppose"}',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: isDark
                                      ? AppColors.brandLime
                                      : AppColors.primaryLimeLight,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            topicTitle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleSmall?.copyWith(
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 2. Chat Message Stream List
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final message = _messages[index];
                  return _buildMessageBubble(theme, message, isDark);
                },
              ),
            ),

            // 3. Message Input Bar or Completion Banner
            if (isCompleted)
              _buildCompletedBanner(theme, isDark)
            else
              _buildInputBar(theme, isDark),
          ],
        ),
      ),
    );
  }

  /// Renders completion banner when debate reaches closing state.
  Widget _buildCompletedBanner(ThemeData theme, bool isDark) {
    final mutedColor =
        isDark ? AppColors.textSecondary : AppColors.textSecondaryLight;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surface : AppColors.cardLight,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.borderSubtle : AppColors.borderLightClean,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.check_circle_outline_rounded,
            color: isDark ? AppColors.brandLime : AppColors.primaryLimeLight,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Debate complete',
                  style: theme.textTheme.titleSmall,
                ),
                Text(
                  'Exercise finished (+25 Logic Points, +30 XP)',
                  style: theme.textTheme.bodySmall?.copyWith(color: mutedColor),
                ),
              ],
            ),
          ),
          FilledButton.icon(
            onPressed: _showReflectionModal,
            icon: const Icon(Icons.insights_outlined, size: 16),
            label: const Text('View analysis'),
          ),
        ],
      ),
    );
  }

  /// Renders message bubble. User and opponent differ by surface step only.
  Widget _buildMessageBubble(ThemeData theme, DebateMessage message, bool isDark) {
    final isUser = message.sender == MessageSender.user;
    final mutedColor =
        isDark ? AppColors.textMutedDark : AppColors.textMutedLight;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14.0),
      child: Column(
        crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              if (!isUser) ...[
                _buildAvatar(
                  icon: Icons.psychology_outlined,
                  isDark: isDark,
                ),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isUser
                        ? (isDark
                            ? AppColors.surfaceContainerHigh
                            : AppColors.surfaceLightClean)
                        : (isDark
                            ? AppColors.surfaceContainerLow
                            : AppColors.cardLight),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(12),
                      topRight: const Radius.circular(12),
                      bottomLeft: Radius.circular(isUser ? 12 : 4),
                      bottomRight: Radius.circular(isUser ? 4 : 12),
                    ),
                    border: Border.all(
                      color: isDark
                          ? AppColors.borderSubtle
                          : AppColors.borderLightClean,
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            message.senderName,
                            style: theme.textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (!isUser) ...[
                            const SizedBox(width: 8),
                            Text(
                              'Rule-based opponent',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: mutedColor,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        message.message,
                        style: theme.textTheme.bodyMedium?.copyWith(height: 1.45),
                      ),
                    ],
                  ),
                ),
              ),
              if (isUser) ...[
                const SizedBox(width: 8),
                _buildAvatar(
                  icon: Icons.person_outline_rounded,
                  isDark: isDark,
                ),
              ],
            ],
          ),

          const SizedBox(height: 4),

          Padding(
            padding: EdgeInsets.only(left: isUser ? 40 : 40, right: 40),
            child: Text(
              _formatTimestamp(message.timestamp),
              style: theme.textTheme.labelSmall?.copyWith(color: mutedColor),
            ),
          ),

          // Transparent rule-based analysis shown under user arguments
          if (isUser && message.analysis != null) ...[
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.only(right: 40.0),
              child: _buildAnalysisCard(message.analysis!, isDark),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAvatar({required IconData icon, required bool isDark}) {
    return Container(
      width: 32,
      height: 32,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: isDark
            ? AppColors.surfaceContainerHigh
            : AppColors.surfaceLightClean,
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLightClean,
        ),
      ),
      child: Icon(
        icon,
        size: 17,
        color: isDark ? AppColors.textSecondary : AppColors.textSecondaryLight,
      ),
    );
  }

  String _formatTimestamp(DateTime time) {
    final hour = time.hour == 0 ? 12 : (time.hour > 12 ? time.hour - 12 : time.hour);
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  /// Compact, transparent argument analysis card shown under each user submission.
  Widget _buildAnalysisCard(ArgumentAnalysis analysis, bool isDark) {
    final theme = Theme.of(context);
    final mutedColor =
        isDark ? AppColors.textMutedDark : AppColors.textMutedLight;
    final isStrong = analysis.totalScore >= 70;
    final scoreColor = isStrong
        ? (isDark ? AppColors.brandLime : AppColors.primaryLimeLight)
        : mutedColor;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDeep : AppColors.surfaceLightClean,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? AppColors.borderSubtle : AppColors.borderLightClean,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.rule_outlined, size: 14, color: mutedColor),
              const SizedBox(width: 6),
              Text(
                'Argument metrics',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: mutedColor,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${analysis.totalScore} / 100',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: scoreColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              _buildCriteriaChip('Relevance', '${analysis.relevanceScore}/25', isDark),
              _buildCriteriaChip('Reasoning', '${analysis.reasoningScore}/30', isDark),
              _buildCriteriaChip('Structure', '${analysis.structureScore}/25', isDark),
              _buildCriteriaChip('Clarity', '${analysis.clarityScore}/20', isDark),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            analysis.feedbackSummary,
            style: theme.textTheme.bodySmall?.copyWith(color: mutedColor),
          ),
        ],
      ),
    );
  }

  Widget _buildCriteriaChip(String label, String value, bool isDark) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceRaised : AppColors.cardLight,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isDark ? AppColors.borderSubtle : AppColors.borderLightClean,
          width: 1,
        ),
      ),
      child: Text(
        '$label: $value',
        style: theme.textTheme.labelSmall,
      ),
    );
  }

  /// Bottom text input bar with send button.
  Widget _buildInputBar(ThemeData theme, bool isDark) {
    final isDarkMode = isDark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.surface : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDarkMode ? AppColors.borderSubtle : AppColors.borderLightClean,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _textController,
              enabled: !_isSubmitting,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: 'Write your argument',
              ),
              onSubmitted: (_) => _handleSendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filled(
            onPressed: _isSubmitting ? null : () => _handleSendMessage(),
            icon: _isSubmitting
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send_rounded, size: 18),
            style: IconButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }
}
