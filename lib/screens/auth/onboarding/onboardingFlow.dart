// OnboardingFlow — the 3-question personalization flow every NEW user walks
// through right after their first successful sign-in (and phone capture):
//
//     1. Name       "What should we call you?"   (pre-filled for Google/Apple)
//     2. Age group  "How old are you?"           (tap → auto-advance)
//     3. Interests  "What makes you go WOW?"     (pick 3+)
//
// then hands the answers to BuildingUniverseScreen, which submits them to
// the backend behind a personalized "building your universe" moment and
// lands the user on CareerHomeScreen with confetti.
//
// Design notes (premium-onboarding research, June 2026 — Duolingo/Headspace
// patterns):
//   • one question per screen, animated segmented progress at the top
//   • single-select auto-advances (no extra "Next" tap), multi-select CTA
//   • the name is used immediately on the next screen's headline
//   • haptics on every selection, spring pops on chips/cards
//
// Re-entry safety: OnboardingPending marks a SharedPreferences flag when the
// flow mounts and BuildingUniverseScreen clears it on success (or explicit
// skip). AuthGate checks the flag, so a user who kills the app mid-onboarding
// resumes here instead of slipping into home half-onboarded.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../apis/howwow/howwowSession.dart';
import '../../../utils/howwowEventLogger.dart';
import '../../../utils/howwowEventNames.dart';
import '../../home/career/careerTheme.dart';
import '../../home/career/cosmicBackground.dart';
import 'buildingUniverseScreen.dart';

// ── flow data ────────────────────────────────────────────────────────────

/// Mutable bag of answers carried across the steps and handed to
/// [BuildingUniverseScreen] for submission.
class OnboardingAnswers {
  String name = '';
  String ageGroup = '';
  final Set<String> interests = {};
}

class OnboardingOption {
  const OnboardingOption(this.id, this.emoji, this.label);
  final String id;
  final String emoji;
  final String label;
}

const List<OnboardingOption> kOnboardingAgeGroups = [
  OnboardingOption('under-11', '🌱', 'Under 11'),
  OnboardingOption('11-13', '🚀', '11 – 13'),
  OnboardingOption('14-16', '🔭', '14 – 16'),
  OnboardingOption('17-plus', '🌟', '17+'),
];

/// The curiosity chips. Ids are what's sent to the backend; labels feed the
/// personalized copy on the building screen.
const List<OnboardingOption> kOnboardingInterests = [
  OnboardingOption('space-rockets', '🚀', 'Space & Rockets'),
  OnboardingOption('robots-ai', '🤖', 'Robots & AI'),
  OnboardingOption('medicine', '🩺', 'Medicine'),
  OnboardingOption('science', '🧪', 'Science Experiments'),
  OnboardingOption('art-design', '🎨', 'Art & Design'),
  OnboardingOption('sports', '🏏', 'Sports'),
  OnboardingOption('business', '💼', 'Business & Startups'),
  OnboardingOption('nature-animals', '🦁', 'Nature & Animals'),
  OnboardingOption('movies-stories', '🎬', 'Movies & Stories'),
  OnboardingOption('gadgets-tech', '📱', 'Gadgets & Tech'),
  OnboardingOption('music', '🎵', 'Music'),
  OnboardingOption('food-cooking', '🍳', 'Food & Cooking'),
];

const int kMinInterests = 3;

// ── pending flag (resume-on-relaunch) ────────────────────────────────────

class OnboardingPending {
  OnboardingPending._();
  static const _key = 'howwowOnboardingPending';

  static Future<void> mark() async =>
      (await SharedPreferences.getInstance()).setBool(_key, true);

  static Future<void> clear() async =>
      (await SharedPreferences.getInstance()).remove(_key);

  static Future<bool> isPending() async =>
      (await SharedPreferences.getInstance()).getBool(_key) ?? false;
}

// ── flow ─────────────────────────────────────────────────────────────────

