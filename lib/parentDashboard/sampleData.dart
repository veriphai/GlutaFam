import 'models.dart';

final student = Student(name: 'Shubham', grade: '8');
const parentPresenceStreak = 3;
const studyStreak = 5;
const bestWindow = '7:30–7:45 PM';

final feed = <FeedGroup>[
  FeedGroup(
    date: DateTime(2025, 8, 21),
    items: [
      ConceptSummary(
        id: 'sci_crop_cp2',
        subject: 'Science',
        chapter: 'Ch 1 — Crop Production & Management',
        concept: 'Post-harvest: store → sell → distribute',
        gapsFound: 2,
        oneLiner:
            'Explains steps well; missed large-scale production as solution.',
        mastery: 0.60,
        confidence: 0.75,
      ),
      ConceptSummary(
        id: 'math_fraction_unlike',
        subject: 'Math',
        chapter: 'Ch 2.3 — Fractions',
        concept: 'Add unlike denominators',
        gapsFound: 1,
        oneLiner: 'Spots rule; slips at step 3 (place value).',
        mastery: 0.64,
        confidence: 0.58,
      ),
    ],
  ),
  FeedGroup(
    date: DateTime(2025, 8, 20),
    items: [
      ConceptSummary(
        id: 'sci_photo_lvdr',
        subject: 'Science',
        chapter: 'Ch 6 — Photosynthesis',
        concept: 'Light vs dark reactions',
        gapsFound: 1,
        oneLiner:
            'Great analogy; confuses ‘needs light’ vs ‘uses stored energy’.',
        mastery: 0.72,
        confidence: 0.66,
      ),
    ],
  ),
  FeedGroup(
    date: DateTime(2025, 8, 18),
    items: [
      ConceptSummary(
        id: 'math_speed_dst',
        subject: 'Math',
        chapter: 'Ch 4 — Motion',
        concept: 'Speed, distance, time',
        gapsFound: 1,
        oneLiner: 'Sets up right; skips unit conversion at end.',
        mastery: 0.70,
        confidence: 0.62,
      ),
    ],
  ),
];

