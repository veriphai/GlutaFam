// Lower-panel content for each mission step: alert card, diagnostic clues,
// repair choice cards (with selected/correct/wrong + shake), and the success
// panel (SYSTEM RESTORED + badge + Next Mission). All text Flutter-rendered.

import 'package:flutter/material.dart';

import '../config/asset_paths.dart';
import '../models/satellite_doctor_mission.dart';
import 'sd_ui.dart';
import '../../../../utils/s3_assets.dart';

/// Big alert card (alert step).
class AlertCard extends StatelessWidget {
  const AlertCard({super.key, required this.mission, required this.onInspect});
  final SatelliteDoctorMission mission;
  final VoidCallback onInspect;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        PremiumCard(
          accent: SDColors.orange,
          danger: SDColors.red,
          child: Column(
            children: [
              // ALERT pill
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: SDColors.orange.withValues(alpha: 0.16),
                  border:
                      Border.all(color: SDColors.orange.withValues(alpha: 0.5)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.warning_amber_rounded,
                        color: SDColors.orange, size: 14),
                    SizedBox(width: 6),
                    Text('SYSTEM ALERT',
                        style: TextStyle(
                            color: SDColors.orange,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2.5)),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // glowing circular danger badge
                  Container(
                    width: 46,
                    height: 46,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(colors: [
                        SDColors.red.withValues(alpha: 0.35),
                        SDColors.red.withValues(alpha: 0.05),
                      ]),
                      border: Border.all(
                          color: SDColors.red.withValues(alpha: 0.7),
                          width: 1.5),
                      boxShadow: [
                        BoxShadow(
                            color: SDColors.red.withValues(alpha: 0.5),
                            blurRadius: 16,
                            spreadRadius: -3),
                      ],
                    ),
                    child: const Icon(Icons.priority_high_rounded,
                        color: SDColors.red, size: 26),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ShaderMask(
                          shaderCallback: (r) => const LinearGradient(
                            colors: [Color(0xFFFFC152), SDColors.orange],
                          ).createShader(r),
                          child: Text(
                            mission.alertTitle.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              height: 1.05,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          mission.alertBody,
                          style: const TextStyle(
                              color: SDColors.textMuted,
                              fontSize: 12.5,
                              height: 1.3),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        SDCta(
            label: 'Inspect the Problem', icon: Icons.search, onTap: onInspect),
      ],
    );
  }
}

/// Diagnostic clue cards (inspect step).
class DiagnosticClues extends StatelessWidget {
  const DiagnosticClues(
      {super.key, required this.mission, required this.onChoose});
  final SatelliteDoctorMission mission;
  final VoidCallback onChoose;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        PremiumCard(
          accent: SDColors.cyan,
          child: Column(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: SDColors.cyan.withValues(alpha: 0.14),
                  border:
                      Border.all(color: SDColors.cyan.withValues(alpha: 0.45)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.biotech_outlined,
                        color: SDColors.cyan, size: 14),
                    SizedBox(width: 6),
                    Text('DIAGNOSTIC SCAN',
                        style: TextStyle(
                            color: SDColors.cyan,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2.5)),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              ...mission.clues.map((c) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        // status dot
                        Container(
                          width: 7,
                          height: 7,
                          margin: const EdgeInsets.only(right: 9),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: c.bad ? SDColors.red : SDColors.green,
                            boxShadow: [
                              BoxShadow(
                                  color: (c.bad ? SDColors.red : SDColors.green)
                                      .withValues(alpha: 0.7),
                                  blurRadius: 6),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Text(c.label,
                              style: const TextStyle(
                                  color: SDColors.text,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600)),
                        ),
                        Text(c.value,
                            style: TextStyle(
                                color: c.bad ? SDColors.red : SDColors.green,
                                fontSize: 13,
                                fontWeight: FontWeight.w900)),
                      ],
                    ),
                  )),
            ],
          ),
        ),
        const SizedBox(height: 14),
        SDCta(
            label: 'Choose a Repair',
            icon: Icons.build_outlined,
            onTap: onChoose),
      ],
    );
  }
}