class OnboardingFlow extends StatefulWidget {
  const OnboardingFlow({super.key});

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow> {
  final _answers = OnboardingAnswers();
  final _page = PageController();
  late final TextEditingController _nameController;
  int _step = 0;

  static const _stepCount = 3;

  @override
  void initState() {
    super.initState();
    // Resume safety — cleared by BuildingUniverseScreen on success/skip.
    OnboardingPending.mark();
    HowwowEventLogger.instance.log(HowwowEvents.onboardingStarted);
    // Google/Apple users arrive with a provider name — pre-fill, let them
    // confirm or edit. Phone users start blank.
    final p = HowwowSession.instance.profile;
    final prefill =
        (p?.firstName ?? p?.displayName?.split(' ').first ?? '').trim();
    _nameController = TextEditingController(text: prefill);
  }

  @override
  void dispose() {
    _page.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _goTo(int step) {
    // Dismiss the name-field keyboard before transitioning. Without this the
    // step-0 keyboard lingers over step 1, and the Android back gesture used
    // to close it gets caught by PopScope (canPop is false past step 0) and
    // walks the step back instead of just dismissing the keyboard.
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _step = step);
    _page.animateToPage(
      step,
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
    );
  }

  static const _stepNames = ['name', 'age_group', 'interests'];

  void _next() {
    HapticFeedback.mediumImpact();
    HowwowEventLogger.instance.log(
      HowwowEvents.onboardingStepCompleted,
      props: {'step': _stepNames[_step]},
    );
    if (_step < _stepCount - 1) {
      _goTo(_step + 1);
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => BuildingUniverseScreen(_answers)),
      );
    }
  }

  void _back() {
    if (_step == 0) return;
    HapticFeedback.lightImpact();
    _goTo(_step - 1);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // System back walks the steps; on step 0 there's nowhere to go (the
      // login stack was cleared), so let it fall through to the OS.
      canPop: _step == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: Scaffold(
        backgroundColor: CareerColors.bgMid,
        body: Stack(
          children: [
            const Positioned.fill(child: CosmicBackground()),
            SafeArea(
              child: Column(
                children: [
                  _topBar(),
                  Expanded(
                    child: PageView(
                      controller: _page,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _NameStep(
                          controller: _nameController,
                          onContinue: (name) {
                            _answers.name = name;
                            _next();
                          },
                        ),
                        _AgeStep(
                          name: () => _answers.name,
                          selectedId: () => _answers.ageGroup,
                          onSelect: (id) {
                            setState(() => _answers.ageGroup = id);
                            // Let the selection pop land, then auto-advance —
                            // single-selects shouldn't need a "Next" tap.
                            Future.delayed(const Duration(milliseconds: 420),
                                () {
                              if (mounted && _step == 1) _next();
                            });
                          },
                        ),
                        _InterestsStep(
                          selected: _answers.interests,
                          onToggle: (id) {
                            setState(() {
                              _answers.interests.contains(id)
                                  ? _answers.interests.remove(id)
                                  : _answers.interests.add(id);
                            });
                          },
                          onContinue: _next,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Back chevron + 3 animated progress segments. The chevron fades out on
  /// step 0 (the auth stack behind us is gone) but keeps its slot so the
  /// segments never jump.
  Widget _topBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 10, 24, 4),
      child: Row(
        children: [
          AnimatedOpacity(
            opacity: _step == 0 ? 0 : 1,
            duration: const Duration(milliseconds: 250),
            child: IconButton(
              onPressed: _step == 0 ? null : _back,
              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white70, size: 20),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Row(
              children: List.generate(_stepCount, (i) {
                final filled = i <= _step;
                return Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 420),
                    curve: Curves.easeOutCubic,
                    height: 5,
                    margin: EdgeInsets.only(right: i == _stepCount - 1 ? 0 : 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(3),
                      color: filled
                          ? CareerColors.gold
                          : Colors.white.withValues(alpha: 0.14),
                      boxShadow: filled
                          ? [
                              BoxShadow(
                                color:
                                    CareerColors.gold.withValues(alpha: 0.45),
                                blurRadius: 8,
                              ),
                            ]
                          : null,
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(width: 44), // visual balance for the chevron slot
        ],
      ),
    );
  }
}

// ── shared pieces ────────────────────────────────────────────────────────

/// The flow's primary CTA — same gold pill language as WelcomeScreen so the
/// whole journey from video → login → onboarding reads as one product.
class GoldCta extends StatelessWidget {
  const GoldCta({super.key, required this.label, this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: CareerColors.gold,
          foregroundColor: CareerColors.onLight,
          disabledBackgroundColor: Colors.white.withValues(alpha: 0.08),
          disabledForegroundColor: Colors.white38,
          padding: const EdgeInsets.symmetric(vertical: 18),
          // Rounded rectangle (was a 32-radius pill) — matches the rest
          // of the auth-flow CTAs.
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: onTap == null ? 0 : 6,
          shadowColor: CareerColors.gold.withValues(alpha: 0.55),
        ),
        child: Text(
          label,
          // Toned down from 20.5 / w700 to match the calmer auth-button
          // label used across the login + phone screens.
          style:
              GoogleFonts.poppins(fontSize: 15.5, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }
}

/// Headline + supporting line, staggered in on every step entrance.
class _StepHeader extends StatelessWidget {
  const _StepHeader({required this.title, required this.subtitle, this.lead});

  /// Optional small line above the headline (e.g. "Nice to meet you, Aarav!").
  final Widget? lead;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (lead != null) ...[
          lead!.animate().fadeIn(duration: 350.ms).slideY(begin: 0.2),
          const SizedBox(height: 10),
        ],
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 30,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            height: 1.15,
          ),
        ).animate().fadeIn(duration: 400.ms, delay: 60.ms).slideY(begin: 0.18),
        const SizedBox(height: 10),
        Text(
          subtitle,
          style: GoogleFonts.poppins(
            fontSize: 14.5,
            color: CareerColors.textSecondary,
            height: 1.45,
          ),
        ).animate().fadeIn(duration: 400.ms, delay: 140.ms).slideY(begin: 0.18),
      ],
    );
  }
}

// ── step 1: name ─────────────────────────────────────────────────────────

class _NameStep extends StatefulWidget {
  const _NameStep({required this.controller, required this.onContinue});

  final TextEditingController controller;
  final ValueChanged<String> onContinue;

  @override
  State<_NameStep> createState() => _NameStepState();
}

class _NameStepState extends State<_NameStep> {
  bool get _valid => widget.controller.text.trim().length >= 2;

  void _submit() {
    if (!_valid) return;
    widget.onContinue(widget.controller.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 18, 28, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _StepHeader(
            title: 'What should we\ncall you?',
            subtitle: 'Your explorer name goes on your career passport.',
          ),
          const SizedBox(height: 36),
          TextField(
            controller: widget.controller,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.done,
            maxLength: 20,
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => _submit(),
            cursorColor: CareerColors.gold,
            style: GoogleFonts.poppins(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
            decoration: InputDecoration(
              counterText: '',
              hintText: 'Your name',
              hintStyle: GoogleFonts.poppins(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: Colors.white24,
              ),
              enabledBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.white24, width: 1.5),
              ),
              focusedBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: CareerColors.gold, width: 2),
              ),
            ),
          ).animate().fadeIn(duration: 400.ms, delay: 220.ms),
          const Spacer(),
          GoldCta(label: 'Continue', onTap: _valid ? _submit : null),
        ],
      ),
    );
  }
}

// ── step 2: age group ────────────────────────────────────────────────────

class _AgeStep extends StatelessWidget {
  const _AgeStep({
    required this.name,
    required this.selectedId,
    required this.onSelect,
  });

  // Read through closures, not values — the PageView builds all steps up
  // front, before the name is typed.
  final String Function() name;
  final String Function() selectedId;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final selected = selectedId();
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 18, 28, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StepHeader(
            lead: _greeting(),
            title: 'How old are you?',
            subtitle:
                'We tune every story and mission to the right level for you.',
          ),
          const SizedBox(height: 32),
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              physics: const NeverScrollableScrollPhysics(),
              // Let the selected card's 1.04 scale + gold glow paint past the
              // grid bounds instead of being clipped at the top / edges.
              clipBehavior: Clip.none,
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
              childAspectRatio: 1.25,
              children: [
                for (final (i, opt) in kOnboardingAgeGroups.indexed)
                  _AgeCard(
                    option: opt,
                    selected: selected == opt.id,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      onSelect(opt.id);
                    },
                  )
                      .animate()
                      .fadeIn(duration: 350.ms, delay: (180 + i * 70).ms)
                      .slideY(begin: 0.15, curve: Curves.easeOutCubic),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _greeting() {
    final n = name();
    return RichText(
      text: TextSpan(
        style: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: CareerColors.textSecondary,
        ),
        children: [
          const TextSpan(text: 'Nice to meet you, '),
          TextSpan(
            text: n.isEmpty ? 'explorer' : n,
            style: const TextStyle(color: CareerColors.gold),
          ),
          const TextSpan(text: '! 👋'),
        ],
      ),
    );
  }
}

class _AgeCard extends StatelessWidget {
  const _AgeCard({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final OnboardingOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedScale(
        scale: selected ? 1.04 : 1.0,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutBack,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          decoration: BoxDecoration(
            color: selected
                ? CareerColors.gold.withValues(alpha: 0.16)
                : CareerColors.glassFill,
            borderRadius: BorderRadius.circular(CareerRadii.smallCard),
            border: Border.all(
              color: selected ? CareerColors.gold : CareerColors.glassBorder,
              width: selected ? 2 : 1,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: CareerColors.gold.withValues(alpha: 0.30),
                      blurRadius: 18,
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(option.emoji, style: const TextStyle(fontSize: 34)),
              const SizedBox(height: 8),
              Text(
                option.label,
                style: GoogleFonts.poppins(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: selected ? CareerColors.gold : Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── step 3: interests ────────────────────────────────────────────────────

class _InterestsStep extends StatelessWidget {
  const _InterestsStep({
    required this.selected,
    required this.onToggle,
    required this.onContinue,
  });

  final Set<String> selected;
  final ValueChanged<String> onToggle;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final remaining = kMinInterests - selected.length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 18, 28, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _StepHeader(
            title: 'What makes you\ngo WOW?',
            subtitle: "Pick 3 or more — we'll build your universe around them.",
          ),
          const SizedBox(height: 28),
          Expanded(
            child: SingleChildScrollView(
              child: Wrap(
                spacing: 10,
                runSpacing: 12,
                children: [
                  for (final (i, opt) in kOnboardingInterests.indexed)
                    _InterestChip(
                      option: opt,
                      selected: selected.contains(opt.id),
                      onTap: () {
                        HapticFeedback.lightImpact();
                        onToggle(opt.id);
                      },
                    )
                        .animate()
                        .fadeIn(duration: 300.ms, delay: (160 + i * 45).ms)
                        .slideY(begin: 0.2, curve: Curves.easeOutCubic),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: Text(
              remaining > 0
                  ? 'Pick $remaining more to continue'
                  : '${selected.length} picked — nice taste! ✨',
              key: ValueKey(remaining > 0 ? 'need$remaining' : 'done'),
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: remaining > 0
                    ? CareerColors.textMuted
                    : CareerColors.gold,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 10),
          GoldCta(
            label: 'Build my universe',
            onTap: remaining > 0 ? null : onContinue,
          ),
        ],
      ),
    );
  }
}

class _InterestChip extends StatelessWidget {
  const _InterestChip({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final OnboardingOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedScale(
        scale: selected ? 1.06 : 1.0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutBack,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          decoration: BoxDecoration(
            color: selected ? CareerColors.gold : CareerColors.glassFill,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: selected ? CareerColors.gold : CareerColors.glassBorder,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: CareerColors.gold.withValues(alpha: 0.35),
                      blurRadius: 12,
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(option.emoji, style: const TextStyle(fontSize: 17)),
              const SizedBox(width: 7),
              Text(
                option.label,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: selected ? CareerColors.onLight : Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
