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
├── mobile/               # Flutter (production: main.dart, dev: main_dev.dart)
│   ├── lib/              # ~92 dart; features: auth, buildings, dues, …
│   ├── android/, ios/
│   ├── tool/             # i18n_scan, çeviri yardımcıları
│   └── pubspec.yaml
└── backend/              # Node.js API (ESM, Express 5)
    ├── index.js            # Giriş noktası, /api/v1 mount
    ├── package.json
    ├── prisma.config.ts
    ├── prisma/
    │   ├── schema.prisma
    │   └── migrations/     # init, deleted_at+password_reset, dekont_system
    ├── src/
    │   ├── config/db.js    # Prisma 7 + @prisma/adapter-pg
    │   ├── routes/
    │   ├── controllers/
    │   ├── services/
    │   ├── middlewares/    # auth, validate (Zod), rateLimit, errorHandler, role
    │   ├── utils/
    │   └── validators/     # authValidator (legacy; asıl doğrulama validate.js)
    ├── test.py             # API smoke / E2E (yerel veya Docker)
    ├── .env.example
    └── nodemon.json
```

---

## 🖥️ Backend

### Stack (kodda mevcut)

| Katman     | Seçim              | Not                                                            |
| ---------- | ------------------ | -------------------------------------------------------------- |
| Runtime    | Node.js 20+        | `"type": "module"` (ESM)                                       |
| Framework  | **Express 5**      | `helmet`, `cors`, `trust proxy`                                |
| ORM        | **Prisma 7**       | `@prisma/adapter-pg` + `pg` pool                               |
| Doğrulama  | **Zod**            | `src/middlewares/validate.js`                                  |
| Veritabanı | PostgreSQL         | 3 migration uygulandı                                          |
| Auth       | JWT                | Access 15dk, refresh 30g, payload `rv` = `refreshTokenVersion` |
| Rate limit | express-rate-limit | Genel 100/15dk; auth 5 (prod) / 50 (dev)                       |
| Email      | Resend (fetch)     | Paket yok; `RESEND_API_KEY` opsiyonel                          |
| Test       | `test.py`          | Faz 1 + Faz 2A: gider, talep, bildirim, duyuru, yetki          |
| Push       | **Firebase Admin** | `config/firebase.js`, `pushService.js`; production’da zorunlu  |

### Stack (henüz kodda yok — plan)

- **Push (mobil):** Flutter `Firebase.initializeApp` + token upload akışı ⬜ (`PLAN.md` B0–B1)
- **SMS/WhatsApp:** Twilio
- **Abonelik:** RevenueCat webhook
- **Deployment:** PM2 + `ecosystem.config.js` (repoda yok)
- **Subdomain:** api.aidatpanel.com

### Backend durum özeti (2026-05)

**Uygulanan route dosyaları (`/api/v1`):** `authRoutes`, `buildingRoutes` (dues, expenses, tickets, announcements), `apartmentRoutes`, `inviteCodeRoutes`, `meRoutes` (`GET /tickets`), `notificationRoutes`, `ticketRoutes`, `apartmentTicketRoutes`, `expenseRoutes`.

**Faz 2A servisleri:** `notificationService` (`createForUsers` + liste/okundu), `ticketService`, `expenseService`, `announcementService`, `pushService`.

**Şema var, API yok:** `Subscription`, `Dekont`, `DuePayment` (dekont migration; OCR/upload route yok).

**Planda olmayan / genişletilmiş özellikler:**

- Giriş: `identifier` ile **e-posta veya telefon** (`login`)
- Oturum iptali: `User.refreshTokenVersion` + refresh JWT içinde `rv` (logout / şifre değişince artar)
- **KVKK:** `DELETE /api/v1/me` — soft delete, PII maskeleme; yöneticide aktif bina varsa 409
- Şifre sıfırlama: 6 karakterlik kod (SHA-256 hash DB’de), Resend opsiyonel; geliştirmede `AIDATPANEL_E2E_RESET_LOG`
- Bina oluşturma: `totalFloors` × `apartmentsPerFloor` ile daireler (`1A`, `1B`…); `dueAmount` varsa **İstanbul takvimine göre** bulunulan aydan yıl sonuna aidat kayıtları
- Aidat: `dueDate`, `overdueDays`; `PATCH .../due-amount` + `affectCurrent`
- Daire: **tek sakin** (`User.apartmentId` @unique); `DELETE .../apartments/:id/resident`
- Bina: tahsilat alanları (`collectionIban`, `collectionAccountTitle`, …) — dekont Faz 2 için şema hazır
- Güvenlik: Helmet, CORS (`ALLOWED_ORIGINS`), global hata yakalayıcı, Zod mesajları Türkçe

### Ortam Değişkenleri (.env)

```env
PORT=4200
DATABASE_URL=postgresql://aidatpanel:PASSWORD@localhost:5432/aidatpanel
JWT_SECRET=...
REFRESH_TOKEN_SECRET=...          # .env.example adı (eski dokümanda JWT_REFRESH_SECRET)
JWT_EXPIRES_IN=15m
REFRESH_TOKEN_EXPIRES_IN=30d
ALLOWED_ORIGINS=http://localhost:3000,...
RESEND_API_KEY=...                # opsiyonel
RESEND_FROM_EMAIL=...
PASSWORD_RESET_EXPIRES_MINUTES=60
AUTH_RATE_LIMIT_MAX=...           # dev/test için
# FIREBASE_SERVICE_ACCOUNT_JSON=...
# TWILIO_*, REVENUECAT_* — henüz kullanılmıyor
```

---

## 🗄️ Veritabanı Şeması (Prisma)

> **Kaynak:** `backend/prisma/schema.prisma` — aşağıdaki blok orijinal plan özetidir; güncel şema farkları için **Şema farkları** bölümüne bakın.

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
  // + DEKONT_RECEIVED, DEKONT_MATCHED, DEKONT_PAYMENT_APPLIED, DEKONT_NEEDS_REVIEW (migration)
}
```