final conceptDetails = <String, ConceptDetailsModel>{
  'sci_crop_cp2': ConceptDetailsModel(
    meta: ConceptMeta(
      subject: 'Science',
      chapter: 'Ch 1 — Crop Production & Management',
      concept: 'Post-harvest: store → sell → distribute',
      desc:
          'Real-world flow after harvesting—how crops reach markets reliably.',
    ),
    gaps: [
      Gap(
        id: 'g1',
        type: 'Conceptual',
        severity: 2,
        why: 'Didn’t mention large-scale production for rising population.',
        details: GapDetails(
          tutorAsk:
              'Imagine population rises but food production stays constant. What happens and how can we solve it?',
          studentText: 'people wont be able to get enough food',
          timeline: [
            TimelineEvent(t: '14:02', verdict: '❌'),
            TimelineEvent(
                t: '14:04', hint: 'Think about producing more at once'),
            TimelineEvent(
                t: '14:06', verdict: '✅', text: 'increase production at scale'),
          ],
        ),
        resolvePlanId: 'rp_cp2',
      ),
      Gap(
        id: 'g2',
        type: 'Careless',
        severity: 1,
        why: 'Skipped mentioning transport step explicitly.',
        details: GapDetails(
          tutorAsk:
              'You’ve grown wheat—what steps make it reach a city across the country?',
          studentText:
              'i need to harvest and store it properly, and then i need to sell it to the market so that it can be distributed',
          timeline: [
            TimelineEvent(t: '14:10', verdict: '❌'),
            TimelineEvent(
                t: '14:11', hint: 'How does it move from farm to market?'),
            TimelineEvent(t: '14:12', verdict: '✅', text: 'trucks, trains'),
          ],
        ),
        resolvePlanId: 'rp_cp2',
      ),
    ],
    shining: [
      ShiningMoment(
          id: 's1',
          wow: 'Explained post-harvest steps logically.',
          quote: 'harvest → store → sell → distribute'),
      ShiningMoment(
          id: 's2',
          wow: 'Correctly used ‘crop’ definition.',
          quote: 'we call it a crop of rice'),
    ],
    mastery: Mastery(start: 0.62, end: 0.78, checkpoints: [0.62, 0.70, 0.78]),
    plan: ResolvePlan(
      talk: 'Ask: Why is large-scale farming needed? Answer with ‘because…’',
      drillIds: ['cp2_q11', 'cp2_q12', 'cp2_q13'],
      realLife: 'Name 2 transport modes; which is faster and why?',
    ),
    checkpointDetails: [
      CheckpointDetails(
        id: 'C1',
        objectives: [
          'Define ‘crop’ with examples',
          'Explain producer vs consumer'
        ],
        mastery: 0.70,
        gaps: [],
        shining: [
          ShiningMoment(
              id: 'cs1',
              wow: 'Applied ‘crop’ definition',
              quote: 'we call it a crop of rice')
        ],
      ),
      CheckpointDetails(
        id: 'C2',
        objectives: [
          'Link population growth to food needs',
          'Propose solutions'
        ],
        mastery: 0.76,
        gaps: [
          Gap(
            id: 'cg1',
            type: 'Conceptual',
            severity: 2,
            why: 'Missed ‘large-scale production’',
            details: GapDetails(
              tutorAsk: 'What fixes the gap between demand and supply?',
              studentText: 'people wont be able to get enough food',
              timeline: [
                TimelineEvent(t: '14:02', verdict: '❌'),
                TimelineEvent(t: '14:04', hint: 'Produce more at once'),
                TimelineEvent(
                    t: '14:06', verdict: '✅', text: 'increase production'),
              ],
            ),
            resolvePlanId: 'rp_cp2',
          ),
        ],
        shining: [],
      ),
      CheckpointDetails(
        id: 'C3',
        objectives: [
          'List post-harvest steps',
          'Describe logistics to markets'
        ],
        mastery: 0.80,
        gaps: [
          Gap(
            id: 'cg2',
            type: 'Careless',
            severity: 1,
            why: 'Skipped ‘transport’ step',
            details: GapDetails(
              tutorAsk: 'Which step moves wheat to city markets?',
              studentText: 'sell to market',
              timeline: [
                TimelineEvent(t: '14:10', verdict: '❌'),
                TimelineEvent(t: '14:11', hint: 'How does it move?'),
                TimelineEvent(t: '14:12', verdict: '✅', text: 'trucks, trains'),
              ],
            ),
            resolvePlanId: 'rp_cp2',
          ),
        ],
        shining: [
          ShiningMoment(
              id: 'cs3',
              wow: 'Logical pipeline',
              quote: 'harvest → store → sell → distribute')
        ],
      ),
    ],
  ),
  'math_fraction_unlike': ConceptDetailsModel(
    meta: ConceptMeta(
      subject: 'Math',
      chapter: 'Ch 2.3 — Fractions',
      concept: 'Add unlike denominators',
      desc:
          'Build certainty on rewriting fractions to a common base and adding.',
    ),
    gaps: [
      Gap(
        id: 'g3',
        type: 'Conceptual',
        severity: 2,
        why: 'Loses place value at step 3.',
        details: GapDetails(
          tutorAsk: 'What must match before adding fractions?',
          studentText: '12+8 / 6',
          timeline: [
            TimelineEvent(t: '19:01', verdict: '❌'),
            TimelineEvent(t: '19:02', hint: 'Rewrite to common denominator'),
            TimelineEvent(t: '19:04', verdict: '✅', text: '7/12'),
          ],
        ),
        resolvePlanId: 'rp_frac',
      ),
    ],
    shining: [
      ShiningMoment(
          id: 's3',
          wow: 'Inferred the rule from examples.',
          quote: 'Do denominators need to match first?')
    ],
    mastery: Mastery(start: 0.52, end: 0.64, checkpoints: [0.52, 0.60, 0.64]),
    plan: ResolvePlan(
      talk: 'Ask: What changes when denominators don’t match?',
      drillIds: ['q_123', 'q_124', 'q_125'],
      realLife: 'Pour 150 mL + 100 mL; convert to L and add.',
    ),
    checkpointDetails: [
      CheckpointDetails(
          id: 'C1',
          objectives: ['Identify denominators', 'Explain need for common base'],
          mastery: 0.58,
          gaps: [],
          shining: []),
      CheckpointDetails(
          id: 'C2',
          objectives: ['Find LCM/LCD', 'Rewrite fractions'],
          mastery: 0.62,
          gaps: [],
          shining: []),
      CheckpointDetails(
          id: 'C3',
          objectives: ['Add rewritten fractions', 'Simplify'],
          mastery: 0.70,
          gaps: [],
          shining: []),
    ],
  ),
  'sci_photo_lvdr': ConceptDetailsModel(
    meta: ConceptMeta(
      subject: 'Science',
      chapter: 'Ch 6 — Photosynthesis',
      concept: 'Light vs dark reactions',
      desc:
          'Separate ‘needs light’ from ‘uses stored energy’ to avoid mix-ups.',
    ),
    gaps: [
      Gap(
        id: 'g4',
        type: 'Vocab',
        severity: 1,
        why: 'Mixes ‘needs light’ with ‘uses stored energy’.',
        details: GapDetails(
          tutorAsk:
              'Which step needs sunlight directly, and which uses stored chemical energy?',
          studentText: 'like charging a battery first, then using it',
          timeline: [
            TimelineEvent(t: '12:02', verdict: '❌'),
            TimelineEvent(t: '12:03', hint: 'Location vs requirement'),
            TimelineEvent(
                t: '12:05',
                verdict: '✅',
                text: 'Calvin cycle can run without direct light'),
          ],
        ),
        resolvePlanId: 'rp_photo',
      ),
    ],
    shining: [
      ShiningMoment(
          id: 's4',
          wow: 'Used strong analogy.',
          quote: 'solar panel by day, battery by night')
    ],
    mastery: Mastery(start: 0.66, end: 0.72, checkpoints: [0.66, 0.70, 0.72]),
    plan: ResolvePlan(
      talk:
          'Ask: Which step needs sunlight directly, and which uses stored energy?',
      drillIds: ['ph_q1', 'ph_q2', 'ph_q3'],
      realLife: 'Observe a solar lamp: charge (day) vs glow (night).',
    ),
    checkpointDetails: [
      CheckpointDetails(
          id: 'C1',
          objectives: ['Identify chlorophyll', 'Define light reaction'],
          mastery: 0.68,
          gaps: [],
          shining: []),
      CheckpointDetails(
          id: 'C2',
          objectives: ['Describe ATP/NADPH use', 'Explain Calvin cycle'],
          mastery: 0.72,
          gaps: [],
          shining: []),
    ],
  ),
  'math_speed_dst': ConceptDetailsModel(
    meta: ConceptMeta(
      subject: 'Math',
      chapter: 'Ch 4 — Motion',
      concept: 'Speed, distance, time',
      desc: 'Ensure unit checks at the end to avoid conversion mistakes.',
    ),
    gaps: [
      Gap(
        id: 'g5',
        type: 'Units',
        severity: 1,
        why: 'Skips km↔m conversion at the end.',
        details: GapDetails(
          tutorAsk: 'Are all units aligned before we compute?',
          studentText: 'Oh, I forgot to convert.',
          timeline: [
            TimelineEvent(t: '10:00', verdict: '❌'),
            TimelineEvent(t: '10:02', hint: 'Check units before answer'),
            TimelineEvent(t: '10:04', verdict: '✅', text: '36 km/h = 10 m/s'),
          ],
        ),
        resolvePlanId: 'rp_dst',
      ),
    ],
    shining: [
      ShiningMoment(
          id: 's5',
          wow: 'Sets up equations correctly.',
          quote: 'distance = speed × time')
    ],
    mastery: Mastery(start: 0.62, end: 0.70, checkpoints: [0.62, 0.68, 0.70]),
    plan: ResolvePlan(
      talk: 'Ask: Are all units aligned before we compute?',
      drillIds: ['dst1', 'dst2', 'dst3'],
      realLife: 'Track walk speed using phone distance + time.',
    ),
    checkpointDetails: [
      CheckpointDetails(
          id: 'C1',
          objectives: ['Relate variables', 'Set up formula'],
          mastery: 0.66,
          gaps: [],
          shining: []),
      CheckpointDetails(
          id: 'C2',
          objectives: ['Unit conversions'],
          mastery: 0.70,
          gaps: [],
          shining: []),
    ],
  ),
};
