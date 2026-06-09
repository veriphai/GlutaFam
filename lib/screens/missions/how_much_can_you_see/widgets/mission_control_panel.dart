// Bottom Mission Control dialogue panel (PRD §6/§11.4). Uses the panel sprite as
// its frame; the message crossfades when it changes (fade out → swap → fade in).
// View + problem labels render in Flutter with the PRD's accent colours.

import 'package:flutter/material.dart';

import '../../../home/career/careerTheme.dart';
import '../config/asset_paths.dart';
import '../../../../utils/s3_assets.dart';

class MissionControlPanel extends StatelessWidget {
  const MissionControlPanel({
    super.key,
    required this.message,
    this.viewLabel,
    this.problemLabel,
    this.isBest = false,
    this.compact = false,
  });

  final String message;
  final String? viewLabel;
  final String? problemLabel;
  final bool isBest; // satellite → green "Best for:" label
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(minHeight: compact ? 78 : 96),
      decoration: BoxDecoration(
        image: DecorationImage(image: netImage(HM.flutter(HM.msgPanel)), fit: BoxFit.fill),
      ),
      padding: const EdgeInsets.fromLTRB(22, 16, 22, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('MISSION CONTROL',
              style: CareerText.label.copyWith(color: CareerColors.cyan, fontSize: 8.5, letterSpacing: 1.2)),
          const SizedBox(height: 5),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            child: Text(
              message,
              key: ValueKey(message),
              style: CareerText.body.copyWith(
                  color: Colors.white, fontSize: 12.5, height: 1.28, fontWeight: FontWeight.w500),
            ),
          ),
          if (viewLabel != null || problemLabel != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                if (viewLabel != null)
                  Flexible(
                    child: Text(viewLabel!,
                        style: CareerText.label.copyWith(
                            color: CareerColors.gold, fontSize: 9.5, letterSpacing: 0.3),
                        overflow: TextOverflow.ellipsis),
                  ),
                if (viewLabel != null && problemLabel != null) const SizedBox(width: 12),
                if (problemLabel != null)
                  Flexible(
                    child: Text(problemLabel!,
                        style: CareerText.label.copyWith(
                            color: isBest ? CareerColors.green : CareerColors.orange,
                            fontSize: 9.5,
                            letterSpacing: 0.3),
                        overflow: TextOverflow.ellipsis),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
