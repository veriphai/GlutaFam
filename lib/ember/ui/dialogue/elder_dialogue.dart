// Ember — ui/dialogue/elder_dialogue.dart
//
// A lightweight branching dialogue card. A [DialogueNode] holds one line + a few
// [DialogueChoice]s; choosing one either jumps to another node, opens the codex
// (tell-me-more), or closes. Dialogues are DATA so leaves/content can ship their
// own trees later; this stage includes a small built-in Elder intro keyed off
// the NPC's dialogueId, so tapping the seeded Elder does something real.
//
// Pure UI: it renders a tree + reports two outcomes (open codex / close) via
// callbacks. It never touches the world.

import 'package:flutter/material.dart';

import '../../art/ember_palette.dart';
import '../ember_theme.dart';
import '../widgets/ember_button.dart';

/// The speaker name + opening line for the non-blocking walk-up speech bubble.
@immutable
class DialogueGreeting {
  const DialogueGreeting({required this.speakerName, required this.line});
  final String speakerName;
  final String line;
}

/// What a dialogue choice does when picked.
enum DialogueAction { goTo, openCodex, close }

/// One selectable reply in a dialogue node.
class DialogueChoice {
  const DialogueChoice({
    required this.label,
    required this.action,
    this.target,
    this.codexEntryId,
  });

  final String label;
  final DialogueAction action;

  /// Next node id (for [DialogueAction.goTo]).
  final String? target;

  /// Codex entry to open (for [DialogueAction.openCodex]); null opens the index.
  final String? codexEntryId;
}

/// A node in a branching dialogue tree.
class DialogueNode {
  const DialogueNode({
    required this.id,
    required this.line,
    this.choices = const <DialogueChoice>[],
  });

  final String id;
  final String line;
  final List<DialogueChoice> choices;
}

/// A whole branching dialogue tree.
class DialogueTree {
  const DialogueTree({
    required this.id,
    required this.speakerName,
    required this.rootId,
    required this.nodes,
  });

  final String id;
  final String speakerName;
  final String rootId;
  final Map<String, DialogueNode> nodes;

  DialogueNode? nodeById(String id) => nodes[id];

  /// The speaker name + opening line for [dialogueId], or null if no tree exists.
  /// Used by the NON-BLOCKING walk-up speech bubble (the "walk up, they say
  /// something" beat) so it can show the greeting without opening the modal —
  /// tapping the bubble's prompt still opens the full branching tree.
  static DialogueGreeting? greetingFor(String? dialogueId) {
    final DialogueTree? tree = forId(dialogueId);
    if (tree == null) return null;
    final DialogueNode? root = tree.nodeById(tree.rootId);
    if (root == null) return null;
    return DialogueGreeting(speakerName: tree.speakerName, line: root.line);
  }

  /// The built-in trees keyed by dialogueId (leaves add their own later).
  static DialogueTree? forId(String? dialogueId) => _builtin[dialogueId];

  static const Map<String, DialogueTree> _builtin = <String, DialogueTree>{
    'elder.intro': DialogueTree(
      id: 'elder.intro',
      speakerName: 'Elder',
      rootId: 'root',
      nodes: <String, DialogueNode>{
        'root': DialogueNode(
          id: 'root',
          line: 'Welcome, young one. Our people need warmth, tools, and '
              'shelter to thrive. Watch, learn, and we will grow strong.',
          choices: <DialogueChoice>[
            DialogueChoice(
              label: 'How do I help?',
              action: DialogueAction.goTo,
              target: 'help',
            ),
            DialogueChoice(
              label: 'Tell me about our knowledge',
              action: DialogueAction.openCodex,
            ),
            DialogueChoice(
              label: 'I will get to work',
              action: DialogueAction.close,
            ),
          ],
        ),
        'help': DialogueNode(
          id: 'help',
          line: 'Gather wood, stone, and food from the land. When a new idea '
              'is ready, discover it — then you can build something new.',
          choices: <DialogueChoice>[
            DialogueChoice(
              label: 'Got it',
              action: DialogueAction.close,
            ),
          ],
        ),
      },
    ),
  };
}

/// Presents a branching dialogue as a bottom sheet card.
class ElderDialogue extends StatefulWidget {
  const ElderDialogue({
    super.key,
    required this.tree,
    required this.onOpenCodex,
    this.palette = EmberPalette.dusk,
  });

  final DialogueTree tree;

  /// Called with a codex entry id (or null for the index) on tell-me-more.
  final void Function(String? codexEntryId) onOpenCodex;
  final EmberPalette palette;

  /// Shows the dialogue for [dialogueId], if a tree exists for it. Returns
  /// silently when there is no tree (e.g. a plain tribe member).
  static Future<void> show(
    BuildContext context, {
    required String? dialogueId,
    required EmberPalette palette,
    required void Function(String? codexEntryId) onOpenCodex,
  }) {
    final DialogueTree? tree = DialogueTree.forId(dialogueId);
    if (tree == null) return Future<void>.value();
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext ctx) => ElderDialogue(
        tree: tree,
        palette: palette,
        onOpenCodex: onOpenCodex,
      ),
    );
  }

  @override
  State<ElderDialogue> createState() => _ElderDialogueState();
}

class _ElderDialogueState extends State<ElderDialogue> {
  late String _nodeId = widget.tree.rootId;

  EmberPalette get _p => widget.palette;

  @override
  Widget build(BuildContext context) {
    final DialogueNode node =
        widget.tree.nodeById(_nodeId) ??
            widget.tree.nodeById(widget.tree.rootId)!;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(EmberUi.gap),
        child: Container(
          padding: const EdgeInsets.all(EmberUi.gapL),
          decoration: EmberUi.panel(_p, raised: true),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _p.emberBright,
                      shape: BoxShape.circle,
                      border: Border.all(color: _p.outline, width: 2),
                    ),
                    child: Icon(Icons.person, color: _p.ink, size: 24),
                  ),
                  const SizedBox(width: EmberUi.gapS),
                  Text(
                    widget.tree.speakerName,
                    style: TextStyle(
                      color: _p.ink,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: EmberUi.gap),
              Text(
                node.line,
                style: TextStyle(
                  color: _p.ink,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: EmberUi.gapL),
              for (final DialogueChoice choice in node.choices) ...<Widget>[
                EmberButton(
                  label: choice.label,
                  style: choice.action == DialogueAction.close
                      ? EmberButtonStyle.secondary
                      : EmberButtonStyle.primary,
                  palette: _p,
                  expand: true,
                  onPressed: () => _pick(choice),
                ),
                const SizedBox(height: EmberUi.gapS),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _pick(DialogueChoice choice) {
    switch (choice.action) {
      case DialogueAction.goTo:
        if (choice.target != null) {
          setState(() => _nodeId = choice.target!);
        }
      case DialogueAction.openCodex:
        Navigator.of(context).pop();
        widget.onOpenCodex(choice.codexEntryId);
      case DialogueAction.close:
        Navigator.of(context).pop();
    }
  }
}
