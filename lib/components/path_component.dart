import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class PathComponent extends Component {
  List<Vector2> _pts = [];

  @override int get priority => 2;

  List<Vector2> buildPath({
    required int cols,
    required int rows,
    required double cellSize,
    required double offsetX,
    required double offsetY,
  }) {
    Vector2 ctr(int c, int r) => Vector2(
      offsetX + c * cellSize + cellSize / 2,
      offsetY + r * cellSize + cellSize / 2,
    );

    final raw = <Vector2>[];
    // Enter off-screen left
    raw.add(Vector2(offsetX - cellSize, offsetY + cellSize * 0.5));

    int r = 0;
    bool toRight = true;
    while (r < rows) {
      if (toRight) {
        raw.add(ctr(0,        r));
        raw.add(ctr(cols - 1, r));
        if (r + 2 <= rows - 1) raw.add(ctr(cols - 1, r + 2));
        else if (r + 1 <= rows - 1) raw.add(ctr(cols - 1, r + 1));
      } else {
        raw.add(ctr(cols - 1, r));
        raw.add(ctr(0,        r));
        if (r + 2 <= rows - 1) raw.add(ctr(0, r + 2));
        else if (r + 1 <= rows - 1) raw.add(ctr(0, r + 1));
      }
      toRight = !toRight;
      r += 2;
    }
    // Exit
    final last = raw.last;
    raw.add(Vector2(
      toRight ? offsetX - cellSize * 1.5 : offsetX + cols * cellSize + cellSize * 1.5,
      last.y,
    ));

    // Deduplicate
    final clean = <Vector2>[raw[0]];
    for (int i = 1; i < raw.length; i++) {
      if ((raw[i] - clean.last).length > 0.5) clean.add(raw[i]);
    }
    _pts = clean;
    return _pts;
  }

  @override
  void render(Canvas canvas) {
    if (_pts.length < 2) return;
    _drawPath(canvas);
    if (_pts.length > 1) _drawStartFlag(canvas, _pts[1]);
    if (_pts.length > 2) _drawCastle(canvas, _pts[_pts.length - 2]);
  }

  void _drawPath(Canvas canvas) {
    final path = Path();
    path.moveTo(_pts[0].x, _pts[0].y);
    for (int i = 1; i < _pts.length; i++) path.lineTo(_pts[i].x, _pts[i].y);

    double cs = 40;
    for (int i = 0; i < _pts.length - 1; i++) {
      final d = (_pts[i + 1] - _pts[i]).length;
      if (d > 80) { cs = (d / 8).clamp(30.0, 100.0); break; }
    }
    final pw = cs * 0.9;

    canvas.drawPath(path, Paint()
      ..color = Colors.black.withOpacity(0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = pw + 5
      ..strokeCap = StrokeCap.square
      ..strokeJoin = StrokeJoin.miter);

    canvas.drawPath(path, Paint()
      ..color = const Color(0xFFB88030)
      ..style = PaintingStyle.stroke
      ..strokeWidth = pw
      ..strokeCap = StrokeCap.square
      ..strokeJoin = StrokeJoin.miter);

    canvas.drawPath(path, Paint()
      ..color = const Color(0xFFD4A050)
      ..style = PaintingStyle.stroke
      ..strokeWidth = pw * 0.6
      ..strokeCap = StrokeCap.square
      ..strokeJoin = StrokeJoin.miter);

    // Dashed centre
    final dp = Path();
    const dl = 7.0, gl = 7.0;
    for (final m in path.computeMetrics()) {
      double d = 0; bool draw = true;
      while (d < m.length) {
        final len = draw ? dl : gl;
        final end = (d + len).clamp(0.0, m.length);
        if (draw) dp.addPath(m.extractPath(d, end), Offset.zero);
        d = end; draw = !draw;
      }
    }
    canvas.drawPath(dp, Paint()
      ..color = Colors.white.withOpacity(0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round);
  }

  void _drawStartFlag(Canvas canvas, Vector2 p) {
    const s = 11.0;
    canvas.drawRect(Rect.fromLTWH(p.x - 1.5, p.y - s * 2.0, 3, s * 2.1),
        Paint()..color = const Color(0xFF7A5010));
    final fp = Path()
      ..moveTo(p.x + 1.5, p.y - s * 2.0)
      ..lineTo(p.x + s * 1.3, p.y - s * 1.5)
      ..lineTo(p.x + 1.5, p.y - s * 1.0)
      ..close();
    canvas.drawPath(fp, Paint()
      ..color = const Color(0xFF22C55E)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3));
    canvas.drawPath(fp, Paint()..color = const Color(0xFF22C55E));
    // START label
    final textPaint = Paint()..color = Colors.transparent;
    canvas.drawRect(Rect.fromLTWH(p.x - 12, p.y + 4, 24, 10), textPaint);
  }

  // ── PROFESSIONAL CASTLE ──
  void _drawCastle(Canvas canvas, Vector2 pt) {
    final p = Offset(pt.x, pt.y);
    const s = 18.0; // base scale unit

    // ── 1. Ground glow ──
    canvas.drawCircle(p, s * 2.2,
        Paint()
          ..color = const Color(0x33FFD700)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18));

    // ── 2. Moat (blue ring) ──
    canvas.drawCircle(p, s * 1.85,
        Paint()
          ..color = const Color(0xFF1A5A8A)
          ..style = PaintingStyle.stroke
          ..strokeWidth = s * 0.28);
    canvas.drawCircle(p, s * 1.85,
        Paint()
          ..color = const Color(0xFF2A7AB0).withOpacity(0.6)
          ..style = PaintingStyle.stroke
          ..strokeWidth = s * 0.18);

    // ── 3. Outer wall (ring) ──
    canvas.drawCircle(p, s * 1.5,
        Paint()..color = const Color(0xFF6A5A48));
    canvas.drawCircle(p, s * 1.5,
        Paint()
          ..color = const Color(0xFF8A7A68)
          ..style = PaintingStyle.stroke
          ..strokeWidth = s * 0.22);

    // Outer wall battlements (small rect notches around ring)
    for (int i = 0; i < 12; i++) {
      if (i % 2 == 0) continue;
      final a = (i / 12) * pi * 2;
      final cx = p.dx + cos(a) * s * 1.5;
      final cy = p.dy + sin(a) * s * 1.5;
      canvas.save();
      canvas.translate(cx, cy);
      canvas.rotate(a);
      canvas.drawRect(
        Rect.fromCenter(center: Offset.zero, width: s * 0.22, height: s * 0.28),
        Paint()..color = const Color(0xFF5A4A38),
      );
      canvas.restore();
    }

    // ── 4. Corner towers (4 small towers) ──
    for (int i = 0; i < 4; i++) {
      final a = (i / 4) * pi * 2 + pi / 4;
      final tx = p.dx + cos(a) * s * 1.1;
      final ty = p.dy + sin(a) * s * 1.1;
      _drawTowerPillar(canvas, Offset(tx, ty), s * 0.42);
    }

    // ── 5. Main keep (centre body) ──
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: p.translate(0, -s * 0.1), width: s * 1.6, height: s * 1.7),
        Radius.circular(s * 0.1),
      ),
      Paint()..color = const Color(0xFF8A7A68),
    );
    // Keep shading
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: p.translate(-s * 0.2, -s * 0.1), width: s * 0.5, height: s * 1.7),
        Radius.circular(s * 0.1),
      ),
      Paint()..color = Colors.black.withOpacity(0.12),
    );
    // Keep border
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: p.translate(0, -s * 0.1), width: s * 1.6, height: s * 1.7),
        Radius.circular(s * 0.1),
      ),
      Paint()
        ..color = const Color(0xFF6A5A48)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // ── 6. Keep battlements ──
    for (int i = 0; i < 5; i++) {
      if (i % 2 == 0) {
        canvas.drawRect(
          Rect.fromLTWH(p.dx - s * 0.8 + i * s * 0.32, p.dy - s * 1.0, s * 0.24, s * 0.32),
          Paint()..color = const Color(0xFF5A4A38),
        );
      }
    }

    // ── 7. Central tower (tallest) ──
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: p.translate(0, -s * 0.85), width: s * 0.72, height: s * 1.1),
        Radius.circular(s * 0.08),
      ),
      Paint()..color = const Color(0xFF9A8A78),
    );

    // ── 8. Pointed roof on centre tower ──
    final roofPath = Path()
      ..moveTo(p.dx - s * 0.38, p.dy - s * 1.4)
      ..lineTo(p.dx + s * 0.38, p.dy - s * 1.4)
      ..lineTo(p.dx, p.dy - s * 2.15)
      ..close();
    canvas.drawPath(roofPath, Paint()..color = const Color(0xFF8B0000));
    canvas.drawPath(roofPath, Paint()
      ..color = const Color(0xFFAA0000)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1);

    // Flag on top
    canvas.drawRect(Rect.fromLTWH(p.dx - 1, p.dy - s * 2.15, 2, s * 0.55),
        Paint()..color = const Color(0xFF8B6914));
    final flagP = Path()
      ..moveTo(p.dx + 1, p.dy - s * 2.15)
      ..lineTo(p.dx + s * 0.4, p.dy - s * 1.95)
      ..lineTo(p.dx + 1, p.dy - s * 1.75)
      ..close();
    canvas.drawPath(flagP, Paint()
      ..color = const Color(0xFFFFD700)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3));
    canvas.drawPath(flagP, Paint()..color = const Color(0xFFFFD700));

    // ── 9. Gate ──
    // Gate arch
    final gatePath = Path()
      ..addArc(
        Rect.fromCenter(center: p.translate(0, s * 0.38), width: s * 0.65, height: s * 0.65),
        pi, pi,
      );
    gatePath.lineTo(p.dx + s * 0.325, p.dy + s * 0.7);
    gatePath.lineTo(p.dx - s * 0.325, p.dy + s * 0.7);
    gatePath.close();
    canvas.drawPath(gatePath, Paint()..color = const Color(0xFF1A0E05));
    // Gate portcullis bars
    for (int i = 0; i < 3; i++) {
      canvas.drawRect(
        Rect.fromLTWH(p.dx - s * 0.28 + i * s * 0.22, p.dy + s * 0.12, s * 0.06, s * 0.52),
        Paint()..color = const Color(0xFF3A2A15).withOpacity(0.7),
      );
    }
    canvas.drawRect(
      Rect.fromLTWH(p.dx - s * 0.28, p.dy + s * 0.38, s * 0.56, s * 0.05),
      Paint()..color = const Color(0xFF3A2A15).withOpacity(0.7),
    );

    // ── 10. Windows ──
    for (final off in [Offset(-s * 0.35, -s * 0.6), Offset(s * 0.35, -s * 0.6)]) {
      canvas.drawOval(
        Rect.fromCenter(center: p + off, width: s * 0.22, height: s * 0.3),
        Paint()..color = const Color(0xFFFFE88A).withOpacity(0.7)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      );
      canvas.drawOval(
        Rect.fromCenter(center: p + off, width: s * 0.22, height: s * 0.3),
        Paint()..color = const Color(0xFF2A1A08),
      );
      // Window light
      canvas.drawOval(
        Rect.fromCenter(center: p + off, width: s * 0.14, height: s * 0.2),
        Paint()..color = const Color(0xFFFFE070).withOpacity(0.5)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
      );
    }

    // ── 11. Overall glow ──
    canvas.drawCircle(p, s * 1.2,
        Paint()
          ..color = const Color(0x22FFD700)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, s * 0.8));
  }

  void _drawTowerPillar(Canvas canvas, Offset p, double r) {
    // Pillar body
    canvas.drawCircle(p, r, Paint()..color = const Color(0xFF7A6A58));
    canvas.drawCircle(p, r, Paint()
      ..color = const Color(0xFF5A4A38)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2);
    // Cone roof
    final roof = Path()
      ..moveTo(p.dx - r, p.dy - r * 0.4)
      ..lineTo(p.dx + r, p.dy - r * 0.4)
      ..lineTo(p.dx, p.dy - r * 1.8)
      ..close();
    canvas.drawPath(roof, Paint()..color = const Color(0xFF8B0000));
    // Battlements
    for (int i = 0; i < 4; i++) {
      if (i % 2 == 0) {
        final bx = p.dx - r + i * r * 0.5;
        canvas.drawRect(
          Rect.fromLTWH(bx, p.dy - r * 0.55, r * 0.35, r * 0.28),
          Paint()..color = const Color(0xFF5A4A38),
        );
      }
    }
  }
}