### Şema farkları (plan → `schema.prisma`)

| Alan / model                                                                                            | Durum                                                |
| ------------------------------------------------------------------------------------------------------- | ---------------------------------------------------- |
| `User.refreshTokenVersion`, `User.deletedAt`                                                            | ✅ Oturum iptali + KVKK                              |
| `User.phone`                                                                                            | ✅ `@unique`                                         |
| `User` ↔ `Apartment`                                                                                    | ✅ **One-to-one** sakin (planda `residents[]` çoklu) |
| `PasswordResetToken`                                                                                    | ✅ 6 haneli kod hash                                 |
| `Building.totalFloors`, `apartmentsPerFloor`, `dueAmount`, `dueDay`, `currency`                         | ✅ Bina + otomatik aidat                             |
| `Building.collectionIban`, `collectionAccountTitle`, `paymentReferenceTemplate`, `collectionVerifiedAt` | ✅ Dekont doğrulama (API yok)                        |
| `Due.dueDate`, `Due.overdueDays`                                                                        | ✅ Gecikme hesabı                                    |
| `Dekont`, `DuePayment`, `DekontStatus`, `DekontSource`                                                  | ✅ Migration; **route yok**                          |
| `Expense`, `Ticket`, `TicketUpdate`, `Notification`                                                     | ✅ Tablo + **REST API (Faz 2A)**                     |
| `Subscription`                                                                                            | ✅ Tablo; **route yok**                              |

---

## 🔌 API Endpoint'leri

Tüm canlı route'lar **`/api/v1`** prefix'i ile mount edilir (`backend/index.js`).

Durum: ✅ uygulandı · ⬜ şema/plan var, kod yok · 🔶 kısmen (şema veya token saklama)

### Auth — ✅

| Method | Path                           | Not                                   |
| ------ | ------------------------------ | ------------------------------------- |
| POST   | `/api/v1/auth/register`        | Yönetici; `role: MANAGER`             |
| POST   | `/api/v1/auth/login`           | `identifier` = email **veya** telefon |
| POST   | `/api/v1/auth/refresh`         | Body: `refreshToken`                  |
| POST   | `/api/v1/auth/logout`          | Bearer; `refreshTokenVersion++`       |
| POST   | `/api/v1/auth/join`            | Davet kodu + sakin kaydı              |
| POST   | `/api/v1/auth/forgot-password` | Resend opsiyonel                      |
| POST   | `/api/v1/auth/reset-password`  | 6 karakter kod + yeni şifre           |

### Buildings (MANAGER) — ✅

| Method | Path                                       | Not                                                |
| ------ | ------------------------------------------ | -------------------------------------------------- |
| GET    | `/api/v1/buildings`                        | Liste                                              |
| POST   | `/api/v1/buildings`                        | Daire + yıl sonuna aidat (opsiyonel `dueAmount`)   |
| GET    | `/api/v1/buildings/:id`                    | Detay                                              |
| PUT    | `/api/v1/buildings/:id`                    | Güncelle                                           |
| DELETE | `/api/v1/buildings/:id`                    | Sil                                                |
| GET    | `/api/v1/buildings/:id/dues`               | Query: `month`, `year`, `status`                   |
| PATCH  | `/api/v1/buildings/:id/due-amount`         | `dueAmount`, `dueDay`, `currency`, `affectCurrent` |
| PATCH  | `/api/v1/buildings/:id/dues/:dueId/status` | `status`, `paidAt`, `note`                         |
| GET    | `/api/v1/buildings/:id/expenses`           | Query: `month`, `year`, `category`               |
| GET    | `/api/v1/buildings/:id/expenses/summary`   | Query: `month`, `year` (**zorunlu**)             |
| POST   | `/api/v1/buildings/:id/expenses`           | Gider kaydı                                      |
| GET    | `/api/v1/buildings/:id/tickets`             | Query: `status`, `category`                        |
| POST   | `/api/v1/buildings/:id/announcements`      | `title`, `body` → tüm aktif sakinlere            |

### Expenses (MANAGER) — ✅

