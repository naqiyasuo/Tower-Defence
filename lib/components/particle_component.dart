import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../game/td_game.dart';

class ParticleComponent extends PositionComponent with HasGameRef<TowerDefenseGame> {
  final Vector2 velocity;
  final Color color;
  final double radius;
  final double lifetime;
  double _elapsed = 0;

  @override
  int get priority => 12;

  ParticleComponent({
    required Vector2 position,
    required this.velocity,
    required this.color,
    required this.radius,
    required this.lifetime,
  }) : super(position: position, anchor: Anchor.center, size: Vector2.all(radius * 2));

  @override
  void update(double dt) {
    _elapsed += dt;
    velocity.y += 80 * dt; // gravity
    position += velocity * dt;
    if (_elapsed >= lifetime) {
      game.removeParticle(this);
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    final life = (1 - _elapsed / lifetime).clamp(0.0, 1.0);
    canvas.drawCircle(
      Offset.zero,
      radius * life,
      Paint()
        ..color = color.withOpacity(life * 0.85)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 4 * life),
    );
  }
}
