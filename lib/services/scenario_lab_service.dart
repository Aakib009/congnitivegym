import 'dart:math';
import '../models/scenario_model.dart';

/// Service providing predefined critical-thinking scenarios for Scenario Lab.
class ScenarioLabService {
  ScenarioLabService._();

  static final Random _random = Random();

  /// Repository of 10 rich, non-political, thought-provoking dilemmas.
  static final List<ScenarioModel> _scenarios = [
    // 1. Village Budget Crisis (Community Leadership)
    const ScenarioModel(
      id: 'sc_01',
      title: 'Village Budget Crisis',
      role: 'Village Leader',
      category: 'Community Leadership',
      imagePath: 'assets/images/Scenario/VillageBudgetCrisis.jpeg',
      background:
          'Your village has received ₹50,000 in emergency development funding. However, the village faces two critical infrastructure crises simultaneously: the main bridge connecting the village to the market is damaged, and the local primary school lacks basic learning materials and desks.',
      objective:
          'Allocate the emergency funds to address the village\'s pressing needs.',
      constraints:
          'The ₹50,000 budget is strictly sufficient to solve only ONE problem completely. Partial funding of both will leave both projects incomplete and non-functional.',
      options: [
        ScenarioOption(
          id: 'opt_a',
          title: 'Option A: Repair the Market Bridge',
          description:
              'Direct the entire ₹50,000 emergency fund toward restoring the damaged market bridge.',
          consequence:
              'Transportation and market access improve immediately. Local farmers and traders can sell produce without delay, boosting village commerce. However, students continue studying in overcrowded classrooms without adequate learning materials.',
          strengths: [
            'Immediate economic stimulus for farmers & local traders',
            'Restores vital transport safety for all villagers',
            'Generates revenue that could support future village needs',
          ],
          weaknesses: [
            'Leaves primary school students without essential supplies',
            'Delays educational growth for the next generation',
          ],
        ),
        ScenarioOption(
          id: 'opt_b',
          title: 'Option B: Fund the Local School',
          description:
              'Allocate the ₹50,000 emergency fund to furnish classrooms and procure essential learning materials.',
          consequence:
              'Students receive modern desks, textbooks, and learning supplies, greatly elevating educational quality. However, transport issues persist, forcing traders to take long detours that lower daily earnings.',
          strengths: [
            'Invests in long-term human development and youth literacy',
            'Improves daily learning conditions for children',
            'Fosters long-term community empowerment',
          ],
          weaknesses: [
            'Leaves trade route disrupted, straining local commerce',
            'Increases daily transit costs for farmers',
          ],
        ),
      ],
    ),

    // 2. Startup Launch Dilemma (Business Decisions)
    const ScenarioModel(
      id: 'sc_02',
      title: 'Startup Launch Dilemma',
      role: 'Product Lead',
      category: 'Business Decisions',
      imagePath: 'assets/images/Scenario/StartUpLaunchDilemma.jpeg',
      background:
          'Your eco-tech startup has spent 12 months developing a smart solar energy monitor. The scheduled investor launch date is in 3 days. Quality testing revealed minor UI latency and occasional sync delays in edge conditions.',
      objective:
          'Decide whether to launch on schedule or delay for further optimization.',
      constraints:
          'Delaying launch will miss the industry summit and risk investor confidence. Launching now means early users may experience minor technical glitches.',
      options: [
        ScenarioOption(
          id: 'opt_a',
          title: 'Option A: Launch on Schedule',
          description:
              'Proceed with the scheduled summit launch and release immediate over-the-air patches.',
          consequence:
              'You capture major press coverage and secure second-round funding interest. However, early adopters log complaints about initial sync delays.',
          strengths: [
            'Capitalizes on peak industry summit exposure',
            'Secures critical investor timeline milestones',
            'Gathers real-world user feedback quickly',
          ],
          weaknesses: [
            'Risks early brand reputation among perfectionists',
            'Requires rapid emergency hotfix deployments',
          ],
        ),
        ScenarioOption(
          id: 'opt_b',
          title: 'Option B: Postpone Launch by 3 Weeks',
          description:
              'Delay the public launch to thoroughly polish performance and fix edge-case bugs.',
          consequence:
              'The product launches flawlessly with stellar stability reviews. However, you miss the industry summit press surge and face investor scrutiny over timeline delays.',
          strengths: [
            'Delivers a rock-solid, premium user experience',
            'Protects long-term brand credibility',
            'Reduces customer support burden post-launch',
          ],
          weaknesses: [
            'Misses major media momentum at industry summit',
            'Strains investor trust regarding schedule commitments',
          ],
        ),
      ],
    ),

    // 3. Overworked Team Member (Team Management)
    const ScenarioModel(
      id: 'sc_03',
      title: 'Overworked Team Member',
      role: 'Engineering Manager',
      category: 'Team Management',
      imagePath: 'assets/images/Scenario/OverworkedTeamMember.jpeg',
      background:
          'Your senior architect is carrying the heaviest workload for a client deliverable due next week. They show clear signs of exhaustion, but their expertise is essential to complete the core security module.',
      objective:
          'Protect team wellbeing while fulfilling client deliverables.',
      constraints:
          'Reassigning the security module to junior engineers will slow delivery by 5 days. Keeping the architect at full pace risks severe burnout.',
      options: [
        ScenarioOption(
          id: 'opt_a',
          title: 'Option A: Extend Client Deadline by 5 Days',
          description:
              'Request a deadline extension from the client and mandate immediate rest for the architect.',
          consequence:
              'The senior architect recovers energy and feels valued by management. However, the client expresses disappointment over the schedule adjustment.',
          strengths: [
            'Prioritizes mental health and prevents senior talent churn',
            'Ensures thorough security review without rushing',
            'Demonstrates human-centric leadership',
          ],
          weaknesses: [
            'Temporarily weakens client satisfaction',
            'May incur minor contractual penalty fees',
          ],
        ),
        ScenarioOption(
          id: 'opt_b',
          title: 'Option B: Pair Junior Engineers to Assist',
          description:
              'Pair 2 junior engineers immediately to offload non-critical tasks while keeping the deadline intact.',
          consequence:
              'The project finishes on schedule and junior engineers gain valuable mentorship. However, the senior architect still works long hours conducting reviews.',
          strengths: [
            'Meets client deadline commitments on time',
            'Accelerates junior team skill development',
            'Avoids contractual penalty clauses',
          ],
          weaknesses: [
            'Senior architect still bears significant review stress',
            'Requires intense coordination effort during crunch time',
          ],
        ),
      ],
    ),

    // 4. Ancient Forest Conservation (Environmental Choices)
    const ScenarioModel(
      id: 'sc_04',
      title: 'Ancient Forest Conservation',
      role: 'Forest Ranger Chief',
      category: 'Environmental Choices',
      imagePath: 'assets/images/Scenario/AncientForestConversation.jpeg',
      background:
          'An ancient oak woodland sanctuary faces invasive plant encroachment. Eco-tourist access generates revenue that funds sanctuary maintenance, but foot traffic accelerates soil erosion around ancient root systems.',
      objective:
          'Preserve the ancient forest ecosystem while maintaining maintenance funding.',
      constraints:
          'Closing trails protects roots but cuts sanctuary funding by 60%. Allowing full access maintains revenue but worsens soil erosion.',
      options: [
        ScenarioOption(
          id: 'opt_a',
          title: 'Option A: Restrict Access to Guided Groups Only',
          description:
              'Limit visitor entry to small, guided eco-tours on raised boardwalks.',
          consequence:
              'Soil erosion drops by 80% and root health recovers rapidly. However, visitor capacity decreases, reducing revenue and requiring staff budget cuts.',
          strengths: [
            'Drastically reduces physical impact on ancient roots',
            'Offers high-quality educational experience for visitors',
            'Ensures long-term ecological preservation',
          ],
          weaknesses: [
            'Reduces overall visitor revenue by 40%',
            'May require temporary reductions in seasonal park staff',
          ],
        ),
        ScenarioOption(
          id: 'opt_b',
          title: 'Option B: Maintain Open Trails with Eco-Maintenance Fee',
          description:
              'Keep trails open while charging a small conservation fee dedicated to root reinforcement.',
          consequence:
              'Funding remains strong, enabling continuous path maintenance. However, high visitor volume continues to strain fragile perimeter flora.',
          strengths: [
            'Sustains full operating revenue for conservation work',
            'Keeps nature accessible to all community members',
            'Funds active soil restoration projects',
          ],
          weaknesses: [
            'High foot traffic continues impacting sensitive root zones',
            'Requires ongoing, labor-intensive trail repairs',
          ],
        ),
      ],
    ),

    // 5. Emergency Relief Distribution (Disaster Response)
    const ScenarioModel(
      id: 'sc_05',
      title: 'Emergency Relief Distribution',
      role: 'Disaster Relief Coordinator',
      category: 'Disaster Response',
      imagePath: 'assets/images/Scenario/ReliefDistribution.jpeg',
      background:
          'Following a severe flash flood, your relief team reaches a crossroads. District North has widespread mild food shortages affecting 2,000 people. District South has 300 injured residents in urgent need of field medical care.',
      objective:
          'Deploy limited transport vehicles to maximize relief impact.',
      constraints:
          'You have only 4 transport trucks available today. Road conditions prevent splitting the convoy efficiently.',
      options: [
        ScenarioOption(
          id: 'opt_a',
          title: 'Option A: Dispatch Convoy to District South (Medical Urgency)',
          description:
              'Focus all 4 trucks on delivering medical supplies and field doctors to District South.',
          consequence:
              '300 injured victims receive life-saving medical treatment immediately. Meanwhile, residents in District North endure food shortages for another 24 hours.',
          strengths: [
            'Saves critically injured lives in urgent medical need',
            'Prevents secondary infections and trauma complications',
            'Addresses highest immediate mortality threat',
          ],
          weaknesses: [
            'Leaves 2,000 residents waiting longer for food supplies',
            'Increases anxiety in surrounding unassisted communities',
          ],
        ),
        ScenarioOption(
          id: 'opt_b',
          title: 'Option B: Dispatch Convoy to District North (Widespread Need)',
          description:
              'Deploy supplies to District North to stabilize food security for 2,000 citizens.',
          consequence:
              'Hunger relief reaches 2,000 citizens, preventing widespread panic. However, injured residents in District South must rely on basic local first-aid.',
          strengths: [
            'Provides essential nutrition to the largest number of citizens',
            'Prevents social unrest and food panic across the region',
            'Establishes stable supply distribution hub',
          ],
          weaknesses: [
            'Delays critical specialized medical care for trauma victims',
            'Risks health complications for severely injured residents',
          ],
        ),
      ],
    ),

    // 6. Family Relocation Dilemma (Family Situations)
    const ScenarioModel(
      id: 'sc_06',
      title: 'Family Relocation Dilemma',
      role: 'Family Head',
      category: 'Family Situations',
      imagePath: 'assets/images/Scenario/FamilyReallocation.jpeg',
      background:
          'You have received a career-defining job offer in a bustling coastal city with a 40% salary raise. However, your teenage daughter is in her final high school year with deep local friendships and academic momentum.',
      objective:
          'Balance career advancement with family emotional well-being.',
      constraints:
          'Relocating now disrupts your daughter\'s senior school year. Declining means forfeiting a rare executive leadership advancement opportunity.',
      options: [
        ScenarioOption(
          id: 'opt_a',
          title: 'Option A: Accept Job & Relocate Immediately',
          description:
              'Accept the promotion and move the family to the coastal city before the school term starts.',
          consequence:
              'Family financial security improves significantly, funding long-term college funds. However, your daughter faces difficult emotional adjustment in a new school.',
          strengths: [
            'Provides long-term financial stability for family future',
            'Unlocks significant executive career trajectory',
            'Exposes family to vibrant new cultural opportunities',
          ],
          weaknesses: [
            'Disrupts daughter\'s senior high school social environment',
            'Adds temporary emotional stress during transition',
          ],
        ),
        ScenarioOption(
          id: 'opt_b',
          title: 'Option B: Decline Offer & Stay Until Graduation',
          description:
              'Decline the offer to let your daughter complete her senior year in her current school.',
          consequence:
              'Your daughter thrives academically and socially during her final year. However, you remain in your current role with slower career growth.',
          strengths: [
            'Preserves emotional stability during crucial academic year',
            'Maintains supportive local community relationships',
            'Demonstrates parental sacrifice and empathy',
          ],
          weaknesses: [
            'Forfeits substantial income enhancement and college savings',
            'May delay executive career progression by several years',
          ],
        ),
      ],
    ),

    // 7. Product Safety Recall (Ethical Dilemmas)
    const ScenarioModel(
      id: 'sc_07',
      title: 'Product Safety Recall',
      role: 'Quality Assurance Director',
      category: 'Ethical Dilemmas',
      imagePath: 'assets/images/Scenario/ProductSafety.jpeg',
      background:
          'Internal audit discovers a rare heating defect in 0.5% of smart thermostats produced last quarter. The defect poses no fire hazard but causes device shutdown in extreme cold snaps.',
      objective:
          'Address the product defect responsibly while managing company impact.',
      constraints:
          'A full public recall costs ₹2 Crore and risks brand reputation. A targeted free replacement program resolves complaints as they arise.',
      options: [
        ScenarioOption(
          id: 'opt_a',
          title: 'Option A: Issue a Voluntary Public Recall',
          description:
              'Announce a voluntary public recall and offer free replacements to all 50,000 customers.',
          consequence:
              'Customers and consumer groups praise the company\'s transparency and safety ethics. However, quarterly profit margins suffer severe impact.',
          strengths: [
            'Demonstrates uncompromising commitment to safety and ethics',
            'Eliminates all risk of customer heating failures',
            'Builds deep long-term consumer trust',
          ],
          weaknesses: [
            'Incurs heavy financial losses for the quarter',
            'Creates temporary negative press around hardware defects',
          ],
        ),
        ScenarioOption(
          id: 'opt_b',
          title: 'Option B: Targeted Outreach & Proactive Replacements',
          description:
              'Contact customers in cold climate zones directly for proactive replacement while maintaining quiet service upgrades elsewhere.',
          consequence:
              'Financial impact is contained, and high-risk customers receive immediate hardware updates. However, low-risk users receive delayed upgrades.',
          strengths: [
            'Protects high-risk customers swiftly and efficiently',
            'Minimizes unnecessary financial disruption',
            'Allows controlled customer support handling',
          ],
          weaknesses: [
            'Differs from full public disclosure standards',
            'Risks public criticism if uncontacted units experience issues',
          ],
        ),
      ],
    ),

    // 8. Water Drought Allocation (Resource Allocation)
    const ScenarioModel(
      id: 'sc_08',
      title: 'Water Drought Allocation',
      role: 'Regional Water Officer',
      category: 'Resource Allocation',
      imagePath: 'assets/images/Scenario/WaterDroughtAllocation.jpeg',
      background:
          'A heatwave has reduced reservoir levels to 30%. You must allocate remaining water reserves between agricultural irrigation for local farms and urban domestic supply for the city.',
      objective:
          'Balance municipal drinking water needs against agricultural crop survival.',
      constraints:
          'Prioritizing agriculture risks urban water rationing. Prioritizing cities risks crop failure for 500 local farming families.',
      options: [
        ScenarioOption(
          id: 'opt_a',
          title: 'Option A: 60% Municipal / 40% Agriculture Split',
          description:
              'Ensure urban drinking reserves remain secure while providing partial irrigation to farms.',
          consequence:
              'Cities avoid strict rationing. Farmers lose 30% of crop yield but preserve core perennial crops.',
          strengths: [
            'Guarantees safe drinking water for city populations',
            'Prevents urban health & sanitation emergencies',
            'Provides partial survival water for crops',
          ],
          weaknesses: [
            'Farmers experience moderate economic loss from reduced yield',
            'Increases local food prices temporarily',
          ],
        ),
        ScenarioOption(
          id: 'opt_b',
          title: 'Option B: 50% / 50% Equal Emergency Split',
          description:
              'Divide remaining water reserves equally between agricultural channels and municipal reservoirs.',
          consequence:
              'Farmers save 90% of crops, securing rural livelihoods. However, cities must implement mandatory night-time water supply restrictions.',
          strengths: [
            'Protects farmer livelihoods and food production',
            'Maintains local agricultural economic stability',
            'Shares hardship equitably across urban and rural sectors',
          ],
          weaknesses: [
            'Requires urban residents to adapt to scheduled water cuts',
            'Strains municipal commercial operations',
          ],
        ),
      ],
    ),

    // 9. Project Scope Creep (Workplace Conflicts)
    const ScenarioModel(
      id: 'sc_09',
      title: 'Project Scope Creep',
      role: 'Project Manager',
      category: 'Workplace Conflicts',
      imagePath: 'assets/images/Scenario/ProjectScopeCreep.jpeg',
      background:
          'Midway through software development, a key stakeholder requests 3 new analytics features. Your team is already working at full capacity to meet the agreed launch date.',
      objective:
          'Manage scope requests while maintaining team performance and deadline integrity.',
      constraints:
          'Adding features without deadline adjustment causes team crunch. Rejecting features risks stakeholder dissatisfaction.',
      options: [
        ScenarioOption(
          id: 'opt_a',
          title: 'Option A: Defer New Features to Phase 2',
          description:
              'Lock the current scope for launch and schedule new analytics features for a dedicated Phase 2 update.',
          consequence:
              'The team delivers a polished product on schedule without overtime burn out. The stakeholder accepts the roadmap plan reluctantly.',
          strengths: [
            'Protects core product quality and team stamina',
            'Meets original timeline and budget targets',
            'Establishes clear product versioning discipline',
          ],
          weaknesses: [
            'Delays stakeholder\'s desired analytics capabilities',
            'Requires ongoing stakeholder communication management',
          ],
        ),
        ScenarioOption(
          id: 'opt_b',
          title: 'Option B: Swap Non-Essential Features for Analytics',
          description:
              'Negotiate to swap 2 minor original features with the requested analytics features to keep scope neutral.',
          consequence:
              'The stakeholder gets top-priority analytics on launch day. However, secondary user workflows are postponed.',
          strengths: [
            'Fulfills critical stakeholder strategic priority',
            'Maintains original release date commitments',
            'Demonstrates agile flexibility in execution',
          ],
          weaknesses: [
            'Omits previously promised minor feature enhancements',
            'Requires quick task reassignment during sprint',
          ],
        ),
      ],
    ),

    // 10. Exam Preparation Strategy (Time Management)
    const ScenarioModel(
      id: 'sc_10',
      title: 'Exam Preparation Strategy',
      role: 'Student Representative',
      category: 'Time Management',
      imagePath: 'assets/images/Scenario/ExamPreparation.jpeg',
      background:
          'With 48 hours remaining before major comprehensive exams, you must structure your final revision block. You can either focus deeply on mastering 3 weak complex topics or conduct high-level revision across all 8 subjects.',
      objective:
          'Optimize study strategy for maximum cognitive retention and performance.',
      constraints:
          'Time is insufficient to complete deep mastery across all 8 subjects.',
      options: [
        ScenarioOption(
          id: 'opt_a',
          title: 'Option A: Deep Conceptual Mastery (3 Weak Areas)',
          description:
              'Dedicating 80% of remaining time to fully mastering your 3 weakest technical subjects.',
          consequence:
              'You score top marks on high-difficulty questions in those 3 subjects. However, your performance on minor questions in other subjects is average.',
          strengths: [
            'Eliminates major knowledge gaps in difficult subjects',
            'Builds confidence in complex problem solving',
            'Ensures mastery over high-weightage questions',
          ],
          weaknesses: [
            'Leaves less revision time for familiar subjects',
            'Risks minor errors on simple recall questions elsewhere',
          ],
        ),
        ScenarioOption(
          id: 'opt_b',
          title: 'Option B: Balanced Comprehensive Review (All 8 Subjects)',
          description:
              'Divide study time equally into 8 structured review blocks for complete curriculum coverage.',
          consequence:
              'You recall key formulas and definitions across all subjects consistently. However, highly complex analytical questions remain challenging.',
          strengths: [
            'Ensures complete coverage across entire syllabus',
            'Maximizes score potential on standard questions',
            'Reduces test anxiety through broad preparedness',
          ],
          weaknesses: [
            'Doesn\'t resolve deep conceptual bottlenecks in hard topics',
            'May limit top-tier performance on complex questions',
          ],
        ),
      ],
    ),
  ];

  /// Returns all available scenarios.
  static List<ScenarioModel> getAllScenarios() {
    return List<ScenarioModel>.from(_scenarios);
  }

  /// Selects a random scenario from the repository.
  static ScenarioModel getRandomScenario() {
    final index = _random.nextInt(_scenarios.length);
    return _scenarios[index];
  }

  /// Fetches a scenario by ID or returns the first scenario if not found.
  static ScenarioModel getScenarioById(String id) {
    return _scenarios.firstWhere(
      (s) => s.id == id,
      orElse: () => _scenarios.first,
    );
  }
}
