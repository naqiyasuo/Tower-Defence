import 'package:flutter/material.dart';

// ══════════════════════════════════════════════════════════
//  إعدادات نوع العدو
// ══════════════════════════════════════════════════════════
class EnemyConfig {
  final String name;          // اسم العدو
  final Color color;          // لون الجسم
  final Color borderColor;    // لون الحدود
  final double baseHp;        // الصحة الأساسية (تُضرب في hpMultiplier عند كل موجة)
  final double baseSpeed;     // السرعة الأساسية بالبكسل/ثانية
  final double size;          // حجم العدو (1.0 = عادي, 1.9 = ضخم)
  final bool hasCrown;        // هل يرتدي تاجاً؟ (boss)
  final bool hasWings;        // هل له أجنحة؟
  final bool hasArmor;        // هل يرتدي درعاً؟

  const EnemyConfig({
    required this.name,
    required this.color,
    required this.borderColor,
    required this.baseHp,
    required this.baseSpeed,
    this.size      = 1.0,
    this.hasCrown  = false,
    this.hasWings  = false,
    this.hasArmor  = false,
  });
}

// ══════════════════════════════════════════════════════════
//  إعدادات الموجة
// ══════════════════════════════════════════════════════════
class WaveConfig {
  final int    enemyCount;       // عدد الأعداء في الموجة
  final double hpMultiplier;     // ضاعف الصحة (2.0 = ضعف الصحة الأساسية)
  final double speedMultiplier;  // ضاعف السرعة
  final double spawnInterval;    // الوقت بين ظهور كل عدو (بالثواني)
  final int    reward;           // الذهب لكل قتل
  final int    waveBonus;        // ذهب إضافي عند إنهاء الموجة
  final int    enemyTypeIndex;   // نوع العدو (رقم من 0 إلى 9 في قائمة types)

  const WaveConfig({
    required this.enemyCount,
    required this.hpMultiplier,
    required this.speedMultiplier,
    required this.spawnInterval,
    required this.reward,
    required this.waveBonus,
    required this.enemyTypeIndex,
  });
}

// ══════════════════════════════════════════════════════════
//  بيانات الأعداء والموجات
//  لإضافة عدو جديد: أضفه في types
//  لتغيير صعوبة موجة: عدّل أرقامها في waves
// ══════════════════════════════════════════════════════════
class EnemyData {

  // ── أنواع الأعداء (الترتيب مهم — رقم الموجة يختار من هنا) ──
  static const List<EnemyConfig> types = [
    // 0 — Goblin: بداية سهلة
    EnemyConfig(name:'Goblin',    color:Color(0xFF22C55E), borderColor:Color(0xFF166534),
        baseHp:80,   baseSpeed:80,  size:1.0),
    // 1 — Orc: أبطأ لكن مدرّع
    EnemyConfig(name:'Orc',       color:Color(0xFF3B82F6), borderColor:Color(0xFF1E40AF),
        baseHp:120,  baseSpeed:70,  size:1.1,  hasArmor:true),
    // 2 — Troll: أضخم
    EnemyConfig(name:'Troll',     color:Color(0xFFF59E0B), borderColor:Color(0xFF92400E),
        baseHp:200,  baseSpeed:60,  size:1.25),
    // 3 — Ogre: ضخم ومدرّع
    EnemyConfig(name:'Ogre',      color:Color(0xFFEF4444), borderColor:Color(0xFF991B1B),
        baseHp:300,  baseSpeed:55,  size:1.4,  hasArmor:true),
    // 4 — Demon: يطير وسريع
    EnemyConfig(name:'Demon',     color:Color(0xFF8B5CF6), borderColor:Color(0xFF5B21B6),
        baseHp:420,  baseSpeed:90,  size:1.45, hasWings:true),
    // 5 — Witch: سريعة وتطير
    EnemyConfig(name:'Witch',     color:Color(0xFFEC4899), borderColor:Color(0xFF9D174D),
        baseHp:380,  baseSpeed:85,  size:1.4,  hasWings:true),
    // 6 — Golem: بطيء جداً لكن صحة هائلة
    EnemyConfig(name:'Golem',     color:Color(0xFF6B7280), borderColor:Color(0xFF1F2937),
        baseHp:600,  baseSpeed:45,  size:1.65, hasArmor:true),
    // 7 — Berserker: سريع + مدرّع + يطير
    EnemyConfig(name:'Berserker', color:Color(0xFFF97316), borderColor:Color(0xFFC2410C),
        baseHp:500,  baseSpeed:100, size:1.55, hasWings:true, hasArmor:true),
    // 8 — IceLord: boss بتاج
    EnemyConfig(name:'IceLord',   color:Color(0xFF06B6D4), borderColor:Color(0xFF0E7490),
        baseHp:750,  baseSpeed:65,  size:1.6,  hasCrown:true),
    // 9 — Dragon: التنين الأخير — boss نهائي
    EnemyConfig(name:'Dragon',    color:Color(0xFFFBBF24), borderColor:Color(0xFFD97706),
        baseHp:1200, baseSpeed:50,  size:1.9,  hasCrown:true, hasWings:true),
  ];

