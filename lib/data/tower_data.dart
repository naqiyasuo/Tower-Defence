import 'package:flutter/material.dart';

// ══════════════════════════════════════════════════════════
//  أنواع الأبراج — لإضافة برج جديد أضف اسمه هنا
// ══════════════════════════════════════════════════════════
enum TowerType { archer, cannon, mage, ice, sniper, bomb }

// ══════════════════════════════════════════════════════════
//  إعدادات البرج — كل خاصية وشرحها
// ══════════════════════════════════════════════════════════
class TowerConfig {
  final TowerType type;         // نوع البرج
  final String name;            // اسم البرج بالعربي
  final String description;     // وصف البرج في القائمة
  final String emoji;           // أيقونة البرج
  final int cost;               // سعر البناء بالذهب
  final double damage;          // مقدار الضرر لكل رصاصة
  final double fireRate;        // عدد الرصاصات في الثانية — كلما زاد كلما أسرع
  final double range;           // المدى بعدد الخلايا — كلما زاد كلما أبعد
  final double bulletSpeed;     // سرعة الرصاصة بالبكسل/ثانية
  final Color color;            // لون البرج الأساسي
  final Color glowColor;        // لون التوهج حول البرج
  final bool hasSplash;         // هل يضرب أكثر من عدو (انفجار)؟
  final double splashRadius;    // نصف قطر الانفجار بالخلايا
  final bool hasChain;          // هل يقفز للأعداء المجاورين؟
  final int chainCount;         // عدد الأعداء الإضافيين في السلسلة
  final bool hasSlow;           // هل يبطئ الأعداء؟
  final double slowDuration;    // مدة الإبطاء بالثوانٍ

  const TowerConfig({
    required this.type,
    required this.name,
    required this.description,
    required this.emoji,
    required this.cost,
    required this.damage,
    required this.fireRate,
    required this.range,
    required this.bulletSpeed,
    required this.color,
    required this.glowColor,
    this.hasSplash    = false,
    this.splashRadius = 0,
    this.hasChain     = false,
    this.chainCount   = 0,
    this.hasSlow      = false,
    this.slowDuration = 0,
  });

  // ── حساب تكلفة الترقية = نصف السعر × المستوى الحالي ──
  int get upgradeCost => cost ~/ 1.5;

  // ── إنشاء نسخة مرقّاة من البرج (يُستدعى عند ترقية البرج) ──
  // كل مستوى يزيد: الضرر ×1.4 | معدل الإطلاق ×1.15 | المدى ×1.1
  TowerConfig withLevel(int level) {
    final multiplier = 1.0 + (level - 1) * 0.4; // معامل الزيادة
    return TowerConfig(
      type:         type,
      name:         name,
      description:  description,
      emoji:        emoji,
      cost:         cost,
      damage:       damage * multiplier,
      fireRate:     fireRate * (1.0 + (level - 1) * 0.15),
      range:        range   * (1.0 + (level - 1) * 0.1),
      bulletSpeed:  bulletSpeed,
      color:        color,
      glowColor:    glowColor,
      hasSplash:    hasSplash,
      splashRadius: splashRadius * (hasSplash ? multiplier * 0.5 + 0.5 : 1),
      hasChain:     hasChain,
      chainCount:   chainCount + (level >= 3 ? 1 : 0), // عند Lvl3 يضيف هدف إضافي
      hasSlow:      hasSlow,
      slowDuration: slowDuration,
    );
  }
}

// ══════════════════════════════════════════════════════════
//  إعدادات كل برج — عدّل الأرقام هنا لتغيير قوة الأبراج
// ══════════════════════════════════════════════════════════
class TowerData {
  static const Map<TowerType, TowerConfig> configs = {

    // ── برج القوس ── سريع ومناسب ضد الأعداء العاديين
    TowerType.archer: TowerConfig(
      type:        TowerType.archer,
      name:        'قوس',
      description: 'سريع ودقيق — مثالي للأعداء السريعة',
      emoji:       '🏹',
      cost:        50,     // ← سعر البناء
      damage:      20,     // ← الضرر
      fireRate:    1.8,    // ← 1.8 رصاصة/ثانية
      range:       1.5,    // ← 3.5 خلايا
      bulletSpeed: 280,
      color:     Color(0xFF22C55E),
      glowColor: Color(0xFF4ADE80),
    ),

    // ── برج المدفع ── يضرب مجموعة أعداء دفعة واحدة
    TowerType.cannon: TowerConfig(
      type:         TowerType.cannon,
      name:         'مدفع',
      description:  'ضرر جماعي — يضرب مجموعة أعداء',
      emoji:        '💣',
      cost:         80,
      damage:       60,
      fireRate:     0.8,   // ← بطيء لكن قوي
      range:        2.4,
      bulletSpeed:  200,
      color:     Color(0xFFD97706),
      glowColor: Color(0xFFFBBF24),
      hasSplash:    true,
      splashRadius: 1.3,   // ← نصف قطر الانفجار بالخلايا
    ),

    // ── برج الساحر ── يقفز بين 3 أعداء
    TowerType.mage: TowerConfig(
      type:       TowerType.mage,
      name:       'ساحر',
      description:'يضرب 3 أعداء بتسلسل',
      emoji:      '🔮',
      cost:       120,
      damage:     12,      // ← ضرر منخفض لكنه يصيب عدة أعداء
      fireRate:   3.0,     // ← سريع جداً
      range:      3.0,
      bulletSpeed:320,
      color:     Color(0xFF9333EA),
      glowColor: Color(0xFFC084FC),
      hasChain:   true,
      chainCount: 3,       // ← يصيب 3 أعداء إضافيين
    ),

    // ── برج الجليد ── يبطئ الأعداء
    TowerType.ice: TowerConfig(
      type:         TowerType.ice,
      name:         'جليد',
      description:  'يجمّد الأعداء ويبطئهم',
      emoji:        '❄️',
      cost:         100,
      damage:       8,     // ← ضرر قليل لكن التجميد مفيد جداً
      fireRate:     1.2,
      range:        3.0,
      bulletSpeed:  240,
      color:     Color(0xFF0891B2),
      glowColor: Color(0xFF67E8F9),
      hasSlow:      true,
      slowDuration: 2.5,   // ← يبطئ لمدة 2.5 ثانية
    ),

    // ── برج القناص ── مدى بعيد جداً وضرر عالٍ
    TowerType.sniper: TowerConfig(
      type:        TowerType.sniper,
      name:        'قناص',
      description: 'مدى خرافي وضرر فائق',
      emoji:       '🎯',
      cost:        165,
      damage:      120,    // ← أعلى ضرر لرصاصة واحدة
      fireRate:    0.5,    // ← بطيء جداً
      range:       4.0,    // ← أبعد مدى في اللعبة
      bulletSpeed: 500,    // ← رصاصة سريعة جداً
      color:     Color(0xFF6D28D9),
      glowColor: Color(0xFFA78BFA),
    ),

    // ── برج الهاون ── انفجار ضخم
    TowerType.bomb: TowerConfig(
      type:         TowerType.bomb,
      name:         'هاون',
      description:  'انفجار ضخم جداً',
      emoji:        '💥',
      cost:         140,
      damage:       90,
      fireRate:     0.75,
      range:        3.0,
      bulletSpeed:  200,   // ← قذيفة بطيئة
      color:     Color(0xFFDC2626),
      glowColor: Color(0xFFF97316),
      hasSplash:    true,
      splashRadius: 1.8,   // ← انفجار أكبر من المدفع
    ),
  };
}