/// The three repair choice cards (chooseRepair step).
class RepairCards extends StatelessWidget {
  const RepairCards({
    super.key,
    required this.mission,
    required this.selectedId,
    required this.wrongId,
    required this.wrongToken,
    required this.onPick,
  });
  final SatelliteDoctorMission mission;
  final String? selectedId;
  final String? wrongId;
  final int wrongToken;
  final void Function(String id) onPick;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: SDColors.cyan.withValues(alpha: 0.12),
              border: Border.all(color: SDColors.cyan.withValues(alpha: 0.4)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.build_rounded, color: SDColors.cyan, size: 14),
                SizedBox(width: 6),
                Text('CHOOSE A REPAIR',
                    style: TextStyle(
                        color: SDColors.cyan,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2.5)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        // IntrinsicHeight bounds the Row's height (tallest card) so the
        // stretch cross-alignment works — without it the cards collapse to
        // zero height in the unbounded Column and render blank.
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final o in mission.repairOptions)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: _RepairCard(
                      option: o,
                      state: _stateFor(o),
                      shakeToken: o.id == wrongId ? wrongToken : 0,
                      onTap: () => onPick(o.id),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  _CardState _stateFor(RepairOption o) {
    if (o.id == wrongId) return _CardState.wrong;
    if (o.id == selectedId) {
      return o.isCorrect ? _CardState.correct : _CardState.selected;
    }
    return _CardState.normal;
  }
}

enum _CardState { normal, selected, correct, wrong }

class _RepairCard extends StatefulWidget {
  const _RepairCard({
    required this.option,
    required this.state,
    required this.shakeToken,
    required this.onTap,
  });
  final RepairOption option;
  final _CardState state;
  final int shakeToken;
  final VoidCallback onTap;

  @override
  State<_RepairCard> createState() => _RepairCardState();
}

class _RepairCardState extends State<_RepairCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shake = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 420));

  @override
  void didUpdateWidget(covariant _RepairCard old) {
    super.didUpdateWidget(old);
    if (widget.shakeToken != old.shakeToken && widget.shakeToken != 0) {
      _shake.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _shake.dispose();
    super.dispose();
  }

  Color get _border {
    switch (widget.state) {
      case _CardState.normal:
        return SDColors.stroke;
      case _CardState.selected:
        return SDColors.cyan;
      case _CardState.correct:
        return SDColors.green;
      case _CardState.wrong:
        return SDColors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    final col = _border;
    final enabled = widget.state != _CardState.correct;
    return AnimatedBuilder(
      animation: _shake,
      builder: (context, child) {
        final dx = _shake.isAnimating
            ? 8 * (1 - _shake.value) * _sin(widget.shakeToken, _shake.value)
            : 0.0;
        return Transform.translate(offset: Offset(dx, 0), child: child);
      },
      child: SDPressable(
        enabled: enabled,
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: widget.state == _CardState.normal
                    ? Colors.black.withValues(alpha: 0.35)
                    : col.withValues(alpha: 0.5),
                blurRadius: widget.state == _CardState.normal ? 12 : 20,
                spreadRadius: -4,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Stack(
              children: [
                // gradient fill (tints toward the accent when active)
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: widget.state == _CardState.normal
                            ? const [Color(0xFF1A2740), Color(0xFF0E1626)]
                            : [
                                Color.lerp(const Color(0xFF1A2740), col, 0.22)!,
                                const Color(0xFF0E1626),
                              ],
                      ),
                    ),
                  ),
                ),
                // top accent strip
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: 3,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [
                        col.withValues(alpha: 0.0),
                        col,
                        col.withValues(alpha: 0.0),
                      ]),
                    ),
                  ),
                ),
                // border
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: col.withValues(
                            alpha:
                                widget.state == _CardState.normal ? 0.5 : 0.95),
                        width: widget.state == _CardState.normal ? 1.2 : 2,
                      ),
                    ),
                  ),
                ),
                // Center so short-content cards align with tall ones when the
                // row stretches all cards to equal height (was top-hugging).
                Center(
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // glowing circular icon badge
                        Container(
                          width: 46,
                          height: 46,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(colors: [
                              col.withValues(alpha: 0.30),
                              col.withValues(alpha: 0.04),
                            ]),
                            border: Border.all(
                                color: col.withValues(alpha: 0.6), width: 1.3),
                            boxShadow: [
                              BoxShadow(
                                  color: col.withValues(alpha: 0.4),
                                  blurRadius: 12,
                                  spreadRadius: -2),
                            ],
                          ),
                          child: Icon(
                            widget.state == _CardState.correct
                                ? Icons.check_rounded
                                : widget.state == _CardState.wrong
                                    ? Icons.close_rounded
                                    : widget.option.icon,
                            color: col,
                            size: 24,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          widget.option.label,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: SDColors.text,
                            fontSize: 12,
                            height: 1.1,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          widget.option.hint,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: SDColors.textMuted,
                              fontSize: 9.5,
                              height: 1.15),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  double _sin(int seed, double v) {
    // alternating shake direction
    return (v * 6).floor().isEven ? 1 : -1;
  }
}

