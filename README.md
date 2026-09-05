# Su Hatırlatıcı

Günlük su içme hatırlatıcısı ve not hatırlatıcı uygulaması (Flutter).

- **Su takibi**: günlük halka, hızlı ekleme (200 / 330 / 500 ml / özel), günlük · haftalık · aylık istatistik.
- **Su hatırlatmaları**: aktif saatler içinde belirlenen aralıkla. İki mod:
  - *Bildirim*: sessiz sistem bildirimi ("Su İçtim" aksiyon butonu ile).
  - *Alarm*: "Su İçtim" diyene kadar çalar (alarm paketi, Android'de tam ekran).
- **Hatırlatıcılar**: not + tarih/saat + tekrar (tek sefer, her gün, hafta içi, her hafta, her ay) + bildirim/alarm.
- **Tema**: açık ("Sakin Su") ve koyu ("Derin Deniz"), sistemle uyumlu.
- **Veri**: tüm veriler cihazda (sqflite + shared_preferences). Sunucu yok.

## Yapı

```
lib/
  core/        tema (AppColors, AppText), ortak widget'lar, biçimlendirme yardımcıları
  data/        modeller, sqflite şeması, repository'ler
  services/    bildirim (flutter_local_notifications), alarm (alarm), zamanlayıcılar
  providers/   Riverpod state: ayarlar, su, hatırlatıcılar
  features/    ekranlar: home, water_alarm, reminders, settings, shell
```

## Çalıştırma

```bash
flutter pub get
flutter run
```

Testler: `flutter test`

## Platform notları

- **Android**: `USE_FULL_SCREEN_INTENT`, `SCHEDULE_EXACT_ALARM` izinleri manifestte. Android 14+ tam ekran alarm izni kullanıcıdan istenebilir.
- **iOS**: Alarm modu, uygulama arka plandayken sessiz ses oturumuyla ayakta kalır (`UIBackgroundModes: audio, fetch`). Uygulama tamamen kapatılırsa iOS'ta alarm çalmaz; bildirim modu her durumda çalışır.
