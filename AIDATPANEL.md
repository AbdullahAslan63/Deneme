# AidatPanel — Claude Code Master Reference

## 📌 Proje Özeti

**AidatPanel**, Türk apartman ve site yöneticileri için geliştirilmiş bir mobil aidat yönetim platformudur. Yöneticiler birden fazla apartmanı tek hesaptan yönetebilir. Sakinler kendi aidat durumlarını görüntüleyebilir ve arıza/talep bildirimi yapabilir.

- **Domain:** aidatpanel.com (Cloudflare üzerinde)
- **Platform:** iOS + Android (Flutter)
- **Backend:** Node.js, aynı Contabo VPS (OkulOptik ile ortak sunucu)
- **Veritabanı:** PostgreSQL
- **Web:** Sadece tanıtım/landing sayfası (mobil uygulama indirme yönlendirmeli)
- **Dil:** Türkçe + İngilizce (i18n hazır)

---

## 📁 Klasör Yapısı

```
aidatpanel/
├── web/                  # Landing page (statik HTML/CSS/JS)
│   ├── index.html
│   ├── assets/
│   └── ...
├── mobile/               # Flutter uygulaması
│   ├── lib/
│   ├── android/
│   ├── ios/
│   ├── pubspec.yaml
│   └── ...
└── backend/              # Node.js API
    ├── src/
    │   ├── routes/
    │   ├── controllers/
    │   ├── models/
    │   ├── middleware/
    │   ├── services/
    │   └── utils/
    ├── prisma/
    │   └── schema.prisma
    ├── .env.example
    ├── package.json
    └── index.js
```

---

## 🖥️ Backend

### Stack
- **Runtime:** Node.js 20+
- **Framework:** Express.js
- **ORM:** Prisma
- **Veritabanı:** PostgreSQL
- **Auth:** JWT (access token 15dk, refresh token 30 gün)
- **Email:** Resend (noreply@aidatpanel.com)
- **Push Notification:** Firebase Admin SDK (FCM)
- **SMS/WhatsApp:** Twilio (veya Netgsm Türkiye alternatifi)
- **Abonelik Doğrulama:** RevenueCat REST API (App Store + Google Play receipt validation)
- **Deployment:** PM2, aynı Contabo VPS
- **Subdomain:** api.aidatpanel.com (CloudPanel üzerinde reverse proxy)

### Ortam Değişkenleri (.env)

```env
PORT=4200
DATABASE_URL=postgresql://aidatpanel:PASSWORD@localhost:5432/aidatpanel
JWT_SECRET=...
JWT_REFRESH_SECRET=...
RESEND_API_KEY=...
FIREBASE_SERVICE_ACCOUNT_JSON=...
TWILIO_ACCOUNT_SID=...
TWILIO_AUTH_TOKEN=...
TWILIO_WHATSAPP_FROM=whatsapp:+14155238886
TWILIO_SMS_FROM=+1...
REVENUECAT_API_KEY=...
REVENUECAT_WEBHOOK_SECRET=...
```

---

## 🗄️ Veritabanı Şeması (Prisma)