| Method | Path | Not |
| ------ | ---- | --- |
| GET | `/api/v1/buildings/:buildingId/expenses` | Liste (`date` desc) |
| GET | `/api/v1/buildings/:buildingId/expenses/summary` | Kategori toplamları + `totalAmount` |
| POST | `/api/v1/buildings/:buildingId/expenses` | `title`, `amount`, `category`, `date`, `note?`, `receiptUrl?` |
| PUT | `/api/v1/expenses/:expenseId` | Kısmi güncelleme; bina sahibi |
| DELETE | `/api/v1/expenses/:expenseId` | Kalıcı silme |

### Tickets — ✅

| Method | Path | Rol |
| ------ | ---- | --- |
| GET | `/api/v1/buildings/:buildingId/tickets` | MANAGER |
| GET | `/api/v1/me/tickets` | RESIDENT |
| GET | `/api/v1/tickets/:ticketId` | MANAGER veya talep sahibi |
| POST | `/api/v1/apartments/:apartmentId/tickets` | RESIDENT (kendi dairesi) |
| POST | `/api/v1/tickets/:ticketId/updates` | MANAGER |
| PATCH | `/api/v1/tickets/:ticketId/status` | MANAGER |

### Notifications — ✅

| Method | Path | Rol |
| ------ | ---- | --- |
| GET | `/api/v1/notifications` | MANAGER, RESIDENT — `?unreadOnly&limit&cursor` |
| PATCH | `/api/v1/notifications/:id/read` | Alıcı |
| PATCH | `/api/v1/notifications/read-all` | Alıcı |

Otomatik: `TICKET_UPDATE` (talep notu / durum), `ANNOUNCEMENT` (yönetici duyuru). E2E seed: `POST /notifications/_e2e/seed` yalnızca `AIDATPANEL_E2E=1`.

### Apartments (MANAGER) — ✅

| Method | Path                                                    | Not                                |
| ------ | ------------------------------------------------------- | ---------------------------------- |
| GET    | `/api/v1/buildings/:buildingId/apartments`              | Sakin dahil                        |
| POST   | `/api/v1/buildings/:buildingId/apartments`              | Tek daire                          |
| PUT    | `/api/v1/buildings/:buildingId/apartments/:id`          |                                    |
| DELETE | `/api/v1/buildings/:buildingId/apartments/:id`          |                                    |
| DELETE | `/api/v1/buildings/:buildingId/apartments/:id/resident` | Sakini daireden ayır (hesap kalır) |
| POST   | `/api/v1/apartments/:apartmentId/invite-code`           | Davet kodu üret                    |

### Profile / Me — ✅

| Method | Path                   | Rol                                        |
| ------ | ---------------------- | ------------------------------------------ |
| GET    | `/api/v1/me`           | MANAGER, RESIDENT                          |
| PUT    | `/api/v1/me`           | Profil                                     |
| DELETE | `/api/v1/me`           | KVKK soft delete                           |
| PUT    | `/api/v1/me/password`  |                                            |
| PUT    | `/api/v1/me/language`  |                                            |
| PUT    | `/api/v1/me/fcm-token` | Token saklama; push gönderimi backend Faz 2A ✅ |
| GET    | `/api/v1/me/dues`      | RESIDENT; query: `status`, `year`, `month` |
| GET    | `/api/v1/me/tickets`   | RESIDENT — kendi talepleri |

### Planlanan — ⬜ (şema veya dokümantasyon var)

```
POST   /api/v1/buildings/:id/dues/bulk          # Yerine: bina oluşturma + due-amount
PATCH  /api/v1/dues/:id/status                  # Yerine: .../buildings/:id/dues/:dueId/status
GET                  /api/v1/me/subscription
POST                 /api/v1/subscription/webhook/revenuecat
GET                  /api/v1/buildings/:id/reports/...
POST                 /api/v1/.../dekonts        # Dekont yükleme + OCR (Faz 2)
```

---

## 📱 Flutter Uygulaması

**Sürüm:** `0.1.2+1778674159` · **SDK:** Dart `^3.11.5` · **~92** aktif `.dart` dosyası (`lib/`)

### Stack (kodda mevcut)

| Katman   | Seçim                                          | Not                                                                                             |
| -------- | ---------------------------------------------- | ----------------------------------------------------------------------------------------------- |
| Mimari   | Clean Architecture                             | `data` / `domain` / `presentation` (kısmi; tüm feature’larda domain yok)                        |
| State    | **flutter_riverpod**                           | `StateNotifier` + `Provider`; `riverpod_annotation` pubspec’te var, **kodda kullanılmıyor**     |
| Router   | **go_router**                                  | Auth redirect; 8 rota                                                                           |
| Ağ       | **dio** + `DioClient`                          | JWT interceptor, 401’de refresh, ayrı `_refreshDio`                                             |
| Depolama | **flutter_secure_storage**                     | access/refresh token, dil, FCM anahtarı                                                         |
| i18n     | **Slang 3**                                    | `strings_tr.i18n.json` / `strings_en.i18n.json` → `strings.g.dart`                              |
| UI       | Material 3                                     | `AppColors`, `AppTypography` (Nunito **adı** tanımlı; font asset pubspec’te yok → sistem fontu) |
| Yardımcı | `share_plus`, `package_info_plus`, `equatable` | Davet kodu paylaşımı, sürüm etiketi                                                             |

