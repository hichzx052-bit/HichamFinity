# 🎬 HichamFinity — هشام فينيتي

أداة البث المباشر لتيك توك — أحسن من TikFinity! 🔥

تطبيق عربي للهاتف يراقب بثك المباشر على تيك توك ويعطيك أدوات تفاعلية.

## ✨ المميزات

| الميزة | الوصف |
|--------|-------|
| 🗣️ قراءة الأسماء | يقرأ أسماء اللي يدخلون البث بصوت عالي (TTS) |
| 🎁 تنبيهات الهدايا | إشعار لكل هدية مع اسم المرسل والقيمة |
| 💬 التعليقات | عرض التعليقات بالوقت الفعلي |
| ❤️ عداد اللايكات | متابعة اللايكات لكل مشاهد |
| 🎬 فيديو مخصص | عند عدد لايكات معين يظهر فيديو باسم المشاهد |
| 📊 إحصائيات | بيانات البث كاملة + ترتيب أكثر المتفاعلين |
| ➕ متابعين جدد | إشعار لكل متابع جديد |
| ⚙️ إعدادات كاملة | تحكم بكل شي (صوت، سرعة، أنواع التنبيهات) |

## 📱 التطبيق (Flutter)

### المتطلبات
- Flutter 3.24+
- Android 5.0+

### البناء
```bash
flutter pub get
flutter build apk --release
```

### تحميل APK
حمّل آخر نسخة من [GitHub Actions](../../actions)

## 🖥️ السيرفر (Node.js)

التطبيق يحتاج سيرفر وسيط يتصل بتيك توك:

```bash
cd server
npm install
node server.js
```

### استضافة مجانية
- [Render](https://render.com) — مجاني
- [Railway](https://railway.app) — مجاني
- على جهازك المحلي

## 🏗️ البنية

```
hicham-finity/
├── lib/
│   ├── main.dart              # نقطة البداية
│   ├── screens/               # الشاشات
│   │   ├── home_screen.dart        # الرئيسية
│   │   ├── live_monitor_screen.dart # مراقبة البث
│   │   ├── tts_settings_screen.dart # إعدادات الصوت
│   │   ├── video_triggers_screen.dart # محفزات الفيديو
│   │   ├── alerts_screen.dart      # التنبيهات
│   │   ├── statistics_screen.dart  # الإحصائيات
│   │   └── settings_screen.dart    # الإعدادات
│   ├── services/              # الخدمات
│   │   ├── tiktok_live_service.dart # اتصال تيك توك
│   │   ├── tts_service.dart        # قراءة صوتية
│   │   └── trigger_service.dart    # المحفزات
│   ├── models/                # النماذج
│   ├── widgets/               # الويدجتات
│   └── utils/                 # الأدوات
├── server/                    # سيرفر Node.js
│   ├── server.js
│   └── package.json
└── .github/workflows/         # GitHub Actions
```

## ⚠️ ملاحظات مهمة

1. **TikTok API غير رسمي** — يستخدم مكتبة `tiktok-live-connector` (غير رسمية)
2. **يحتاج سيرفر** — التطبيق لحاله ما يتصل بتيك توك مباشرة
3. **الفيديو المخصص** — تختار فيديو من جهازك ويظهر لما المشاهد يوصل العدد المطلوب

## 👨‍💻 المطور

**Hichamdzz** 🔥

---
صنع بـ ❤️