```prisma
model User {
  id            String        @id @default(uuid())
  email         String        @unique
  passwordHash  String
  name          String
  phone         String?
  role          UserRole      @default(RESIDENT)
  fcmToken      String?
  language      String        @default("tr")
  createdAt     DateTime      @default(now())
  updatedAt     DateTime      @updatedAt

  // Yönetici ilişkileri
  managedBuildings  Building[]     @relation("BuildingManager")

  // Sakin ilişkileri
  apartment     Apartment?    @relation(fields: [apartmentId], references: [id])
  apartmentId   String?

  // Ortak
  notifications Notification[]
  tickets       Ticket[]
  subscription  Subscription?
}

enum UserRole {
  MANAGER
  RESIDENT
}

model Subscription {
  id                  String    @id @default(uuid())
  userId              String    @unique
  user                User      @relation(fields: [userId], references: [id])
  status              SubscriptionStatus
  plan                String    // "monthly" | "annual"
  platform            String    // "ios" | "android"
  revenuecatId        String?
  currentPeriodStart  DateTime
  currentPeriodEnd    DateTime
  createdAt           DateTime  @default(now())
  updatedAt           DateTime  @updatedAt
}

enum SubscriptionStatus {
  ACTIVE
  EXPIRED
  CANCELLED
  TRIAL
}

model Building {
  id          String      @id @default(uuid())
  name        String
  address     String
  city        String
  managerId   String
  manager     User        @relation("BuildingManager", fields: [managerId], references: [id])
  apartments  Apartment[]
  expenses    Expense[]
  createdAt   DateTime    @default(now())
  updatedAt   DateTime    @updatedAt
}

model Apartment {
  id           String    @id @default(uuid())
  number       String    // "B-12", "3A" vb.
  floor        Int?
  buildingId   String
  building     Building  @relation(fields: [buildingId], references: [id])
  residents    User[]
  dues         Due[]
  inviteCodes  InviteCode[]
  tickets      Ticket[]
  createdAt    DateTime  @default(now())
}

model InviteCode {
  id          String    @id @default(uuid())
  code        String    @unique  // Örn: "AP3-B12-X7K9"
  apartmentId String
  apartment   Apartment @relation(fields: [apartmentId], references: [id])
  usedAt      DateTime?
  usedBy      String?
  expiresAt   DateTime
  createdAt   DateTime  @default(now())
}

model Due {
  id          String    @id @default(uuid())
  apartmentId String
  apartment   Apartment @relation(fields: [apartmentId], references: [id])
  amount      Decimal   @db.Decimal(10, 2)
  currency    String    @default("TRY")
  month       Int       // 1-12
  year        Int
  status      DueStatus @default(PENDING)
  paidAt      DateTime?
  note        String?
  createdAt   DateTime  @default(now())
  updatedAt   DateTime  @updatedAt
}

enum DueStatus {
  PENDING
  PAID
  OVERDUE
  WAIVED
}

model Expense {
  id          String    @id @default(uuid())
  buildingId  String
  building    Building  @relation(fields: [buildingId], references: [id])
  title       String
  amount      Decimal   @db.Decimal(10, 2)
  category    ExpenseCategory
  date        DateTime
  note        String?
  receiptUrl  String?
  createdAt   DateTime  @default(now())
}

enum ExpenseCategory {
  CLEANING
  ELEVATOR
  ELECTRICITY
  WATER
  INSURANCE
  REPAIR
  GARDEN
  OTHER
}

model Ticket {
  id          String      @id @default(uuid())
  apartmentId String
  apartment   Apartment   @relation(fields: [apartmentId], references: [id])
  userId      String
  user        User        @relation(fields: [userId], references: [id])
  title       String
  description String
  category    TicketCategory
  status      TicketStatus @default(OPEN)
  updates     TicketUpdate[]
  createdAt   DateTime    @default(now())
  updatedAt   DateTime    @updatedAt
}

enum TicketCategory {
  COMPLAINT
  REQUEST
  MALFUNCTION
  OTHER
}

enum TicketStatus {
  OPEN
  IN_PROGRESS
  RESOLVED
  CLOSED
}

model TicketUpdate {
  id        String  @id @default(uuid())
  ticketId  String
  ticket    Ticket  @relation(fields: [ticketId], references: [id])
  message   String
  fromRole  UserRole
  createdAt DateTime @default(now())
}

model Notification {
  id        String    @id @default(uuid())
  userId    String
  user      User      @relation(fields: [userId], references: [id])
  title     String
  body      String
  type      NotificationType
  isRead    Boolean   @default(false)
  data      Json?
  createdAt DateTime  @default(now())
}

enum NotificationType {
  DUE_REMINDER
  DUE_PAID
  TICKET_UPDATE
  ANNOUNCEMENT
  SYSTEM
}
```

---

## 🔌 API Endpoint'leri