### Stack (henüz entegre değil)

| Plan                                    | Durum                                                                                                                                   |
| --------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------- |
| `purchases_flutter` (RevenueCat)        | pubspec’te **yok** (yalnızca Android proguard yorumu)                                                                                   |
| `cached_network_image`, `shimmer`       | pubspec’te **yok**                                                                                                                      |
| `freezed` / `json_serializable` üretimi | pubspec dev’de var; modeller **manuel** `fromJson`                                                                                      |
| Firebase                                | `firebase_core` / `firebase_messaging` bağımlılık var; **`main.dart` içinde `Firebase.initializeApp` yok**, `firebase_options.dart` yok |
| FCM sunucuya gönderim                   | `SecureStorage` + `ApiConstants.fcmToken` hazır; kayıt akışı bağlanmamış                                                                |

### Giriş noktaları

| Dosya               | Amaç                                                                                 |
| ------------------- | ------------------------------------------------------------------------------------ |
| `lib/main.dart`     | Production — gerçek API (`https://api.aidatpanel.com`)                               |
| `lib/main_dev.dart` | Mock repository override; sağ üst **DEV** rozeti; `flutter run -t lib/main_dev.dart` |

### Mobil durum özeti (2026-05)

**GoRouter rotaları:** `/` splash → oturum kurtarma → `/login` \| `/register` \| `/join` \| `/forgot-password` \| `/reset-password` → `/manager-dashboard` \| `/resident-dashboard`

**Yönetici sekmeleri (4 — plan’daki 5 değil):** Ana Sayfa · Binalar · Aidat · Ayarlar  
_(Giderler / Bildirimler ayrı tab değil; ayarlarda “yakında”)_

**Sakin sekmeleri (4):** Ana Sayfa · Aidatlarım · Talepler _(placeholder metin)_ · Ayarlar

**Planda olmayan / genişletilmiş:**

- `main_dev.dart` + `dev/dev_mocks.dart` (sunucusuz UI)
- `SystemNavigatorBridge` — geri tuşu uygulamayı arka plana alır (çıkış yok)
- `FriendlyErrorScreen` + `ToastOverlay` — global hata ve snack benzeri bildirim
- `building_residents_screen` — çoklu daire seçimi, toplu davet, daire CRUD, sakin çıkarma
- `cities_data.dart` — bina formu şehir listesi
- `ApiConstants` — Faz 2 endpoint sabitleri önceden tanımlı (backend henüz yok)
- Aidat özeti — yönetici ana sayfada tüm binaların aidatlarından tahsilat oranı hesabı
- `tool/` — `i18n_scan`, `check_translations`, `add_translation`

### pubspec.yaml — Gerçek bağımlılıklar (özet)

```yaml
dependencies:
  flutter_riverpod: ^2.5.0
  go_router: ^13.0.0
  dio: ^5.4.0
  flutter_secure_storage: ^9.0.0
  slang / slang_flutter: ^3.30.0
  firebase_core: ^3.0.0          # başlatılmıyor
  firebase_messaging: ^15.0.0
  equatable, json_annotation, freezed_annotation  # üretim kullanılmıyor
  share_plus, package_info_plus

dev_dependencies:
  build_runner, json_serializable, freezed, flutter_launcher_icons, flutter_lints
```

### Flutter klasör yapısı (gerçek)

```
mobile/lib/
├── main.dart
├── main_dev.dart
├── dev/dev_mocks.dart
├── core/
│   ├── constants/          api_constants.dart, app_constants.dart
│   ├── theme/              app_colors, app_typography, app_theme, app_sizes
│   ├── router/app_router.dart
│   ├── network/            dio_client.dart, api_exception.dart
│   ├── storage/secure_storage.dart
│   ├── providers/locale_provider.dart
│   ├── platform/system_navigator_bridge.dart
│   └── utils/input_validators.dart
├── l10n/
│   ├── i18n.yaml
│   ├── strings_tr.i18n.json, strings_en.i18n.json
│   └── strings.g.dart      # üretilmiş
├── features/
│   ├── auth/               ✅ ekranlar + AuthRepository + splash bootstrap
│   ├── dashboard/          ✅ manager + resident dashboard
│   ├── buildings/          ✅ CRUD, davet kodu, residents ekranı
│   ├── apartments/         ✅ data/UI (buildings akışına gömülü)
│   ├── dues/               ✅ manager_dues_tab, resident_dues_tab
│   ├── profile/            ✅ şifre, hesap silme (API)
│   ├── expenses/           ⬜ yalnızca .gitkeep iskelet
│   ├── tickets/            ⬜ iskelet
│   ├── notifications/      ⬜ iskelet
│   ├── reports/            ⬜ iskelet
│   └── subscription/       ⬜ iskelet
└── shared/
    ├── widgets/            settings_tab, empty_state, friendly_error, toast, …
    ├── providers/navigation_provider.dart
    └── utils/auth_validators.dart

mobile/test/                 auth_validators_test.dart, widget_test.dart (şablon)
mobile/tool/                 i18n_scan, check_translations, add_translation
```

