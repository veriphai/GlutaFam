// Bottom mission card for the play screen: the task instruction plus the
// Scanner / Zoom / Hint tool row (storyboard frames 4 & 8). All Flutter, with a
// premium holographic Mission-Control look.

import 'package:flutter/material.dart';

import '../../../home/career/careerCommon.dart';
import '../../../home/career/careerTheme.dart';
import '../models/earth_detective_mission.dart';
import '../state/earth_detective_state.dart';

class MissionInstructionCard extends StatelessWidget {
  const MissionInstructionCard({
    super.key,
    required this.mission,
    required this.state,
    required this.onHint,
    required this.onZoom,
  });

  final EarthDetectiveMission mission;
  final EarthDetectiveState state;
  final VoidCallback onHint;
  final VoidCallback onZoom;

  @override
  Widget build(BuildContext context) {
    final isCompare = mission.interactionMode == InteractionMode.compareBeforeAfter;
    final canZoom = !isCompare;
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xF21A2F58), Color(0xF20A1730)],
        ),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: CareerColors.cyan.withValues(alpha: 0.30), width: 1.2),
        boxShadow: [
          BoxShadow(color: CareerColors.blue.withValues(alpha: 0.28), blurRadius: 24, offset: const Offset(0, 8)),
          BoxShadow(color: Colors.black.withValues(alpha: 0.35), blurRadius: 14, offset: const Offset(0, 6)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // top accent hairline
          Container(
            margin: const EdgeInsets.only(top: 10, bottom: 14),
            height: 2.5,
            width: 44,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                CareerColors.cyan.withValues(alpha: 0),
                CareerColors.cyan,
                CareerColors.cyan.withValues(alpha: 0),
              ]),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.my_location_rounded, size: 15, color: CareerColors.cyan.withValues(alpha: 0.9)),
              const SizedBox(width: 7),
              Flexible(
                child: Text(
                  mission.instructionText,
                  textAlign: TextAlign.center,
                  style: CareerText.cardTitleLg.copyWith(
                    fontSize: 15,
                    color: Colors.white,
                    shadows: [Shadow(color: CareerColors.cyan.withValues(alpha: 0.45), blurRadius: 10)],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _ToolChip(
                icon: isCompare ? Icons.swap_horiz_rounded : Icons.center_focus_strong_rounded,
                label: isCompare ? 'Slide' : 'Scanner',
                active: true,
                engaged: true, // the tool in use — an indicator, not a button
              ),
              _ToolChip(
                icon: Icons.zoom_in_rounded,
                label: canZoom ? '${state.zoomLevel.toStringAsFixed(1)}x' : 'Zoom',
                active: canZoom,
                onTap: canZoom ? onZoom : null,
              ),
              _ToolChip(
                icon: Icons.lightbulb_rounded,
                label: 'Hint',
                active: true,
                badge: state.hintLevel > 0 ? state.hintLevel : null,
                onTap: onHint,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ToolChip extends StatelessWidget {
  const _ToolChip({
    required this.icon,
    required this.label,
    this.active = false,
    this.engaged = false,
    this.badge,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;

  /// The tool currently in use — rendered as a FILLED, lit indicator with an
  /// "active" dot, so it doesn't read as an idle button waiting to be pressed.
  final bool engaged;

  final int? badge;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = active ? CareerColors.cyan : CareerColors.textMuted;
    final dimmed = onTap == null && !active;
    return PressableScale(
      onTap: onTap,
      child: Opacity(
        opacity: dimmed ? 0.5 : 1,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                // glowing holographic disc (engaged = solid filled state)
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: engaged
                        ? const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF2BB1E8), Color(0xFF0E5C9E)],
                          )
                        : RadialGradient(
                            colors: [
                              color.withValues(alpha: 0.30),
                              color.withValues(alpha: 0.06),
                            ],
                            radius: 0.85,
                          ),
                    border: Border.all(
                        color: engaged ? Colors.white.withValues(alpha: 0.85) : color.withValues(alpha: 0.7),
                        width: 1.6),
                    boxShadow: active
                        ? [
                            BoxShadow(
                                color: color.withValues(alpha: engaged ? 0.6 : 0.45),
                                blurRadius: engaged ? 20 : 16,
                                spreadRadius: engaged ? 2 : 1)
                          ]
                        : null,
                  ),
                ),
                // inner ring
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: (engaged ? Colors.white : color).withValues(alpha: 0.35), width: 1),
                  ),
                ),
                Icon(icon, size: 23, color: active ? Colors.white : color),
                if (engaged)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 11,
                      height: 11,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: CareerColors.green,
                        border: Border.all(color: const Color(0xFF0A1730), width: 1.5),
                        boxShadow: [
                          BoxShadow(color: CareerColors.green.withValues(alpha: 0.7), blurRadius: 7)
                        ],
                      ),
                    ),
                  ),
                if (badge != null)
                  Positioned(
                    right: -3,
                    top: -3,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                      decoration: BoxDecoration(
                        gradient: CareerGradients.gold,
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: CareerColors.gold.withValues(alpha: 0.5), blurRadius: 8)],
                      ),
                      child: Text('$badge',
                          textAlign: TextAlign.center,
                          style: CareerText.label.copyWith(fontSize: 9.5, color: CareerColors.onLight)),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 7),
            Text(label.toUpperCase(),
                style: CareerText.label.copyWith(color: color, fontSize: 9.5, letterSpacing: 1.1)),
          ],
        ),
      ),
    );
  }
}
