// The vertical height rail + draggable camera marker (PRD §10, §19, §23).
//
// The child drags the marker up/down the rail; on release it snaps to the
// nearest of six nodes and reports the level. Tapping a node jumps to it (the
// forgiving accessibility path, PRD §23). Nodes show active / completed /
// inactive sprites; the marker swaps to its "dragging" sprite while held.
//
// Marker/rail glow sprites keep a faint pale matte fringe from the strip; over
// the bright scene backgrounds it reads as part of the neon glow.

import 'package:flutter/material.dart';

import '../../../home/career/careerTheme.dart';
import '../config/asset_paths.dart';
import '../config/height_levels.dart';
import '../../../../utils/s3_assets.dart';

class HeightRail extends StatefulWidget {
  const HeightRail({
    super.key,
    required this.currentLevel,
    required this.visited,
    required this.onSelect,
    this.nudgeUp = false,
  });

  final ViewHeightLevel currentLevel;
  final Set<ViewHeightLevel> visited;
  final ValueChanged<ViewHeightLevel> onSelect;
  final bool nudgeUp; // idle hint: bounce the marker up a touch

  @override
  State<HeightRail> createState() => _HeightRailState();
}

class _HeightRailState extends State<HeightRail> {
  static const double _pad = 10; // track inset top/bottom
  static const double _marker = 50;

  bool _dragging = false;
  double _dragNorm = 0;

  double _norm(ViewHeightLevel l) => kHeightLevels[l]!.railNormY;

  double _yFor(double norm, double h) => _pad + norm * (h - 2 * _pad);

  void _onPan(double localY, double h) {
    final span = h - 2 * _pad;
    final n = ((localY - _pad) / span).clamp(0.04, 0.92);
    setState(() => _dragNorm = n);
  }

  void _endPan() {
    final level = nearestLevelForNormY(_dragNorm);
    setState(() => _dragging = false);
    widget.onSelect(level);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 96,
      child: LayoutBuilder(
        builder: (context, c) {
          final h = c.maxHeight;
          final markerNorm = _dragging ? _dragNorm : _norm(widget.currentLevel);
          final markerY = _yFor(markerNorm, h);
          const trackLeft = 6.0;
          const trackW = 38.0;

          return Stack(
            clipBehavior: Clip.none,
            children: [
              // Rail image, spanning the track.
              Positioned(
                left: trackLeft + trackW / 2 - 9,
                top: _pad - 6,
                bottom: _pad - 6,
                width: 18,
                child: netImageWidget(HM.flutter(HM.rail), fit: BoxFit.fill),
              ),

              // SPACE / EARTH end labels.
              Positioned(
                left: trackLeft, top: -2, width: trackW,
                child: _endLabel('SPACE'),
              ),
              Positioned(
                left: trackLeft, bottom: -2, width: trackW,
                child: _endLabel('EARTH'),
              ),

              // Nodes + labels.
              for (final entry in kHeightLevels.entries)
                ..._nodeAndLabel(entry.value, h, trackLeft, trackW),

              // Forgiving drag area over the whole track.
              Positioned(
                left: 0, top: 0, bottom: 0, width: trackLeft + trackW,
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onVerticalDragStart: (d) {
                    setState(() {
                      _dragging = true;
                      _dragNorm = markerNorm;
                    });
                    _onPan(d.localPosition.dy, h);
                  },
                  onVerticalDragUpdate: (d) => _onPan(d.localPosition.dy, h),
                  onVerticalDragEnd: (_) => _endPan(),
                ),
              ),

              // Camera marker.
              AnimatedPositioned(
                duration: _dragging ? Duration.zero : const Duration(milliseconds: 220),
                curve: Curves.easeOutBack,
                left: trackLeft + trackW / 2 - _marker / 2,
                top: markerY - _marker / 2 + (widget.nudgeUp && !_dragging ? -6 : 0),
                child: IgnorePointer(
                  child: AnimatedScale(
                    scale: _dragging ? 1.08 : 1.0,
                    duration: const Duration(milliseconds: 140),
                    child: netImageWidget(
                      HM.flutter(_dragging ? HM.markerDragging : HM.markerIdle),
                      width: _marker,
                      height: _marker,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  List<Widget> _nodeAndLabel(HeightLevelConfig cfg, double h, double trackLeft, double trackW) {
    final y = _yFor(cfg.railNormY, h);
    final isCurrent = cfg.level == widget.currentLevel;
    final isVisited = widget.visited.contains(cfg.level);
    final node = isCurrent
        ? HM.nodeActive
        : isVisited
            ? HM.nodeCompleted
            : HM.nodeInactive;
    const nodeSize = 22.0;
    return [
      Positioned(
        left: trackLeft + trackW / 2 - nodeSize / 2,
        top: y - nodeSize / 2,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => widget.onSelect(cfg.level), // tap-to-jump (PRD §23)
          child: netImageWidget(HM.flutter(node), width: nodeSize, height: nodeSize),
        ),
      ),
      Positioned(
        left: trackLeft + trackW + 2,
        top: y - 9,
        child: IgnorePointer(
          child: Text(
            cfg.railLabel,
            style: CareerText.label.copyWith(
              fontSize: 8.5,
              letterSpacing: 0.2,
              color: isCurrent
                  ? CareerColors.cyan
                  : isVisited
                      ? Colors.white
                      : CareerColors.textMuted,
              shadows: const [Shadow(color: Colors.black87, blurRadius: 4)],
            ),
          ),
        ),
      ),
    ];
  }

  Widget _endLabel(String t) => IgnorePointer(
        child: Center(
          child: Text(t,
              style: CareerText.label.copyWith(
                  fontSize: 7.5,
                  color: CareerColors.textMuted,
                  letterSpacing: 1.0,
                  shadows: const [Shadow(color: Colors.black87, blurRadius: 4)])),
        ),
      );
}
