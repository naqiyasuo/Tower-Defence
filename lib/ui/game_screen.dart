import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import '../game/td_game.dart';
import '../data/tower_data.dart';
import '../data/enemy_data.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});
  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  late TowerDefenseGame _game;
  late AnimationController _toastCtrl;
  late AnimationController _bannerCtrl;
  String _toastMsg  = '';
  String _bannerMsg = '';
  bool   _placingMode = false;
  bool   _isDragging  = false;
  Offset _dragLocal   = Offset.zero;

  final GlobalKey _gameAreaKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _game = TowerDefenseGame();
    _toastCtrl  = AnimationController(vsync: this, duration: const Duration(milliseconds: 280));
    _bannerCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 380));
    _game.onStateChanged = () { if (mounted) setState(() {}); };
    _game.onGoldChanged  = () { if (mounted) setState(() {}); };
    _game.onLivesChanged = () { if (mounted) setState(() {}); };
    _game.onWaveChanged  = () { if (mounted) setState(() {}); };
    _game.onShowToast    = _toast;
  }

  @override
  void dispose() { _toastCtrl.dispose(); _bannerCtrl.dispose(); super.dispose(); }

  Offset _toLocal(Offset global) {
    final box = _gameAreaKey.currentContext?.findRenderObject() as RenderBox?;
    if (box != null && box.hasSize) return box.globalToLocal(global);
    return global;
  }

  Size _gameSize() {
  final box = _gameAreaKey.currentContext?.findRenderObject() as RenderBox?;
  return box?.size ?? Size.zero;
}

  void _toast(String msg) {
    if (!mounted) return;
    setState(() => _toastMsg = msg);
    _toastCtrl.forward(from: 0).then((_) =>
        Future.delayed(const Duration(milliseconds: 1700),
            () { if (mounted) _toastCtrl.reverse(); }));
  }

  void _banner(String msg) {
    if (!mounted) return;
    setState(() => _bannerMsg = msg);
    _bannerCtrl.forward(from: 0).then((_) =>
        Future.delayed(const Duration(seconds: 2),
            () { if (mounted) _bannerCtrl.reverse(); }));
  }

  void _selectType(TowerType type) {
    final cfg = TowerData.configs[type]!;
    if (_game.gold < cfg.cost) { _toast('💰 تحتاج ${cfg.cost}🪙'); return; }
    setState(() {
      _game.selectedTowerType = type;
      _game.deselectTower();
      _placingMode = true;
    });
    _toast('انقر على الخريطة لوضع ${cfg.name}');
  }

  // ── لمس بسيط على الخريطة ──
  void _onGameTap(Offset local) {
  final size = _gameSize();

  final scaledX = local.dx * (_game.size.x / size.width);
  final scaledY = local.dy * (_game.size.y / size.height);

  final (col, row) = _game.pixelToCell(scaledX, scaledY);

  if (_placingMode) {
    final ok = _game.placeTower(_game.selectedTowerType, col, row);
    if (ok) setState(() {
      _placingMode  = false;
      _game.dragCol = null;
      _game.dragRow = null;
    });
  } else {
    _game.trySelectAt(col, row);
  }
}

  // ── حركة الإصبع داخل منطقة اللعبة ——
  // localPosition مباشر ✓ — لا يحتاج _toLocal
  void _moveInGame(Offset local) {
  final size = _gameSize();

  final scaledX = local.dx * (_game.size.x / size.width);
  final scaledY = local.dy * (_game.size.y / size.height);

  final (c, r) = _game.pixelToCell(scaledX, scaledY);

  _dragLocal = local;
  _game.dragCol = c;
  _game.dragRow = r;

  if (mounted) setState(() {});
}

  // ── بدء السحب من الـ panel ──
  void _startDrag(TowerType type, Offset global) {
    final cfg = TowerData.configs[type]!;
    if (_game.gold < cfg.cost) { _toast('💰 تحتاج ${cfg.cost}🪙'); return; }
    final local = _toLocal(global);
    setState(() {
      _game.selectedTowerType = type;
      _game.deselectTower();
      _isDragging  = true;
      _placingMode = false;
    });
    _dragLocal = local;
    final (c, r) = _game.pixelToCell(local.dx, local.dy);
    _game.dragCol = c;
    _game.dragRow = r;
  }

  // ── حركة السحب من الـ panel ──
  void _moveDrag(Offset global) {
    if (!_isDragging) return;
    final local = _toLocal(global);
    _dragLocal = local;
    final (c, r) = _game.pixelToCell(local.dx, local.dy);
    _game.dragCol = c;
    _game.dragRow = r;
    if (mounted) setState(() {});
  }

  // ── إنهاء السحب — يضع البرج في نفس الخلية المعروضة في المعاينة ──
  void _endDrag() {
    if (!_isDragging) return;
    final dc = _game.dragCol;
    final dr = _game.dragRow;
    // ← يستخدم dragCol/dragRow المخزّن — نفس الخلية في المعاينة تماماً
    if (dc != null && dr != null) {
      _game.placeTower(_game.selectedTowerType, dc, dr);
    }
    setState(() {
      _isDragging   = false;
      _game.dragCol = null;
      _game.dragRow = null;
    });
  }

  void _cancelPlace() => setState(() {
    _placingMode  = false;
    _game.dragCol = null;
    _game.dragRow = null;
  });

  @override
  Widget build(BuildContext context) {
    final pad = MediaQuery.of(context).padding;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(children: [

        Container(
          color: Colors.black,
          padding: EdgeInsets.only(top: pad.top + 4, bottom: 6, left: 12, right: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _stat('❤️', '${_game.lives}',  const Color(0xFFFF6B6B)),
              _stat('💰', '${_game.gold}',   const Color(0xFFFFD93D)),
              _stat('🌊', '${_game.currentWave}/${EnemyData.waves.length}', const Color(0xFF4ADE80)),
              _stat('⭐', '${_game.score}',  const Color(0xFF60A5FA)),
            ],
          ),
        ),

        Expanded(
          child: LayoutBuilder(builder: (ctx, box) {
            _game.updateGameSize(box.maxWidth, box.maxHeight);
            return Stack(key: _gameAreaKey, children: [

              GameWidget(game: _game),

              GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTapUp: (d) => _onGameTap(d.localPosition),
                onPanStart:  (d) {
                  if (_placingMode || _isDragging) _moveInGame(d.localPosition);
                },
                onPanUpdate: (d) {
                  if (_placingMode || _isDragging) _moveInGame(d.localPosition);
                },
                onPanEnd: (_) { if (_isDragging) _endDrag(); },
                child: const SizedBox.expand(),
              ),

              Positioned(
                top: 8, right: 10,
                child: GestureDetector(
                  onTap: () => setState(() =>
                      _game.setGameSpeed(_game.gameSpeed >= 3 ? 1 : _game.gameSpeed + 1)),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 1),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('⏩ ×${_game.gameSpeed.toInt()}',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF4ADE80))),
                  ),
                ),
              ),

              if (_placingMode)
                Positioned(bottom: 8, left: 10, right: 10, child: _buildPlacingHint()),

              if (_isDragging || _placingMode) _buildDragIcon(),

              Positioned(top: 8, left: 20, right: 20, child: _buildToast()),
              _buildBanner(),
              if (_game.state != GameState.playing) _buildEndScreen(),
            ]);
          }),
        ),

        _buildPanel(pad),
      ]),
    );
  }

  Widget _stat(String ico, String val, Color col) => Row(children: [
    Text(ico, style: const TextStyle(fontSize: 15)),
    const SizedBox(width: 3),
    Text(val, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: col)),
  ]);

  Widget _buildPlacingHint() {
    final cfg = TowerData.configs[_game.selectedTowerType]!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.5),
        border: Border.all(color: cfg.glowColor),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(cfg.emoji, style: const TextStyle(fontSize: 18)),
        const SizedBox(width: 6),
        Flexible(child: Text('انقر لوضع ${cfg.name}',
            style: TextStyle(fontSize: 11.5, color: cfg.glowColor, fontWeight: FontWeight.w700))),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: _cancelPlace,
          child: const Text('✕', style: TextStyle(fontSize: 16, color: Colors.redAccent, fontWeight: FontWeight.w900)),
        ),
      ]),
    );
  }

  // ── أيقونة السحب — تطابق GridComponent تماماً ──
  Widget _buildDragIcon() {
    final dc = _game.dragCol;
    final dr = _game.dragRow;
    final cs = _game.cellSize;
    if (dc == null || dr == null || cs <= 0) return const SizedBox.shrink();

    final cfg   = TowerData.configs[_game.selectedTowerType]!;
    final valid = _game.isCellValid(dc, dr);
    final col   = valid ? cfg.glowColor : Colors.red;

    // نفس إحداثيات GridComponent بالضبط
    final cellX = _game.mapOffsetX + dc * cs;
    final cellY = _game.mapOffsetY + dr * cs;

    return Positioned(
      left: cellX,
      top:  cellY,
      child: IgnorePointer(
        child: Container(
          width: cs, height: cs,
          decoration: BoxDecoration(
            color:  col.withValues(alpha: 0.55),
            border: Border.all(color: col, width: 2.5),
            borderRadius: BorderRadius.circular(6),
            boxShadow: [BoxShadow(color: col.withValues(alpha: 0.7), blurRadius: 8)],
          ),
          child: Center(
            child: Text(cfg.emoji,
                style: TextStyle(fontSize: (cs * 0.5).clamp(14.0, 26.0))),
          ),
        ),
      ),
    );
  }

  Widget _buildPanel(EdgeInsets pad) => Container(
    color: const Color(0xFF0A0A0A),
    padding: EdgeInsets.fromLTRB(10, 8, 10, pad.bottom + 10),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      if (_game.selectedTower != null) _buildSelInfo(),
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(children: TowerType.values.map(_buildTowerBtn).toList()),
      ),
      const SizedBox(height: 7),
      Row(children: [
        Expanded(child: _actBtn('▶ ابدأ', const Color(0xFF22C55E), const Color(0xFF15803D),
            _game.waveActive ? null : () { _game.startWave(); _banner('🌊 موجة ${_game.currentWave}'); })),
        const SizedBox(width: 6),
        Expanded(child: _actBtn('⬆ ترقية', const Color(0xFFF59E0B), const Color(0xFFB45309),
            _game.selectedTower == null ? null : _game.upgradeTower)),
        const SizedBox(width: 6),
        Expanded(child: _actBtn('🗑 بيع', const Color(0xFFEF4444), const Color(0xFFB91C1C),
            _game.selectedTower == null ? null : _game.sellTower)),
      ]),
    ]),
  );

  Widget _buildTowerBtn(TowerType type) {
    final cfg       = TowerData.configs[type]!;
    final isSel     = _game.selectedTowerType == type && _placingMode;
    final canAfford = _game.gold >= cfg.cost;
    return GestureDetector(
      onTap: () => _selectType(type),
      onLongPressStart:      (d) => _startDrag(type, d.globalPosition),
      onLongPressMoveUpdate: (d) => _moveDrag(d.globalPosition),
      onLongPressEnd:        (_) => _endDrag(),
      onLongPressCancel:     ()  { setState(() {
        _isDragging = false; _game.dragCol = null; _game.dragRow = null;
      }); },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: isSel ? cfg.glowColor.withValues(alpha: 0.50) : Colors.white.withValues(alpha: 0.02),
          border: Border.all(
            color: isSel ? cfg.glowColor : Colors.white.withValues(alpha: canAfford ? 0.5 : 0.1),
            width: isSel ? 2.5 : 1.5,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSel ? [BoxShadow(color: cfg.glowColor.withValues(alpha: 0.65), blurRadius: 12)] : [],
        ),
        child: Opacity(
          opacity: canAfford ? 1.0 : 0.38,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(cfg.emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(height: 2),
            Text(cfg.name, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700,
                color: Colors.white.withValues(alpha: 0.82))),
            Text('${cfg.cost}🪙', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700,
                color: canAfford ? const Color(0xFFFFD93D) : Colors.redAccent)),
            const SizedBox(height: 3),
            Container(height: 2.5, width: 44, decoration: BoxDecoration(
                color: canAfford ? cfg.glowColor : cfg.glowColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2))),
          ]),
        ),
      ),
    );
  }

  Widget _buildSelInfo() => Container(
    margin: const EdgeInsets.only(bottom: 7),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.7),
      border: Border.all(color: Colors.white.withValues(alpha: 0.42)),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Expanded(child: Text(
          '${_game.selectedTower!.config.emoji} ${_game.selectedTower!.config.name}  —  Lvl ${_game.selectedTower!.level}/5',
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
          overflow: TextOverflow.ellipsis)),
      Text('ترقية: ${_game.selectedTower!.config.cost ~/ 2 * _game.selectedTower!.level}🪙',
          style: const TextStyle(fontSize: 10, color: Color(0xFFFFD93D))),
    ]),
  );

  Widget _actBtn(String label, Color c1, Color c2, VoidCallback? fn) =>
      GestureDetector(
        onTap: fn,
        child: Opacity(
          opacity: fn == null ? 0.38 : 1.0,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 11),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [c1, c2]),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Text(label, textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.white)),
          ),
        ),
      );

  Widget _buildToast() => FadeTransition(
    opacity: _toastCtrl,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.9),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.8)),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(_toastMsg, textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFFFFD93D))),
    ),
  );

  Widget _buildBanner() => Center(
    child: ScaleTransition(
      scale: CurvedAnimation(parent: _bannerCtrl, curve: Curves.elasticOut),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xF0031408),
          border: Border.all(color: const Color(0xFF4ADE80), width: 2.5),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(color: const Color(0xFF4ADE80).withValues(alpha: 0.4), blurRadius: 40)],
        ),
        child: Text(_bannerMsg,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF4ADE80))),
      ),
    ),
  );

  Widget _buildEndScreen() {
    final win = _game.state == GameState.victory;
    return Container(
      color: Colors.black.withValues(alpha: 0.88),
      child: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(win ? '🏆' : '💀', style: const TextStyle(fontSize: 72)),
          const SizedBox(height: 10),
          Text(win ? 'انتصرت!' : 'خسرت!',
              style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900,
                  color: win ? const Color(0xFF4ADE80) : const Color(0xFFEF4444))),
          const SizedBox(height: 5),
          Text('النقاط: ${_game.score}',
              style: const TextStyle(fontSize: 15, color: Color(0xFF94A3B8))),
          const SizedBox(height: 22),
          GestureDetector(
            onTap: () => Navigator.pushReplacement(
                context, MaterialPageRoute(builder: (_) => const GameScreen())),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 13),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF22C55E), Color(0xFF15803D)]),
                borderRadius: BorderRadius.circular(13),
              ),
              child: const Text('العب مجددًا',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF052E16))),
            ),
          ),
        ]),
      ),
    );
  }
}