### Auth
```
POST   /api/auth/register          # Yönetici kaydı
POST   /api/auth/login             # Giriş
POST   /api/auth/refresh           # Token yenile
POST   /api/auth/logout            # Çıkış
POST   /api/auth/join              # Sakin davet koduyla kaydolur
POST   /api/auth/forgot-password   # Şifre sıfırlama maili
POST   /api/auth/reset-password    # Yeni şifre set
```

### Buildings (Yönetici only)
```
GET    /api/buildings              # Yöneticinin tüm apartmanları
POST   /api/buildings              # Yeni apartman ekle
GET    /api/buildings/:id          # Apartman detayı
PUT    /api/buildings/:id          # Güncelle
DELETE /api/buildings/:id          # Sil
```

### Apartments (Yönetici only)
```
GET    /api/buildings/:id/apartments          # Apartmandaki daireler
POST   /api/buildings/:id/apartments          # Daire ekle
PUT    /api/buildings/:buildingId/apartments/:id
DELETE /api/buildings/:buildingId/apartments/:id
POST   /api/apartments/:id/invite-code        # Davet kodu üret
```

### Dues (Aidat)
```
GET    /api/buildings/:id/dues               # Tüm aidat listesi (Yönetici)
POST   /api/buildings/:id/dues/bulk          # Toplu aidat oluştur (Yönetici)
PATCH  /api/dues/:id/status                  # Ödendi/ödenmedi işaretle (Yönetici)
GET    /api/me/dues                          # Kendi aidat geçmişim (Sakin)
```

### Expenses (Gider)
```
GET    /api/buildings/:id/expenses           # Gider listesi (Yönetici)
POST   /api/buildings/:id/expenses           # Gider ekle (Yönetici)
PUT    /api/expenses/:id                     # Güncelle (Yönetici)
DELETE /api/expenses/:id                     # Sil (Yönetici)
GET    /api/buildings/:id/expenses/summary   # Aylık özet (Yönetici)
```

### Tickets (Arıza/Talep)
```
GET    /api/buildings/:id/tickets            # Tüm talepler (Yönetici)
GET    /api/tickets/:id                      # Talep detayı
POST   /api/apartments/:id/tickets           # Yeni talep (Sakin)
POST   /api/tickets/:id/updates             # Güncelleme ekle (Yönetici)
PATCH  /api/tickets/:id/status              # Durum değiştir (Yönetici)
GET    /api/me/tickets                       # Kendi taleplerim (Sakin)
```

### Notifications
```
GET    /api/notifications                    # Bildirimlerim
PATCH  /api/notifications/:id/read           # Okundu işaretle
PATCH  /api/notifications/read-all           # Tümünü oku
PUT    /api/me/fcm-token                     # FCM token güncelle
```

### Reports (Yönetici only)
```
GET    /api/buildings/:id/reports/monthly    # Aylık rapor (PDF)
GET    /api/buildings/:id/reports/summary    # Özet istatistik
```

### Subscription
```
POST   /api/subscription/webhook/revenuecat  # RevenueCat webhook (ödeme olayları)
GET    /api/me/subscription                  # Abonelik durumum
```

### Profile
```
GET    /api/me                               # Profil bilgisi
PUT    /api/me                               # Güncelle
PUT    /api/me/password                      # Şifre değiştir
PUT    /api/me/language                      # Dil değiştir
```

---

## 📱 Flutter Uygulaması

### pubspec.yaml — Temel Paketler

```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # State Management
  flutter_riverpod: ^2.5.0
  riverpod_annotation: ^2.3.0
  
  # Navigation
  go_router: ^13.0.0
  
  # Network
  dio: ^5.4.0
  flutter_secure_storage: ^9.0.0
  
  # i18n
  flutter_localizations:
    sdk: flutter
  intl: ^0.19.0
  
  # Firebase
  firebase_core: ^3.0.0
  firebase_messaging: ^15.0.0
  
  # In-App Purchase (RevenueCat)
  purchases_flutter: ^7.0.0
  
  # UI
  cached_network_image: ^3.3.0
  shimmer: ^3.0.0
  
  # Utils
  equatable: ^2.0.5
  json_annotation: ^4.8.1
  freezed_annotation: ^2.4.0

dev_dependencies:
  build_runner: ^2.4.0
  riverpod_generator: ^2.3.0
  freezed: ^2.4.0
  json_serializable: ^6.7.0
```

