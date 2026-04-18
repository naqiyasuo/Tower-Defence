import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../game/td_game.dart';

class MapComponent extends Component with HasGameRef<TowerDefenseGame> {
  final _rng  = Random(42);
  final _trees = <_Tree>[];
  bool _ready  = false;

  @override int get priority => 1;

  void _init() {
    if (_ready) return;
    _ready = true;
    final g  = gameRef;
    final cs = g.cellSize;
    for (int r = 0; r < TowerDefenseGame.ROWS; r++) {
      for (int c = 0; c < TowerDefenseGame.COLS; c++) {
        if (g.pathCells.contains('$c,$r')) continue;
        if (_rng.nextDouble() < 0.14) {
          _trees.add(_Tree(
            x:     g.mapOffsetX + c * cs + cs * 0.5 + (_rng.nextDouble() - 0.5) * cs * 0.3,
            y:     g.mapOffsetY + r * cs + cs * 0.5 + (_rng.nextDouble() - 0.5) * cs * 0.3,
            scale: 0.5 + _rng.nextDouble() * 0.38,
            dark:  _rng.nextBool(),
          ));
        }
      }
    }
  }

  @override
  void render(Canvas canvas) {
    _init();
    final g   = gameRef;
    final cs  = g.cellSize;
    final ox  = g.mapOffsetX;
    final oy  = g.mapOffsetY;
    final w   = TowerDefenseGame.COLS * cs;
    final h   = TowerDefenseGame.ROWS * cs;

    // ── Full screen background ──
    canvas.drawRect(
      Rect.fromLTWH(0, 0, gameRef.size.x, gameRef.size.y),
      Paint()..color = const Color(0xFF2A6018),
    );

    // ── Grass cells ──
    for (int r = 0; r < TowerDefenseGame.ROWS; r++) {
      for (int c = 0; c < TowerDefenseGame.COLS; c++) {
        final onPath = g.pathCells.contains('$c,$r');
        final rect   = Rect.fromLTWH(ox + c * cs, oy + r * cs, cs, cs);
        if (!onPath) {
          canvas.drawRect(rect,
              Paint()..color = (c + r) % 2 == 0
                  ? const Color(0xFF3A8828)
                  : const Color(0xFF348022));
        }
      }
    }

    // ── Dirt path cells ──
    for (int r = 0; r < TowerDefenseGame.ROWS; r++) {
      for (int c = 0; c < TowerDefenseGame.COLS; c++) {
        if (!g.pathCells.contains('$c,$r')) continue;
        final rect = Rect.fromLTWH(ox + c * cs, oy + r * cs, cs, cs);
        canvas.drawRect(rect,
            Paint()..color = (c + r) % 2 == 0
                ? const Color(0xFFC8963C)
                : const Color(0xFFB88030));
        // Top highlight
        canvas.drawRect(
          Rect.fromLTWH(ox + c * cs + cs * 0.08, oy + r * cs + cs * 0.05, cs * 0.84, cs * 0.1),
          Paint()..color = Colors.white.withOpacity(0.1),
        );
      }
    }

    // ── Map border ──
    canvas.drawRect(Rect.fromLTWH(ox, oy, w, h),
        Paint()
          ..color = Colors.black.withOpacity(0.25)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2);

    // ── Trees ──
    for (final t in _trees) _drawTree(canvas, t, cs);
  }

  void _drawTree(Canvas canvas, _Tree t, double cs) {
    final s = t.scale * cs * 0.44;
    canvas.drawRect(
      Rect.fromCenter(center: Offset(t.x, t.y + s * 0.1), width: s * 0.28, height: s * 0.6),
      Paint()..color = const Color(0xFF6B3A10),
    );
    final colors = t.dark
        ? [const Color(0xFF1A5A10), const Color(0xFF226018), const Color(0xFF1E6616)]
        : [const Color(0xFF2A7A1E), const Color(0xFF368826), const Color(0xFF40962C)];
    for (int i = 0; i < 3; i++) {
      final path = Path()
        ..moveTo(t.x - s * (0.72 - i * 0.06), t.y - s * (0.22 - i * 0.32))
        ..lineTo(t.x + s * (0.72 - i * 0.06), t.y - s * (0.22 - i * 0.32))
        ..lineTo(t.x, t.y - s * (1.05 + i * 0.1))
        ..close();
      canvas.drawPath(path, Paint()..color = colors[i]);
    }
  }
}

class _Tree {
  final double x, y, scale;
  final bool dark;
  const _Tree({required this.x, required this.y, required this.scale, required this.dark});
}
