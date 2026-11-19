import '../models/debate_session.dart';
import '../models/debate_topic.dart';

/// Transparent, rule-based argument analysis result.
class ArgumentAnalysis {
  final int relevanceScore; // 0 - 25
  final int reasoningScore; // 0 - 30
  final int structureScore; // 0 - 25
  final int clarityScore; // 0 - 20
  final int totalScore; // 0 - 100
  final String feedbackSummary;
  final List<String> strengthNotes;
  final List<String> improvementNotes;
  final List<String> matchedKeywords;

  const ArgumentAnalysis({
    required this.relevanceScore,
    required this.reasoningScore,
    required this.structureScore,
    required this.clarityScore,
    required this.totalScore,
    required this.feedbackSummary,
    required this.strengthNotes,
    required this.improvementNotes,
    required this.matchedKeywords,
  });
}

/// Offline, deterministic sparring partner and rule-based debate evaluation engine.
///
/// Provides:
/// 1. Coherent, curated opponent positions for all 9 Cognitive Gym debate topics.
/// 2. Transparent, rule-based feedback based on concrete rhetorical criteria
///    (Relevance, Reasoning, Structure, Clarity).
/// 3. Zero network requests, zero simulated latency, zero fabricated AI personas.
class OfflineDebateService {
  OfflineDebateService._();

  static final OfflineDebateService instance = OfflineDebateService._();

  // ---------------------------------------------------------------------------
  // 1. TOPIC VOCABULARY & KNOWLEDGE BASE
  // ---------------------------------------------------------------------------

  static const Map<String, List<String>> _topicKeywords = {
    'topic_01': [
      'patriotism', 'country', 'nation', 'unity', 'loyalty', 'citizen',
      'nationalism', 'division', 'pride', 'borders', 'global', 'identity',
      'community', 'solidarity', 'cohesion', 'sacrifice', 'history',
    ],
    'topic_02': [
      'ai', 'artificial', 'intelligence', 'dependent', 'dependence', 'skills',
      'thinking', 'human', 'creativity', 'automation', 'memory', 'cognitive',
      'tools', 'problem-solving', 'technology', 'agency', 'learning',
    ],
    'topic_03': [
      'entrepreneurship', 'employment', 'business', 'job', 'risk', 'autonomy',
      'stability', 'security', 'income', 'freedom', 'salary', 'capital',
      'innovation', 'work-life', 'career', 'market', 'startup',
    ],
    'topic_04': [
      'exams', 'intelligence', 'testing', 'standardized', 'memory', 'ability',
      'potential', 'education', 'learning', 'creativity', 'grades', 'skills',
      'holistic', 'stress', 'evaluation', 'academic', 'metrics',
    ],
    'topic_05': [
      'happiness', 'goal', 'purpose', 'meaning', 'duty', 'fulfillment',
      'hedonism', 'resilience', 'struggle', 'virtue', 'satisfaction',
      'philosophy', 'suffering', 'growth', 'responsibility', 'values',
    ],
    'topic_06': [
      'hard work', 'talent', 'effort', 'practice', 'innate', 'ability',
      'consistency', 'discipline', 'gifted', 'success', 'potential',
      'persistence', 'skill', 'mastery', 'genetics', 'achievement',
    ],
    'topic_07': [
      'voting', 'civic', 'knowledge', 'democracy', 'test', 'rights',
      'participation', 'citizens', 'government', 'suffrage', 'equality',
      'informed', 'elections', 'policy', 'disenfranchisement', 'literacy',
    ],
    'topic_08': [
      'modern', 'life', 'lonelier', 'loneliness', 'isolation', 'digital',
      'social', 'media', 'hyper-connectivity', 'community', 'connection',
      'mental health', 'relationships', 'urbanization', 'superficial',
    ],
    'topic_09': [
      'philosophy', 'mandatory', 'schools', 'ethics', 'critical thinking',
      'reasoning', 'logic', 'curriculum', 'education', 'students',
      'moral', 'societal', 'decision-making', 'analysis', 'wisdom',
    ],
  };

