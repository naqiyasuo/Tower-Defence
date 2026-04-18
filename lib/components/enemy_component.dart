import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../data/enemy_data.dart';

typedef EnemyCallback    = void Function(EnemyComponent e);
typedef EnemyDieCallback = void Function(EnemyComponent e, int reward);

class EnemyComponent extends PositionComponent {
  final EnemyConfig  config;
  double hp;
  final double       maxHp;
  final double       speed;   // pixels per second
  final int          reward;
  final List<Vector2> pathPoints;
  final EnemyCallback    onReachEnd;
  final EnemyDieCallback onDie;

  // Distance travelled along path (pixels)
  double _dist   = 0;
  double progress = 0; // 0..pathPoints.length-1 (for targeting)
  double _slow   = 0;
  bool   _dead   = false;
  bool   get isDead => _dead;

  // Pre-computed cumulative distances between waypoints
  late final List<double> _segLens;
  late final double       _totalLen;

  double _wobble = 0;

  @override
  int get priority => 8; // above map(1), path(2), grid(6)

  EnemyComponent({
    required this.config,
    required double hp,
    required this.speed,
    required this.reward,
    required this.pathPoints,
    required this.onReachEnd,
    required this.onDie,
  })  : hp    = hp,
        maxHp = hp,
        super(anchor: Anchor.center, size: Vector2.all(30));

  @override
  Future<void> onLoad() async {
    // Pre-compute segment lengths
    _segLens = [];
    double total = 0;
    for (int i = 0; i < pathPoints.length - 1; i++) {
      final len = pathPoints[i].distanceTo(pathPoints[i + 1]);
      _segLens.add(len);
      total += len;
    }
    _totalLen = total.clamp(1.0, double.infinity);

    // Start at beginning of path
    position = pathPoints.first.clone();
  }

  void takeDamage(double dmg) {
    if (_dead) return;
    hp -= dmg;
    if (hp <= 0) {
      _dead = true;
      onDie(this, reward);
      removeFromParent();
    }
  }

  void applySlow(double duration) => _slow = duration;
  bool get isSlowed => _slow > 0;

  @override
  void update(double dt) {
    if (_dead) return;
    if (_slow > 0) _slow -= dt;
    _wobble += dt * 5.5;

    final effectiveSpeed = isSlowed ? speed * 0.35 : speed;
    _dist += effectiveSpeed * dt;

    if (_dist >= _totalLen) {
      _dead = true;
      onReachEnd(this);
      removeFromParent();
      return;
    }

    // Find position along path by cumulative distance
    double remaining = _dist;
    int seg = 0;
    while (seg < _segLens.length - 1 && remaining > _segLens[seg]) {
      remaining -= _segLens[seg];
      seg++;
    }
    final t = _segLens[seg] > 0 ? remaining / _segLens[seg] : 0.0;

    final a = pathPoints[seg];
    final b = pathPoints[min(seg + 1, pathPoints.length - 1)];

    position = Vector2(
      a.x + (b.x - a.x) * t,
      a.y + (b.y - a.y) * t + sin(_wobble) * 1.2,
    );

    // Keep progress in sync (used by towers for targeting)
    progress = seg + t;
  }

  @override
  void render(Canvas canvas) {
    if (_dead) return;
    final r = (size.x / 2) * config.size;
    _drawBody(canvas, r);
    _drawHpBar(canvas, r);
  }

  void _drawBody(Canvas canvas, double r) {
    // Aura glow
    canvas.drawCircle(Offset.zero, r * 1.9,
        Paint()
          ..color = config.color.withOpacity(0.2)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10));

    // Shadow on ground
    canvas.drawOval(
      Rect.fromCenter(center: Offset(0, r * 0.55), width: r * 1.8, height: r * 0.45),
      Paint()..color = Colors.black.withOpacity(0.28),
    );

