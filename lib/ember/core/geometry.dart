// Ember — core/geometry.dart
//
// GridCoord: the integer (x,y) value type used everywhere a tile position is
// needed. Pure, immutable, value-equal, JSON-friendly. No Flutter Offset here —
// the game layer projects GridCoord into screen space; the source of truth is
// integer grid space.

import 'dart:math' as math;

/// An immutable integer grid cell coordinate.
class GridCoord {
  const GridCoord(this.x, this.y);

  final int x;
  final int y;

  static const GridCoord zero = GridCoord(0, 0);

  /// The four orthogonal neighbours (N,E,S,W) in N,S,E,W independent order.
  List<GridCoord> get neighbors4 => <GridCoord>[
        GridCoord(x, y - 1),
        GridCoord(x + 1, y),
        GridCoord(x, y + 1),
        GridCoord(x - 1, y),
      ];

  /// The eight surrounding neighbours (orthogonal + diagonal).
  List<GridCoord> get neighbors8 => <GridCoord>[
        GridCoord(x - 1, y - 1),
        GridCoord(x, y - 1),
        GridCoord(x + 1, y - 1),
        GridCoord(x - 1, y),
        GridCoord(x + 1, y),
        GridCoord(x - 1, y + 1),
        GridCoord(x, y + 1),
        GridCoord(x + 1, y + 1),
      ];

  GridCoord translate(int dx, int dy) => GridCoord(x + dx, y + dy);

  GridCoord operator +(GridCoord o) => GridCoord(x + o.x, y + o.y);
  GridCoord operator -(GridCoord o) => GridCoord(x - o.x, y - o.y);

  /// Manhattan (taxicab) distance — used for cheap range checks.
  int manhattanTo(GridCoord o) => (x - o.x).abs() + (y - o.y).abs();

  /// Chebyshev (chessboard) distance — 8-neighbour radius.
  int chebyshevTo(GridCoord o) =>
      math.max((x - o.x).abs(), (y - o.y).abs());

  /// Euclidean distance (for falloff curves like light/coverage).
  double euclideanTo(GridCoord o) {
    final int dx = x - o.x;
    final int dy = y - o.y;
    return math.sqrt((dx * dx + dy * dy).toDouble());
  }

  /// Rectangular footprint of [w]x[h] tiles anchored at this coord.
  List<GridCoord> footprint(int w, int h) {
    final List<GridCoord> out = <GridCoord>[];
    for (int dy = 0; dy < h; dy++) {
      for (int dx = 0; dx < w; dx++) {
        out.add(GridCoord(x + dx, y + dy));
      }
    }
    return out;
  }

  Map<String, dynamic> toJson() => <String, dynamic>{'x': x, 'y': y};

  factory GridCoord.fromJson(Map<String, dynamic> j) => GridCoord(
        (j['x'] as num?)?.toInt() ?? 0,
        (j['y'] as num?)?.toInt() ?? 0,
      );

  @override
  bool operator ==(Object other) =>
      other is GridCoord && other.x == x && other.y == y;

  @override
  int get hashCode => Object.hash(x, y);

  @override
  String toString() => '($x, $y)';
}
