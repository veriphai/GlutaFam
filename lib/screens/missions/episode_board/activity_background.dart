// The shared Episode-1 activity backdrop — the dossier "power grid at dusk" art
// (pylons, plant, town framing a dark centre where the activity plays). Drop-in
// for the activity screens' bottom background layer. Cover-fit over a dark base;
// degrades to the dark base if the asset isn't bundled yet.

import 'package:flutter/material.dart';

class ActivityDossierBackground extends StatelessWidget {
  const ActivityDossierBackground({super.key});

  static const String _bg = 'assets/images/episode_board/episode1_activity_bg.png';

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: Color(0xFF070A14)),
        Image.asset(
          _bg,
          fit: BoxFit.cover,
          alignment: Alignment.center,
          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
        ),
      ],
    );
  }
}
