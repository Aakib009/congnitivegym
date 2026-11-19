import 'package:flutter/material.dart';
import '../models/debate_topic.dart';

/// Predefined repository of curated Debate Arena topics.
class DebateArenaService {
  DebateArenaService._();

  static const List<DebateTopic> _topics = [
    DebateTopic(
      id: 'topic_01',
      title: 'Is patriotism beneficial or harmful?',
      category: 'Ethics & Society',
      icon: Icons.flag_outlined,
      description: 'Explore how love for one\'s country can inspire unity while also raising questions about division and identity.',
      imagePath: 'assets/images/PetriotsimDebate.jpeg',
    ),
    DebateTopic(
      id: 'topic_02',
      title: 'Will AI make humanity more intelligent or more dependent?',
      category: 'Tech & Future',
      icon: Icons.smart_toy_outlined,
      description: 'Consider whether artificial intelligence enhances human potential or gradually reduces independent thinking.',
      imagePath: 'assets/images/HumanityDepnedentOrIntellgentDebate.jpeg',
    ),
    DebateTopic(
      id: 'topic_03',
      title: 'Is entrepreneurship better than employment?',
      category: 'Career & Life',
      icon: Icons.work_outline_rounded,
      description: 'Compare the autonomy and risk of building your own business against the stability and structure of employment.',
      imagePath: 'assets/images/EntrepreneuarVsEmployment.jpeg',
    ),
    DebateTopic(
      id: 'topic_04',
      title: 'Are exams outdated measures of intelligence?',
      category: 'Education',
      icon: Icons.school_outlined,
      description: 'Examine whether standardized testing accurately reflects human potential or restricts holistic problem-solving.',
      imagePath: 'assets/images/ExamsOutdatedDebate.jpeg',
    ),
    DebateTopic(
      id: 'topic_05',
      title: 'Should happiness be life\'s ultimate goal?',
      category: 'Philosophy',
      icon: Icons.favorite_border_rounded,
      description: 'Differentiate between seeking personal fulfillment and prioritizing duty, resilience, or deeper purpose.',
      imagePath: 'assets/images/HappinessDebate.jpeg',
    ),
    DebateTopic(
      id: 'topic_06',
      title: 'Can hard work beat talent?',
      category: 'Growth & Mindset',
      icon: Icons.fitness_center_outlined,
      description: 'Reflect on whether consistent effort and deliberate practice can overcome innate natural ability.',
      imagePath: 'assets/images/HardworkVsTalentDebate.jpeg',
    ),
    DebateTopic(
      id: 'topic_07',
      title: 'Should voting require basic civic knowledge?',
      category: 'Governance',
      icon: Icons.how_to_vote_outlined,
      description: 'Weigh the principles of equal democratic participation against the value of informed civic decision-making.',
      imagePath: 'assets/images/VotingDebate.jpeg',
    ),
    DebateTopic(
      id: 'topic_08',
      title: 'Does modern life make people lonelier?',
      category: 'Society & Well-being',
      icon: Icons.people_outline_rounded,
      description: 'Question whether digital hyper-connectivity brings communities closer or isolates individuals in daily life.',
      imagePath: 'assets/images/ModernLifeDebate.jpeg',
    ),
    DebateTopic(
      id: 'topic_09',
      title: 'Should philosophy be mandatory in schools?',
      category: 'Education & Ethics',
      icon: Icons.psychology_outlined,
      description: 'Evaluate whether teaching ethics, logic, and critical reasoning from an early age strengthens societal thinking.',
      imagePath: 'assets/images/PhilosophyDebate.jpeg',
    ),
  ];

  /// Returns all available debate topics.
  static List<DebateTopic> getAllTopics() {
    return List<DebateTopic>.from(_topics);
  }

  /// Fetches a debate topic by ID or returns the first topic if not found.
  static DebateTopic getTopicById(String id) {
    return _topics.firstWhere(
      (t) => t.id == id,
      orElse: () => _topics.first,
    );
  }
}
