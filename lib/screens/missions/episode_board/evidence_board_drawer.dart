// The peek DRAWER — tap the corner case node to pull up the evidence board: the
// pinned guiding question at the top and every photo collected so far, pinned to a
// warm desk. Peekable any time, never required. Slides up over the activity (which
// dims behind it); close on the X or the scrim.

import 'dart:typed_data';

import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'case_theme.dart';
import 'evidence_models.dart';
import 'photo_card.dart';

class EvidenceBoardDrawer extends StatefulWidget {
  const EvidenceBoardDrawer({
    super.key,
    required this.question,
    required this.capturedIds,
    required this.images,
    required this.onClose,
  });

  final String question;
  final ValueListenable<List<String>> capturedIds;
  final ValueListenable<Map<String, Uint8List>> images;
  final VoidCallback onClose;

  @override
  State<EvidenceBoardDrawer> createState() => _EvidenceBoardDrawerState();
}

class _EvidenceBoardDrawerState extends State<EvidenceBoardDrawer> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 380));

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Future<void> _close() async {
    await _c.reverse();
    widget.onClose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final t = Curves.easeOutCubic.transform(_c.value);
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                onTap: _close,
                child: Opacity(opacity: 0.7 * t, child: const ColoredBox(color: Color(0xFF05070F))),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: FractionalTranslation(
                translation: Offset(0, 1 - t),
                child: _panel(context),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _panel(BuildContext context) {
    final h = MediaQuery.of(context).size.height * 0.82;
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
      child: SizedBox(
        height: h,
        child: CaseBoardBackground(
          child: SafeArea(
            top: false,
            child: Column(
              children: [
                const SizedBox(height: 10),
                Container(width: 44, height: 5, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(3))),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 12, 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('THE CASE',
                                style: GoogleFonts.ibmPlexMono(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 2.4, color: CaseTheme.gold)),
                            const SizedBox(height: 4),
                            Text(widget.question,
                                style: GoogleFonts.bricolageGrotesque(fontSize: 17, height: 1.2, fontWeight: FontWeight.w800, color: Colors.white)),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: _close,
                        icon: const Icon(Icons.close_rounded, color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                Divider(color: Colors.white.withValues(alpha: 0.1), height: 1),
                Expanded(
                  child: ValueListenableBuilder<List<String>>(
                    valueListenable: widget.capturedIds,
                    builder: (context, ids, _) => ValueListenableBuilder<Map<String, Uint8List>>(
                      valueListenable: widget.images,
                      builder: (context, imgs, __) => _board(context, ids, imgs),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _board(BuildContext context, List<String> ids, Map<String, Uint8List> imgs) {
    if (ids.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.photo_camera_rounded, size: 34, color: Colors.white.withValues(alpha: 0.3)),
            const SizedBox(height: 10),
            Text('No clues yet — keep exploring.',
                style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: Colors.white.withValues(alpha: 0.55))),
          ],
        ),
      );
    }
    final w = MediaQuery.of(context).size.width;
    final photo = ((w - 20 * 2 - 20) / 2).clamp(110.0, 160.0);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 28),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 20,
        runSpacing: 24,
        children: [
          for (var i = 0; i < ids.length; i++)
            if (evidenceById(ids[i]) != null)
              PhotoCard(
                tile: evidenceById(ids[i])!,
                size: photo,
                imageBytes: imgs[ids[i]],
                tilt: (i.isEven ? 1 : -1) * 0.03,
              ),
        ],
      ),
    );
  }
}