### Flutter Klasör Yapısı

```
mobile/lib/
├── main.dart
├── firebase_options.dart
├── core/
│   ├── constants/
│   │   ├── api_constants.dart      # Base URL, endpoint'ler
│   │   └── app_constants.dart
│   ├── theme/
│   │   ├── app_theme.dart
│   │   ├── app_colors.dart
│   │   └── app_typography.dart
│   ├── router/
│   │   └── app_router.dart         # GoRouter tanımları
│   ├── network/
│   │   ├── dio_client.dart         # Interceptor'lar, token refresh
│   │   └── api_exception.dart
│   ├── storage/
│   │   └── secure_storage.dart     # JWT token saklama
│   └── utils/
│       ├── date_utils.dart
│       └── currency_utils.dart
├── l10n/
│   ├── app_tr.arb                  # Türkçe metinler
│   └── app_en.arb                  # İngilizce metinler
├── features/
│   ├── auth/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   │       ├── login_screen.dart
│   │       ├── register_screen.dart
│   │       └── join_screen.dart    # Sakin davet kodu girişi
│   ├── dashboard/
│   │   └── presentation/
│   │       ├── manager_dashboard.dart
│   │       └── resident_dashboard.dart
│   ├── buildings/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   ├── apartments/
│   ├── dues/
│   ├── expenses/
│   ├── tickets/
│   ├── notifications/
│   ├── reports/
│   └── subscription/
│       └── presentation/
│           └── paywall_screen.dart  # RevenueCat paywall
└── shared/
    ├── widgets/
    │   ├── loading_widget.dart
    │   ├── error_widget.dart
    │   └── empty_state_widget.dart
    └── models/
```

---

## 👥 Kullanıcı Rolleri ve Yetkiler

### MANAGER (Yönetici)

**Abonelik aktifken:**
- Birden fazla apartman oluşturma ve yönetme
- Daire ekleme/düzenleme/silme
- Her daire için davet kodu üretme (tek kullanımlık, 7 gün geçerli)
- Aylık aidat oluşturma (toplu — tüm dairelere otomatik)
- Aidat ödendi/ödenmedi işaretleme
- Gider kaydı (kategorili)
- Aylık PDF rapor alma
- Arıza/talep takibi ve güncelleme
- FCM push bildirimi gönderme (tüm sakinlere duyuru)

**Abonelik dolduğunda (kilitlenen özellikler):**
- Yeni apartman/daire ekleme
- Yeni aidat oluşturma
- PDF rapor alma
- Toplu bildirim gönderme

*(Mevcut veriler okunabilir, sakinler etkilenmez)*

### RESIDENT (Sakin)

**Her zaman erişebilir (abonelikten bağımsız):**
- Kendi aylık aidat durumu (PENDING/PAID/OVERDUE)
- Aidat geçmişi (tüm aylar)
- Arıza/talep oluşturma ve takip etme
- Bildirimlerini görme
- Uygulama dilini değiştirme

---

## 🔑 Sakin Onboarding Akışı

```
1. Yönetici → Daire detayından "Davet Kodu Üret" butonuna basar
2. Backend → Benzersiz 12 karakterlik kod üretir (Örn: "APB3-K7X9-M2")
   - Koda daire ID'si bağlıdır
   - 7 gün geçerlilik süresi
   - Tek kullanımlık (kullanıldıktan sonra geçersiz)
3. Yönetici kodu sakine iletir (WhatsApp/kağıt/sözlü)
4. Sakin uygulamayı indirir → "Davet Koduyla Katıl" ekranını seçer
5. Kodu girer → Backend kodu doğrular, hangi daire/bina olduğunu döner
6. Sakin adını, emailini ve şifresini belirler → Kayıt tamamlanır
7. Kullanıcı direkt olarak sakin dashboard'una yönlendirilir
```

---

## 🔔 Bildirim Sistemi

### Firebase FCM (Push Notification)