  // ── الموجات العشر — عدّل الأرقام لتغيير الصعوبة ──
  // الترتيب: enemyCount | hpMultiplier | speedMultiplier | spawnInterval | reward | waveBonus | enemyTypeIndex
  static const List<WaveConfig> waves = [
    // موجة 1 — Goblin — سهلة جداً
    WaveConfig(enemyCount:8,  hpMultiplier:1.0, speedMultiplier:1.0,  spawnInterval:1.8, reward:8,  waveBonus:60,  enemyTypeIndex:0),
    // موجة 2 — Orc
    WaveConfig(enemyCount:10, hpMultiplier:1.3, speedMultiplier:1.05, spawnInterval:1.6, reward:10, waveBonus:80,  enemyTypeIndex:1),
    // موجة 3 — Troll
    WaveConfig(enemyCount:12, hpMultiplier:1.7, speedMultiplier:1.1,  spawnInterval:1.5, reward:12, waveBonus:100, enemyTypeIndex:2),
    // موجة 4 — Ogre
    WaveConfig(enemyCount:14, hpMultiplier:2.2, speedMultiplier:1.15, spawnInterval:1.4, reward:14, waveBonus:120, enemyTypeIndex:3),
    // موجة 5 — Demon
    WaveConfig(enemyCount:16, hpMultiplier:2.8, speedMultiplier:1.2,  spawnInterval:1.3, reward:17, waveBonus:150, enemyTypeIndex:4),
    // موجة 6 — Witch
    WaveConfig(enemyCount:18, hpMultiplier:3.5, speedMultiplier:1.25, spawnInterval:1.2, reward:20, waveBonus:180, enemyTypeIndex:5),
    // موجة 7 — Golem
    WaveConfig(enemyCount:20, hpMultiplier:4.5, speedMultiplier:1.3,  spawnInterval:1.1, reward:24, waveBonus:220, enemyTypeIndex:6),
    // موجة 8 — Berserker
    WaveConfig(enemyCount:23, hpMultiplier:5.5, speedMultiplier:1.35, spawnInterval:1.0, reward:29, waveBonus:260, enemyTypeIndex:7),
    // موجة 9 — IceLord
    WaveConfig(enemyCount:27, hpMultiplier:7.0, speedMultiplier:1.4,  spawnInterval:0.9, reward:36, waveBonus:320, enemyTypeIndex:8),
    // موجة 10 — Dragon — النهائية
    WaveConfig(enemyCount:32, hpMultiplier:9.0, speedMultiplier:1.5,  spawnInterval:0.8, reward:46, waveBonus:400, enemyTypeIndex:9),
  ];
}