/// Centered success popup (repaired step): a scrim + a dialog card with a big
/// badge, SYSTEM RESTORED headline, MediBot line, and the Next Mission CTA.
/// Pops in with a scale/fade so it feels like a reward moment.
class SuccessPopup extends StatefulWidget {
  const SuccessPopup({
    super.key,
    required this.mission,
    required this.isLast,
    required this.onNext,
  });
  final SatelliteDoctorMission mission;
  final bool isLast;
  final VoidCallback onNext;

  @override
  State<SuccessPopup> createState() => _SuccessPopupState();
}

class _SuccessPopupState extends State<SuccessPopup>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 420))
    ..forward();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.mission;
    final pop = CurvedAnimation(parent: _c, curve: Curves.easeOutBack);
    final fade = CurvedAnimation(parent: _c, curve: Curves.easeOut);
    return FadeTransition(
      opacity: fade,
      child: Container(
        color: Colors.black.withValues(alpha: 0.62),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: ScaleTransition(
          scale: Tween(begin: 0.7, end: 1.0).animate(pop),
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 26, 20, 20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF14233A), Color(0xFF0C1526)],
              ),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(
                  color: SDColors.green.withValues(alpha: 0.55), width: 1.6),
              boxShadow: [
                BoxShadow(
                    color: SDColors.green.withValues(alpha: 0.3),
                    blurRadius: 40,
                    spreadRadius: -6),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // big badge with a soft glow halo
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                          color: SDColors.yellow.withValues(alpha: 0.35),
                          blurRadius: 36,
                          spreadRadius: 2),
                    ],
                  ),
                  child: netImageWidget(
                    SD.flutter(m.badgeAsset),
                    width: 132,
                    height: 132,
                    errorBuilder: (_, __, ___) => const Icon(
                        Icons.workspace_premium,
                        color: SDColors.yellow,
                        size: 120),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.verified, color: SDColors.green, size: 22),
                    SizedBox(width: 8),
                    Text('SYSTEM RESTORED',
                        style: TextStyle(
                            color: SDColors.green,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2)),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  m.successHeadline,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: SDColors.text,
                      fontSize: 15,
                      fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 10),
                Text(
                  m.badgeName,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: SDColors.yellow,
                      fontSize: 14,
                      fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(
                  m.successMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: SDColors.textMuted, fontSize: 13, height: 1.3),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: SDCta(
                    label: widget.isLast ? 'Finish Mission' : 'Next Mission',
                    icon: Icons.chevron_right,
                    // deep teal-green so it reads on light backgrounds
                    colors: const [Color(0xFF1FAE7A), Color(0xFF0C5C44)],
                    onTap: widget.onNext,
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
