import '../services/offline_debate_service.dart';
import 'debate_message.dart';
import 'debate_topic.dart';

/// User's chosen stance in a debate session.
enum DebateSide {
  support,
  oppose,
}

extension DebateSideExtension on DebateSide {
  String get displayName {
    switch (this) {
      case DebateSide.support:
        return 'Support (In Favor)';
      case DebateSide.oppose:
        return 'Oppose (Against)';
    }
  }

  DebateSide get opposite {
    return this == DebateSide.support ? DebateSide.oppose : DebateSide.support;
  }
}

/// Active status of a debate session.
enum DebateStatus {
  notStarted,
  inProgress,
  paused,
  completed,
}

/// Session data model storing state, history, usage metrics, and final
/// performance results for a debate.
class DebateSession {
  final DebateTopic topic;
  final DebateSide userSide;
  final DebateSide aiSide;
  DebateStage currentStage;
  int currentTurn;
  final int maxTurns;
  final List<DebateMessage> messages;
  DebateStatus status;
  bool hasAwardedRewards;
  String? strongestArgument;

  /// Final normalized 0-100 performance score, set when the debate is
  /// scored and recorded via rule-based criteria.
  int? performanceScore;

  /// Transparent rule-based criteria breakdown.
  int? relevanceScore;
  int? reasoningScore;
  int? structureScore;
  int? clarityScore;
  ArgumentAnalysis? finalAnalysis;

  /// Participation XP actually earned for this completion.
  int? earnedXp;

  /// Performance-scaled logic (critical thinking) points actually earned.
  int? logicPointsEarned;

  DebateSession({
    required this.topic,
    required this.userSide,
    required this.aiSide,
    this.currentStage = DebateStage.opening,
    this.currentTurn = 1,
    this.maxTurns = 5,
    List<DebateMessage>? messages,
    this.status = DebateStatus.notStarted,
    this.hasAwardedRewards = false,
    this.strongestArgument,
  }) : messages = messages ?? [];

  /// Appends a new message to the session conversation history.
  void addMessage(DebateMessage msg) {
    messages.add(msg);
  }

  /// Increments current turn number.
  void advanceTurn() {
    currentTurn++;
  }

  /// Updates debate status.
  void updateStatus(DebateStatus newStatus) {
    status = newStatus;
  }

  /// Advances to the next debate stage based on turn progression.
  void nextStage() {
    switch (currentStage) {
      case DebateStage.opening:
        currentStage = DebateStage.rebuttal;
        break;
      case DebateStage.rebuttal:
        if (currentTurn >= maxTurns) {
          currentStage = DebateStage.closing;
        }
        break;
      case DebateStage.crossExamination:
        currentStage = DebateStage.closing;
        break;
      case DebateStage.closing:
        currentStage = DebateStage.finished;
        status = DebateStatus.completed;
        break;
      case DebateStage.finished:
        break;
    }
  }
}
