# 📝 مهامي — تطبيق To-Do بـ Flutter مع تحديث عن بعد

تطبيق قائمة مهام عربي (RTL) يمكنك **تحديثه عن بعد** بثلاث طرق:

| الطريقة | ماذا تغيّر؟ | يحتاج تنزيل؟ | السرعة |
|---|---|---|---|
| ⚡ **الإعدادات عن بعد** (`remote/config.json`) | العنوان، الألوان، الوضع الليلي، الإعلانات، الميزات، التصنيفات، النصائح، وضع الصيانة، إرسال مهام | ❌ لا شيء | فوري (خلال دقائق) |
| 🌐 **نسخة الويب** (GitHub Pages) | أي شيء في الكود | ❌ لا شيء | تلقائي بعد كل push |
| 📦 **إصدار APK جديد** | أي شيء في الكود (أندرويد) | ✅ ينزّل داخل التطبيق بضغطة زر | عند الإصدار |

---

## ⚡ 1) التحديث الفوري — بدون أي تنزيل

افتح الملف [`remote/config.json`](remote/config.json) على GitHub ← اضغط ✏️ ← عدّل ← **Commit**.

التطبيق يجلب الإعدادات: عند الفتح، وعند الرجوع إليه، وكل 5 دقائق، وعند سحب الشاشة للأسفل.

> 💡 **زِد `config_version` بواحد** في كل تعديل، فيظهر للمستخدم إشعار "وصل تحديث جديد".

### أمثلة
```jsonc
"theme": { "primary_color": "#E11D48", "dark_mode": true }    // غيّر لون التطبيق كاملاً
"announcement": { "enabled": true, "text": "عرض خاص!", "color": "#10B981", "url": "https://..." }
"maintenance": { "enabled": true, "message": "صيانة لمدة ساعة" }   // اقفل التطبيق مؤقتاً
"features": { "allow_delete": false, "show_stats": false }      // شغّل/أطفئ ميزات
"categories": ["عام", "عمل", "رياضة"]                            // غيّر التصنيفات
"remote_tasks": [{ "id": "task-2", "title": "مهمة من المطوّر" }]  // أرسل مهمة لكل المستخدمين (id جديد كل مرة)
```

## 🌐 2) نسخة الويب — تتحدّث تلقائياً
أي `push` لمجلد `lib/` يبني وينشر التطبيق على:
**https://qbrahym02-cmyk.github.io/todo-ota-app/**
يمكن إضافتها للشاشة الرئيسية في الجوال كتطبيق (PWA).

## 📦 3) إصدار APK جديد (لتغييرات الكود على أندرويد)
1. عدّل الكود وارفعه.
2. GitHub ← **Actions** ← **📦 Release Android APK** ← **Run workflow**.
3. اكتب رقم الإصدار (مثلاً `1.0.1`) وما الجديد، واختر إن كان إجبارياً.
4. عند فتح التطبيق، تظهر للمستخدم نافذة **"إصدار جديد"** ← **تحديث الآن** ← يُنزَّل ويُثبَّت من داخل التطبيق.

> ⚠️ كل الإصدارات موقّعة بنفس المفتاح (محفوظ في Secrets: `ANDROID_KEYSTORE_BASE64` و`ANDROID_KEY_PROPERTIES`). **لا تحذفه** وإلا لن تعمل التحديثات.

---

## 🏗️ بنية المشروع
```
lib/
├── main.dart                       # يعيد بناء الواجهة عند تغيّر الإعدادات عن بعد
├── config.dart                     # روابط المستودع والإعدادات
├── models/task.dart
├── services/
│   ├── remote_config_service.dart  # جلب + كاش + تحديث دوري للإعدادات
│   ├── update_service.dart         # فحص GitHub Releases + تثبيت APK
│   └── task_storage.dart           # حفظ المهام على الجهاز
├── screens/ (home, about)
└── widgets/ (task_tile, task_editor, update_dialog)
remote/config.json                  # ⚡ عدّل هذا للتحديث الفوري
.github/workflows/                  # بناء APK + نشر الويب تلقائياً
```

## ▶️ التشغيل محلياً
```bash
flutter pub get
flutter run            # جوال
flutter run -d chrome  # ويب
```

## 🚀 ترقية اختيارية: Shorebird (Code Push حقيقي)
لو تبي تحديث **كود Dart** على أندرويد/iOS بدون APK جديد: سجّل في [shorebird.dev](https://shorebird.dev)، ثم
`shorebird init` ← `shorebird release android` ← وبعد كل تعديل `shorebird patch android`.
