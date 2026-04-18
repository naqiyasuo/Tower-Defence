import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../data/tower_data.dart';
import '../game/td_game.dart';
import 'enemy_component.dart';

class TowerComponent extends PositionComponent with HasGameRef<TowerDefenseGame> {
  final int gridCol;
  final int gridRow;
  TowerConfig config;
  int level = 1;
  bool _selected = false;
  double _cooldown = 0;
  double _aimAngle = 0;
  double _pulse = 0;
  final TowerDefenseGame game;

  TowerComponent({
    required this.gridCol,
    required this.gridRow,
    required Vector2 position,
    required this.config,
    required this.game,
  }) : super(position: position, anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    // Size = one grid cell
    size = Vector2.all(game.cellSize);
  }

  void setSelected(bool v) => _selected = v;
  void upgrade() { level++; config = TowerData.configs[config.type]!.withLevel(level); }

  @override
  int get priority => 10;

  @override
  void update(double dt) {
    _pulse += dt * 2.5;
    _cooldown -= dt;
    final target = _findTarget();
    if (target == null) return;
    final d = target.position - position;
    _aimAngle = atan2(d.y, d.x);
    if (_cooldown <= 0) {
      _cooldown = 1.0 / config.fireRate;
      game.fireBullet(from: position, target: target, cfg: config);
    }
  }

  EnemyComponent? _findTarget() {
    final range = config.range * game.cellSize;
    EnemyComponent? best;
    double bestProg = -1;
    for (final e in game.enemies) {
      if (e.isDead) continue;
      if (e.position.distanceTo(position) <= range && e.progress > bestProg) {
        bestProg = e.progress;
        best = e;
      }
    }
    return best;
  }

  @override
  void render(Canvas canvas) {
    final cs = game.cellSize;
    final half = cs / 2;

    // ── Range ring (selected only) ──
    if (_selected) {
      final range = config.range * cs;
      canvas.drawCircle(Offset.zero, range,
          Paint()..color = config.glowColor.withOpacity(0.14)..style = PaintingStyle.fill);
      final dashPaint = Paint()
        ..color = config.glowColor.withOpacity(0.55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      // Dashed circle approximation
      for (int i = 0; i < 36; i++) {
        if (i % 2 == 0) {
          final a1 = i / 36 * pi * 2, a2 = (i + 0.8) / 36 * pi * 2;
          canvas.drawArc(Rect.fromCircle(center: Offset.zero, radius: range), a1, a2 - a1, false, dashPaint);
        }
      }
    }

    // ── Square platform (full cell, slightly inset) ──
    final inset = cs * 0.06;
    final baseRect = Rect.fromLTWH(-half + inset, -half + inset, cs - inset * 2, cs - inset * 2);
    final baseRR = RRect.fromRectAndRadius(baseRect, Radius.circular(cs * 0.12));

    // Shadow
    canvas.drawRRect(baseRR.shift(const Offset(2, 3)),
        Paint()..color = Colors.black.withOpacity(0.35));

    // Platform fill
    canvas.drawRRect(baseRR, Paint()..color = const Color(0xFF1E2535));

    // Platform border
    canvas.drawRRect(baseRR,
        Paint()
          ..color = config.color.withOpacity(0.4)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5);

    // Glow on platform
    final pulse = 0.5 + sin(_pulse) * 0.25;
    canvas.drawRRect(baseRR,
        Paint()
          ..color = config.glowColor.withOpacity(0.12 * pulse)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 8 * pulse));

    // Corner bolts
    for (final dx in [-1.0, 1.0]) {
      for (final dy in [-1.0, 1.0]) {
        canvas.drawCircle(Offset(dx * (half - inset - cs*0.07), dy * (half - inset - cs*0.07)),
            cs * 0.04, Paint()..color = const Color(0xFF334155));
      }
    }

    // ── Tower body (centered on platform) ──
    _drawBody(canvas, cs);

    // ── Aimed barrel ──
    canvas.save();
    canvas.rotate(_aimAngle);
    _drawBarrel(canvas, cs);
    canvas.restore();

    // ── Glow orb ──
    final orbY = -cs * 0.28;
    final orbR = cs * 0.1 * (0.8 + sin(_pulse) * 0.25);
    canvas.drawCircle(Offset(0, orbY), orbR * 2,
        Paint()..color = config.glowColor.withOpacity(0.3 * pulse)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 8));
    canvas.drawCircle(Offset(0, orbY), orbR, Paint()..color = config.glowColor);

