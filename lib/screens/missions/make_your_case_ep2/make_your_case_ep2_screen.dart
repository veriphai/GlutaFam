// Episode 2 "Make Your Case" — the thin registered wrapper on the shared CER
// engine v2 (prd_make_your_case_ep2 §11: "Wrapper only"). It is NOT a new engine:
// it just hands the EP2 config to the same `MakeYourCaseScreen` that closes EP1.
// All EP2-specific content (the locked 8-tile catalog, the 2-slot claim, the
// playback capstone, every string, and the High Road synthesis card) lives in
// `kEp2CerConfig`. Registration in activityRegistry.dart (registry id
// `make_your_case_ep2`) is central-integration work, not this wrapper.

import 'package:flutter/widgets.dart';

import '../make_your_case/config/cer_config_ep2.dart';
import '../make_your_case/make_your_case_screen.dart';

class MakeYourCaseEp2Screen extends StatelessWidget {
  const MakeYourCaseEp2Screen({super.key});

  @override
  Widget build(BuildContext context) =>
      const MakeYourCaseScreen(config: kEp2CerConfig);
}
