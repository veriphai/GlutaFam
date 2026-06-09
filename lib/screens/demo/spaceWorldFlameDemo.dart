// TEMPORARY PROTOTYPE — "Astronaut Life" space-world, built with FLAME.
//
// Same concept as spaceWorldDemo.dart (the pure-Flutter version), rebuilt on
// the Flame game engine to show what the engine makes cheap:
//   • a CAMERA that follows the astronaut across a map bigger than the screen
//   • a PARALLAX starfield (near stars drift faster than far ones -> depth)
//   • a PARTICLE thruster trail streaming behind the astronaut as it travels
//
// The visuals are still placeholder (emoji + glow). Flame doesn't make it
// prettier — it makes motion, depth, a roaming camera, and particles easy.
//
// To remove: delete this file + the pure-Flutter demo, remove `flame` from
// pubspec, and revert the one-line swap in lib/main.dart back to HomeScreenV2().

import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/particles.dart';
import 'package:flutter/material.dart';

enum MissionStatus { completed, unlocked, locked }

class MissionData {
  final String title;
  final String emoji; // used only in the Flutter bottom sheet (renders fine there)
  final Color color; // planet body colour (Flame draws shapes, not emoji)
  final Vector2 pos; // WORLD coordinates (the map is bigger than the screen)
  MissionStatus status;
  MissionData(this.title, this.emoji, this.color, this.pos, this.status);
}

// ───────────────────────────────────────────────────────── Flutter wrapper ──

class SpaceWorldFlameDemo extends StatefulWidget {
  const SpaceWorldFlameDemo({super.key});

  @override
  State<SpaceWorldFlameDemo> createState() => _SpaceWorldFlameDemoState();
}

class _SpaceWorldFlameDemoState extends State<SpaceWorldFlameDemo> {
  late final List<MissionData> _missions;
  late final SpaceGame _game;

  @override
  void initState() {
    super.initState();
    _missions = [
      MissionData('Liftoff', '🌍', const Color(0xFF4A90D9), Vector2(0, 800), MissionStatus.completed),
      MissionData('Orbit Insertion', '🛰️', const Color(0xFF9AA0B5), Vector2(320, 430), MissionStatus.unlocked),
      MissionData('Spacewalk', '🪐', const Color(0xFFE0A458), Vector2(-140, 60), MissionStatus.locked),
      MissionData('Moon Landing', '🌙', const Color(0xFFCED3DC), Vector2(260, -360), MissionStatus.locked),
      MissionData('Deep Space', '☄️', const Color(0xFF8E7CC3), Vector2(-60, -760), MissionStatus.locked),
    ];
    _game = SpaceGame(
      missions: _missions,
      onArrive: _showMissionSheet,
      onLocked: _showLocked,
    );
  }

