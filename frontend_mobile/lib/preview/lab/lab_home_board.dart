import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../config.dart';
import '../../state/app_settings.dart';
import '../preview_labels.dart';
import '../preview_store.dart';
import 'lab_store.dart';

class LabHomeBoard extends StatefulWidget {
  const LabHomeBoard({super.key});

  @override
  State<LabHomeBoard> createState() => _LabHomeBoardState();
}

class _LabHomeBoardState extends State<LabHomeBoard>
    with TickerProviderStateMixin {
  late final AnimationController _jiggle;
  HqWidgetId? _dragging;
  Offset _dragDelta = Offset.zero;
  HqWidgetId? _resizing;
  Size _resizeStart = Size.zero;
  Offset _resizeAccum = Offset.zero;

  @override
  void initState() {
    super.initState();
    _jiggle = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _jiggle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final layout = context.watch<LabLayoutStore>();
    final copy = PreviewCopy.of(
      context.watch<AppSettings>(),
      context.watch<PreviewKitchenStore>().companion,
    );
    if (layout.editing && !_jiggle.isAnimating) {
      _jiggle.repeat(reverse: true);
    }
    if (!layout.editing && _jiggle.isAnimating) {
      _jiggle.stop();
      _jiggle.reset();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        const gutter = 10.0;
        const columns = LabLayoutStore.columns;
        final cellW = (constraints.maxWidth - gutter * (columns - 1)) / columns;
        const cellH = 78.0;
        var maxRow = 0;
        for (final tile in layout.tiles) {
          maxRow = max(maxRow, tile.row + tile.h);
        }
        final boardH = maxRow * cellH + max(0, maxRow - 1) * gutter + 24;

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    layout.editing ? 'Jiggle mode — drag tiles, pull a corner to resize' : 'Long-press a tile to rearrange',
                    style: const TextStyle(
                      color: AppColors.textVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: layout.toggleEditing,
                  child: Text(layout.editing ? 'Done' : 'Edit'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: boardH,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  for (final tile in layout.tiles)
                    _placedTile(
                      layout: layout,
                      copy: copy,
                      tile: tile,
                      cellW: cellW,
                      cellH: cellH,
                      gutter: gutter,
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _placedTile({
    required LabLayoutStore layout,
    required PreviewCopy copy,
    required LabTile tile,
    required double cellW,
    required double cellH,
    required double gutter,
  }) {
    final dragging = _dragging == tile.id;
    var left = tile.col * (cellW + gutter);
    var top = tile.row * (cellH + gutter);
    if (dragging) {
      left += _dragDelta.dx;
      top += _dragDelta.dy;
    }
    final width = tile.w * cellW + (tile.w - 1) * gutter;
    final height = tile.h * cellH + (tile.h - 1) * gutter;
    final angle = layout.editing && !dragging
        ? (_jiggle.value - 0.5) * 0.04
        : 0.0;

    return AnimatedPositioned(
      duration: dragging || _resizing == tile.id
          ? Duration.zero
          : const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      left: left,
      top: top,
      width: width,
      height: height,
      child: Transform.rotate(
        angle: angle,
        child: GestureDetector(
          onLongPress: () => layout.setEditing(true),
          onPanStart: layout.editing
              ? (_) {
                  if (_resizing != null) return;
                  setState(() {
                    _dragging = tile.id;
                    _dragDelta = Offset.zero;
                  });
                }
              : null,
          onPanUpdate: layout.editing && _dragging == tile.id
              ? (d) => setState(() => _dragDelta += d.delta)
              : null,
          onPanEnd: layout.editing && _dragging == tile.id
              ? (_) {
                  final col = ((left) / (cellW + gutter)).round();
                  final row = ((top) / (cellH + gutter)).round();
                  layout.moveTile(tile.id, col, row);
                  setState(() {
                    _dragging = null;
                    _dragDelta = Offset.zero;
                  });
                }
              : null,
          child: Stack(
            children: [
              _face(copy, tile, layout.editing),
              if (layout.editing)
                Positioned(
                  right: 4,
                  bottom: 4,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onPanDown: (_) {
                      setState(() {
                        _resizing = tile.id;
                        _dragging = null;
                        _resizeStart = Size(tile.w.toDouble(), tile.h.toDouble());
                        _resizeAccum = Offset.zero;
                      });
                    },
                    onPanUpdate: (d) {
                      _resizeAccum += d.delta;
                      final nextW =
                          (_resizeStart.width + _resizeAccum.dx / (cellW + gutter))
                              .round()
                              .clamp(1, 4);
                      final nextH =
                          (_resizeStart.height + _resizeAccum.dy / (cellH + gutter))
                              .round()
                              .clamp(1, 4);
                      layout.resizeTile(tile.id, nextW, nextH);
                    },
                    onPanEnd: (_) => setState(() => _resizing = null),
                    onPanCancel: () => setState(() => _resizing = null),
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: AppColors.outline, width: 2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.open_in_full, size: 14, color: AppColors.outline),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _face(PreviewCopy copy, LabTile tile, bool editing) {
    final store = context.watch<PreviewKitchenStore>();
    String line = copy.widgetHint(tile.id);
    switch (tile.id) {
      case HqWidgetId.colonyStatus:
        final c = store.colonyCounts();
        line = 'Urgent ${c.urgent} · Soon ${c.soon} · Safe ${c.safe}';
      case HqWidgetId.tonightBriefing:
        line = store.suggested.first.title;
      case HqWidgetId.askCompanion:
        line = copy.askTitle;
      case HqWidgetId.topPicks:
        line = store.topPicks.map((h) => h.name.split(' ').first).join(' · ');
      case HqWidgetId.boughtNotEaten:
        line = store.boughtNotEaten.map((h) => h.name.split(' ').first).join(' · ');
      case HqWidgetId.mostLikedRecipe:
        line = '${store.mostLikedRecipe.title} · ${store.mostLikedRecipe.likes} likes';
      case HqWidgetId.huddleTrending:
        line = store.topTip.body;
      default:
        break;
    }

    return Material(
      color: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: editing ? AppColors.primary : AppColors.outline,
          width: 2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 28, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              copy.widgetTitle(tile.id),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.quicksand(fontWeight: FontWeight.w800, fontSize: 15),
            ),
            const SizedBox(height: 4),
            Text(
              line,
              maxLines: tile.h == 1 ? 1 : 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textVariant,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
