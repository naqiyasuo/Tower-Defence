import 'package:flutter/material.dart';
import 'game_screen.dart';

class MainMenuScreen extends StatefulWidget {
  const MainMenuScreen({super.key});
  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _pulse = Tween<double>(begin: 1.0, end: 1.08).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF060D06), Color(0xFF0A1A0A), Color(0xFF060812)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              // Logo
              ScaleTransition(
                scale: _pulse,
                child: Container(
                  width: 110, height: 110,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const RadialGradient(colors: [Color(0xFF22C55E), Color(0xFF052E16)]),
                    boxShadow: [BoxShadow(color: const Color(0xFF22C55E).withOpacity(0.5), blurRadius: 30)],
                  ),
                  child: const Center(child: Text('🏰', style: TextStyle(fontSize: 52))),
                ),
              ),
              const SizedBox(height: 24),
              // Title
              ShaderMask(
                shaderCallback: (r) => const LinearGradient(colors: [Color(0xFFFBBF24), Color(0xFFF97316)]).createShader(r),
                child: const Text('Kingdom Guard', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white)),
              ),
              const SizedBox(height: 6),
              Text('دافع عن قلعتك!', style: TextStyle(fontSize: 16, color: Colors.white.withOpacity(0.5))),
              const SizedBox(height: 52),
              // Play button
              GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GameScreen())),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 56, vertical: 16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF22C55E), Color(0xFF15803D)]),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: const Color(0xFF22C55E).withOpacity(0.5), blurRadius: 24, offset: const Offset(0, 6))],
                  ),
                  child: const Text('▶  العب الآن', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF052E16))),
                ),
              ),
              const SizedBox(height: 16),
              // How to play
              GestureDetector(
                onTap: () => _showHowToPlay(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white.withOpacity(0.2)),
                    borderRadius: BorderRadius.circular(14),
                    color: Colors.white.withOpacity(0.05),
                  ),
                  child: const Text('❓  طريقة اللعب', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                ),
              ),
              const SizedBox(height: 40),
              // Tower icons
              Wrap(
                spacing: 12,
                children: ['🏹','💣','🔮','❄️','🎯','💥'].map((e) =>
                    Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withOpacity(0.1)),
                      ),
                      child: Center(child: Text(e, style: const TextStyle(fontSize: 22))),
                    )
                ).toList(),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  void _showHowToPlay(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF0F1A0F),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('طريقة اللعب', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 18)),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: const [
          _Step('1', '👆 اختر نوع البرج من الأسفل'),
          _Step('2', '👆 انقر على الأرض الخضراء لبنائه'),
          _Step('3', '▶ اضغط "ابدأ الموجة" لإطلاق الأعداء'),
          _Step('4', '👆 انقر على برج لتحديده ثم رقّيه أو بعه'),
          _Step('5', '⏩ اضغط زر السرعة لتسريع اللعبة'),
          SizedBox(height: 12),
          Text('🎯 الهدف: منع الأعداء من الوصول للقلعة!',
              style: TextStyle(fontSize: 12, color: Color(0xFF4ADE80), fontWeight: FontWeight.w700)),
        ]),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('حسناً!', style: TextStyle(color: Color(0xFF4ADE80), fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }
}

class _Step extends StatelessWidget {
  final String num;
  final String text;
  const _Step(this.num, this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(children: [
        Container(
          width: 24, height: 24,
          decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFF22C55E).withOpacity(0.2)),
          child: Center(child: Text(num, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFF22C55E)))),
        ),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: TextStyle(fontSize: 12.5, color: Colors.white.withOpacity(0.8)))),
      ]),
    );
  }
}
