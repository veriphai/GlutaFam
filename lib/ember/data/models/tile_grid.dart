// Ember — data/models/tile_grid.dart
//
// Dense row-major matrix of Tiles. The spatial source of truth. Round-trips as
// {width,height,tiles:[...]} where tiles are stored in row-major order, so
// fromJson rebuilds the exact same matrix.

import '../../core/enums.dart';
import '../../core/geometry.dart';
import 'tile.dart';

class TileGrid {
  TileGrid({
    required this.width,
    required this.height,
    required List<Tile> tiles,
  })  : assert(tiles.length == width * height,
            'tiles length ${tiles.length} != $width*$height'),
        _tiles = List<Tile>.of(tiles, growable: false);

  /// Builds an all-grass grid of [width]x[height] for scaffolding/empties.
  factory TileGrid.filled(
    int width,
    int height, {
    TerrainType terrain = TerrainType.grass,
  }) {
    final List<Tile> tiles = <Tile>[];
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        tiles.add(Tile.fromTerrain(GridCoord(x, y), terrain));
      }
    }
    return TileGrid(width: width, height: height, tiles: tiles);
  }

  final int width;
  final int height;
  final List<Tile> _tiles; // row-major: index = y*width + x

  /// Unmodifiable view of all tiles (row-major).
  List<Tile> get tiles => List<Tile>.unmodifiable(_tiles);

  int get length => _tiles.length;

  bool inBounds(GridCoord c) =>
      c.x >= 0 && c.y >= 0 && c.x < width && c.y < height;

  int _index(GridCoord c) => c.y * width + c.x;

  /// Tile at [c], or null if out of bounds.
  Tile? at(GridCoord c) => inBounds(c) ? _tiles[_index(c)] : null;

  /// Tile at [c], asserting in-bounds (use when you know it's valid).
  Tile atUnsafe(GridCoord c) => _tiles[_index(c)];

  /// Returns the tiles covered by a [w]x[h] footprint anchored at [origin],
  /// or null if any cell is out of bounds.
  List<Tile>? footprint(GridCoord origin, int w, int h) {
    final List<Tile> out = <Tile>[];
    for (final GridCoord c in origin.footprint(w, h)) {
      final Tile? t = at(c);
      if (t == null) return null;
      out.add(t);
    }
    return out;
  }

  /// The set of distinct regionIds present in the grid (a region is "unlocked"
  /// once any of its tiles is explored).
  Set<int> get unlockedRegions {
    final Set<int> regions = <int>{};
    for (final Tile t in _tiles) {
      if (t.explored) regions.add(t.regionId);
    }
    return regions;
  }

  /// Returns a NEW grid with [tile] written at its coord (immutable update).
  TileGrid withTile(Tile tile) {
    if (!inBounds(tile.coord)) return this;
    final List<Tile> next = List<Tile>.of(_tiles);
    next[_index(tile.coord)] = tile;
    return TileGrid(width: width, height: height, tiles: next);
  }

  /// Returns a NEW grid applying [update] to each of [coords] that are in bounds.
  TileGrid withTiles(Iterable<GridCoord> coords, Tile Function(Tile) update) {
    final List<Tile> next = List<Tile>.of(_tiles);
    for (final GridCoord c in coords) {
      if (inBounds(c)) {
        final int i = _index(c);
        next[i] = update(next[i]);
      }
    }
    return TileGrid(width: width, height: height, tiles: next);
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'width': width,
        'height': height,
        'tiles': <Map<String, dynamic>>[
          for (final Tile t in _tiles) t.toJson(),
        ],
      };

  factory TileGrid.fromJson(Map<String, dynamic> j) {
    final int w = (j['width'] as num?)?.toInt() ?? 0;
    final int h = (j['height'] as num?)?.toInt() ?? 0;
    final List<dynamic> raw = (j['tiles'] as List?) ?? const <dynamic>[];
    final List<Tile> tiles = <Tile>[
      for (final dynamic e in raw)
        Tile.fromJson((e as Map).cast<String, dynamic>()),
    ];
    return TileGrid(width: w, height: h, tiles: tiles);
  }

  @override
  bool operator ==(Object other) {
    if (other is! TileGrid) return false;
    if (other.width != width || other.height != height) return false;
    if (other._tiles.length != _tiles.length) return false;
    for (int i = 0; i < _tiles.length; i++) {
      if (other._tiles[i] != _tiles[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(width, height, Object.hashAll(_tiles));
}
