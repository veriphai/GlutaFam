// TEMPORARY PROTOTYPE — "Astronaut Life" space-world concept.
//
// Pure Flutter (CustomPainter + animations), no assets, no extra packages.
// Demonstrates the interaction we discussed: a floating astronaut, planets as
// mission nodes on a path, tap an unlocked planet -> astronaut glides to it ->
// a "Start Mission" sheet appears -> completing it unlocks the next node.
//
// This is a throwaway concept test, NOT production. The polished version would
// swap the emoji/shape placeholders for Rive (or commissioned sprite) art.
//
// To remove: delete this file and revert the one-line swap in lib/main.dart
// (MainPage `screens` list) back to HomeScreenV2().

import 'dart:math' as math;
import 'package:flutter/material.dart';

enum MissionStatus { completed, unlocked, locked }

class _Mission {
  final String title;
  final String emoji;
  final Offset pos; // normalized (0..1, 0..1)
  MissionStatus status;
  _Mission({
    required this.title,
    required this.emoji,
    required this.pos,
    required this.status,
  });
}

class _Star {
  final Offset pos; // normalized
  final double radius;
  final double phase;
  final double baseOpacity;
  _Star(this.pos, this.radius, this.phase, this.baseOpacity);
}

class SpaceWorldDemo extends StatefulWidget {
  const SpaceWorldDemo({super.key});

  @override
  State<SpaceWorldDemo> createState() => _SpaceWorldDemoState();
}