Kullanım senaryoları:
- Aylık aidat hatırlatıcısı (yönetici tetikler veya otomatik)
- Arıza talebi güncellemesi (yönetici not eklediğinde)
- Duyurular (yöneticiden tüm sakine)

```javascript
// FCM gönderme servisi (backend)
// services/notification.service.js
const sendPushNotification = async (fcmToken, title, body, data = {}) => {
  const message = {
    token: fcmToken,
    notification: { title, body },
    data,
    android: { priority: 'high' },
    apns: { payload: { aps: { sound: 'default' } } }
  };
  await admin.messaging().send(message);
};
```

### WhatsApp (Twilio)

Kullanım senaryoları:
- Aidat hatırlatma mesajı (yönetici "Hatırlat" butonuna bastığında)
- Sakin telefon numarası varsa gönderilir

```javascript
// Örnek WhatsApp mesaj şablonu
const message = `Sayın ${residentName}, ${buildingName} apartmanı ${month}/${year} dönemi aidatınız (${amount}₺) henüz ödenmemiştir. Detaylar için AidatPanel uygulamasını açınız.`;
```

### SMS (Twilio — fallback)

WhatsApp mesajı iletilemezse SMS olarak düşer.

---

## 💳 Abonelik Sistemi (RevenueCat)

### Neden RevenueCat?
- App Store (iOS) ve Google Play (Android) aboneliklerini tek API'dan yönetir
- Receipt validation backend'i üstlenir
- Webhook ile anlık abonelik olayları alınır

### Abonelik Planları (App Store Connect + Play Console'da tanımlanacak)

| Plan | ID | Fiyat (önerilen) |
|------|-------|---------|
| Aylık | `aidatpanel_monthly` | ₺99/ay |
| Yıllık | `aidatpanel_annual` | ₺799/yıl |

### Webhook Olayları (RevenueCat → Backend)

```javascript
// POST /api/subscription/webhook/revenuecat
const events = {
  'INITIAL_PURCHASE': () => activateSubscription(),
  'RENEWAL': () => extendSubscription(),
  'CANCELLATION': () => markCancelled(),
  'EXPIRATION': () => expireSubscription(),
  'BILLING_ISSUE': () => notifyBillingIssue(),
};
```

### Flutter'da RevenueCat Entegrasyonu

```dart
// main.dart içinde
await Purchases.setLogLevel(LogLevel.debug);
PurchasesConfiguration configuration;
if (Platform.isAndroid) {
  configuration = PurchasesConfiguration(androidApiKey);
} else {
  configuration = PurchasesConfiguration(iosApiKey);
}
await Purchases.configure(configuration);
```

---

## 🌐 Web (Landing Page)

**Amaç:** Sadece tanıtım. Uygulama indirmeye yönlendirme.

**İçerik:**
- Hero: Uygulama adı, tagline, App Store + Google Play butonları
- Özellikler bölümü (3-4 madde)
- Ekran görüntüleri (mockup)
- Fiyatlandırma (aylık/yıllık)
- SSS
- İletişim / Destek emaili
- Gizlilik politikası ve KVKK metni (yasal zorunluluk)

**Teknoloji:** Saf HTML + CSS + minimal JS (framework yok)

**Deployment:** CloudPanel üzerinden aidatpanel.com domain'ine bağlı statik site

---

## 🚀 Deployment

### Backend (VPS)

```bash
# PM2 ecosystem dosyası
# backend/ecosystem.config.js
module.exports = {
  apps: [{
    name: 'aidatpanel-api',
    script: 'index.js',
    env: {
      NODE_ENV: 'production',
      PORT: 4200
    }
  }]
};
```

### Subdomain Yapısı

| Subdomain | Hedef |
|-----------|-------|
| `aidatpanel.com` | Web landing page |
| `api.aidatpanel.com` | Node.js backend (port 4200) |

### Veritabanı

```bash
# PostgreSQL kullanıcı ve veritabanı oluşturma
createuser aidatpanel --pwprompt
createdb aidatpanel --owner=aidatpanel

# Prisma migration
npx prisma migrate deploy
```

---

