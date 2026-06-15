// Ember — concepts/tools/tools_codex.dart
//
// The discoverable knowledge cards for stone tools (discovery story / science /
// history) plus the myth -> evidence model upgrade the Knapping activity lands
// (PRD §10): from "some stones are lucky" to "hard, glassy stone FRACTURES into
// sharp edges — it's the material." Copy is written for a 7-14 audience:
// accessible, never falsely precise about prehistory dates, and child-safe
// (hunting/butchering is abstract, never graphic — PRD §16).

import '../../contracts/codex_entry.dart';
import '../../core/enums.dart';
import 'tools_knowledge.dart';

/// The tools leaf's codex content + model upgrade.
class ToolsCodex {
  const ToolsCodex._();

  /// Stable codex entry ids (referenced by the activity's codexEntryIds).
  static const String entryKnapping = 'tools.codex.knapping';
  static const String entryMaterials = 'tools.codex.materials';
  static const String entryHafting = 'tools.codex.hafting';

  /// Every codex entry this leaf contributes.
  static List<CodexEntry> all() => <CodexEntry>[
        knapping(),
        materials(),
        hafting(),
      ];

  /// The headline card: knapping = the right strike on the right stone.
  static CodexEntry knapping() => const CodexEntry(
        id: entryKnapping,
        concept: ConceptId.stoneTools,
        title: 'Knapping a Sharp Edge',
        discoveryStory:
            'The Elder set a glassy stone on a slab, lined up a glancing blow '
            'with the hammerstone, and struck — and a long, razor-sharp flake '
            'sprang free. With a few more careful strikes a useless rock became '
            'the sharpest thing in the whole camp.',
        science:
            'Hard, glassy stone breaks in smooth, curved chips when you strike '
            'it at the right angle with the right force. Too gentle and nothing '
            'comes off; too hard or straight-on and it shatters. The trick is a '
            'controlled, glancing blow — that pops a clean, sharp flake.',
        history:
            'People were shaping stone tools for an enormously long time — even '
            'before they could make fire on demand. Rough choppers and sharp '
            'flakes came first, then the all-purpose hand axe, then finer blades.',
      );

  /// Depth card: why the MATERIAL matters (flint/obsidian vs soft stone).
  static CodexEntry materials() => const CodexEntry(
        id: entryMaterials,
        concept: ConceptId.stoneTools,
        title: 'Why This Stone, Not That One',
        discoveryStory:
            'The tribe used to think some stones were simply lucky. But the '
            'lucky ones were always the same: hard and glassy. The soft, grainy '
            'stones never made an edge no matter how you hit them.',
        science:
            'Flint, chert, and obsidian are hard and glassy, so they fracture '
            'into sharp edges — obsidian (volcanic glass) can end up sharper '
            'than a steel knife. Soft, grainy stones just crumble. It was never '
            'luck — it was always the material.',
        history:
            'Stone Age toolmakers travelled and traded to get the best stone for '
            'knapping, carrying prized flint and obsidian far from where it was '
            'dug — some of the earliest long-distance trade we know of.',
      );

  /// Older-kid depth: hafting + the link back to Fire (heat-treatment).
  static CodexEntry hafting() => const CodexEntry(
        id: entryHafting,
        concept: ConceptId.stoneTools,
        title: 'A Tool to Make Tools — and the Spear',
        discoveryStory:
            'Then came the leap: lashing a sharp point onto a wooden shaft. A '
            'flake in your hand is useful; the same flake on a spear gives you '
            'reach and power. And a tool used to shape OTHER tools meant the '
            'tribe could make almost anything it needed.',
        science:
            'Attaching a point to a handle — hafting — adds reach and leverage. '
            'Fire makes both parts better: heat-treating glassy stone helps it '
            'flake more cleanly, and fire-hardening the wooden tip makes the '
            'shaft tougher. Tools you make to make more tools are "meta-tools."',
        history:
            'Hafted spears made hunting far more effective and safer from a '
            'distance. The same toolmaking skill later led to finer blades, the '
            'bow, and eventually metal tools.',
      );

  /// The belief shift: "some stones are lucky" -> "the material fractures sharp."
  static ModelUpgrade modelUpgrade() => const ModelUpgrade(
        concept: ConceptId.stoneTools,
        mythBelief:
            'Some stones are simply lucky — a few magic rocks happen to cut, and '
            'most do not.',
        evidenceBelief:
            'There is no luck in it — hard, glassy stone fractures into sharp '
            'edges because of WHAT IT IS. We shape our world; we don\'t just '
            'live in it.',
        flag: ToolsKnowledge.toolModelUpgraded,
      );
}
