// Ember — ui/build_menu/edit_mode_bar.dart
//
// The placement/edit action bar shown while a ghost is live (placing a new
// object or moving an existing one). It watches the [PlacementController]
// (a ChangeNotifier) and offers: rotate, confirm (enabled only when the pure
// validator says the cell is valid), and cancel. When editing an EXISTING
// placeable it also offers Remove with a refund-confirm dialog.
//
// It drives the controller directly (rotate/confirm/cancel/remove) — those are
// game-layer commands, not world mutations; the controller dispatches the
// resulting Intents through the bridge. This keeps the world screen thin.

import 'package:flutter/material.dart';

import '../../art/ember_palette.dart';
import '../../core/ids.dart';
import '../../game/placement/placement_controller.dart';
import '../../game/placement/placement_validator.dart';
import '../ember_theme.dart';
import '../widgets/ember_button.dart';

/// The bottom action bar for the placement/edit flow.
class EditModeBar extends StatefulWidget {
  const EditModeBar({
    super.key,
    required this.controller,
    this.palette = EmberPalette.dusk,
    this.editingId,
  });

  /// The placement state machine to drive + observe.
  final PlacementController controller;
  final EmberPalette palette;

  /// When set, the bar is editing an existing placeable and shows Remove.
  final EntityId? editingId;

  @override
  State<EditModeBar> createState() => _EditModeBarState();
}

class _EditModeBarState extends State<EditModeBar> {
  PlacementController get _c => widget.controller;
  EmberPalette get _p => widget.palette;

  @override
  void initState() {
    super.initState();
    _c.addListener(_onChange);
  }

  @override
  void dispose() {
    _c.removeListener(_onChange);
    super.dispose();
  }

  void _onChange() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (!_c.isPlacing) return const SizedBox.shrink();
    final bool valid = _c.canConfirm;
    final bool isMove = _c.mode == PlacementMode.move;

    return Container(
      padding: const EdgeInsets.all(EmberUi.gap),
      decoration: EmberUi.panel(_p, raised: true),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (!valid) ...<Widget>[
            _invalidHint(),
            const SizedBox(height: EmberUi.gapS),
          ],
          Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              EmberIconButton(
                icon: Icons.rotate_right,
                tooltip: 'Rotate',
                palette: _p,
                onPressed: () => _c.rotate(),
              ),
              const SizedBox(width: EmberUi.gapS),
              if (isMove && widget.editingId != null) ...<Widget>[
                EmberIconButton(
                  icon: Icons.delete_outline,
                  tooltip: 'Remove',
                  palette: _p,
                  background: _p.surface,
                  foreground: _p.danger,
                  onPressed: _confirmRemove,
                ),
                const SizedBox(width: EmberUi.gapS),
              ],
              EmberButton(
                label: 'Cancel',
                style: EmberButtonStyle.secondary,
                palette: _p,
                onPressed: () => _c.cancel(),
              ),
              const SizedBox(width: EmberUi.gapS),
              EmberButton(
                label: isMove ? 'Move here' : 'Place',
                icon: Icons.check,
                palette: _p,
                onPressed: valid ? () => _c.confirm() : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _invalidHint() {
    final List<PlacementReason> reasons = _c.blockingReasons;
    final String text =
        reasons.isEmpty ? "Can't build here" : reasons.first.message;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(Icons.block, color: _p.danger, size: 18),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(
            color: _p.danger,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Future<void> _confirmRemove() async {
    final EntityId? id = widget.editingId;
    if (id == null) return;
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        backgroundColor: _p.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(EmberUi.radius),
          side: BorderSide(color: _p.outline, width: 1.5),
        ),
        title: Text(
          'Remove this?',
          style: TextStyle(color: _p.ink, fontWeight: FontWeight.w800),
        ),
        content: Text(
          'You get back some of what it cost.',
          style: TextStyle(color: _p.inkSoft),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Keep', style: TextStyle(color: _p.inkSoft)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              'Remove',
              style: TextStyle(color: _p.danger, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
    if (ok ?? false) {
      _c.remove(id);
    }
  }
}
