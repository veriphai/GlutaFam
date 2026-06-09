// Stage 1 — Choose the Right Satellite (PRD §12). Four hologram satellites on
// stacked platform rows; the child drags a cyan SCANNER BEAM vertically over
// them — the row under the beam glows and reveals its power (no MCQ cards;
// discovery through scanning). Deploy CTA binds to the last-scanned satellite;
// a wrong deploy just hints and keeps the scanner alive.

import 'package:flutter/material.dart';

import '../config/scc_assets.dart';
import '../config/scc_stage_configs.dart';
import '../config/scc_theme.dart';
import '../state/mission_stage_controller.dart';
import '../widgets/mission_dialogue_overlay.dart';
import '../widgets/scanner_beam.dart';
import '../widgets/scc_buttons.dart';

class ScannerScene extends StatefulWidget {
  const ScannerScene({super.key, required this.controller});

  final MissionStageController controller;

  @override
  State<ScannerScene> createState() => _ScannerSceneState();
}

class _ScannerSceneState extends State<ScannerScene> {
  double? _beamY; // beam centre, local to the rows area
  bool _scanning = false;
  bool _movingUp = false; // veil trails on the opposite side
  int _rowUnderBeam = -1;
  int _contactToken = 0; // bumps when the beam crosses onto a new row

  void _moveBeam(double y, double areaH) {
    final clamped = y.clamp(0.0, areaH);
    final rowH = areaH / kSatCatalog.length;
    final idx = (clamped / rowH).floor().clamp(0, kSatCatalog.length - 1);
    setState(() {
      if (_beamY != null && (clamped - _beamY!).abs() > 0.5) {
        _movingUp = clamped < _beamY!;
      }
      _beamY = clamped;
      _scanning = true;
      if (idx != _rowUnderBeam) {
        _rowUnderBeam = idx;
        _contactToken++; // contact ripple on the new row
      }
    });
    widget.controller.scanSatellite(kSatCatalog[idx].kind);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final scanner = widget.controller.state.scanner;
        return Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(child: sceneVignette(strength: 0.4)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
            children: [
              Expanded(
                child: LayoutBuilder(
                  builder: (context, box) {
                    final areaH = box.maxHeight;
                    return GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onVerticalDragStart: (d) => _moveBeam(d.localPosition.dy, areaH),
                      onVerticalDragUpdate: (d) => _moveBeam(d.localPosition.dy, areaH),
                      onVerticalDragEnd: (_) => setState(() => _scanning = false),
                      onTapDown: (d) => _moveBeam(d.localPosition.dy, areaH),
                      onTapUp: (_) => setState(() => _scanning = false),
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: Column(
                              children: [
                                for (final def in kSatCatalog)
                                  Expanded(
                                    child: _SatRow(
                                      def: def,
                                      discovered: scanner.discovered.contains(def.kind),
                                      selected: scanner.lastScanned == def.kind,
                                      // 3rd hint → visually guide to the answer
                                      // (PRD §22.4 level-3 escalation)
                                      guide: def.kind == SatKind.weather &&
                                          widget.controller.hintLevelFor(
                                                  MissionStage.chooseSatellite) >=
                                              3,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          // the scanner beam (procedural — photocopier sweep)
                          if (_beamY != null)
                            Positioned(
                              left: 0,
                              right: 0,
                              top: _beamY! - 45,
                              height: 90,
                              child: IgnorePointer(
                                child: ScannerBeam(
                                  scanning: _scanning,
                                  movingUp: _movingUp,
                                  contactToken: _contactToken,
                                  tint: _rowUnderBeam >= 0
                                      ? kSatCatalog[_rowUnderBeam].glow
                                      : SccColors.cyan,
                                ),
                              ),
                            ),
                          // first-use affordance
                          if (_beamY == null)
                            Positioned(
                              bottom: 8,
                              left: 0,
                              right: 0,
                              child: IgnorePointer(
                                child: Column(
                                  children: [
                                    const Icon(Icons.swipe_vertical_rounded,
                                        color: SccColors.cyan, size: 26),
                                    Text('drag the scanner beam',
                                        style: SccText.label
                                            .copyWith(color: SccColors.cyan)),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              // Orbit speaks ABOVE the deploy button (scene embeds the
              // bubble; the shell hides its own copy on this stage)
              Padding(
                padding: const EdgeInsets.only(right: 0),
                child: MissionDialogueOverlay(controller: widget.controller),
              ),
              const SizedBox(height: 10),
              SccCta(
                label: 'DEPLOY THIS SATELLITE',
                icon: Icons.rocket_launch_rounded,
                enabled: scanner.lastScanned != null && !scanner.deployed,
                onTap: widget.controller.deploySelected,
              ),
              const SizedBox(height: 8),
            ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SatRow extends StatelessWidget {
  const _SatRow(
      {required this.def,
      required this.discovered,
      required this.selected,
      this.guide = false});

  final SatDef def;
  final bool discovered;
  final bool selected;
  final bool guide;

  @override
  Widget build(BuildContext context) {
    final border = guide
        ? SccColors.warningAmber
        : selected
            ? def.glow
            : discovered
                ? def.glow.withValues(alpha: 0.55)
                : SccColors.panelBorder;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      margin: const EdgeInsets.symmetric(vertical: 5),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: SccColors.panelFill,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border, width: selected || guide ? 1.8 : 1.1),
        boxShadow: guide
            ? [
                BoxShadow(
                    color: SccColors.warningAmber.withValues(alpha: 0.45),
                    blurRadius: 18)
              ]
            : discovered
                ? [BoxShadow(color: def.glow.withValues(alpha: 0.25), blurRadius: 14)]
                : null,
      ),
      child: Row(
        children: [
          // hologram on its glowing platform pad — cyan-ghosted until the
          // scanner discovers it, full colour after
          Expanded(
            flex: 2,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // platform pad glow
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    height: 10,
                    margin: const EdgeInsets.only(bottom: 2),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: (discovered ? def.glow : SccColors.cyan)
                              .withValues(alpha: discovered ? 0.55 : 0.30),
                          blurRadius: 14,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                ),
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 300),
                  opacity: discovered ? 1 : 0.55,
                  child: discovered
                      ? sccImage(SCC.flutter(def.sprite), fit: BoxFit.contain)
                      : sccImage(SCC.flutter(def.sprite),
                          fit: BoxFit.contain,
                          color: SccColors.cyan.withValues(alpha: 0.55),
                          colorBlendMode: BlendMode.srcATop),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 3,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(def.name,
                    style: SccText.chip.copyWith(
                        color: discovered ? def.glow : SccColors.textMuted,
                        fontSize: 12)),
                const SizedBox(height: 3),
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 300),
                  opacity: discovered ? 1 : 0,
                  child: Text(def.power,
                      style: SccText.body.copyWith(fontSize: 11.5)),
                ),
              ],
            ),
          ),
          if (selected)
            const Icon(Icons.check_circle_rounded, color: SccColors.success, size: 18),
        ],
      ),
    );
  }
}