    // ── Level dots ──
    for (int i = 0; i < level - 1; i++) {
      final dotX = -((level - 2) * cs * 0.065) + i * cs * 0.13;
      canvas.drawCircle(Offset(dotX, half - cs * 0.1), cs * 0.055,
          Paint()..color = Colors.amber
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2));
    }

    // ── Selected highlight ──
    if (_selected) {
      canvas.drawRRect(baseRR,
          Paint()
            ..color = Colors.white.withOpacity(0.6)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.0
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5));
    }
  }

  void _drawBody(Canvas canvas, double cs) {
    final h = cs * 0.42; // tower body height above centre
    switch (config.type) {
      case TowerType.archer:
        // Wooden tower
        canvas.drawRRect(
          RRect.fromRectAndRadius(Rect.fromLTWH(-cs*0.18, -h, cs*0.36, h * 0.85), Radius.circular(cs*0.04)),
          Paint()..color = level >= 3 ? const Color(0xFF5A3800) : const Color(0xFF4A3010),
        );
        // Pointed roof
        final roof = Path()
          ..moveTo(-cs*0.22, -h * 0.85)
          ..lineTo(cs*0.22, -h * 0.85)
          ..lineTo(0, -h * 1.3)
          ..close();
        canvas.drawPath(roof, Paint()..color = level >= 2 ? const Color(0xFFC0160C) : const Color(0xFF991B1B));
        // Window
        canvas.drawCircle(Offset(0, -h * 0.5), cs * 0.07,
            Paint()..color = (level >= 3 ? Colors.blue : Colors.amber).withOpacity(0.6)
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5));
        break;

      case TowerType.cannon:
        canvas.drawCircle(Offset.zero, cs * 0.22,
            Paint()..color = level >= 3 ? const Color(0xFF374151) : const Color(0xFF4B5563));
        for (int i = 0; i < 6; i++) {
          if (i % 2 == 0) {
            final a = (i / 6) * pi * 2;
            canvas.drawCircle(Offset(cos(a) * cs * 0.18, sin(a) * cs * 0.18), cs * 0.065,
                Paint()..color = const Color(0xFF374151));
          }
        }
        canvas.drawCircle(Offset.zero, cs * 0.09,
            Paint()..color = level >= 4 ? const Color(0xFFEF4444) : const Color(0xFF6B7280));
        break;

      case TowerType.mage:
        canvas.drawRRect(
          RRect.fromRectAndRadius(Rect.fromLTWH(-cs*0.16, -h, cs*0.32, h * 0.85), Radius.circular(cs*0.05)),
          Paint()..color = level >= 3 ? const Color(0xFF4C1D95) : const Color(0xFF5B21B6),
        );
        final spire = Path()
          ..moveTo(-cs*0.2, -h * 0.85)
          ..lineTo(cs*0.2, -h * 0.85)
          ..lineTo(0, -h * 1.35)
          ..close();
        canvas.drawPath(spire, Paint()..color = const Color(0xFF6D28D9));
        final p = 0.7 + sin(_pulse * 1.2) * 0.35;
        canvas.drawCircle(Offset(0, -h * 0.5), cs * 0.09 * p,
            Paint()..color = const Color(0xFFC084FC).withOpacity(p * 0.6)
              ..maskFilter = MaskFilter.blur(BlurStyle.normal, 10 * p));
        break;

      case TowerType.ice:
        canvas.drawRRect(
          RRect.fromRectAndRadius(Rect.fromLTWH(-cs*0.15, -h, cs*0.30, h * 0.85), Radius.circular(cs*0.04)),
          Paint()..color = const Color(0xFF0E4D5A),
        );
        final iceSpire = Path()
          ..moveTo(-cs*0.13, -h * 0.85)
          ..lineTo(cs*0.13, -h * 0.85)
          ..lineTo(0, -h * 1.3)
          ..close();
        canvas.drawPath(iceSpire, Paint()..color = level >= 4 ? const Color(0xFFA5F3FC) : const Color(0xFF67E8F9));
        for (int i = 0; i < 3 + level; i++) {
          final ix = -cs * 0.16 + i * (cs * 0.32 / (3 + level));
          final icicle = Path()
            ..moveTo(ix - cs*0.025, -cs*0.04)
            ..lineTo(ix + cs*0.025, -cs*0.04)
            ..lineTo(ix, cs*0.14)
            ..close();
          canvas.drawPath(icicle, Paint()..color = const Color(0xFFCFFAFE));
        }
        break;

      case TowerType.sniper:
        canvas.drawRRect(
          RRect.fromRectAndRadius(Rect.fromLTWH(-cs*0.11, -h * 1.15, cs*0.22, h * 1.15), Radius.circular(cs*0.04)),
          Paint()..color = level >= 3 ? const Color(0xFF1E1B4B) : const Color(0xFF312E81),
        );
        canvas.drawCircle(Offset(0, -h * 0.75), cs * 0.15,
            Paint()..color = const Color(0xFF4338CA));
        canvas.drawCircle(Offset(0, -h * 0.75), cs * 0.08,
            Paint()..color = const Color(0xFF1E1B4B));
        break;

      case TowerType.bomb:
        canvas.drawCircle(Offset.zero, cs * 0.2,
            Paint()..color = level >= 3 ? const Color(0xFF7F1D1D) : const Color(0xFF991B1B));
        for (int i = 0; i < 5; i++) {
          final a = (i / 5) * pi * 2;
          canvas.drawCircle(Offset(cos(a) * cs * 0.15, sin(a) * cs * 0.15), cs * 0.065,
              Paint()..color = const Color(0xFFB91C1C));
        }
        // Upward barrel
        canvas.drawRRect(
          RRect.fromRectAndRadius(Rect.fromLTWH(-cs*0.06, -cs*0.28, cs*0.12, cs*0.22), Radius.circular(cs*0.03)),
          Paint()..color = const Color(0xFF1F2937),
        );
        final mp = 0.8 + sin(_pulse * 1.5) * 0.3;
        canvas.drawCircle(Offset(0, -cs * 0.26), cs * 0.07,
            Paint()..color = const Color(0xFFF97316).withOpacity(mp * 0.6)
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));
        break;
    }
  }

  void _drawBarrel(Canvas canvas, double cs) {
    // Only for directional towers
    if (config.type == TowerType.bomb) return; // bomb has upward barrel
    final bh = cs * 0.28, bw = cs * 0.07;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(-bw / 2, -bh, bw, bh), Radius.circular(bw * 0.3)),
      Paint()..color = const Color(0xFF1F2937),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(-bw / 2, -bh, bw, bh * 0.22), Radius.circular(bw * 0.3)),
      Paint()..color = config.glowColor.withOpacity(0.7),
    );
  }
}
