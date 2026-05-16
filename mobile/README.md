# AidatPanel Mobile

Apartman ve site yönetiminde en çok zamanı yiyen işlerden biri aidat takibi: kim ödedi, kim gecikti, hangi daire boş? **AidatPanel**, yöneticilere ve sakinlere aynı uygulama içinde net bir tablo sunar — telefonla daire dağıtmak, davet koduyla sakin eklemek, aidat durumunu güncellemek ve pano özetine bakmak tek akışta toplanır.

Bu klasör, Flutter ile yazılmış resmi mobil istemcidir. Mimari **Clean Architecture** (domain → data → presentation), durum yönetimi **Riverpod**, yönlendirme **GoRouter**; ağ katmanı **Dio** ve JWT ile çalışır. Metinler **Slang** ile Türkçe ve İngilizce sunulur.

## Hızlı başlangıç

```bash
cd mobile
flutter pub get
flutter run
```

Sunucu olmadan arayüz denemek için (mock veri, ekranda **DEV** rozeti):

```bash
flutter run -t lib/main_dev.dart
```

## Çeviri ve görevler

Çeviri anahtarları `lib/l10n/` altındaki JSON dosyalarında; üretilen kod `strings.g.dart`. Üst klasördeki VS Code / Cursor görevleri: Slang watch/generate, i18n tarama (`dart run tool/i18n_scan.dart`, `dart run tool/check_translations.dart`). Toplu çeviri için DeepL API anahtarı `tool/.deepl_key` dosyasına konur (dosya `.gitignore`’dadır, repoya girmez). Tek anahtar eklemek: `dart run tool/add_translation.dart <anahtar> "Türkçe" ["English"]`.

## Google Play (release imzası)

1. `android/upload-keystore.jks` dosyan `android/` klasöründe olsun (veya `key.properties` içindeki `storeFile` yolunu ona göre düzenle).
2. `android/key.properties.example` dosyasını `android/key.properties` olarak kopyala; şifreleri ve `storeFile` yolunu doldur. Bu dosya `.gitignore`’dadır.
3. `flutter build appbundle --release` → `build/app/outputs/bundle/release/app-release.aab` dosyasını Play Console’a yükle.

`key.properties` yoksa release derlemesi geçici olarak debug anahtarıyla imzalanır; mağazaya **yalnızca** `key.properties` + keystore ile üretilen AAB gönder.

## Proje belgeleri

API sözleşmesi, fazlar ve mobil–backend eşlemesi repoda `resources/` altında (ör. `AIDATPANEL.md`, `FAZ_DURUMU.md`, `MOBILE-TO-BACKEND.md`). Bu README yalnızca mobil pakete giriş içindir; ayrıntılı kurallar ve checklist orada güncellenir.

---

*AidatPanel — aidat ve site işlerini telefonda toparlayan yardımcınız.*