### Feature → API eşlemesi

| Feature              | UI  | Backend API | Not                                    |
| -------------------- | --- | ----------- | -------------------------------------- |
| Auth                 | ✅  | ✅          | login `identifier`, join, forgot/reset |
| Binalar              | ✅  | ✅          | liste, ekle, düzenle, sil              |
| Daireler             | ✅  | ✅          | nested `/buildings/:id/apartments`     |
| Davet kodu           | ✅  | ✅          | paylaşım (`share_plus`)                |
| Aidat (yönetici)     | ✅  | ✅          | filtre, durum, `due-amount`            |
| Aidat (sakin)        | ✅  | ✅          | `GET /me/dues`                         |
| Profil / dil / şifre | ✅  | ✅          | `SettingsTab`                          |
| Hesap silme          | ✅  | ✅          | KVKK dialog                            |
| Giderler             | ⬜  | ⬜          |                                        |
| Talepler             | 🔶  | ⬜          | sakin “Talepler” sekmesi boş           |
| Bildirimler          | 🔶  | ⬜          | ayarlarda coming soon                  |
| Abonelik / Paywall   | ⬜  | ⬜          |                                        |
| Dekont yükleme       | ⬜  | ⬜          |                                        |

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

_(Mevcut veriler okunabilir, sakinler etkilenmez)_

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

**Backend (Faz 2A — uygulandı):** `src/config/firebase.js` (`initFirebase`), `src/services/pushService.js` (`sendToToken`), `notificationService.createForUsers` her DB kaydından sonra FCM dener. Production’da `FIREBASE_SERVICE_ACCOUNT_JSON` yoksa süreç başlamaz; development’ta push atlanır (DB kaydı oluşur).

### FCM `data` payload (tüm değerler string)

| Anahtar | Örnek | Açıklama |
|---------|--------|----------|
| `type` | `TICKET_UPDATE` | `NotificationType` enum |
| `notificationId` | UUID | Okundu / detay |
| `ticketId` | UUID | Talep deep link (talep bildirimlerinde) |
| `buildingId` | UUID | Bina bağlamı |
| `status` | `IN_PROGRESS` | Talep durumu (opsiyonel) |
| `route` | `/resident-dashboard` | GoRouter kısayolu |

`notification` (title/body) FCM `notification` alanında; `data` deep link için. Ayrıntılı plan: [`PLAN.md`](PLAN.md).

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

| Plan   | ID                   | Fiyat (önerilen) |
| ------ | -------------------- | ---------------- |
| Aylık  | `aidatpanel_monthly` | ₺99/ay           |
| Yıllık | `aidatpanel_annual`  | ₺799/yıl         |

### Webhook Olayları (RevenueCat → Backend)