  void _showLocked() {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(
        content: Text('🔒 Reach the previous mission first'),
        duration: Duration(milliseconds: 1400),
        behavior: SnackBarBehavior.floating,
      ));
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
                  onPressed: () {
                    setState(() {
                      m.status = MissionStatus.completed;
                      final next = index + 1;
                      if (next < _missions.length && _missions[next].status == MissionStatus.locked) {
                        _missions[next].status = MissionStatus.unlocked;
                      }
                    });
                    Navigator.pop(ctx);
                  },
                  child: const Text('Mark complete (demo) →', style: TextStyle(color: Colors.white60)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final completed = _missions.where((m) => m.status == MissionStatus.completed).length;
    return Scaffold(
      body: Stack(
        children: [
          GameWidget(game: _game),
          // Flutter UI layered over the Flame canvas (header + badge).
          Positioned(
            top: 0,
            left: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('🚀 Astronaut Life (Flame)',
                        style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('$completed / ${_missions.length} missions · tap a glowing planet · camera follows you',
                        style: const TextStyle(color: Colors.white60, fontSize: 12)),
                  ],
                ),
              ),
            ),
          ),
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
                child: const Text('FLAME · PROTOTYPE',
                    style: TextStyle(color: Colors.white70, fontSize: 10, letterSpacing: 1.2, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────── the game ──

class SpaceGame extends FlameGame with DragCallbacks {
  SpaceGame({required this.missions, required this.onArrive, required this.onLocked});

  final List<MissionData> missions;
  final void Function(int index) onArrive;
  final VoidCallback onLocked;

  late final AstronautComponent astronaut;
  bool traveling = false;

  @override
  Color backgroundColor() => const Color(0xFF050511);

  @override
  Future<void> onLoad() async {
    // Screen-space background layers (parallax depth).
    // NOTE: must go in `backdrop` (renders BEHIND the world), not `viewport`
    // (which renders ON TOP and would hide the planets/astronaut).
    camera.backdrop.add(GradientBackground());
    camera.backdrop.add(StarfieldComponent());

    // World-space content (moves with the camera).
    world.add(PathComponent(missions.map((m) => m.pos).toList()));
    for (var i = 0; i < missions.length; i++) {
      world.add(PlanetComponent(i, missions[i]));
    }
    astronaut = AstronautComponent()..position = missions.first.pos.clone();
    world.add(astronaut);

    // Start the view centred on the astronaut. Follow only kicks in while
    // travelling, so the rest of the time you can freely drag-pan the map.
    camera.viewfinder.zoom = 0.7;
    camera.viewfinder.position = astronaut.position.clone();
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    if (traveling) return;
    // Grab-and-drag the map: convert the screen-space drag into world units.
    camera.viewfinder.position -= event.localDelta / camera.viewfinder.zoom;
  }

  void travelTo(int index) {
    if (traveling) return;
    traveling = true;
    astronaut.thrusting = true;
    camera.follow(astronaut); // track the astronaut during the trip
    astronaut.add(
      MoveToEffect(
        missions[index].pos.clone(),
        EffectController(duration: 1.25, curve: Curves.easeInOutCubic),
        onComplete: () {
          traveling = false;
          astronaut.thrusting = false;
          camera.stop(); // release follow so the user can drag-pan again
          onArrive(index);
        },
      ),
    );
  }
}

// ───────────────────────────────────────────────────────────── components ──

class AstronautComponent extends PositionComponent with HasGameReference<SpaceGame> {
  AstronautComponent() : super(size: Vector2.all(56), anchor: Anchor.center);

  final _rnd = math.Random();
  bool thrusting = false;
  double _t = 0;
  double _emit = 0;

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    if (thrusting) {
      _emit -= dt;
      if (_emit <= 0) {
        _emit = 0.035;
        _spawnTrail();
      }
    }
  }

  void _spawnTrail() {
    game.world.add(
      ParticleSystemComponent(
        position: position.clone(),
        particle: Particle.generate(
          count: 4,
          lifespan: 0.7,
          generator: (i) => AcceleratedParticle(
            speed: Vector2((_rnd.nextDouble() - 0.5) * 50, _rnd.nextDouble() * 70 + 30),
            child: CircleParticle(
              radius: _rnd.nextDouble() * 2.5 + 1,
              paint: Paint()..color = const Color(0xFF00CEC9).withValues(alpha: 0.8),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void render(Canvas canvas) {
    // Gentle idle bob (render-only, so the follow-camera doesn't jitter).
    final bob = game.traveling ? 0.0 : math.sin(_t * 2) * 4;
    canvas.save();
    canvas.translate(0, bob);
    final center = Offset(size.x / 2, size.y / 2);
    // glow
    canvas.drawCircle(
      center,
      22,
      Paint()
        ..color = const Color(0xFF6C5CE7).withValues(alpha: 0.6)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14),
    );
    // helmet
    canvas.drawCircle(center, 15, Paint()..color = Colors.white);
    // visor
    canvas.drawCircle(center + const Offset(0, -1), 9, Paint()..color = const Color(0xFF12143A));
    // visor highlight
    canvas.drawCircle(center + const Offset(-3, -3), 2.5, Paint()..color = const Color(0xFF00CEC9));
    canvas.restore();
  }
}

class PlanetComponent extends PositionComponent with TapCallbacks, HasGameReference<SpaceGame> {
  PlanetComponent(this.index, this.data)
      : super(size: Vector2.all(64), anchor: Anchor.center, position: data.pos.clone());

  final int index;
  final MissionData data;

  final _label = TextPaint(
    style: const TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w600),
  );
  final _labelLocked = TextPaint(
    style: const TextStyle(fontSize: 13, color: Colors.white38, fontWeight: FontWeight.w600),
  );
  double _t = 0;

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    final pulse = data.status == MissionStatus.unlocked ? 1 + math.sin(_t * 3) * 0.06 : 1.0;
    scale = Vector2.all(pulse);
  }

  Color get _glow => switch (data.status) {
        MissionStatus.completed => const Color(0xFF2ECC71),
        MissionStatus.unlocked => const Color(0xFF00CEC9),
        MissionStatus.locked => Colors.white24,
      };

  @override
  void render(Canvas canvas) {
    final center = Offset(size.x / 2, size.y / 2);
    final locked = data.status == MissionStatus.locked;

    // status glow
    if (!locked) {
      canvas.drawCircle(
        center,
        30,
        Paint()
          ..color = _glow.withValues(alpha: 0.5)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14),
      );
    }
    // planet body
    canvas.drawCircle(
      center,
      24,
      Paint()..color = locked ? data.color.withValues(alpha: 0.25) : data.color,
    );
    // status ring
    canvas.drawCircle(
      center,
      29,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = _glow,
    );
    // completed -> checkmark; locked -> small lock bar
    if (data.status == MissionStatus.completed) {
      final tick = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..color = Colors.white;
      canvas.drawPath(
        Path()
          ..moveTo(center.dx - 7, center.dy)
          ..lineTo(center.dx - 1, center.dy + 6)
          ..lineTo(center.dx + 8, center.dy - 6),
        tick,
      );
    }
    final tp = locked ? _labelLocked : _label;
    tp.render(canvas, data.title, Vector2(center.dx, size.y + 8), anchor: Anchor.topCenter);
  }

  @override
  void onTapUp(TapUpEvent event) {
    if (data.status == MissionStatus.locked) {
      game.onLocked();
      return;
    }
    game.travelTo(index);
  }
}

class PathComponent extends Component {
  PathComponent(this.points);
  final List<Vector2> points;

  @override
  void render(Canvas canvas) {
    if (points.length < 2) return;
    final path = Path()..moveTo(points.first.x, points.first.y);
    for (var i = 1; i < points.length; i++) {
      path.lineTo(points[i].x, points[i].y);
    }
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xFF6C5CE7).withValues(alpha: 0.18)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    final dash = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..color = Colors.white.withValues(alpha: 0.35);
    for (final metric in path.computeMetrics()) {
      var dist = 0.0;
      while (dist < metric.length) {
        final len = math.min(10.0, metric.length - dist);
        canvas.drawPath(metric.extractPath(dist, dist + len), dash);
        dist += 18.0;
      }
    }
  }
}

// ───────────────────────────────────────────── screen-space background ──

class GradientBackground extends Component with HasGameReference<FlameGame> {
  @override
  void render(Canvas canvas) {
    final rect = Offset.zero & Size(game.size.x, game.size.y);
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0B0B2B), Color(0xFF1A1140), Color(0xFF050511)],
        ).createShader(rect),
    );
  }
}