  // ---------------------------------------------------------------------------
  // 2. CURATED OPPONENT ARGUMENTS PER TOPIC & STANCE
  // ---------------------------------------------------------------------------

  static const Map<String, Map<DebateSide, List<String>>> _opponentArguments = {
    'topic_01': {
      DebateSide.oppose: [
        'Patriotism often serves as a dangerous catalyst for tribalism and exclusion. When national pride supersedes universal human solidarity, history demonstrates that it frequently leads to conflict, border militarization, and intolerance of internal dissent. How do you reconcile national loyalty with our broader ethical obligations as global citizens?',
        'While you emphasize unity, the empirical reality is that state-sanctioned patriotism is frequently weaponized by regimes to suppress critical domestic inquiries. If loyalty to a flag requires glossing over systemic flaws, does that genuine unity not come at the direct expense of truth and moral progress?',
        'Consider the interconnected challenges of our era—climate change, global health, and economic stability. None of these obey national borders. Isn\'t an allegiance organized around 19th-century state lines fundamentally ill-equipped for 21st-century global cooperation?',
      ],
      DebateSide.support: [
        'Healthy patriotism provides the civic glue necessary for democratic societies to function. Without a shared civic narrative and mutual commitment to a national project, communities fracture into atomized interest groups unwilling to make collective sacrifices. How do you propose maintaining democratic welfare systems without national solidarity?',
        'You argue against tribalism, but internationalism lacks actionable democratic mechanisms. We pay taxes, build public infrastructure, and protect civil rights through specific national legal compacts. Without patriotic civic pride, what motivates citizens to uphold local civic duties?',
        'Look at historic movements for domestic social justice: leaders like Martin Luther King Jr. appealed directly to the foundational ideals of their nation to demand equality. Is not civic patriotism one of the most potent levers for internal positive reform?',
      ],
    },
    'topic_02': {
      DebateSide.oppose: [
        'Artificial intelligence increasingly acts as an externalized cognitive crutch. By automating complex drafting, numerical analysis, and decision synthesis, humans are experiencing measurable cognitive atrophy in foundational reasoning and spatial recall. If we outsource our thinking to algorithms, are we truly becoming more capable, or merely more fragile?',
        'The critical issue is epistemic dependence. When people rely on automated black-box recommendations without understanding the underlying logic, they forfeit intellectual autonomy. How can society claim greater intelligence when individual users cannot audit or verify the tools they depend upon daily?',
        'Historical precedent shows that when automated systems fail, humans who have not practiced foundational tasks are helpless to intervene. Doesn\'t systemic reliance on AI create a catastrophic single-point-of-failure for human problem-solving?',
      ],
      DebateSide.support: [
        'Throughout human history, every transformative intellectual tool—from the written alphabet to arithmetic notation and search engines—was initially criticized for weakening memory. In reality, offloading mechanical cognitive tasks liberates human working memory for higher-order conceptual synthesis and creative breakthroughs. Why should AI be viewed differently?',
        'You point to dependency, but consider medical diagnostics, material science, and astrophysics. Human researchers working alongside AI models are discovering vaccines and clean energy materials at speeds that were physically impossible alone. Isn\'t that an objective expansion of human capability?',
        'Intelligence is not defined by rote manual execution; it is defined by the capacity to frame questions, discern relevance, and direct complex systems toward humane goals. Does not mastering AI elevate our intellectual leverage rather than diminish it?',
      ],
    },
    'topic_03': {
      DebateSide.oppose: [
        'The romanticization of entrepreneurship ignores economic reality: over 80% of new ventures fail within five years, often leaving founders with catastrophic financial debt and severe mental strain. Employment provides guaranteed income, healthcare security, and clear boundaries between work and life. Why should volatility be privileged over sustainable stability?',
        'Furthermore, specialized employment in large institutions enables high-impact collaboration that no solitary startup can replicate—such as launching aerospace missions or constructing major infrastructure. Isn\'t focused specialization within an organization often more productive than managing administrative startup overhead?',
        'Autonomy in entrepreneurship is frequently an illusion; founders are answerable to demanding clients, investors, and creditors 24/7. Does taking on 80-hour workweeks truly represent genuine freedom?',
      ],
      DebateSide.support: [
        'Traditional employment concentrates economic leverage in corporate hierarchies, leaving employees exposed to unilateral downsizing, wage stagnation, and capped career ceilings. Entrepreneurship directly aligns an individual\'s effort with their ownership and creative autonomy. Why should individuals rent their minds to corporate gatekeepers when they can build durable equity?',
        'Economic resilience is actually higher when an entrepreneur possesses diverse clients rather than depending on a single corporate employer who holds the power of sudden termination. Isn\'t diversification of income sources safer than single-salary reliance?',
        'True innovation throughout economic history has emerged from agile independent operators who challenged incumbent monopolies. Without entrepreneurial risk-taking, how would society prevent industrial stagnation?',
      ],
    },
    'topic_04': {
      DebateSide.oppose: [
        'Standardized exams primarily measure short-term rote memorization, test-taking privilege, and speed under stress, rather than genuine intellectual curiosity or adaptive problem-solving. In real life, professionals have open access to information and work collaboratively. How can a closed-book, timed test accurately reflect intellectual capability?',
        'High-stakes testing also creates perverse academic incentives: schools teach to the test, stifling unconventional thinking and penalizing neurodivergent minds that excel in divergent synthesis. Why defend an evaluation framework that systematically ignores creativity and interpersonal judgment?',
        'Look at modern research on grit, curiosity, and emotional intelligence—traits that correlate far more strongly with lifetime innovation than timed exam percentiles. Shouldn\'t evaluation reflect modern cognitive science rather than 19th-century factory-model metrics?',
      ],
      DebateSide.support: [
        'While imperfect, standardized exams provide an objective, blind, and egalitarian yardstick that protects against nepotism, subjective grading bias, and socio-economic prestige signaling. Without objective testing, university admissions and certifications would devolve into subjective portfolio reviews favoring candidates with wealthy connections. What alternative offers comparable objectivity?',
        'Examinations also test an indispensable cognitive discipline: the ability to assimilate foundational principles, synthesize complex material under rigorous constraints, and perform reliably under pressure. Are not focus and cognitive stamina vital components of practical intelligence?',
        'Standardized assessments allow educational systems to identify structural curriculum deficiencies and measure learning outcomes across diverse demographics. How would society detect educational inequities without standardized diagnostic data?',
      ],
    },
    'topic_05': {
      DebateSide.oppose: [
        'Prioritizing personal happiness as life\'s ultimate goal creates a fragile, self-absorbed existence. The greatest human contributions—from scientific breakthroughs to civil rights struggles—frequently demanded profound discomfort, sacrifice, and long periods of unhappiness. If duty and truth require hardship, doesn\'t a fixation on happiness undermine moral fortitude?',
        'The psychological paradox of hedonism demonstrates that pursuing happiness directly almost always leads to disappointment. Deep satisfaction is an indirect byproduct of meaningful responsibility, not an end in itself. Shouldn\'t meaning and virtue supersede emotional state?',
        'When communities face existential crises, individuals driven purely by happiness optimization are disincentivized from bearing necessary burdens. Is not resilience in the face of inevitable tragedy a higher human aim?',
      ],
      DebateSide.support: [
        'Happiness, when properly understood in the Aristotelian sense of eudaimonia (human flourishing), encompasses deep fulfillment, ethical integrity, and healthy relationships—not superficial sensory indulgence. If an action does not ultimately contribute to the flourishing of conscious beings, what rational justification gives it value?',
        'All ethical philosophies—including utilitarianism, virtue ethics, and humanism—fundamentally seek to reduce suffering and increase collective well-being. To dismiss happiness as shallow is to confuse fleeting pleasure with authentic mental health and flourishing. Why pursue any goal if its end state is misery?',
        'Psychological research confirms that happy, fulfilled individuals are demonstrably more compassionate, creative, and civically engaged. Isn\'t cultivating flourishing the foundational prerequisite for helping others effectively?',
      ],
    },
    'topic_06': {
      DebateSide.oppose: [
        'At elite competitive levels, hard work is a baseline requirement, not a differentiator. Natural genetic endowments—in processing speed, working memory capacity, spatial cognition, or physical biomechanics—place a hard ceiling on what pure effort can achieve. How can deliberate practice bridge the gap against an opponent with equal dedication plus innate genius?',
        'The belief that hard work always beats talent is a comforting meritocratic myth that can lead individuals to pursue paths where their biological or cognitive wiring is mismatched, leading to burnout. Isn\'t recognizing natural aptitudes essential for realistic self-actualization?',
        'History shows prodigies like Mozart, Ramanujan, or Gauss who displayed intuitive mastery that no amount of standard practice could replicate in ordinary peers. Doesn\'t innate talent remain the ultimate decisive factor at the summit of human achievement?',
      ],
      DebateSide.support: [
        'Untapped talent is one of the most common tragedies in human history; without obsessive discipline and grit, innate potential amounts to nothing. Conversely, consistent deliberate practice physically rewires neural pathways, expanding working memory and perceptual chunking beyond baseline talent. Why celebrate dormant potential over realized discipline?',
        'Psychologist Carol Dweck\'s research shows that fixed talent mindsets lead to fragility when faced with early failure, whereas individuals dedicated to iterative effort adapt and outpace complacent prodigies over time. Does not sustained growth outlive initial advantage?',
        'The vast majority of real-world accomplishments require perseverance, team collaboration, and emotional resilience across decades—qualities built through hard work, not genetic chance. In practice, isn\'t consistency the true driver of mastery?',
      ],
    },
    'topic_07': {
      DebateSide.oppose: [
        'Historically, every implementation of a voting qualification test—such as literacy tests in the American South—was systematically designed to disenfranchise marginalized groups, protect ruling elites, and suppress political opposition. Who gets to decide what constitutes \'correct\' civic knowledge without introducing political bias?',
        'Democratic legitimacy derives from the principle that all individuals subject to the laws of a state must have equal voice in shaping those laws, regardless of formal academic attainment. Isn\'t voting a fundamental human right rather than an earned privilege?',
        'Educated voters are just as susceptible to ideological extremism and self-interested voting as anyone else. What objective evidence suggests that a knowledge quiz produces a more ethical or compassionate democracy?',
      ],
      DebateSide.support: [
        'We require rigorous certification and licensing for driving, operating machinery, and practicing medicine because uninformed actions inflict severe collateral damage on the public. A vote directly influences macroeconomic stability, war, and public welfare. Why should voting be the only high-consequence civic power exercised without basic literacy on how government operates?',
        'A basic civic test does not need to be ideological; it could simply ensure voters understand the separation of powers, the role of each office on the ballot, and how laws are passed. Wouldn\'t a minimally informed electorate hold demagogues far more accountable?',
        'If citizens cannot evaluate basic policy mechanisms, democracy degenerates into emotional tribalism and media manipulation. Shouldn\'t society incentivize civic education as a prerequisite for stewardship of the republic?',
      ],
    },
    'topic_08': {
      DebateSide.oppose: [
        'Modern hyper-connectivity creates an illusion of intimacy that replaces deep, face-to-face community with performative, parasocial digital interactions. Urban density paired with individualized screens has led to measurable declines in close confidants and communal civic spaces. How can we call this era connected when rates of reported clinical loneliness have tripled?',
        'Digital communication strips away vocal nuance, physical proximity, and shared real-world vulnerability—the biological prerequisites for deep trust. By optimizing for convenience, hasn\'t modern society eroded the social infrastructure that keeps humans emotionally anchored?',
        'Modern work patterns—remote isolation, frequent geographic relocation, and long working hours—disrupt multi-generational family and neighborhood networks. Isn\'t chronic alienation an inevitable byproduct of hyper-individualized modern culture?',
      ],
      DebateSide.support: [
        'Before modern connectivity, individuals who differed from their immediate local geography—due to minority identities, rare interests, or intellectual inclinations—faced crushing social isolation with zero recourse. Today, anyone can find a vibrant global community of like-minded peers regardless of physical location. Isn\'t that a triumph against genuine loneliness?',
        'Loneliness is an ancient human condition thoroughly documented in literature for millennia; blaming modern tools confuses nostalgia with historical fact. Modern medicine, global travel, and instant messaging allow families and friends to remain intimately connected across continents. How does that foster isolation?',
        'The modern world also provides unprecedented access to mental health resources, support groups, and community interest hubs that were nonexistent in closed historical agrarian villages. Shouldn\'t we differentiate between the tool and how individuals choose to wield it?',
      ],
    },
    'topic_09': {
      DebateSide.oppose: [
        'School curricula are already overburdened with essential STEM literacy, practical financial skills, and foundational literacy. Abstract philosophical debates about epistemology or metaphysics do not prepare students for the practical realities of modern workforce demands. Why mandate speculative philosophy over concrete vocational skills?',
        'Mandating philosophy in public schools risks deep cultural and religious conflicts, as teaching moral philosophy can easily be perceived as state-sponsored indoctrination of specific values. Shouldn\'t ethical and philosophical instruction remain the domain of families and personal choice?',
        'Critical thinking can and should be integrated organically into existing subjects like history, literature, and science without dedicating an entire mandatory course to historical European or classical dogma. Why create an isolated academic silo?',
      ],
      DebateSide.support: [
        'In an age of algorithmically generated disinformation, deepfakes, and societal polarization, critical reasoning, formal logic, and ethical inquiry are the foundational defense mechanisms for a functioning democracy. Without philosophy, students are taught what to think, but never how to think. Why treat intellectual self-defense as optional?',
        'Every practical discipline—from computer science algorithms to bioethics, law, and corporate governance—is built upon philosophical frameworks. A society skilled only in technical execution without moral discernment is profoundly dangerous. Doesn\'t philosophy provide the compass for technological power?',
        'Children introduced to Philosophy for Children (P4C) programs show documented improvements in reading comprehension, mathematical problem-solving, and emotional self-regulation. Isn\'t rigorous critical thinking the ultimate meta-skill that enhances all other learning?',
      ],
    },
  };

