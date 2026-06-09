// Parts inventory (PRD §7.7) — a horizontally SCROLLING list of comfortably
// sized cards. All parts are shown; only the current step's parts are bright +
// draggable, the rest are dimmed/locked, installed ones show a checkmark.
//
// Drag model: cards use a Draggable with `affinity: Axis.vertical`. The list
// scrolls on HORIZONTAL swipes; a VERTICAL drag (up toward the satellite) grabs
// the part IMMEDIATELY — no press-and-hold (important for a mobile kids' game).
// The two gestures use different axes, so they never fight.
// The matching DragTarget lives in the screen around the Flame GameWidget.
// The active part is auto-scrolled into view whenever the step changes.

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../home/career/careerTheme.dart';
import '../config/part_catalog.dart';
import '../state/build_satellite_controller.dart';
import '../../../../utils/s3_assets.dart';

class InventoryTray extends StatefulWidget {
  const InventoryTray({super.key, required this.controller, required this.onPickup});

  final BuildSatelliteController controller;
  final void Function(String partId) onPickup;

  @override
  State<InventoryTray> createState() => _InventoryTrayState();
}

class _InventoryTrayState extends State<InventoryTray> {
  final ScrollController _scroll = ScrollController();

  static const double _cardWidth = 84;
  static const double _gap = 12;

  String _lastHighlight = '';

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _maybeScrollToActive() {
    final id = widget.controller.state.highlightedPartId;
    if (id.isEmpty || id == _lastHighlight) return;
    _lastHighlight = id;
    final index = kSatelliteParts.indexWhere((p) => p.id == id);
    if (index < 0 || !_scroll.hasClients) return;
    // Keep the active card comfortably in view (slightly inset from the left).
    final target = (index * (_cardWidth + _gap) - 24)
        .clamp(0.0, _scroll.position.maxScrollExtent);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(target,
            duration: const Duration(milliseconds: 420), curve: Curves.easeOutCubic);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Rebuilt by the screen's AnimatedBuilder on every state change.
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeScrollToActive());

    return SizedBox(
      height: 104,
      child: ListView.separated(
        controller: _scroll,
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 2),
        itemCount: kSatelliteParts.length,
        separatorBuilder: (_, __) => const SizedBox(width: _gap),
        itemBuilder: (_, i) => _PartCard(
          part: kSatelliteParts[i],
          controller: widget.controller,
          onPickup: widget.onPickup,
          width: _cardWidth,
        ),
      ),
    );
  }
}

class _PartCard extends StatelessWidget {
  const _PartCard({
    required this.part,
    required this.controller,
    required this.onPickup,
    required this.width,
  });

  final SatellitePart part;
  final BuildSatelliteController controller;
  final void Function(String partId) onPickup;
  final double width;

  @override
  Widget build(BuildContext context) {
    final installed = controller.isInstalled(part.id);
    final active = controller.isActive(part.id);
    final highlight = active &&
        (controller.state.highlightedPartId == part.id || controller.state.hintActive);

    final card = _card(active: active, installed: installed, highlight: highlight);

    if (!active) return SizedBox(width: width, child: card);

    return SizedBox(
      width: width,
      child: Draggable<String>(
        data: part.id,
        // Vertical affinity: drag UP grabs immediately, horizontal swipe scrolls.
        affinity: Axis.vertical,
        dragAnchorStrategy: pointerDragAnchorStrategy,
        onDragStarted: () => onPickup(part.id),
        feedback: _Feedback(part: part),
        childWhenDragging: Opacity(opacity: 0.25, child: card),
        child: card,
      ),
    );
  }

  Widget _card({required bool active, required bool installed, required bool highlight}) {
    final Color border = installed
        ? CareerColors.green
        : active
            ? CareerColors.cyan
            : CareerColors.glassBorder;

    Widget content = Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: active ? 0.12 : 0.05),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border, width: active || installed ? 2 : 1),
        boxShadow: highlight
            ? [BoxShadow(color: CareerColors.cyan.withValues(alpha: 0.55), blurRadius: 16)]
            : null,
      ),
      padding: const EdgeInsets.fromLTRB(6, 8, 6, 6),
      child: Column(
        children: [
          Expanded(
            child: Opacity(
              opacity: active || installed ? 1.0 : 0.45,
              child: netImageWidget(part.spriteFlutter, fit: BoxFit.contain),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            part.displayName,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: CareerText.statLabel.copyWith(
              fontSize: 9,
              height: 1.05,
              color: active ? CareerColors.textPrimary : CareerColors.textMuted,
            ),
          ),
        ],
      ),
    );

    if (installed) {
      content = Stack(children: [
        content,
        Positioned(
          right: 6,
          top: 6,
          child: Container(
            padding: const EdgeInsets.all(2),
            decoration: const BoxDecoration(color: CareerColors.green, shape: BoxShape.circle),
            child: const Icon(Icons.check_rounded, size: 12, color: Colors.white),
          ),
        ),
      ]);
    } else if (!active) {
      content = Stack(children: [
        content,
        Positioned(
          right: 6,
          top: 6,
          child: Icon(Icons.lock_rounded, size: 13, color: CareerColors.textMuted.withValues(alpha: 0.8)),
        ),
      ]);
    }

    if (highlight) {
      content = content
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .scaleXY(end: 1.05, duration: 850.ms, curve: Curves.easeInOut);
    }
    return content;
  }
}

/// The enlarged, glowing part image that follows the finger while dragging.
class _Feedback extends StatelessWidget {
  const _Feedback({required this.part});

  final SatellitePart part;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Transform.translate(
        // pointerDragAnchorStrategy pins the top-left to the finger; shift so the
        // image is centred under it.
        offset: const Offset(-52, -52),
        child: SizedBox(
          width: 104,
          height: 104,
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: CareerColors.cyan.withValues(alpha: 0.6), blurRadius: 26)],
            ),
            child: netImageWidget(part.spriteFlutter, fit: BoxFit.contain),
          ),
        ),
      ),
    );
  }
}