```javascript
// POST /api/subscription/webhook/revenuecat
const events = {
  INITIAL_PURCHASE: () => activateSubscription(),
  RENEWAL: () => extendSubscription(),
  CANCELLATION: () => markCancelled(),
  EXPIRATION: () => expireSubscription(),
  BILLING_ISSUE: () => notifyBillingIssue(),
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

| Subdomain            | Hedef                       |
| -------------------- | --------------------------- |
| `aidatpanel.com`     | Web landing page            |
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

#### Backend (`/api/v1`)

Güncel liste: **Backend durum özeti** + `backend/prisma/schema.prisma` + `backend/test.py`.

- [x] Auth: register, login (email/telefon), refresh, logout, join, forgot/reset şifre
- [x] JWT + `refreshTokenVersion` (`rv` claim); logout ve şifre değişiminde sürüm artışı
- [x] Profil: `GET/PUT /me`, şifre, dil, **KVKK `DELETE /me`**
- [x] Bina CRUD + kat/daire şablonu ile otomatik daire oluşturma
- [x] Daire CRUD + **sakini daireden ayırma** (`DELETE .../resident`)
- [x] Davet kodu (`POST .../invite-code`)
- [x] Aidat: bina kurulumunda yıl sonuna kayıt; `PATCH due-amount`; `GET .../dues`; `PATCH .../status`; `GET /me/dues`
- [x] Zod doğrulama, rate limit, Helmet, merkezi hata yanıtı
- [x] `test.py` smoke testleri
- [x] FCM: `PUT /me/fcm-token` + Admin SDK gönderim (`pushService`, production zorunlu)
- [ ] RevenueCat webhook / `GET /me/subscription` ⬜
- [ ] Landing page (`web/`) — repoda `web/` klasörü henüz yok

#### Mobil (Flutter)

- [x] Auth akışı: splash (oturum kurtarma + timeout), login, register, join, forgot/reset
- [x] GoRouter + rol bazlı dashboard yönlendirme
- [x] Dio: Bearer, refresh token, Türkçe `ApiException` mesajları
- [x] Yönetici: bina listesi/ekleme/düzenleme/silme, daire & sakin yönetimi, davet kodu
- [x] Yönetici: aidat listesi, filtre, ödendi/bekliyor/gecikmiş, aidat tutarı güncelleme
- [x] Sakin: aidatlarım sekmesi (`GET /me/dues`)
- [x] Ayarlar: profil kartı, şifre değiştir, dil (TR/EN, Slang + secure storage), hesap silme
- [x] i18n Slang (TR/EN); `main_dev` mock modu
- [x] Tasarım token’ları: renk, tipografi, 56dp buton, `NavigationBar`
- [-] Firebase / FCM: bağımlılık var, **init ve token upload akışı yok**
- [ ] RevenueCat / paywall ⬜
- [ ] Giderler, bildirimler, raporlar UI ⬜
- [ ] Sakin talepler sekmesi (API + UI) ⬜ — şu an placeholder

**Faz 1 dışı kalan plan maddeleri (bilinçli veya ertelenmiş):**

- [ ] `POST .../dues/bulk` — yerine bina create + `due-amount` akışı
- [ ] `ecosystem.config.js` / PM2 repoda yok
- [ ] `docker-compose.yml`, `scripts/docker-test.sh` — `.env.example`’da referans var, repoda henüz yok

### Faz 2 — Tamamlama

**Dekont / ödeme doğrulama**

- [x] Veritabanı: `Dekont`, `DuePayment`, bina tahsilat IBAN alanları, bildirim enum’ları (migration `20260515120000_dekont_system`)
- [ ] Dekont upload API + dosya depolama
- [ ] OCR / banka profilleri (10 banka listesi planı geçerli)
- [ ] Alıcı, gönderen, tarih, tutar, banka, sorgu no, IBAN eşleştirme

**Diğer**

- [x] Gider API (`Expense`) — **Faz 2A backend ✅**
- [x] Arıza/talep API (`Ticket`, `TicketUpdate`) — **Faz 2A backend ✅**
- [x] Bildirim listesi + okundu + yönetici duyuru + FCM — **Faz 2A backend ✅** (mobil UI ⬜)
- [ ] WhatsApp aidat hatırlatma
- [ ] PDF rapor (aylık özet)
- [x] i18n (TR/EN) — mobil: Slang; ayarlar + ekran metinleri

---

## 📋 Faz 2A — Gider, Talep, Bildirim + Firebase FCM

> **Ayrıntılı aşamalı plan:** [`PLAN.md`](PLAN.md) (backend **A0–A6 ✅**, Flutter B0–B6, FCM **zorunlu**).

**Hedef:** Expense / Ticket / Notification REST API; **Firebase Admin push zorunlu**; Flutter’da FCM + bildirim/talep/gider ekranları implementasyona hazır.

**Kapsam dışı (bu sprint):** Dekont/OCR, `receiptUrl` dosya upload, RevenueCat kilidi, WhatsApp/SMS, PDF rapor.

### Mevcut durum

| Modül | Şema | Backend API | Mobil UI |
| ----- | ---- | ----------- | -------- |
| Expense | ✅ | ✅ | ⬜ iskelet |
| Ticket + TicketUpdate | ✅ | ✅ | ⬜ placeholder sekme |
| Notification + duyuru | ✅ | ✅ | ⬜ ayarlarda “yakında” |
| FCM push (Admin SDK) | ✅ | ✅ production zorunlu | ⬜ init yok |
| FCM token | ✅ | ✅ `PUT /me/fcm-token` | ⬜ upload akışı |

**Tekrar kullanılan kalıp:** `dueService` / `buildingRoutes` — bina sahipliği `managerId`, sakin `apartmentId` + `RESIDENT`, yanıt `{ success, message?, data }`, yetki sızıntısı **404** (enumeration önleme).

### Önerilen dosya yapısı

```
backend/src/
├── config/firebase.js
├── services/
│   ├── notificationService.js   # createForUsers + list/read + FCM
│   ├── pushService.js
│   ├── announcementService.js
│   ├── ticketService.js
│   └── expenseService.js
├── controllers/  (notification, ticket, expense, announcement)
├── routes/
│   ├── notificationRoutes.js
│   ├── ticketRoutes.js
│   ├── apartmentTicketRoutes.js
│   ├── expenseRoutes.js
│   └── buildingRoutes.js  (+ expenses, tickets, announcements)
└── middlewares/validate.js  # expenseSchemas, ticketSchemas, notificationSchemas
```

`index.js` mount sırası (çakışma önleme):

```js
app.use("/api/v1/notifications", notificationRoutes);
app.use("/api/v1/tickets", ticketRoutes);
app.use("/api/v1/apartments/:apartmentId/tickets", apartmentTicketRoutes);
// buildingRoutes içinde: /:id/expenses, /:id/expenses/summary, /:id/tickets, /:id/announcements
// meRoutes içinde: GET /tickets
```

### API sözleşmesi (`/api/v1`)

#### 1) Giderler (MANAGER)

| Method | Path | Body / Query | Açıklama |
| ------ | ---- | ------------ | -------- |
| GET | `/buildings/:buildingId/expenses` | `?month=&year=&category=` | Liste, `date` desc |
| GET | `/buildings/:buildingId/expenses/summary` | `?month=&year=` | Kategori toplamları + genel toplam |
| POST | `/buildings/:buildingId/expenses` | `title, amount, category, date, note?, receiptUrl?` | Kayıt |
| PUT | `/expenses/:expenseId` | Aynı alanlar (kısmi) | Bina sahibi doğrulaması |
| DELETE | `/expenses/:expenseId` | — | Sil |

`receiptUrl`: Faz 2A’da opsiyonel **HTTPS URL string** (max 2048); dosya upload Faz 2B.

`summary` örnek yanıt:

```json
{
  "success": true,
  "data": {
    "month": 5,
    "year": 2026,
    "totalAmount": "12500.00",
    "currency": "TRY",
    "byCategory": [{ "category": "CLEANING", "amount": "3000.00", "count": 2 }]
  }
}
```

#### 2) Talepler (Ticket)

| Method | Path | Rol | Açıklama |
| ------ | ---- | --- | -------- |
| GET | `/buildings/:buildingId/tickets` | MANAGER | `?status=&category=`; daire + sakin özeti |
| GET | `/me/tickets` | RESIDENT | Kendi talepleri |
| GET | `/tickets/:ticketId` | MANAGER veya talep sahibi | `updates` dahil |
| POST | `/apartments/:apartmentId/tickets` | RESIDENT | Yeni talep; `userId` = JWT, daire = kullanıcının `apartmentId` |
| POST | `/tickets/:ticketId/updates` | MANAGER | `message`; `fromRole: MANAGER` |
| PATCH | `/tickets/:ticketId/status` | MANAGER | `status`: OPEN → IN_PROGRESS → RESOLVED → CLOSED |

**İş kuralları:**

- Sakin yalnızca **kendi dairesinde** talep açar (`apartmentId === user.apartmentId`).
- Yönetici yalnızca **kendi binasındaki** talepleri görür/günceller (`apartment.building.managerId`).
- `POST .../updates` ve durum değişimleri: `Notification` (`TICKET_UPDATE`) + FCM denemesi.
- `CLOSED` sonrası güncelleme: 409 (veya yalnızca status değişimine izin — netleştirilecek).

#### 3) Bildirimler

| Method | Path | Rol | Açıklama |
| ------ | ---- | --- | -------- |
| GET | `/notifications` | Her iki rol | `?unreadOnly=true&limit=20&cursor=` |
| PATCH | `/notifications/:id/read` | Alıcı | `userId` eşleşmesi |
| PATCH | `/notifications/read-all` | Alıcı | Tümünü okundu |
| POST | `/buildings/:buildingId/announcements` | MANAGER | `title, body` → binadaki tüm sakinlere `ANNOUNCEMENT` |

**`notificationService.create` (iç):**

```js
// userId[], type, title, body, data?: { ticketId, buildingId, ... }
// Her kullanıcı için Notification INSERT; fcmToken varsa push kuyruğu
```

**Otomatik tetikleyiciler (Faz 2A):**

| Olay | type | Alıcı |
| ---- | ---- | ----- |
| Yönetici talep güncellemesi | `TICKET_UPDATE` | Talep sahibi sakin |
| Yönetici duyuru | `ANNOUNCEMENT` | Binadaki tüm sakinler |
| (Sonra) Aidat ödendi | `DUE_PAID` | İlgili sakin |

**FCM katmanı (zorunlu):** `config/firebase.js` + `pushService.js` — production’da Admin SDK şart; her `createForUsers` sonrası push. Ayrıntı: `PLAN.md`.

### Yetkilendirme özeti

```
MANAGER + building.managerId === req.user.id  →  bina expenses/tickets/announcements
RESIDENT + user.apartmentId === apartmentId →  talep oluşturma
RESIDENT + ticket.userId === req.user.id      →  talep detayı (kendi)
MANAGER + ticket.apartment.building.managerId →  talep detayı / güncelleme
notification.userId === req.user.id           →  okundu işaretleme
```

### Uygulama sırası (önerilen)

| Adım | İş | Tahmini | Çıktı |
| ---- | -- | ------- | ----- |
| **2A.1** | `notificationService` + routes | ✅ | Bildirim kutusu API |
| **2A.2** | `ticketService` + ticket route’ları + `me/tickets` | ✅ | Talep CRUD |
| **2A.3** | Ticket → `TICKET_UPDATE` | ✅ | Olay tetikleyici |
| **2A.4** | `expenseService` + summary | ✅ | Gider API |
| **2A.5** | `POST .../announcements` | ✅ | Yönetici duyuru |
| **2A.6** | Firebase + `pushService` | ✅ | Production FCM zorunlu |
| **2A.7** | Zod + `test.py` Faz 2A | ✅ | E2E smoke |

**Toplam:** ~4–5 geliştirici günü (tek kişi, mevcut kalıba hakim).

### `validate.js` ekleri (özet)

- `expenseSchemas`: create, update, list query, summary query, `expenseId` params
- `ticketSchemas`: create (title, description, category), update status, add update, list filters
- `notificationSchemas`: list query (limit 1–50, cursor uuid), announce body

### Test planı (`test.py`)

1. Yönetici: bina → gider CRUD + summary assert  
2. Sakin: join → talep oluştur → listede görünür  
3. Yönetici: talep status + update → sakin `GET /notifications` içinde `TICKET_UPDATE`  
4. Yönetici: announcement → tüm sakinlerde kayıt  
5. Yetkisiz: başka binanın gideri/talebi → 403/404  

### Mobil uyum (Faz 2A sonrası)

| Backend | Mobil iş |
| ------- | -------- |
| Expenses API | `features/expenses/` data + yönetici tab (veya bina detayı) |
| Tickets API | `resident_dashboard` Talepler sekmesi + yönetici liste |
| Notifications API | `SettingsTab` bildirimler + isteğe bağlı ayrı sekme |

`ApiConstants` içindeki sabitler (`buildingExpenses`, `myTickets`, `notifications`, …) zaten tanımlı — backend path’ler bunlarla birebir hizalanmalı.

### Açık kararlar (implementasyon öncesi)

1. **Abonelik kilidi:** Duyuru ve yeni gider için `Subscription.status === ACTIVE` zorunlu mu? (Şimdilik **hayır** — RevenueCat gelene kadar atlanır.)  
2. **Talep kapanınca:** `CLOSED` iken yönetici notu — izin ver / verme? (Öneri: yalnızca `OPEN`/`IN_PROGRESS` iken not.)  
3. **Sayfalama:** Bildirimler cursor (`createdAt` + `id`) mı offset mi? (Öneri: cursor.)  
4. **`DELETE /expenses`:** Kalıcı silme mi soft-delete? (Öneri: kalıcı — şemada `deletedAt` yok.)

### Kabul kriterleri (Definition of Done — backend)

- [x] Tüm endpoint’ler `/api/v1` altında, Zod doğrulamalı, Türkçe hata mesajları  
- [x] MANAGER/RESIDENT yetki sızıntısı yok (`test.py` çapraz yönetici 404)  
- [x] Talep güncellemesi DB bildirimi + `TICKET_UPDATE`  
- [x] `test.py` Faz 1 + Faz 2A senaryoları  
- [x] `AIDATPANEL.md` API tabloları güncel  
- [ ] Gerçek cihazda FCM (Firebase env + geçerli token — manuel; Flutter B1 sonrası)

### Faz 3 — Büyüme

- [ ] SMS API konuşulacak
- [ ] Online ödeme işlemleri (Fahrettin hoca)
- [ ] Çoklu yönetici (personel atama)
- [ ] Aidat geçmişi grafiği / istatistik dashboard
- [ ] Belge paylaşımı (yönetim kararları, toplantı tutanakları)

---

## ⚙️ Teknik Kararlar ve Gerekçeleri

| Karar            | Seçim            | Gerekçe                                     |
| ---------------- | ---------------- | ------------------------------------------- |
| State management | Riverpod         | OkulOptik'te zaten biliniyor                |
| Navigation       | GoRouter         | Flutter best practice, deep link desteği    |
| ORM              | Prisma           | Type-safe, migration yönetimi kolay         |
| Abonelik         | RevenueCat       | iOS + Android tek entegrasyon               |
| Push             | Firebase FCM     | Cross-platform standart                     |
| WhatsApp         | Twilio           | Sandbox ile hızlı test, Türkiye desteği var |
| i18n             | **Slang** (JSON) | ARB yerine `strings_*.i18n.json` + codegen  |

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

**Material `NavigationBar` (ikon + etiket). Hamburger menü yok.**

| Rol      | Sekmeler (uygulama)                         | Plan dokümanı (hedef)             |
| -------- | ------------------------------------------- | --------------------------------- |
| Yönetici | Ana Sayfa · Binalar · Aidat · Ayarlar       | + Giderler · Bildirimler ayrı tab |
| Sakin    | Ana Sayfa · Aidatlarım · Talepler · Ayarlar | Talepler API’siz placeholder      |

Alt ekranlar `Navigator.push` ile: `AddBuildingScreen`, `BuildingResidentsScreen`, `InviteCodeScreen` (GoRouter dışı stack).

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
- Tüm API route'ları `/api/v1/` prefix'i ile başlamalı — **uygulandı** (`backend/index.js`)
- [x] KVKK: `DELETE /api/v1/me` — soft delete, yönetici aktif bina varken 409
- Aidat son ödeme günü: `src/utils/trDueDate.js` (Europe/Istanbul)
- Yerel test: `cd backend && npm run dev` · smoke: `python test.py` (API `http://127.0.0.1:4200/api/v1`)
- Prisma: `npx prisma migrate deploy` (3 migration)
- Apple App Store'da "Kids Category" seçilmemeli, subscription için "Finance" kategorisi uygundur

### Backend migration geçmişi

| Migration                                       | İçerik                                                  |
| ----------------------------------------------- | ------------------------------------------------------- |
| `20260510005756_init`                           | Tüm çekirdek tablolar + `dueDate` / bina aidat ayarları |
| `20260510023405_user_deleted_at_password_reset` | `deletedAt`, `PasswordResetToken`                       |
| `20260515120000_dekont_system`                  | `Dekont`, `DuePayment`, bina tahsilat kolonları         |
