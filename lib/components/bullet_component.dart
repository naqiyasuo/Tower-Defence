import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../data/tower_data.dart';
import '../game/td_game.dart';
import 'enemy_component.dart';

typedef BulletHitCallback = void Function(BulletComponent bullet, EnemyComponent target);

class BulletComponent extends PositionComponent with HasGameRef<TowerDefenseGame> {
  final EnemyComponent target;
  final TowerConfig config;
  final BulletHitCallback onHit;
  final TowerDefenseGame game;

  Vector2 _prevPos = Vector2.zero();
  double _spinAngle = 0;

  @override
  int get priority => 9;

  BulletComponent({
    required Vector2 startPosition,
    required this.target,
    required this.config,
    required this.game,
    required this.onHit,
  }) : super(
          position: startPosition,
          anchor: Anchor.center,
          size: Vector2.all(14),
        );

  @override
  Future<void> onLoad() async {
    _prevPos = position.clone();
  }

  @override
  void update(double dt) {
    if (target.isDead) {
      game.removeBullet(this);
      removeFromParent();
      return;
    }

    _spinAngle += dt * 8;
    _prevPos = position.clone();
    final dir = target.position - position;
    final dist = dir.length;
    final step = config.bulletSpeed * dt;

    if (dist <= step * 2) {
      onHit(this, target);
      game.removeBullet(this);
      removeFromParent();
      return;
    }

    dir.normalize();
    position += dir * step;
  }

  @override
  void render(Canvas canvas) {
    _drawBullet(canvas);
  }

  void _drawBullet(Canvas canvas) {
    final glow = Paint()
      ..color = config.glowColor.withOpacity(0.8)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    switch (config.bt) {
      case 'arrow':
        canvas.drawCircle(Offset.zero, 4,
            Paint()..color = config.color..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
        canvas.drawCircle(Offset.zero, 4, Paint()..color = config.color);
        canvas.drawCircle(Offset.zero, 2, Paint()..color = Colors.white);
        break;

      case 'ball':
        canvas.drawCircle(Offset.zero, 7, glow);
        canvas.drawCircle(Offset.zero, 7, Paint()..color = config.color);
        canvas.drawCircle(const Offset(-2, -2), 2.5, Paint()..color = Colors.white.withOpacity(0.55));
        break;

      case 'magic':
        canvas.save();
        canvas.rotate(_spinAngle);
        for (int i = 0; i < 6; i++) {
          final angle = (i / 6) * pi * 2;
          canvas.drawCircle(Offset(cos(angle) * 6, sin(angle) * 6), 3, glow);
          canvas.drawCircle(Offset(cos(angle) * 6, sin(angle) * 6), 3, Paint()..color = config.color);
        }
        canvas.restore();
        break;

      case 'ice':
        canvas.drawCircle(Offset.zero, 5, glow);
        canvas.drawCircle(Offset.zero, 5, Paint()..color = const Color(0xFFCFFAFE));
        canvas.drawCircle(Offset.zero, 5,
            Paint()
              ..color = const Color(0xFF67E8F9)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.5);
        break;

      case 'sniper':
        // Draw streak from prev to current
        final offset = _prevPos - position;
        canvas.drawLine(Offset(offset.x, offset.y), Offset.zero,
            Paint()
              ..color = config.color
              ..strokeWidth = 2.5
              ..strokeCap = StrokeCap.round
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3));
        canvas.drawCircle(Offset.zero, 3, Paint()..color = Colors.white);
        break;

      case 'bomb':
        canvas.drawCircle(Offset.zero, 8, Paint()..color = const Color(0xFF1A1A1A));
        canvas.drawCircle(Offset.zero, 5.5, Paint()..color = config.color);
        // Fuse spark
        canvas.drawCircle(const Offset(4, -6), 2.5,
            Paint()..color = Colors.amber
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));
        break;

      default:
        canvas.drawCircle(Offset.zero, 4, Paint()..color = config.color);
    }
  }
}

// Extension on TowerConfig for bullet type string
extension TowerConfigExt on TowerConfig {
  String get bt {
    switch (type) {
      case TowerType.archer: return 'arrow';
      case TowerType.cannon: return 'ball';
      case TowerType.mage:   return 'magic';
      case TowerType.ice:    return 'ice';
      case TowerType.sniper: return 'sniper';
      case TowerType.bomb:   return 'bomb';
    }
  }
}
