import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../game/td_game.dart';
import '../data/tower_data.dart';

class GridComponent extends Component with HasGameRef<TowerDefenseGame> {
  @override
  int get priority => 6;

  @override
  void render(Canvas canvas) {
    final g = gameRef;
    final cs = g.cellSize;
    final ox = g.mapOffsetX, oy = g.mapOffsetY;

    // ── Subtle grid lines on grass cells ──
    final linePaint = Paint()
      ..color = Colors.black.withOpacity(0.07)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.7;

    for (int r = 0; r < TowerDefenseGame.ROWS; r++) {
      for (int c = 0; c < TowerDefenseGame.COLS; c++) {
        if (!g.pathCells.contains('$c,$r')) {
          canvas.drawRect(
            Rect.fromLTWH(ox + c * cs, oy + r * cs, cs, cs),
            linePaint,
          );
        }
      }
    }

    // ── Drag preview cell ──
    final dc = g.dragCol, dr = g.dragRow;
    if (dc != null && dr != null &&
        dc >= 0 && dc < TowerDefenseGame.COLS &&
        dr >= 0 && dr < TowerDefenseGame.ROWS) {
      final valid = g.isCellValid(dc, dr);
      final color = valid ? const Color(0xFF22C55E) : const Color(0xFFEF4444);
      final rx = ox + dc * cs, ry = oy + dr * cs;

      // Fill
      canvas.drawRect(
        Rect.fromLTWH(rx + 1, ry + 1, cs - 2, cs - 2),
        Paint()..color = color.withOpacity(0.3),
      );

      // Glowing border
      canvas.drawRect(
        Rect.fromLTWH(rx + 1.5, ry + 1.5, cs - 3, cs - 3),
        Paint()
          ..color = color.withOpacity(0.9)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, valid ? 5 : 3),
      );
      canvas.drawRect(
        Rect.fromLTWH(rx + 1.5, ry + 1.5, cs - 3, cs - 3),
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );

      if (valid) {
        // Mini tower preview
        final cfg = TowerData.configs[g.selectedTowerType]!;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset(rx + cs/2, ry + cs/2), width: cs * 0.58, height: cs * 0.58),
            Radius.circular(cs * 0.1),
          ),
          Paint()..color = cfg.color.withOpacity(0.38),
        );
        // checkmark
        final ck = Paint()
          ..color = color
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(
          Offset(rx + cs*0.32, ry + cs*0.52),
          Offset(rx + cs*0.46, ry + cs*0.66),
          ck,
        );
        canvas.drawLine(
          Offset(rx + cs*0.46, ry + cs*0.66),
          Offset(rx + cs*0.68, ry + cs*0.36),
          ck,
        );
      } else {
        // X mark
        final xp = Paint()
          ..color = color
          ..strokeWidth = 2.2
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(Offset(rx + cs*0.28, ry + cs*0.28), Offset(rx + cs*0.72, ry + cs*0.72), xp);
        canvas.drawLine(Offset(rx + cs*0.72, ry + cs*0.28), Offset(rx + cs*0.28, ry + cs*0.72), xp);
      }
    }
  }
}