class _StarLayer {
  _StarLayer(math.Random rnd, int count, this.factor, this.radius, this.opacity)
      : stars = List.generate(count, (_) => Vector2(rnd.nextDouble(), rnd.nextDouble()));
  final List<Vector2> stars; // normalized 0..1 within one screen tile
  final double factor; // parallax strength (smaller = farther away)
  final double radius;
  final double opacity;
}

class StarfieldComponent extends Component with HasGameReference<FlameGame> {
  StarfieldComponent() {
    final rnd = math.Random(7);
    _layers = [
      _StarLayer(rnd, 70, 0.12, 1.2, 0.5), // far
      _StarLayer(rnd, 30, 0.30, 2.0, 0.85), // near
    ];
  }
  late final List<_StarLayer> _layers;

  @override
  void render(Canvas canvas) {
    final w = game.size.x;
    final h = game.size.y;
    if (w == 0 || h == 0) return;
    final cam = game.camera.viewfinder.position; // world center the camera looks at
    final paint = Paint();
    for (final layer in _layers) {
      paint.color = Colors.white.withValues(alpha: layer.opacity);
      final ox = -(cam.x * layer.factor) % w;
      final oy = -(cam.y * layer.factor) % h;
      for (final s in layer.stars) {
        var x = (s.x * w + ox) % w;
        var y = (s.y * h + oy) % h;
        if (x < 0) x += w;
        if (y < 0) y += h;
        canvas.drawCircle(Offset(x, y), layer.radius, paint);
      }
    }
  }
}
