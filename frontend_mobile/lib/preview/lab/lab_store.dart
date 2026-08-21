// Layout lab — isolated experiment.
// Does NOT replace KitchenPreviewShell / PreviewHomeView / PreviewInventoryView.
// Open from Kitchen preview settings → "Try layout lab (experiment)".

import 'package:flutter/material.dart';

import '../preview_store.dart';

class LabTile {
  LabTile({
    required this.id,
    required this.col,
    required this.row,
    required this.w,
    required this.h,
  });

  final HqWidgetId id;
  int col;
  int row;
  int w;
  int h;

  LabTile copy() => LabTile(id: id, col: col, row: row, w: w, h: h);
}

class LabLayoutStore extends ChangeNotifier {
  LabLayoutStore() {
    _tiles = [
      LabTile(id: HqWidgetId.colonyStatus, col: 0, row: 0, w: 4, h: 2),
      LabTile(id: HqWidgetId.tonightBriefing, col: 0, row: 2, w: 4, h: 2),
      LabTile(id: HqWidgetId.askCompanion, col: 0, row: 4, w: 4, h: 1),
      LabTile(id: HqWidgetId.topPicks, col: 0, row: 5, w: 2, h: 2),
      LabTile(id: HqWidgetId.boughtNotEaten, col: 2, row: 5, w: 2, h: 2),
      LabTile(id: HqWidgetId.mostLikedRecipe, col: 0, row: 7, w: 2, h: 2),
      LabTile(id: HqWidgetId.huddleTrending, col: 2, row: 7, w: 2, h: 2),
    ];
  }

  static const columns = 4;

  late List<LabTile> _tiles;
  bool editing = false;

  List<LabTile> get tiles => List.unmodifiable(_tiles);

  LabTile tileFor(HqWidgetId id) => _tiles.firstWhere((t) => t.id == id);

  void toggleEditing() {
    editing = !editing;
    notifyListeners();
  }

  void setEditing(bool value) {
    if (editing == value) return;
    editing = value;
    notifyListeners();
  }

  void moveTile(HqWidgetId id, int col, int row) {
    final tile = tileFor(id);
    final nextCol = col.clamp(0, columns - tile.w);
    final nextRow = row < 0 ? 0 : row;
    if (!_fits(tile, nextCol, nextRow, tile.w, tile.h, ignore: id)) {
      final slot = _firstFit(tile.w, tile.h, ignore: id);
      if (slot == null) return;
      tile.col = slot.$1;
      tile.row = slot.$2;
    } else {
      tile.col = nextCol;
      tile.row = nextRow;
    }
    notifyListeners();
  }

  void resizeTile(HqWidgetId id, int w, int h) {
    final tile = tileFor(id);
    final nextW = w.clamp(1, columns);
    final nextH = h.clamp(1, 4);
    var col = tile.col;
    if (col + nextW > columns) col = columns - nextW;
    if (!_fits(tile, col, tile.row, nextW, nextH, ignore: id)) return;
    tile.col = col;
    tile.w = nextW;
    tile.h = nextH;
    notifyListeners();
  }

  bool _fits(
    LabTile _,
    int col,
    int row,
    int w,
    int h, {
    required HqWidgetId ignore,
  }) {
    if (col < 0 || row < 0 || col + w > columns) return false;
    for (final other in _tiles) {
      if (other.id == ignore) continue;
      final overlap = col < other.col + other.w &&
          col + w > other.col &&
          row < other.row + other.h &&
          row + h > other.row;
      if (overlap) return false;
    }
    return true;
  }

  (int, int)? _firstFit(int w, int h, {required HqWidgetId ignore}) {
    for (var row = 0; row < 24; row++) {
      for (var col = 0; col <= columns - w; col++) {
        if (_fits(tileFor(ignore), col, row, w, h, ignore: ignore)) {
          return (col, row);
        }
      }
    }
    return null;
  }
}