  // ---------------------------------------------------------------------------
  // 3. PUBLIC API: GET OPPONENT STATEMENTS
  // ---------------------------------------------------------------------------

  /// Returns the opponent opening statement for a given topic and chosen user side.
  String getOpponentOpeningStatement({
    required DebateTopic topic,
    required DebateSide userSide,
  }) {
    final opponentSide = userSide.opposite;
    final topicArgs = _opponentArguments[topic.id];
    if (topicArgs != null && topicArgs.containsKey(opponentSide)) {
      return topicArgs[opponentSide]!.first;
    }
    // Universal fallback
    return 'I will be challenging your position on "${topic.title}". '
        'From my perspective (${opponentSide.displayName}), there are critical trade-offs '
        'and consequences that must be addressed. Please present your opening argument.';
  }

  /// Returns the opponent's round rebuttal / counter-question for a turn.
  String getOpponentRebuttal({
    required DebateTopic topic,
    required DebateSide userSide,
    required int turn,
  }) {
    final opponentSide = userSide.opposite;
    final topicArgs = _opponentArguments[topic.id];
    if (topicArgs != null && topicArgs.containsKey(opponentSide)) {
      final list = topicArgs[opponentSide]!;
      final index = (turn - 1).clamp(0, list.length - 1);
      return list[index];
    }
    return 'You have raised an interesting point, but consider the opposing perspective: '
        'how do you account for unintended consequences and systemic costs? '
        'Please formulate your counterargument.';
  }