class _SpaceWorldDemoState extends State<SpaceWorldDemo>
    with TickerProviderStateMixin {
  late final AnimationController _bob; // floating idle
  late final AnimationController _stars; // twinkle
  late final AnimationController _travel; // astronaut movement
  Animation<Offset>? _travelAnim;

  late final List<_Mission> _missions;
  late final List<_Star> _starfield;

  late Offset _astronaut; // current normalized position
  bool _traveling = false;

  @override
  void initState() {
    super.initState();

    _missions = [
      _Mission(title: 'Liftoff', emoji: '🌍', pos: const Offset(0.26, 0.84), status: MissionStatus.completed),
      _Mission(title: 'Orbit Insertion', emoji: '🛰️', pos: const Offset(0.66, 0.67), status: MissionStatus.unlocked),
      _Mission(title: 'Spacewalk', emoji: '🪐', pos: const Offset(0.30, 0.49), status: MissionStatus.locked),
      _Mission(title: 'Moon Landing', emoji: '🌙', pos: const Offset(0.70, 0.32), status: MissionStatus.locked),
      _Mission(title: 'Deep Space', emoji: '☄️', pos: const Offset(0.42, 0.15), status: MissionStatus.locked),
    ];
    _astronaut = _missions.first.pos;

    final rnd = math.Random(7);
    _starfield = List.generate(90, (_) {
      return _Star(
        Offset(rnd.nextDouble(), rnd.nextDouble()),
        rnd.nextDouble() * 1.6 + 0.4,
        rnd.nextDouble() * math.pi * 2,
        rnd.nextDouble() * 0.5 + 0.3,
      );
    });

    _bob = AnimationController(vsync: this, duration: const Duration(milliseconds: 2200))..repeat(reverse: true);
    _stars = AnimationController(vsync: this, duration: const Duration(seconds: 5))..repeat();
    _travel = AnimationController(vsync: this, duration: const Duration(milliseconds: 950));
  }

  @override
  void dispose() {
    _bob.dispose();
    _stars.dispose();
    _travel.dispose();
    super.dispose();
  }

  void _onTapNode(int i) {
    final m = _missions[i];
    if (m.status == MissionStatus.locked) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(
          content: Text('🔒 Reach the previous mission first'),
          duration: Duration(milliseconds: 1400),
          behavior: SnackBarBehavior.floating,
        ));
      return;
    }
    if (_traveling) return;
    _goTo(i);
  }

  void _goTo(int targetIndex) {
    final target = _missions[targetIndex].pos;
    _travelAnim = Tween<Offset>(begin: _astronaut, end: target)
        .animate(CurvedAnimation(parent: _travel, curve: Curves.easeInOutCubic));
    setState(() => _traveling = true);
    _travel.forward(from: 0).then((_) {
      if (!mounted) return;
      setState(() {
        _astronaut = target;
        _traveling = false;
      });
      _showMissionSheet(targetIndex);
    });
  }

  void _showMissionSheet(int index) {
    final m = _missions[index];
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF15173A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 14, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 20),
            Row(children: [
              Text(m.emoji, style: const TextStyle(fontSize: 34)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(m.title, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                  Text('Mission ${index + 1} of ${_missions.length}', style: const TextStyle(color: Colors.white54, fontSize: 13)),
                ]),
              ),
            ]),
            const SizedBox(height: 16),
            const Text(
              'In the real app, "Start Mission" opens your existing lesson / AI-tutor screen for this concept.',
              style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.4),
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C5CE7),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('🚀 (Demo) Your lesson screen would open here'),
                    behavior: SnackBarBehavior.floating,
                  ));
                },
                child: const Text('Start Mission', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            if (m.status != MissionStatus.completed) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => _complete(index),
                  child: const Text('Mark complete (demo) →', style: TextStyle(color: Colors.white60)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _complete(int index) {
    setState(() {
      _missions[index].status = MissionStatus.completed;
      final next = index + 1;
      if (next < _missions.length && _missions[next].status == MissionStatus.locked) {
        _missions[next].status = MissionStatus.unlocked;
      }
    });
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final completed = _missions.where((m) => m.status == MissionStatus.completed).length;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0B0B2B), Color(0xFF1A1140), Color(0xFF050511)],
          ),
        ),
        child: LayoutBuilder(
          builder: (context, c) {
            final w = c.maxWidth;
            final h = c.maxHeight;
            Offset px(Offset n) => Offset(n.dx * w, n.dy * h);

            return AnimatedBuilder(
              animation: Listenable.merge([_bob, _stars, _travel]),
              builder: (context, _) {
                final bob = math.sin(_bob.value * math.pi * 2) * 10; // px
                final aNorm = _traveling && _travelAnim != null ? _travelAnim!.value : _astronaut;
                final aPx = px(aNorm) + Offset(0, _traveling ? 0 : bob);

                return Stack(
                  children: [
                    Positioned.fill(
                      child: CustomPaint(painter: _StarPainter(_starfield, _stars.value)),
                    ),
                    Positioned.fill(
                      child: CustomPaint(painter: _PathPainter(_missions.map((m) => px(m.pos)).toList())),
                    ),
                    for (int i = 0; i < _missions.length; i++) _buildNode(i, px(_missions[i].pos)),
                    Positioned(
                      left: aPx.dx - 28,
                      top: aPx.dy - 28,
                      child: _astronautWidget(),
                    ),
                    _buildHeader(completed),
                    Positioned(
                      top: 0,
                      right: 0,
                      child: SafeArea(
                        child: Container(
                          margin: const EdgeInsets.all(12),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.white12,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white24),
                          ),
                          child: const Text('PROTOTYPE',
                              style: TextStyle(color: Colors.white70, fontSize: 10, letterSpacing: 1.2, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(int completed) {
    return Positioned(
      top: 0,
      left: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('🚀 Astronaut Life',
                  style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text('$completed / ${_missions.length} missions complete · tap a glowing planet',
                  style: const TextStyle(color: Colors.white60, fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _astronautWidget() {
    return Container(
      width: 56,
      height: 56,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: const Color(0xFF6C5CE7).withValues(alpha: 0.6), blurRadius: 24, spreadRadius: 2)],
      ),
      child: const Text('🧑‍🚀', style: TextStyle(fontSize: 40)),
    );
  }

  Widget _buildNode(int i, Offset center) {
    final m = _missions[i];
    final isUnlocked = m.status == MissionStatus.unlocked;
    final isCompleted = m.status == MissionStatus.completed;
    final isLocked = m.status == MissionStatus.locked;
    final pulse = isUnlocked ? 1 + math.sin(_bob.value * math.pi * 2) * 0.06 : 1.0;

    final Color glow = isCompleted
        ? const Color(0xFF2ECC71)
        : isUnlocked
            ? const Color(0xFF00CEC9)
            : Colors.white24;

    return Positioned(
      left: center.dx - 42,
      top: center.dy - 50,
      child: GestureDetector(
        onTap: () => _onTapNode(i),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Transform.scale(
              scale: pulse,
              child: Container(
                width: 64,
                height: 64,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.05),
                  border: Border.all(color: glow, width: 2),
                  boxShadow: isLocked ? null : [BoxShadow(color: glow.withValues(alpha: 0.5), blurRadius: 18, spreadRadius: 1)],
                ),
                child: Opacity(
                  opacity: isLocked ? 0.4 : 1,
                  child: Text(m.emoji, style: const TextStyle(fontSize: 30)),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(8)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                if (isLocked)
                  const Padding(padding: EdgeInsets.only(right: 4), child: Icon(Icons.lock, size: 11, color: Colors.white54)),
                if (isCompleted)
                  const Padding(padding: EdgeInsets.only(right: 4), child: Icon(Icons.check_circle, size: 11, color: Color(0xFF2ECC71))),
                Text(m.title,
                    style: TextStyle(color: isLocked ? Colors.white38 : Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}

class _StarPainter extends CustomPainter {
  final List<_Star> stars;
  final double t;
  _StarPainter(this.stars, this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    for (final s in stars) {
      final tw = (math.sin(t * math.pi * 2 + s.phase) + 1) / 2;
      paint.color = Colors.white.withValues(alpha: (s.baseOpacity * (0.4 + tw * 0.6)).clamp(0.0, 1.0));
      canvas.drawCircle(Offset(s.pos.dx * size.width, s.pos.dy * size.height), s.radius, paint);
    }
  }

  @override
  bool shouldRepaint(_StarPainter old) => old.t != t;
}

class _PathPainter extends CustomPainter {
  final List<Offset> points;
  _PathPainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    final glow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..color = const Color(0xFF6C5CE7).withValues(alpha: 0.18)
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..color = Colors.white.withValues(alpha: 0.35)
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, glow);
    _drawDashed(canvas, path, line);
  }

  void _drawDashed(Canvas canvas, Path source, Paint paint) {
    const dash = 10.0, gap = 8.0;
    for (final metric in source.computeMetrics()) {
      double dist = 0;
      while (dist < metric.length) {
        final len = math.min(dash, metric.length - dist);
        canvas.drawPath(metric.extractPath(dist, dist + len), paint);
        dist += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(_PathPainter old) => old.points != points;
}
