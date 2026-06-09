// One-shot achievement/feedback badge pop (PRD per-scene "Required Assets" +
// §17 positive/warning feedback). Driven by a bump token on the state: when the
// token changes, the badge scales in, holds, and fades out. Wires the
// image_captured / data_sent / shadow_warning / sunlight_mode / power_warning
// badges + the captured cyclone thumbnail.

import 'package:flutter/material.dart';

import '../../../home/career/careerTheme.dart';
import '../config/asset_paths.dart';
import '../models/power_balance_models.dart';
import 'pb_palette.dart';

class FeedbackBadgePop extends StatefulWidget {
  const FeedbackBadgePop({super.key, required this.token, required this.badge});

  final int token;
  final FeedbackBadge badge;

  @override
  State<FeedbackBadgePop> createState() => _FeedbackBadgePopState();
}

class _FeedbackBadgePopState extends State<FeedbackBadgePop> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1700));

  @override
  void didUpdateWidget(covariant FeedbackBadgePop old) {
    super.didUpdateWidget(old);
    if (widget.token != old.token && widget.badge != FeedbackBadge.none) {
      _c.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  ({String badge, String label, Color color}) get _spec => switch (widget.badge) {
        FeedbackBadge.imageCaptured => (badge: PB.imageCapturedBadge, label: 'Image Captured!', color: PBPalette.skyBlue),
        FeedbackBadge.dataSent => (badge: PB.dataSentBadge, label: 'Data Sent!', color: PBPalette.successGreen),
        FeedbackBadge.shadow => (badge: PB.shadowWarningBadge, label: "Earth's Shadow", color: Color(0xFF8A93E6)),
        FeedbackBadge.sunlight => (badge: PB.sunlightBadge, label: 'Solar Charging', color: PBPalette.solarGold),
        FeedbackBadge.lowPower => (badge: PB.powerWarningBadge, label: 'Low Battery!', color: PBPalette.warningRed),
        FeedbackBadge.none => (badge: PB.sunlightBadge, label: '', color: PBPalette.skyBlue),
      };

  @override
  Widget build(BuildContext context) {
    final spec = _spec;
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final t = _c.value;
          if (t == 0 || t >= 1 || widget.badge == FeedbackBadge.none) {
            return const SizedBox.shrink();
          }
          // scale-in 0..0.18, hold, fade-out 0.78..1.0
          final scale = t < 0.18 ? Curves.easeOutBack.transform(t / 0.18) : 1.0;
          final opacity = t < 0.18
              ? (t / 0.18).clamp(0.0, 1.0)
              : t > 0.78
                  ? (1 - (t - 0.78) / 0.22).clamp(0.0, 1.0)
                  : 1.0;
          return Opacity(
            opacity: opacity,
            child: Transform.scale(
              scale: scale,
              child: Container(
                padding: const EdgeInsets.fromLTRB(10, 8, 18, 8),
                decoration: BoxDecoration(
                  color: PBPalette.panelFill,
                  borderRadius: BorderRadius.circular(CareerRadii.pill),
                  border: Border.all(color: spec.color.withValues(alpha: 0.7), width: 1.5),
                  boxShadow: [BoxShadow(color: spec.color.withValues(alpha: 0.45), blurRadius: 20)],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // for a capture, frame the actual cyclone thumbnail next to the medal
                    if (widget.badge == FeedbackBadge.imageCaptured) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: pbImage(PB.flutter(PB.cycloneThumb), width: 40, height: 40, fit: BoxFit.cover),
                      ),
                      const SizedBox(width: 8),
                    ],
                    pbImage(PB.flutter(spec.badge), width: 46, height: 46),
                    const SizedBox(width: 10),
                    Text(spec.label,
                        style: CareerText.cardTitleLg.copyWith(color: spec.color, fontSize: 14)),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
