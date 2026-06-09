// Final Success (PRD §20) — the MISSION COMPLETE card screen (house pattern,
// cf. satellite_doctor's FinalScene): same holographic-console backdrop as
// the badge reveal, a pop-in completion card with the mission stats, and
// Orbit below reading the payoff + emotional recap through the shell's
// dialogue bubble. Continue lights up after the mission-control lines have
// had reading time, then leads into the badge reveal.

import 'package:flutter/material.dart';

import '../config/scc_dialogue.dart';
import '../config/scc_theme.dart';
import '../state/mission_stage_controller.dart';
import '../widgets/scc_buttons.dart';

class FinaleScene extends StatefulWidget {
  const FinaleScene({super.key, required this.controller});

  final MissionStageController controller;

  @override
  State<FinaleScene> createState() => _FinaleSceneState();
}

class _FinaleSceneState extends State<FinaleScene>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 480),
  )..forward();

  @override
  void dispose() {
    _pop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pop = CurvedAnimation(parent: _pop, curve: Curves.easeOutBack);
    final fade = CurvedAnimation(parent: _pop, curve: Curves.easeOut);
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final s = widget.controller.state;
        return Stack(
          fit: StackFit.expand,
          children: [
            // backdrop comes from the SHELL (full-screen holo console, no
            // seam under the dialogue strip)
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const Spacer(),
                    FadeTransition(
                      opacity: fade,
                      child: ScaleTransition(
                        scale: Tween(begin: 0.78, end: 1.0).animate(pop),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.fromLTRB(20, 26, 20, 22),
                          decoration: sccPanel(
                              borderColor: SccColors.success, radius: 24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // medal
                              Container(
                                width: 86,
                                height: 86,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: SccColors.panelNavy,
                                  border: Border.all(
                                      color: SccColors.success, width: 2),
                                  boxShadow: [
                                    BoxShadow(
                                      color: SccColors.success
                                          .withValues(alpha: 0.45),
                                      blurRadius: 26,
                                    ),
                                  ],
                                ),
                                child: const Icon(Icons.military_tech_rounded,
                                    color: SccColors.success, size: 52),
                              ),
                              const SizedBox(height: 14),
                              Text('MISSION COMPLETE',
                                  style: SccText.missionTitle.copyWith(
                                      fontSize: 20, color: SccColors.success)),
                              const SizedBox(height: 4),
                              Text('SAVE THE COASTAL CITY',
                                  style: SccText.label.copyWith(fontSize: 11)),
                              const SizedBox(height: 16),
                              // stats row
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _StatChip(
                                    icon: Icons.checklist_rounded,
                                    label: 'SYSTEMS',
                                    value:
                                        '${s.completed.length}/${s.completed.length}',
                                  ),
                                  const SizedBox(width: 12),
                                  _StatChip(
                                    icon: Icons.campaign_rounded,
                                    label: 'WARNING',
                                    value: '${s.readiness}%',
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                SccDialogue.missionControl,
                                textAlign: TextAlign.center,
                                style: SccText.body.copyWith(fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    SccCta(
                      label: 'CONTINUE',
                      icon: Icons.arrow_forward_rounded,
                      enabled: s.finale.continueEnabled,
                      onTap: widget.controller.finaleContinue,
                    ),
                    const Spacer(),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: SccColors.panelNavy,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SccColors.panelBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: SccColors.success),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: SccText.label.copyWith(fontSize: 8)),
              Text(value,
                  style: SccText.meterValue
                      .copyWith(fontSize: 13, color: SccColors.success)),
            ],
          ),
        ],
      ),
    );
  }
}
