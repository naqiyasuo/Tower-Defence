import 'dart:math';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import '../components/path_component.dart';
import '../components/tower_component.dart';
import '../components/enemy_component.dart';
import '../components/bullet_component.dart';
import '../components/particle_component.dart';
import '../components/map_component.dart';
import '../components/grid_component.dart';
import '../data/tower_data.dart';
import '../data/enemy_data.dart';

enum GameState { playing, gameOver, victory }

class TowerDefenseGame extends FlameGame with HasCollisionDetection {

  int gold = 150; int lives = 20; int score = 0;
  int currentWave = 0; bool waveActive = false;
  GameState state = GameState.playing;
  double gameSpeed = 1.0;

  VoidCallback?     onStateChanged;
  VoidCallback?     onGoldChanged;
  VoidCallback?     onLivesChanged;
  VoidCallback?     onWaveChanged;
  Function(String)? onShowToast;

  static const int COLS = 9;
  static const int ROWS = 13;

  double gameW = 0;
  double gameH = 0;

  // ══════════════════════════════════════════════════════
  // هذه الثلاث يتم تحديثها دفعة واحدة في _rebuildPath
  // لا تستخدم getters حتى تبقى متسقة دائماً
  // ══════════════════════════════════════════════════════
  double cellSize   = 40.0;
  double mapOffsetX = 0.0;
  double mapOffsetY = 0.0;

  final Set<String> pathCells     = {};
  final Set<String> occupiedCells = {};

  int? dragCol; int? dragRow;
  TowerType selectedTowerType = TowerType.archer;
  TowerComponent? selectedTower;

  late PathComponent   pathComp;
  late List<Vector2>   pathPoints;
  late GridComponent   gridComp;
  late MapComponent    mapComp;

  final List<TowerComponent>    towers    = [];
  final List<EnemyComponent>    enemies   = [];
  final List<BulletComponent>   bullets   = [];
  final List<ParticleComponent> particles = [];

  bool   _pathCompReady = false;
  double _lastW = 0, _lastH = 0;
  double _spawnTimer = 0; int _spawnCount = 0;
  final Random _rng = Random();

  @override
  Color backgroundColor() => const Color(0xFF3A8828);

  @override
  Future<void> onLoad() async {
    mapComp  = MapComponent();  await add(mapComp);
    pathComp = PathComponent(); await add(pathComp);
    gridComp = GridComponent(); await add(gridComp);
    pathPoints = [];
    _pathCompReady = true;
    // إذا جاء الحجم قبل onLoad
    if (gameW > 0 && gameH > 0) _rebuildPath();
  }

  // ── يُستدعى من LayoutBuilder — نفس الأبعاد التي تستخدمها localPosition ──
  void updateGameSize(double w, double h) {
    gameW = w; gameH = h;
    if (!_pathCompReady) return;
    if ((w - _lastW).abs() < 0.5 && (h - _lastH).abs() < 0.5) return;
    _lastW = w; _lastH = h;
    _rebuildPath();
  }

  // ── يحسب الأبعاد ويبني المسار دفعة واحدة ──
  void _rebuildPath() {
    if (gameW <= 0 || gameH <= 0) return;

    // تحديث الثلاثة دفعة واحدة — لا يوجد تناقض بينها
    cellSize   = min(gameW / COLS, gameH / ROWS);
    mapOffsetX = (gameW - cellSize * COLS) / 2;
    mapOffsetY = (gameH - cellSize * ROWS) / 2;

    pathPoints = pathComp.buildPath(
      cols: COLS, rows: ROWS,
      cellSize: cellSize, offsetX: mapOffsetX, offsetY: mapOffsetY,
    );
    _buildPathSet();

    for (final t in towers) {
      t.position = cellCenter(t.gridCol, t.gridRow);
      t.size     = Vector2.all(cellSize);
    }
  }

