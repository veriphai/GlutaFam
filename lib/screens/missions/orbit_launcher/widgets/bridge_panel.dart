// Bridge panel (PRD next-activity bridge): the satellite is now an empty box in
// orbit — what goes inside? Shows the six part icons (a tease of the next
// activity) and the final CTA. The CTA returns to the activities hub.

import 'package:flutter/material.dart';

import '../../../home/career/careerCommon.dart';
import '../../../home/career/careerTheme.dart';
import '../config/asset_paths.dart';
import '../config/parts_catalog.dart';
import 'orbit_button.dart';
import '../../../../utils/s3_assets.dart';

class BridgePanel extends StatelessWidget {
  const BridgePanel({super.key, required this.onFinish});

  final VoidCallback onFinish;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        color: const Color(0xD90A1838),
        borderRadius: BorderRadius.circular(CareerRadii.card),
        border: Border.all(color: CareerColors.glassBorder),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('What should we put inside it?',
              style: CareerText.body.copyWith(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Row(
            children: [
              for (var i = 0; i < kBridgeParts.length; i++) ...[
                if (i > 0) const SizedBox(width: 7),
                Expanded(
                    child: RevealOnLoad(
                  delay: Duration(milliseconds: 80 * i),
                  child: _PartCell(part: kBridgeParts[i]),
                )),
              ],
            ],
          ),
          const SizedBox(height: 14),
          Stack(
            alignment: Alignment.center,
            children: [
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: netImageWidget(OL.flutter(OL.buildCtaGlow), fit: BoxFit.fill),
                ),
              ),
              OrbitButton(
                label: 'Let’s Build It!',
                colors: const [Color(0xFF9A55F0), Color(0xFF6E2FC9)],
                trailingIcon: Icons.arrow_forward_rounded,
                onTap: onFinish,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PartCell extends StatelessWidget {
  const _PartCell({required this.part});

  final PartTease part;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: const Color(0xFF0E1C42),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: CareerColors.cyan.withValues(alpha: 0.35)),
          ),
          child: AspectRatio(
            aspectRatio: 1,
            child: netImageWidget(part.asset, fit: BoxFit.contain),
          ),
        ),
        const SizedBox(height: 4),
        Text(part.label,
            textAlign: TextAlign.center,
            style: CareerText.label.copyWith(fontSize: 6.5, color: Colors.white70, height: 1.1)),
      ],
    );
  }
}