    // Body
    final bodyColor = isSlowed ? const Color(0xFF93C5FD) : config.color;
    canvas.drawCircle(Offset.zero, r, Paint()..color = bodyColor);
    canvas.drawCircle(Offset.zero, r,
        Paint()
          ..color = config.borderColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5);

    // Shine
    canvas.drawOval(
      Rect.fromCenter(center: Offset(-r * 0.24, -r * 0.28), width: r * 0.38, height: r * 0.22),
      Paint()..color = Colors.white.withOpacity(0.3),
    );

    // Eyes
    for (final sx in [-1.0, 1.0]) {
      canvas.drawCircle(Offset(sx * r * 0.3, -r * 0.1), r * 0.16, Paint()..color = Colors.white);
      canvas.drawCircle(Offset(sx * r * 0.3, -r * 0.07), r * 0.09, Paint()..color = const Color(0xFF1A0800));
      canvas.drawCircle(Offset(sx * r * 0.32, -r * 0.13), r * 0.05, Paint()..color = Colors.white);
    }

    // Mouth
    canvas.drawArc(
      Rect.fromCenter(center: Offset(0, r * 0.2), width: r * 0.44, height: r * 0.22),
      0.1, pi - 0.2, false,
      Paint()
        ..color = Colors.black.withOpacity(0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4,
    );

    // Crown for big enemies
    if (config.hasCrown) _drawCrown(canvas, r);

    // Wings
    if (config.hasWings) _drawWings(canvas, r);

    // Armor highlight
    if (config.hasArmor) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(0, -r * 0.05), width: r * 0.62, height: r * 0.5),
          Radius.circular(r * 0.05),
        ),
        Paint()..color = Colors.blueGrey.withOpacity(0.55),
      );
    }
  }

  void _drawCrown(Canvas canvas, double r) {
    final cy = -r - 2;
    canvas.drawCircle(Offset(0, cy), r * 0.18,
        Paint()..color = Colors.amber.withOpacity(0.35)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7));
    final p = Path();
    p.moveTo(-r * 0.52, cy);
    p.lineTo(-r * 0.72, cy - r * 0.52);
    p.lineTo(-r * 0.24, cy - r * 0.2);
    p.lineTo(0, cy - r * 0.62);
    p.lineTo(r * 0.24, cy - r * 0.2);
    p.lineTo(r * 0.72, cy - r * 0.52);
    p.lineTo(r * 0.52, cy);
    p.close();
    canvas.drawPath(p, Paint()..color = Colors.amber);
    canvas.drawPath(p, Paint()
      ..color = Colors.amber
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
  }

  void _drawWings(Canvas canvas, double r) {
    for (final sx in [-1.0, 1.0]) {
      canvas.save();
      canvas.scale(sx, 1);
      final w = Path()
        ..moveTo(r * 0.12, -r * 0.08)
        ..lineTo(r * 0.65, -r * 0.55)
        ..lineTo(r * 0.48,  r * 0.12)
        ..close();
      canvas.drawPath(w, Paint()..color = config.color.withOpacity(0.5));
      canvas.drawPath(w, Paint()
        ..color = config.borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0);
      canvas.restore();
    }
  }

  void _drawHpBar(Canvas canvas, double r) {
    final bw = r * 2.4, bh = 5.0;
    final bx = -bw / 2, by = -r - 12;

    // Background
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(bx, by, bw, bh), const Radius.circular(2.5)),
      Paint()..color = Colors.black.withOpacity(0.65),
    );

    // Fill
    final pct = (hp / maxHp).clamp(0.0, 1.0);
    if (pct > 0) {
      final col = pct > 0.6
          ? const Color(0xFF22C55E)
          : pct > 0.3
              ? const Color(0xFFFBBF24)
              : const Color(0xFFEF4444);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(bx + 1, by + 1, (bw - 2) * pct, bh - 2),
            const Radius.circular(2)),
        Paint()..color = col,
      );
    }
  }
}
