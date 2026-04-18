# Kingdom Guard — Tower Defense Flutter

## هيكل المشروع

```
lib/
├── main.dart                    ← نقطة البداية
├── data/
│   ├── tower_data.dart          ← إعدادات جميع الأبراج
│   └── enemy_data.dart          ← إعدادات الأعداء والموجات
├── game/
│   └── td_game.dart             ← المحرك الرئيسي (Flame)
├── components/
│   ├── map_component.dart       ← الخريطة (سماء + عشب + أشجار)
│   ├── path_component.dart      ← المسار + علم + قلعة
│   ├── tower_component.dart     ← رسم وتصرف الأبراج
│   ├── enemy_component.dart     ← رسم وتصرف الأعداء
│   ├── bullet_component.dart    ← الرصاصات بأنواعها
│   └── particle_component.dart  ← جزيئات الانفجار
└── ui/
    ├── main_menu.dart            ← شاشة البداية
    └── game_screen.dart          ← واجهة اللعبة (HUD + Shop)
```

## التثبيت

```bash
flutter pub get
flutter run
```

## المتطلبات

- Flutter SDK >= 3.0.0
- Flame ^1.18.0

## الأبراج

| البرج | التكلفة | الميزة |
|-------|---------|--------|
| 🏹 قوس | 50🪙 | سريع ودقيق |
| 💣 مدفع | 100🪙 | ضرر جماعي (splash) |
| 🔮 ساحر | 130🪙 | chain x3 |
| ❄️ جليد | 110🪙 | يجمّد الأعداء |
| 🎯 قناص | 175🪙 | مدى 7 خلايا |
| 💥 هاون | 160🪙 | انفجار واسع |

## الترقية

كل برج يصل لـ Lvl 5:
- ضرر × 1.4 لكل مستوى
- معدل نار × 1.15
- مدى × 1.1

## الموجات

10 موجات بصعوبة متزايدة — من Goblin للـ Dragon King