## 🏗️ MVP Geliştirme Önceliği

### Faz 1 — Çekirdek (MVP)
- [ ] Auth (register, login, JWT, davet kodu ile katılım)
- [ ] Bina ve daire CRUD
- [ ] Davet kodu sistemi
- [ ] Aylık aidat oluşturma (toplu) ve durum güncelleme
- [ ] Sakin: kendi aidat durumunu görme
- [ ] FCM push notification altyapısı
- [ ] RevenueCat abonelik entegrasyonu (iOS + Android)
- [ ] Landing page (web)

### Faz 2 — Tamamlama
- [ ] Gider kaydı ve kategorileme
- [ ] Arıza/talep sistemi (Ticket)
- [ ] Yönetici → Sakin bildirim gönderme
- [ ] WhatsApp aidat hatırlatma
- [ ] PDF rapor (aylık özet)
- [ ] i18n (TR/EN)

### Faz 3 — Büyüme
- [ ] Online ödeme entegrasyonu (İyzico/PayTR)
- [ ] Çoklu yönetici (personel atama)
- [ ] Aidat geçmişi grafiği / istatistik dashboard
- [ ] Belge paylaşımı (yönetim kararları, toplantı tutanakları)

---

## ⚙️ Teknik Kararlar ve Gerekçeleri

| Karar | Seçim | Gerekçe |
|-------|-------|---------|
| State management | Riverpod | OkulOptik'te zaten biliniyor |
| Navigation | GoRouter | Flutter best practice, deep link desteği |
| ORM | Prisma | Type-safe, migration yönetimi kolay |
| Abonelik | RevenueCat | iOS + Android tek entegrasyon |
| Push | Firebase FCM | Cross-platform standart |
| WhatsApp | Twilio | Sandbox ile hızlı test, Türkiye desteği var |
| i18n | Flutter ARB | Flutter native çözüm |

---

## 🎨 Tasarım Sistemi

### Hedef Kitle ve Tasarım Felsefesi

AidatPanel kullanıcılarının önemli bir kısmı **50+ yaş** grubundadır (apartman yöneticileri çoğunlukla emekli veya orta-üst yaş erkekler, sakinlerin büyük kısmı da bu yaş grubundadır). Tasarımın her kararı bu gerçeği gözetmelidir.

**Temel ilke:** Sade, güvenilir, net. Şova gerek yok — işlevsellik ön planda.

---

### Renk Paleti

```dart
// core/theme/app_colors.dart

class AppColors {
  // Ana renkler
  static const primary       = Color(0xFF1B3A6B); // Koyu lacivert — güven, resmiyet
  static const primaryLight  = Color(0xFF2D5FA8); // Hover/pressed state
  static const accent        = Color(0xFFF59E0B); // Amber — aksiyon butonları, vurgu

  // Durum renkleri
  static const success       = Color(0xFF16A34A); // Ödendi, tamamlandı
  static const error         = Color(0xFFDC2626); // Gecikmiş aidat, hata
  static const warning       = Color(0xFFF59E0B); // Beklemede, uyarı
  static const info          = Color(0xFF2563EB); // Bilgi mesajları

  // Nötr renkler
  static const background    = Color(0xFFF8FAFC); // Ana arka plan (saf beyaz değil)
  static const surface       = Color(0xFFFFFFFF); // Kart, modal yüzeyi
  static const border        = Color(0xFFE2E8F0); // Ayırıcı çizgiler
  static const textPrimary   = Color(0xFF0F172A); // Ana metin
  static const textSecondary = Color(0xFF475569); // İkincil metin
  static const textDisabled  = Color(0xFF94A3B8); // Devre dışı metin

  // Durum badge arka planları (açık ton)
  static const successBg     = Color(0xFFDCFCE7);
  static const errorBg       = Color(0xFFFEE2E2);
  static const warningBg     = Color(0xFFFEF3C7);
}
```

---

### Tipografi