  void _buildPathSet() {
    pathCells.clear();
    if (pathPoints.isEmpty) return;
    for (int i = 0; i < pathPoints.length - 1; i++) {
      final a = pathPoints[i], b = pathPoints[i + 1];
      final steps = (a.distanceTo(b) / (cellSize * 0.2)).ceil() + 4;
      for (int s = 0; s <= steps; s++) {
        final t  = s / steps;
        final px = a.x + (b.x - a.x) * t;
        final py = a.y + (b.y - a.y) * t;
        final c  = ((px - mapOffsetX) / cellSize).floor();
        final r  = ((py - mapOffsetY) / cellSize).floor();
        if (c >= 0 && c < COLS && r >= 0 && r < ROWS) pathCells.add('$c,$r');
      }
    }
    for (int i = 1; i < pathPoints.length - 1; i++) {
      final p = pathPoints[i];
      final c = ((p.x - mapOffsetX) / cellSize).floor();
      final r = ((p.y - mapOffsetY) / cellSize).floor();
      if (c >= 0 && c < COLS && r >= 0 && r < ROWS) pathCells.add('$c,$r');
    }
  }

  (int, int) pixelToCell(double px, double py) => (
    ((px - mapOffsetX) / cellSize).floor(),
    ((py - mapOffsetY) / cellSize).floor(),
  );

  Vector2 cellCenter(int col, int row) => Vector2(
    mapOffsetX + col * cellSize + cellSize / 2,
    mapOffsetY + row * cellSize + cellSize / 2,
  );

  bool isCellValid(int c, int r) {
    if (c < 0 || c >= COLS || r < 0 || r >= ROWS) return false;
    if (pathCells.contains('$c,$r'))     return false;
    if (occupiedCells.contains('$c,$r')) return false;
    return true;
  }

  bool placeTower(TowerType type, int col, int row) {
    if (!isCellValid(col, row)) {
      onShowToast?.call('❌ لا يمكن البناء هنا!');
      return false;
    }
    final cfg = TowerData.configs[type]!;
    if (gold < cfg.cost) { onShowToast?.call('💰 تحتاج ${cfg.cost}🪙'); return false; }
    gold -= cfg.cost; onGoldChanged?.call();
    final t = TowerComponent(
      gridCol: col, gridRow: row,
      position: cellCenter(col, row),
      config: cfg, game: this,
    );
    towers.add(t); occupiedCells.add('$col,$row'); add(t);
    spawnParticles(cellCenter(col, row), cfg.glowColor, 6);
    return true;
  }

  void trySelectAt(int col, int row) {
    for (final t in towers) {
      if (t.gridCol == col && t.gridRow == row) {
        selectedTower?.setSelected(false); selectedTower = t; t.setSelected(true);
        onStateChanged?.call(); return;
      }
    }
    deselectTower();
  }

  void deselectTower() {
    selectedTower?.setSelected(false); selectedTower = null; onStateChanged?.call();
  }

  void upgradeTower() {
    final t = selectedTower; if (t == null) return;
    if (t.level >= 5) { onShowToast?.call('🏆 المستوى الأقصى!'); return; }
    final cost = t.config.cost ~/ 2 * t.level;
    if (gold < cost) { onShowToast?.call('تحتاج $cost🪙'); return; }
    gold -= cost; t.upgrade(); onGoldChanged?.call(); onStateChanged?.call();
    spawnParticles(t.position, t.config.glowColor, 8);
    onShowToast?.call('✅ Lvl ${t.level}');
  }

  void sellTower() {
    final t = selectedTower; if (t == null) return;
    final ref = (t.config.cost * 0.65 * t.level).toInt();
    gold += ref; occupiedCells.remove('${t.gridCol},${t.gridRow}');
    towers.remove(t); remove(t); selectedTower = null;
    onGoldChanged?.call(); onStateChanged?.call();
    onShowToast?.call('💰 +$ref🪙');
  }

  void startWave() {
    if (waveActive || state != GameState.playing) return;
    if (currentWave >= EnemyData.waves.length) return;
    currentWave++; waveActive = true; _spawnTimer = 0; _spawnCount = 0;
    onWaveChanged?.call(); onStateChanged?.call();
  }