  /// Returns the opponent closing synthesis statement.
  String getOpponentClosing({
    required DebateTopic topic,
    required DebateSide userSide,
  }) {
    return 'Thank you for this rigorous cognitive exchange. We have examined the core tensions of "${topic.title}" '
        'across multiple dimensions. A strong mind is built not by clinging to assumptions, but by fearlessly '
        'testing them against counter-evidence. Let us review the reflection and breakdown of your arguments.';
  }

  // ---------------------------------------------------------------------------
  // 4. DETERMINISTIC RULE-BASED ARGUMENT EVALUATION
  // ---------------------------------------------------------------------------

  /// Evaluates a submitted debate argument using transparent, measurable criteria:
  /// - Relevance (0-25): Topic keyword and semantic theme coverage.
  /// - Reasoning (0-30): Argument elaboration, length, and deductive connectives.
  /// - Counterargument Structure (0-25): Contrastive discourse markers and trade-off consideration.
  /// - Clarity (0-20): Type-token ratio, readability, and sentence structure.
  ArgumentAnalysis evaluateArgument({
    required String argument,
    required DebateTopic topic,
    required DebateSide userSide,
    required int turn,
  }) {
    final trimmed = argument.trim();
    if (trimmed.isEmpty) {
      return const ArgumentAnalysis(
        relevanceScore: 0,
        reasoningScore: 0,
        structureScore: 0,
        clarityScore: 0,
        totalScore: 0,
        feedbackSummary: 'No argument was provided.',
        strengthNotes: [],
        improvementNotes: ['Submit a substantive statement containing your rationale.'],
        matchedKeywords: [],
      );
    }

    final words = _tokenize(trimmed);
    final wordCount = words.length;

    // 1. RELEVANCE (0 - 25)
    final topicKeywords = _topicKeywords[topic.id] ?? [];
    final matchedKeywords = <String>{};
    for (final word in words) {
      for (final kw in topicKeywords) {
        if (word.startsWith(kw) || kw.startsWith(word)) {
          matchedKeywords.add(kw);
        }
      }
    }

    int relevanceScore;
    String relevanceNote;
    if (matchedKeywords.length >= 4) {
      relevanceScore = 25;
      relevanceNote = 'Exceptional topical alignment: deeply engaged with core themes.';
    } else if (matchedKeywords.length >= 2) {
      relevanceScore = 20;
      relevanceNote = 'Solid topical focus: explicitly references primary subject matter.';
    } else if (matchedKeywords.length == 1) {
      relevanceScore = 14;
      relevanceNote = 'Moderate alignment: mentions key concepts but could integrate more domain vocabulary.';
    } else {
      relevanceScore = 8;
      relevanceNote = 'Peripheral relevance: argument would be strengthened by directly naming topic principles.';
    }

    // 2. REASONING & ELABORATION (0 - 30)
    final causalConnectives = [
      'because', 'therefore', 'since', 'consequently', 'due to', 'leads to',
      'results in', 'implies', 'evidence', 'for example', 'as a result',
      'specifically', 'furthermore', 'proves', 'justifies', 'illustrates',
    ];
    int causalCount = 0;
    for (final conn in causalConnectives) {
      if (trimmed.toLowerCase().contains(conn)) {
        causalCount++;
      }
    }

    int reasoningScore = 0;
    // Length component (up to 15 pts)
    final lengthRatio = (wordCount / 40.0).clamp(0.0, 1.0);
    reasoningScore += (lengthRatio * 15).round();

    // Causal depth component (up to 15 pts)
    if (causalCount >= 3) {
      reasoningScore += 15;
    } else if (causalCount == 2) {
      reasoningScore += 12;
    } else if (causalCount == 1) {
      reasoningScore += 8;
    } else {
      reasoningScore += 4;
    }
    reasoningScore = reasoningScore.clamp(0, 30);

    String reasoningNote;
    if (reasoningScore >= 25) {
      reasoningScore = 30; // Clean top bracket
      reasoningNote = 'Strong deductive reasoning supported by clear causal links and elaboration.';
    } else if (reasoningScore >= 18) {
      reasoningNote = 'Clear rationale with structured logic; consider providing concrete supporting evidence.';
    } else {
      reasoningNote = 'Brief claim: substantiate your point with "because", "therefore", or illustrative examples.';
    }

    // 3. COUNTERARGUMENT STRUCTURE (0 - 25)
    final contrastiveMarkers = [
      'however', 'although', 'while', 'despite', 'on the other hand', 'critics',
      'conversely', 'even if', 'yet', 'alternatively', 'counter', 'nevertheless',
      'whereas', 'nonetheless', 'in contrast', 'opponents', 'objection',
    ];
    int contrastiveCount = 0;
    for (final marker in contrastiveMarkers) {
      if (trimmed.toLowerCase().contains(marker)) {
        contrastiveCount++;
      }
    }

    int structureScore;
    String structureNote;
    if (contrastiveCount >= 2) {
      structureScore = 25;
      structureNote = 'Excellent dialectic balance: directly challenges opposing assumptions with contrastive markers.';
    } else if (contrastiveCount == 1) {
      structureScore = 18;
      structureNote = 'Good counter-perspective structure; acknowledges opposing trade-offs.';
    } else {
      structureScore = 10;
      structureNote = 'Primarily one-sided: introduce contrast ("however", "while", "critics argue") to counter the opponent.';
    }

    // 4. CLARITY & ARTICULATION (0 - 20)
    int clarityScore = 0;
    if (words.isNotEmpty) {
      final ttr = words.toSet().length / words.length;
      if (ttr >= 0.70) {
        clarityScore += 10;
      } else if (ttr >= 0.50) {
        clarityScore += 7;
      } else {
        clarityScore += 4;
      }
    }

    // Sentence structure / length balance
    final sentences = trimmed.split(RegExp(r'[.!?]+')).where((s) => s.trim().isNotEmpty).toList();
    if (sentences.isNotEmpty) {
      final avgSentenceLength = wordCount / sentences.length;
      if (avgSentenceLength >= 8 && avgSentenceLength <= 30) {
        clarityScore += 10;
      } else {
        clarityScore += 6;
      }
    } else {
      clarityScore += 5;
    }
    clarityScore = clarityScore.clamp(0, 20);

    String clarityNote;
    if (clarityScore >= 16) {
      clarityNote = 'Articulate, diverse phrasing with well-balanced sentence cadence.';
    } else {
      clarityNote = 'Adequate clarity: strive for greater lexical variety and defined sentence boundaries.';
    }

    final total = (relevanceScore + reasoningScore + structureScore + clarityScore).clamp(0, 100);

    final strengths = <String>[];
    final improvements = <String>[];

    if (relevanceScore >= 18) {
      strengths.add(relevanceNote);
    } else {
      improvements.add(relevanceNote);
    }

    if (reasoningScore >= 20) {
      strengths.add(reasoningNote);
    } else {
      improvements.add(reasoningNote);
    }

    if (structureScore >= 18) {
      strengths.add(structureNote);
    } else {
      improvements.add(structureNote);
    }

    if (clarityScore >= 15) {
      strengths.add(clarityNote);
    } else {
      improvements.add(clarityNote);
    }

    final summary = total >= 80
        ? 'High-impact argument: rigorous reasoning and direct topical engagement.'
        : total >= 60
            ? 'Competent counterpoint: sound premise with room for deeper structural contrast.'
            : 'Developing argument: expand reasoning depth and address opposing claims directly.';

    return ArgumentAnalysis(
      relevanceScore: relevanceScore,
      reasoningScore: reasoningScore,
      structureScore: structureScore,
      clarityScore: clarityScore,
      totalScore: total,
      feedbackSummary: summary,
      strengthNotes: strengths,
      improvementNotes: improvements,
      matchedKeywords: matchedKeywords.toList(),
    );
  }

  static List<String> _tokenize(String text) {
    final clean = text
        .toLowerCase()
        .replaceAll(RegExp(r'[^\p{L}\p{N}\s]', unicode: true), ' ');
    return clean.split(RegExp(r'\s+')).where((t) => t.isNotEmpty).toList();
  }
}