```dart
// core/theme/app_typography.dart
// Kullanılan font: "Nunito" (Google Fonts)
// Seçim gerekçesi: Yuvarlak hatları sayesinde sıcak ve okunabilir,
// yaşlı kullanıcılar için Inter/Roboto'dan daha az yorucu.

class AppTypography {
  static const fontFamily = 'Nunito';

  // Başlıklar
  static const h1 = TextStyle(fontSize: 28, fontWeight: FontWeight.w700, height: 1.3);
  static const h2 = TextStyle(fontSize: 22, fontWeight: FontWeight.w700, height: 1.3);
  static const h3 = TextStyle(fontSize: 18, fontWeight: FontWeight.w600, height: 1.4);

  // Gövde metni — MİNİMUM 16sp, asla altına inme
  static const body1 = TextStyle(fontSize: 16, fontWeight: FontWeight.w400, height: 1.6);
  static const body2 = TextStyle(fontSize: 16, fontWeight: FontWeight.w600, height: 1.6);

  // Etiket ve küçük metinler — 14sp alt sınır
  static const label = TextStyle(fontSize: 14, fontWeight: FontWeight.w600, height: 1.4);
  static const caption = TextStyle(fontSize: 14, fontWeight: FontWeight.w400, height: 1.4);

  // Buton metni
  static const button = TextStyle(fontSize: 17, fontWeight: FontWeight.w700, letterSpacing: 0.2);
}
```

**Kritik kural:** `textScaleFactor` hiçbir yerde kısıtlanmamalı. Kullanıcı sistem fontunu büyüttüyse uygulama buna saygı göstermeli.

---

### Dokunma Alanları ve Boyutlar

```dart
// Minimum dokunma alanı: 48x48dp (Google Material standardı)
// Yaşlı kullanıcılar için ideal: 56x56dp+

class AppSizes {
  // Buton yükseklikleri
  static const buttonHeightPrimary   = 56.0; // Ana aksiyon butonu
  static const buttonHeightSecondary = 48.0; // İkincil buton

  // İkon + dokunma alanı
  static const iconTouchTarget = 48.0; // İkon etrafında minimum alan
  static const iconSize        = 24.0; // İkon boyutu

  // Boşluklar
  static const spacingXS  = 4.0;
  static const spacingS   = 8.0;
  static const spacingM   = 16.0;
  static const spacingL   = 24.0;
  static const spacingXL  = 32.0;
  static const spacingXXL = 48.0;

  // Kart ve köşe
  static const cardRadius   = 12.0;
  static const buttonRadius = 10.0;
  static const inputRadius  = 10.0;

  // Liste öğesi yüksekliği (kolay tıklanabilir)
  static const listItemHeight = 72.0;
}
```

---

### Buton Stilleri

```dart
// Birincil buton — tam genişlik, belirgin
ElevatedButton(
  style: ElevatedButton.styleFrom(
    backgroundColor: AppColors.primary,
    foregroundColor: Colors.white,
    minimumSize: const Size(double.infinity, 56),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    textStyle: AppTypography.button,
    elevation: 0,
  ),
)

// Aksiyon butonu (Ödendi işaretle, Davet kodu üret vb.)
ElevatedButton(
  style: ElevatedButton.styleFrom(
    backgroundColor: AppColors.accent,
    foregroundColor: Colors.white,
    minimumSize: const Size(double.infinity, 56),
    ...
  ),
)
```

---

### Navigasyon

**Her zaman BottomNavigationBar kullan — hamburger menü yasak.**

```dart
// Yönetici tab'ları
// 1. Ana Sayfa (Apartments overview)
// 2. Aidat
// 3. Giderler
// 4. Bildirimler
// 5. Profil

// Sakin tab'ları
// 1. Aidatlarım
// 2. Taleplerim
// 3. Bildirimler
// 4. Profil

// Her tab: ikon + yazı birlikte gösterilmeli, sadece ikon yok
BottomNavigationBarItem(
  icon: Icon(Icons.home_outlined),
  activeIcon: Icon(Icons.home),
  label: 'Ana Sayfa', // Yazı her zaman görünür
)
```

---

### Dil Kuralları (UI Metinleri)