  @override
  void update(double dt) {
    if (state != GameState.playing) return;
    final s = dt * gameSpeed;
    super.update(s);
    _updateSpawn(s);
    _checkWaveEnd();
  }

  void _updateSpawn(double dt) {
    if (!waveActive || currentWave == 0 || pathPoints.isEmpty) return;
    final wave = EnemyData.waves[currentWave - 1];
    if (_spawnCount >= wave.enemyCount) return;
    _spawnTimer += dt;
    if (_spawnTimer >= wave.spawnInterval) {
      _spawnTimer = 0;
      final cfg = EnemyData.types[wave.enemyTypeIndex];
      final e = EnemyComponent(
        config: cfg,
        hp: cfg.baseHp * wave.hpMultiplier,
        speed: cfg.baseSpeed * wave.speedMultiplier,
        reward: wave.reward, pathPoints: pathPoints,
        onReachEnd: (e) {
          lives--; enemies.remove(e); onLivesChanged?.call();
          if (lives <= 0) { state = GameState.gameOver; onStateChanged?.call(); }
          spawnParticles(e.position, const Color(0xFFEF4444), 8);
        },
        onDie: (e, rew) {
          gold += rew; score += rew * 12; enemies.remove(e);
          onGoldChanged?.call(); onStateChanged?.call();
          spawnParticles(e.position, e.config.color, 12);
        },
      );
      enemies.add(e); add(e); _spawnCount++;
    }
  }

  void _checkWaveEnd() {
    if (!waveActive || currentWave == 0) return;
    final wave = EnemyData.waves[currentWave - 1];
    if (_spawnCount >= wave.enemyCount && enemies.isEmpty) {
      waveActive = false; gold += wave.waveBonus; score += 500;
      onGoldChanged?.call(); onStateChanged?.call();
      onShowToast?.call('🎉 موجة منتهية! +${wave.waveBonus}🪙');
      if (currentWave >= EnemyData.waves.length) {
        state = GameState.victory; onStateChanged?.call();
      }
    }
  }

  void fireBullet({required Vector2 from, required EnemyComponent target, required TowerConfig cfg}) {
    final b = BulletComponent(
      startPosition: from.clone(), target: target, config: cfg, game: this,
      onHit: (b, t) {
        bullets.remove(b);
        if (cfg.hasSplash) {
          for (final e in List.from(enemies)) {
            if (!e.isDead && e.position.distanceTo(t.position) <= cfg.splashRadius * cellSize)
              e.takeDamage(cfg.damage);
          }
          spawnParticles(t.position, cfg.glowColor, 10);
        } else if (cfg.hasChain) {
          t.takeDamage(cfg.damage); int ch = 0;
          final sorted = List<EnemyComponent>.from(enemies)
            ..sort((a, bb) => a.position.distanceTo(t.position).compareTo(bb.position.distanceTo(t.position)));
          for (final e in sorted) {
            if (ch >= cfg.chainCount || e == t || e.isDead) continue;
            e.takeDamage(cfg.damage * 0.6); spawnParticles(e.position, cfg.glowColor, 3); ch++;
          }
        } else {
          if (cfg.hasSlow) t.applySlow(cfg.slowDuration);
          t.takeDamage(cfg.damage);
        }
        spawnParticles(t.position, cfg.glowColor, 5);
      },
    );
    bullets.add(b); add(b);
  }

  void spawnParticles(Vector2 pos, Color col, int n) {
    for (int i = 0; i < n; i++) {
      final a = _rng.nextDouble() * pi * 2;
      final sp = _rng.nextDouble() * 80 + 30;
      particles.add(ParticleComponent(
        position: pos.clone(),
        velocity: Vector2(cos(a) * sp, sin(a) * sp - 40),
        color: col, radius: 2.5 + _rng.nextDouble() * 3,
        lifetime: 0.35 + _rng.nextDouble() * 0.35,
      )..addToParent(this));
    }
  }

  void removeParticle(ParticleComponent p) => particles.remove(p);
  void removeBullet(BulletComponent b)      => bullets.remove(b);
  void setGameSpeed(double s)               => gameSpeed = s;
}
