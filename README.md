# Su Hatırlatıcı

Günlük su içme hatırlatıcısı ve not hatırlatıcı uygulaması (Flutter). Tüm veriler cihazda kalır.

## Özellikler

- **Su takibi**: günlük halka, hızlı ekleme (200 / 330 / 500 ml / özel), kayıt düzenleme, günlük · haftalık · aylık istatistik, önceki hafta/ay gezinme, seri (üst üste hedef), hedef kutlaması.
- **Su hatırlatmaları**: aktif saatler (hafta sonu için ayrı saatler), aralık, 7 gün ileriye kurulur. Az önce içildiyse sıradaki dilim atlanır. Akşam "hedefe kaldı" bildirimi ve pazar akşamı haftalık özet.
- **Üç uyarı tipi**: *Bildirim* (sessiz), *Alarm* (durdurana kadar çalar), *Yükselen* (önce bildirim, yanıt yoksa alarm).
- **Hatırlatıcılar**: not + tarih/saat + tekrar (tek sefer, her gün, hafta içi, her hafta, her ay) + uyarı tipi + önceden haber verme. Bildirime dokununca veya alarm çalınca aynı aksiyon ekranı: "Tamam" ya da ertele.
- **Entegrasyonlar**: Apple Sağlık / Health Connect'e su yazma; iOS 26+ AlarmKit sistem alarmı (uygulama kapalıyken de çalar); ana ekran widget'ı.
- **Yedek**: JSON dışa/içe aktarma.
- **Tema**: açık ("Sakin Su") ve koyu ("Derin Deniz").

## Yapı

```
lib/
  core/        tema (AppColors, AppText), ortak widget'lar, biçimlendirme yardımcıları
  data/        modeller, sqflite şeması, repository'ler
  services/    bildirim, alarm (alarm paketi + AlarmKit), zamanlayıcılar, sağlık, widget, yedek
  providers/   Riverpod state: ayarlar, su, hatırlatıcılar, geçmiş istatistik
  features/    ekranlar: onboarding, home, water_alarm, reminders, settings, shell
```

## Çalıştırma

```bash
flutter pub get
flutter run
```

Testler: `flutter test`

## Xcode'da yapılması gereken iki adım (bir kez)

Bu iki hedef Xcode arayüzünden oluşturulur; kod dosyaları hazır.

1. **AlarmKit Live Activity** (sistem alarmının canlı etkinlik arayüzü)
   - `ios/Runner.xcworkspace` aç → File > New > Target > *Widget Extension*, adı tam olarak `AlarmkitWidget`, yalnızca *Live Activity* işaretli.
   - Runner ve AlarmkitWidgetExtension hedeflerinde Signing & Capabilities > App Groups > `group.flutter-alarmkit` ekle.
   - Xcode'u kapat, `dart run flutter_alarmkit:setup` çalıştır (dosyaları `ios/AlarmkitWidget/` altına yazar), `dart run flutter_alarmkit:setup --doctor` ile doğrula.
2. **Ana ekran widget'ı**
   - File > New > Target > *Widget Extension*, adı `SuWidget`, Live Activity işaretsiz.
   - Xcode'un ürettiği Swift dosyalarını `ios/SuWidget/` içindekilerle değiştir.
   - Runner ve SuWidgetExtension hedeflerinde App Groups > `group.com.furkanbalci.suHatirlatici` ekle.

HealthKit yetkisi `ios/Runner/Runner.entitlements` içinde hazır; otomatik imzalama App ID'ye ekler.

## Platform notları

- **Android**: minSdk 26 (Health Connect), compileSdk 37. `USE_FULL_SCREEN_INTENT`, `SCHEDULE_EXACT_ALARM`, pil optimizasyonu izinleri Ayarlar'dan yönetilir. Widget'taki "+ bardak" düğmesi uygulama açılmadan arka planda kayıt ekler.
- **iOS**: Alarm modunda AlarmKit (iOS 26+) açıksa alarm uygulama kapalıyken de çalar. AlarmKit kapalıysa `alarm` paketi devrededir ve uygulama tamamen kapatılırsa çalmaz; bildirim modu her durumda çalışır.
- Bildirimdeki "Su İçtim" düğmesi uygulamayı öne getirir ve kaydı o anda ekler.