```
✅ DOĞRU                         ❌ YANLIŞ
"Aidat Ekle"                     "Add Due"
"Ödendi İşaretle"                "Mark as Paid"
"Geri Dön"                       "Navigate Back"
"Telefon numarası hatalı"        "Error 422: Validation failed"
"Bu işlemi geri alamazsınız"     "This action is irreversible"
"Emin misiniz?"                  "Confirm action?"
"Yükleniyor..."                  "Loading..."  ← bu kabul edilebilir
```

**Kural:** Dashboard, sync, toggle, payload, cache gibi teknik terimler UI'da asla görünmemeli.

---

### Geri Dönülemez İşlemler — Onay Dialog'u

Her silme, ödendi işaretleme ve toplu işlem için zorunlu:

```dart
showDialog(
  context: context,
  builder: (_) => AlertDialog(
    title: const Text('Emin misiniz?', style: AppTypography.h3),
    content: const Text(
      'Bu daireyi silmek istediğinizden emin misiniz? Bu işlem geri alınamaz.',
      style: AppTypography.body1,
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('İptal', style: TextStyle(fontSize: 16)),
      ),
      ElevatedButton(
        onPressed: () { /* işlemi yap */ },
        style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
        child: const Text('Sil', style: TextStyle(fontSize: 16)),
      ),
    ],
  ),
);
```

---

### Durum Göstergeleri (Aidat Durumu)

```dart
// Aidat durumu badge'leri — renk + yazı birlikte, sadece renk yok
Widget _buildStatusBadge(DueStatus status) {
  final config = {
    DueStatus.paid:    ('Ödendi',    AppColors.success,   AppColors.successBg),
    DueStatus.pending: ('Bekliyor',  AppColors.warning,   AppColors.warningBg),
    DueStatus.overdue: ('Gecikmiş',  AppColors.error,     AppColors.errorBg),
    DueStatus.waived:  ('Muaf',      AppColors.textSecondary, AppColors.border),
  }[status]!;

  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: config.$3,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(config.$1,
      style: AppTypography.label.copyWith(color: config.$2)),
  );
}
```

---

### Animasyon Kuralları

```dart
// Geçiş süresi: hızlı ve sade
const Duration kAnimDuration = Duration(milliseconds: 200);
const Curve kAnimCurve = Curves.easeInOut;

// PageTransition: slide — sola/sağa, yukarı/aşağı yok
// Loading state: CircularProgressIndicator (primary renkte)
// Skeleton loading: shimmer paketi ile (kart placeholder)

// YASAK:
// - Lottie animasyonları (gereksiz karmaşıklık)
// - Hero animasyonları (göz yanıltıcı)
// - Bounce/elastic eğriler
// - 300ms+ süren geçişler
```

---

### Erişilebilirlik Kontrol Listesi

Her ekran tamamlanmadan önce şunlar kontrol edilmeli:

- [ ] Tüm metinler minimum 16sp
- [ ] Kontrast oranı 4.5:1+ (WCAG AA) — koyu arka plan üzerine açık metin veya tersi
- [ ] Tüm butonlar minimum 48dp yükseklik
- [ ] Her buton/ikonun `Semantics` label'ı var
- [ ] `textScaleFactor` hiçbir yerde kısıtlanmıyor
- [ ] Hata mesajları Türkçe ve anlaşılır
- [ ] Geri dönülemez işlemler onay dialog'u içeriyor
- [ ] Her tab'da ikon + yazı birlikte görünüyor

---

## 📝 Geliştirici Notları

- OkulOptik ile **aynı PostgreSQL instance** kullanılabilir ama **ayrı veritabanı** (`aidatpanel` adıyla) oluşturulmalı
- Port çakışması olmaması için OkulOptik portunu kontrol et, 4200 müsait değilse 4201 kullan
- Tüm API route'ları `/api/v1/` prefix'i ile başlamalı (ileride versiyonlama için)
- KVKK uyumu için kullanıcı verisi silme endpoint'i (`DELETE /api/me`) faz 1'de yazılmalı
- Apple App Store'da "Kids Category" seçilmemeli, subscription için "Finance" kategorisi uygundur
