# AidatPanel — Kapsamlı Proje Analiz Raporu

> **İlk tarih:** 2026-05-19 · **Son senkron:** 2026-05-20  
> **Güncel özet (aşağıdaki bölüm esas alınır):** [`FLUTTER_GAP_RAPORU.md`](FLUTTER_GAP_RAPORU.md) · [`DOKUMANTASYON.md`](DOKUMANTASYON.md) · [`PLAN.md`](PLAN.md)  
> **E2E:** [`mobile/E2E_CHECKLIST.md`](mobile/E2E_CHECKLIST.md)

---

## Güncel durum özeti (2026-05-20)

| Katman | Faz 1 | Faz 2A | Not |
|--------|-------|--------|-----|
| Backend API + push | ✅ | ✅ | `test.py` 120 OK |
| Flutter mobil | ✅ | ✅ kod | B0–B6 implemente; cihaz E2E 🔶 |
| Uçtan uca Faz 2A | — | 🔶 ~%90 | Gerçek FCM + checklist |

**Workspace:** `backend/` + `mobile/` aynı kök dizinde (birleşik repo).

**Flutter Faz 2A (kod):** `core/notifications/`, `features/notifications|tickets|expenses/`, rotalar (`/notifications`, `/manager/tickets`, …), `main_dev` + `mock_faz2_datasources.dart`, `ApiConstants` tam, Slang Faz 2 anahtarları.

**Kalan (bilinçli):** Manuel E2E, UI tasarım polish, iOS `GoogleService-Info.plist`, Faz 2B+ (dekont, RevenueCat, raporlar), ayarlarda gizlilik/yardım toast.

*Aşağıdaki bölümler 2026-05-20 itibarıyla güncellenmiştir; tarihsel 2026-05-19 ifadeleri kaldırıldı veya düzeltildi.*

---

## Proje Genel Durumu

**AidatPanel**, Türk apartman/site yöneticileri için Flutter mobil + Node.js API + PostgreSQL tabanlı bir aidat yönetim platformudur. Proje üç Git dalında parçalı tutuluyor:

| Dal | İçerik |
|-----|--------|
| `main` | Yalnızca `AIDATPANEL.md` |
| [`backend/api`](https://github.com/AbdullahAslan63/Deneme/tree/backend/api) | Backend, `PLAN.md`, `docker-compose.yml`, güncel dokümantasyon |
| `mobile/flutter` (uzak dal) | Flutter — yerel workspace’te `mobile/` klasörü |

Yerel workspace: **`mobile/` + `backend/`** tek kök dizinde (`Deneme/`).

### Genel tamamlanma özeti

| Katman | Faz 1 (MVP) | Faz 2A (Gider/Talep/Bildirim) | Faz 2B+ |
|--------|-------------|-------------------------------|---------|
| **Backend API** | ✅ ~%100 | ✅ ~%100 | ⬜ Dekont, abonelik, rapor |
| **Database şema** | ✅ | ✅ (tablolar hazır) | Dekont/OCR alanları şemada, API yok |
| **Flutter mobil** | ✅ ~%90 | ✅ ~%95 (kod) | ⬜ Faz 2B+ |
| **Firebase FCM (uçtan uca)** | ⬜ | Backend ✅ / Mobil ✅ kod · E2E 🔶 | — |
| **Web landing** | ⬜ | — | — |
| **Deployment (PM2/prod)** | ⬜ | — | — |

**Özet:** Backend Faz 2A production-ready. Flutter Faz 2A **kod tamam**; kalan: gerçek cihazda E2E doğrulaması ve UI polish.

### Çalışır durum doğrulaması

| Bileşen | Durum | Kanıt |
|---------|--------|-------|
| Backend sunucu | ✅ Çalışıyor | `npm run dev` → port 4200, DB bağlı |
| PostgreSQL | ✅ | `docker-compose.yml` (5433), Prisma migrate |
| Postman bildirim testleri | ✅ | Önceki oturum: register, FCM token, seed, read |
| `test.py` | ✅ | 120 OK (yerel: `AIDATPANEL_API_BASE=http://127.0.0.1:4200/api/v1`) |
| Flutter prod build | ✅ Faz 1 + Faz 2A ekranları | E2E cihazda doğrulanmalı |
| Gerçek FCM push | 🔶 | Backend env + mobil token + fiziksel cihaz / Play AVD |

---

## Mevcut Çalışan Özellikler

### Backend — Faz 1 + Faz 2A (doğrulandı)

**Auth & oturum**
- Register, login (email/telefon `identifier`), refresh, logout, join (davet kodu)
- Forgot/reset password (Resend opsiyonel; E2E log modu)
- JWT access (15dk) + refresh (30g), `refreshTokenVersion` ile oturum iptali
- Rate limit: genel 100/15dk, auth 5/15dk (prod)

**Profil / Me**
- `GET/PUT/DELETE /me` (KVKK soft delete)
- Şifre, dil, FCM token kaydı
- Sakin: `GET /me/dues`, `GET /me/tickets`

**Yönetici — bina & aidat**
- Bina CRUD, kat×daire şablonu ile otomatik daire oluşturma
- Daire CRUD, sakin çıkarma, davet kodu üretimi
- Aidat listesi/filtre, durum güncelleme, `due-amount` patch
- Yıl sonuna otomatik aidat kaydı (İstanbul takvimi)

**Faz 2A — gider, talep, bildirim**
- Gider: liste, özet, CRUD (`Expense`)
- Talep: sakin oluşturma, yönetici liste/not/durum, durum makinesi
- Bildirim: liste (cursor pagination), okundu, tümünü okundu
- Duyuru: `POST /buildings/:id/announcements` → tüm aktif sakinlere DB + FCM
- Aidat: `DUE_PAID` (status PAID), `DUE_REMINDER` (`POST .../dues/remind`)
- Talep: `TICKET_CREATED` (yeni talep → yönetici), `TICKET_UPDATE` (not/durum → sakin)
- Push: `pushService` + Firebase Admin (dev’de dosya yolu/JSON ile açılabilir; prod zorunlu)
- Logout: `fcmToken` temizlenir

**Altyapı**
- Express 5, Helmet, CORS, Zod doğrulama, merkezi hata handler
- Prisma 7 + PostgreSQL; migration’lar `backend/prisma/migrations/` (2 migration klasörü, 2026-05-20)
- `test.py` — Faz 1 + Faz 2A smoke senaryoları

### Mobile — Faz 1 (doğrulandı)

**Auth UX:** Splash (oturum kurtarma), login, register, join, forgot/reset password

**Yönetici dashboard (4 sekme)**
- Ana sayfa: metrikler, bina listesi
- Binalar: CRUD, davet kodu, daire/sakin yönetimi
- Aidat: filtre, durum, tutar güncelleme
- Ayarlar: profil, şifre, dil, hesap silme

**Sakin dashboard (4 sekme)**
- Ana sayfa: aidat özeti (API’den)
- Aidatlarım: tam implementasyon
- Talepler: ✅ `ResidentTicketsTab` *(2026-05-20 güncelleme)*
- Ayarlar: paylaşımlı `SettingsTab`

**Teknik**
- Riverpod state, GoRouter (8 rota), Dio + JWT refresh interceptor
- Slang i18n TR/EN, `main_dev.dart` mock modu
- Global hata ekranı, toast overlay

### Database — uygulanmış modeller

| Model | Tablo | API |
|-------|-------|-----|
| User, Building, Apartment, InviteCode, Due | ✅ | ✅ |
| Expense, Ticket, TicketUpdate, Notification | ✅ | ✅ |
| PasswordResetToken | ✅ | ✅ |
| Subscription | ✅ | ⬜ route yok |
| Dekont, DuePayment | ✅ | ⬜ route yok |

---

## Eksik Özellikler

### Dokümantasyonda planlanmış, kodda yok

| Özellik | Backend | Mobil | Faz |
|---------|---------|-------|-----|
| Dekont upload + OCR | ⬜ | ⬜ | 2B/2C |
| RevenueCat / abonelik kilidi | ⬜ | ⬜ | 3 |
| PDF aylık rapor | ⬜ | ⬜ | 2+ |
| WhatsApp/SMS hatırlatma | ⬜ | ⬜ | 3 |
| Web landing (`web/`) | ⬜ | — | 1 |
| PM2 / `ecosystem.config.js` | ⬜ | — | Deploy |
| `DUE_REMINDER`, `DUE_PAID` push | ✅ | ✅ deep link (dashboard/route) | E2E cihaz 🔶 |
| Yeni talep → yönetici (`TICKET_CREATED`) | ✅ | ✅ deep link + talep UI | E2E cihaz 🔶 |

### PLAN.md Faz 2A — Flutter (B0–B6) — 2026-05-20 durumu

| Aşama | İçerik | Durum (2026-05-20) |
|-------|--------|---------------------|
| B0 | Firebase dosyaları | ✅ (iOS plist hedefe göre) |
| B1 | FCM çekirdek | ✅ |
| B2 | Bildirim feature | ✅ |
| B3 | Talep feature | ✅ |
| B4 | Gider feature | ✅ |
| B5 | Dashboard + `main_dev` mock | ✅ |
| B6 | Test & E2E checklist | 🔶 [`mobile/E2E_CHECKLIST.md`](mobile/E2E_CHECKLIST.md) |

### Mobil — tamamlanan (Faz 2A kod)

- Firebase `initFirebase`, FCM token → `PUT /me/fcm-token`, `FcmScope` (foreground/tap)
- Bildirim listesi, okundu, read-all, ayarlarda badge + `/notifications`
- Duyuru: `AnnouncementFormSheet` + `POST .../announcements`
- Talep: `ResidentTicketsTab`, `ManagerTicketsScreen`, `TicketDetailScreen`, durum/not kuralları
- Gider: `ManagerExpensesScreen`, CRUD, özet, `ExpenseFormSheet`
- `ApiConstants` Faz 2 sabitleri tanımlı ve kullanılıyor
- Yerel API: `--dart-define=API_BASE_URL=...` (`api_config.dart`)

### Mobil — kalan (Faz 2A dışı veya doğrulama)

- Manuel E2E checklist ([`mobile/E2E_CHECKLIST.md`](mobile/E2E_CHECKLIST.md))
- iOS `GoogleService-Info.plist` (hedef için `flutterfire configure`)
- `PUT /me/language` backend senkronu (opsiyonel)
- Gizlilik/KVKK/yardım: `comingSoon` toast (3 ayar satırı)
- Sakin ana sayfa: ödeme/faturalar no-op; işlem geçmişi boş
- UI tasarım polish (bilinçli ertelendi)

### Backend spesifik eksikler (Faz 2A dışı)

- `GET /me/subscription`, RevenueCat webhook
- `GET /buildings/:id/reports/...`
- Dekont CRUD + OCR pipeline
- `backend/scripts/docker-test.sh` (test.py referans veriyor, repoda yok)
- Health check endpoint (`GET /health`)

---

## Hatalar ve Riskler

### Kod hataları / bug adayları

| # | Konu | Şiddet | Detay |
|---|------|--------|-------|
| 1 | `test.py` varsayılan BASE URL | **Düşük** | Production URL; yerel test için `AIDATPANEL_API_BASE=http://127.0.0.1:4200/api/v1` kullanın |
| 2 | JWT role kaynağı | **Orta** | `requireRoles` JWT payload’dan okur; DB’de rol değişince ~15dk gecikme |
| 3 | `strictLimiter` tanımlı, mount edilmemiş | **Orta** | forgot-password sadece `authLimiter` (5/15dk) |
| 4 | E2E seed production riski | **Orta** | `AIDATPANEL_E2E=1` prod’da açılırsa her auth kullanıcı seed oluşturabilir |
| 5 | Access token expiry | **Düşük** | Süresi dolmuş token → refresh denemeden reddedilir; 401’de refresh çalışır |
| 6 | `addTicketUpdate` response formatı | **Düşük** | Diğer ticket endpoint’leriyle tutarsız serialization |
| 7 | `authService.js` | **Düşük** | Dead code — auth `authControllers.js`’te |

### Güvenlik riskleri

| Alan | Durum | Not |
|------|--------|-----|
| Helmet + CORS + rate limit | ✅ | Production origin listesi `.env` ile |
| JWT + refresh version | ✅ | Logout/şifre değişiminde invalidation |
| IDOR koruması | ✅ | Yanlış manager → 404 pattern |
| Soft delete user | ✅ | `deletedAt` ile oturum reddi |
| Firebase prod fail-fast | ✅ | Env yoksa `process.exit(1)` |
| Refresh token rotation | ⬜ | Yeni refresh token üretilmiyor (plan gerektirmiyor) |
| Cookie auth path | ⬜ | `authMiddleware` cookie okur ama `cookie-parser` yok — dead path |
| FCM sequential send | **Düşük** | Büyük binalarda duyuru yavaş/DoS riski |
| `.env` commit | ⚠️ | `.gitignore`’da; yerel `.env` untracked olmalı |

### Kısmi UI / iskelet envanteri (2026-05-20)

| Konum | Durum |
|-------|--------|
| `features/notifications/`, `tickets/`, `expenses/` | ✅ API + UI (bazı alt klasörlerde `.gitkeep` kalabilir) |
| `features/reports/`, `subscription/` | ⬜ Faz 2B+ iskelet |
| `settings_tab` (gizlilik, yardım, çoklu dil) | `comingSoon` toast |
| Sakin ana sayfa quick actions (ödeme, faturalar) | no-op |
| İşlem geçmişi | boş + coming soon metni |
| `widget_test.dart` | şablon test |

### TODO/FIXME taraması

`backend/src` ve `mobile/lib` içinde anlamlı `TODO`/`FIXME` **bulunamadı** (2026-05-20).

---

## Mobile Analizi

### Mimari

```
mobile/lib/
├── main.dart / main_dev.dart
├── core/          → router, network, theme, storage, constants
├── features/
│   ├── auth/          ✅ tam
│   ├── buildings/     ✅ tam
│   ├── apartments/    ✅ tam
│   ├── dues/          ✅ tam
│   ├── profile/       ✅ kısmi (widget’lar, ayrı screen yok)
│   ├── dashboard/     ✅ manager + resident (+ Faz 2 kısayolları)
│   ├── notifications/ ✅ liste, duyuru, datasource
│   ├── tickets/       ✅ sakin/yönetici/detay, repository
│   ├── expenses/      ✅ CRUD, özet, form sheet
│   ├── reports/       ⬜ Faz 2B+ iskelet
│   └── subscription/  ⬜ Faz 3 iskelet
├── core/notifications/ ✅ FCM, payload
├── shared/widgets/    ✅ settings, toast, empty state, error
└── dev/               ✅ dev_mocks.dart, mock_faz2_datasources.dart
```

### State management & routing

- **Riverpod:** `StateNotifier` + `Provider`; `riverpod_annotation` pubspec’te var, kodda kullanılmıyor
- **GoRouter:** auth + dashboard + Faz 2 (`/notifications`, `/manager/tickets`, `/tickets/:id`, …); bina ekranları `Navigator.push`
- **Dio:** Bearer interceptor, 401’de refresh, ayrı `_refreshDio`

### API entegrasyon haritası

| ApiConstants grubu | Kullanılıyor | Kullanılmıyor |
|--------------------|--------------|---------------|
| Auth, buildings, apartments, dues, profile | ✅ | — |
| Expenses, tickets, notifications, fcmToken, announcements | ✅ | — |
| changeLanguage, subscription, reports | — | Faz 2B+ / opsiyonel |

### Firebase / FCM durumu

| Bileşen | Durum |
|---------|--------|
| `pubspec.yaml` bağımlılıkları | ✅ |
| `firebase_options.dart` | ✅ |
| `google-services.json` (Android) | ✅ |
| iOS `GoogleService-Info.plist` | 🔶 hedef bundle |
| `initFirebase()` (`main.dart`) | ✅ |
| Token → `PUT /me/fcm-token` | ✅ (`fcm_service`, `syncFcmAfterAuth`) |
| Gerçek cihaz push | 🔶 E2E checklist |

### UI/UX değerlendirmesi

**Güçlü yanlar:** Material 3, tutarlı renk/tipografi token’ları, TR/EN, loading/error state’leri (bina/aidat), KVKK hesap silme dialog

**Zayıf yanlar (2026-05-20):**
- Ayarlarda gizlilik/yardım/çoklu dil hâlâ `comingSoon` toast
- Sakin ana sayfa: ödeme/faturalar no-op; işlem geçmişi boş
- Nunito font adı tanımlı, asset yok → sistem fontu
- Tasarım polish ertelendi (fonksiyon öncelikli tamamlandı)

### Test durumu

| Dosya | Kapsam |
|-------|--------|
| `auth_validators_test.dart` | ✅ invite code validasyon |
| `widget_test.dart` | şablon · `notification_payload_test.dart` ✅ |

---

## Database Analizi

### Migration geçmişi (`backend/prisma/migrations/`)

1. `20260519001941_init` — çekirdek + Faz 2A modelleri
2. `20260519010242_ticket_created_notification_type` — `TICKET_CREATED` bildirim tipi

### Şema vs API uyumu

| Model | Şema | API | Mobil |
|-------|------|-----|-------|
| User (+ fcmToken, refreshTokenVersion, deletedAt) | ✅ | ✅ | ✅ token upload |
| Building (+ collectionIban alanları) | ✅ | ✅ CRUD | ✅ |
| Apartment (tek sakin @unique) | ✅ | ✅ | ✅ |
| Due (+ dueDate, overdueDays) | ✅ | ✅ | ✅ |
| Expense (+ receiptUrl) | ✅ | ✅ | ✅ |
| Ticket + TicketUpdate | ✅ | ✅ | ✅ |
| Notification (+ data Json) | ✅ | ✅ | ✅ |
| Dekont (15+ status enum) | ✅ | ⬜ | ⬜ |
| Subscription | ✅ | ⬜ | ⬜ |

### İndeksler

Kritik sorgular için indeksler mevcut: `Notification(userId, isRead, createdAt)`, `Ticket(status, createdAt)`, `Due(status, dueDate)` — PLAN’daki cursor pagination ile uyumlu.

### Eksik DB yapıları

Şema tarafında Faz 2B+ için hazırlık var; **eksik olan API katmanı**, tablo değil. Ek migration gerekmiyor (Faz 2A için).

---

## Backend Analizi

### Klasör organizasyonu

```
backend/
├── index.js                 # Express bootstrap, route mount
├── prisma/schema.prisma
├── src/
│   ├── config/              db.js, firebase.js
│   ├── routes/              10 route modülü
│   ├── controllers/         10 controller
│   ├── services/            notification, ticket, expense, push, fcmToken, …
│   ├── middlewares/         auth, validate, rateLimit, error, role
│   ├── utils/               access, httpError, trDueDate, notificationPayload
│   ├── validators/          authValidator, notificationValidator
│   └── constants/           notificationConstants
├── test.py                  # smoke test (120 OK)
└── postman/                 # AidatPanel-Notifications.postman_collection.json
```

### API endpoint doğrulama (AIDATPANEL.md tablolarına karşı)

| Grup | Doküman | Kod | Uyum |
|------|---------|-----|------|
| Auth (7 endpoint) | ✅ | ✅ | ✅ |
| Buildings + dues + announcements | ✅ | ✅ | ✅ |
| Expenses (5 endpoint) | ✅ | ✅ | ✅ |
| Tickets (6 endpoint) | ✅ | ✅ | ✅ |
| Notifications (3 + seed) | ✅ | ✅ | ✅ |
| Apartments + invite | ✅ | ✅ | ✅ |
| Me (8 endpoint) | ✅ | ✅ | ✅ |
| Subscription, reports, dekont | ⬜ planlı | ⬜ | ✅ (beklenen) |

### PLAN.md backend ilerleme (A0–A6)

Tüm aşamalar ✅ işaretli; kod incelemesi bunu **doğruluyor**.

### Bildirim modülü

- `notificationValidator.js`, `notificationConstants.js`, `notificationPayload.js`
- `fcmTokenService.js`, `pushService.js`, `notificationDemo.js`
- E2E seed: `AIDATPANEL_E2E=1` ile `POST /notifications/_e2e/seed`
- Postman: `backend/postman/AidatPanel-Notifications.postman_collection.json`

### Performans notları

- `createForUsers`: kullanıcı başına sıralı `create` + sıralı FCM — PLAN’daki `createMany`/`sendBatch` yerine; büyük duyurularda yavaşlayabilir
- Global rate limit 100/15dk — normal mobil kullanım için yeterli

---

## Frontend Analizi

> **Not:** Projede ayrı bir web frontend veya admin paneli **yok**. “Frontend” = Flutter mobil UI.

### Mevcut ekranlar (GoRouter + push)

| Ekran | Rol | API bağlı |
|-------|-----|-----------|
| Splash | Herkes | ✅ session restore |
| Login / Register / Join | Herkes | ✅ |
| Forgot / Reset password | Herkes | ✅ |
| Manager dashboard | MANAGER | ✅ (Faz 1) |
| Resident dashboard | RESIDENT | ✅ (aidat + talep sekmesi) |
| Add building, building residents, invite code | MANAGER | ✅ (Navigator.push) |

### Eksik ekranlar (Faz 2B+ / polish)

- Reports, subscription paywall
- Legal pages (privacy, KVKK, help) — ayarlarda toast
- Dekont upload UI

### Frontend / backend sözleşme uyumu

`ApiConstants` backend path’leriyle **uyumlu**; Faz 2 sabitleri **kullanımda**. Faz 1 login/register sözleşmesi `test.py` `FLUTTER_*_KEYS` ile doğrulanmış.

---

## Ticket / Arıza Talep Sistemi Durumu

### Backend — ✅ Tam

| Özellik | Durum |
|---------|--------|
| Sakin talep oluşturma | `POST /apartments/:id/tickets` |
| Sakin kendi talepleri | `GET /me/tickets` |
| Yönetici bina talepleri | `GET /buildings/:id/tickets` |
| Detay | `GET /tickets/:id` (manager veya sahip) |
| Yönetici not | `POST /tickets/:id/updates` |
| Durum geçişi | `PATCH /tickets/:id/status` — ileri-only makine |
| Bildirim | Not/durum değişince `TICKET_UPDATE` → DB + FCM |
| Yetki | Yanlış erişim → 404 |

### Mobile — ✅ Tam (Faz 2A kod)

- `ResidentTicketsTab`, `ManagerTicketsScreen`, `TicketDetailScreen`, `CreateTicketScreen`
- Rotalar: `/tickets/new`, `/tickets/:ticketId`, `/manager/tickets`
- `TICKET_CREATED` / `TICKET_UPDATE` deep link (`notification_payload.dart`)

### Database — ✅ Hazır

`Ticket`, `TicketUpdate` modelleri, enum’lar (`OPEN` → `CLOSED`), indeksler migration’da mevcut.

---

## Öncelik Sırasına Göre Yapılması Gerekenler

### P0 — Kritik (2026-05-20)

1. **Manuel E2E:** [`mobile/E2E_CHECKLIST.md`](mobile/E2E_CHECKLIST.md) — 2 hesap, gerçek cihaz / Play AVD
2. **iOS Firebase:** `flutterfire configure` → `GoogleService-Info.plist`
3. **`test.py` yerel:** `AIDATPANEL_API_BASE=http://127.0.0.1:4200/api/v1`

### P1 — Yüksek (2026-05-20)

6. ~~B4–B5 Faz 2A kod~~ ✅
7. **E2E checklist** — gerçek cihaz
8. **`PUT /me/language`** mobil senkronizasyonu (opsiyonel)
9. **UI tasarım polish**
10. **iOS** `GoogleService-Info.plist`

### P2 — Orta

11. **B6:** Unit/widget testler (notification_payload, dio refresh, dues)
12. **`strictLimiter`** forgot-password’a mount
13. **JWT role:** DB’den rol doğrulama (opsiyonel hardening)
14. **`authService.js`** dead code temizliği
15. **`docker-test.sh`** ekle veya test.py referansını güncelle

### P3 — Düşük / sonraki faz

16. Dekont upload + OCR (Faz 2B/2C)
17. RevenueCat + paywall (Faz 3)
18. Web landing page
19. PM2 deployment config
20. WhatsApp/SMS, PDF rapor

---

## Kritik Sorunlar

1. **Uçtan uca Faz 2A tamamlanmamış** — Backend hazır, mobil %0; kullanıcı talep/bildirim/gider kullanamaz.
2. **Firebase mobil tarafı sıfır** — Backend push altyapısı dev’de atlanıyor; prod’da mobil token olmadan push anlamsız.
3. **Sakin “Talepler” sekmesi yanıltıcı** — Uygulama özelliği var gibi görünüp boş metin gösteriyor.
4. **Git dal parçalanması** — `mobile/flutter` ve `backend/api` ayrı; tek workspace birleşimi commit edilmemiş, ekip karışıklığı riski.
5. **`test.py` varsayılan URL typo** — CI/local test env unutulursa sessiz fail.
6. **Production API hardcoded mobilde** — Yerel backend (4200) ile test zor; sadece `main_dev` mock veya manuel değişiklik.

---

## Önerilen Sonraki Adımlar

### Hemen (1–2 gün)

```bash
# 1. Dal durumunu netleştir
git add backend/ PLAN.md docker-compose.yml AIDATPANEL.md ...
git commit -m "chore: merge backend/api into mobile/flutter workspace"

# 2. test.py düzelt
# BASE default: https:// (küçük s)

# 3. Yerel E2E doğrula
cd backend && AIDATPANEL_API_BASE=http://127.0.0.1:4200/api/v1 python test.py
```

### Kısa vade (1–2 hafta) — PLAN B0–B5

1. ~~Faz 2A kod maddeleri~~ ✅ (2026-05-20)
2. E2E checklist tamamlama
3. UI tasarım polish

### Orta vade

- Gerçek cihazda FCM push E2E (PLAN B6 checklist 7 senaryo)
- RevenueCat + abonelik kilidi tasarımı
- Landing page + PM2 deploy
- Dekont/OCR faz planlaması

---

## Ek: Dokümantasyon ↔ Kod uyum matrisi

| AIDATPANEL.md maddesi | Backend | Mobil | Not |
|------------------------|---------|-------|-----|
| Auth + JWT + KVKK delete | ✅ | ✅ | |
| Bina/daire/davet/aidat | ✅ | ✅ | |
| Gider API | ✅ | ✅ | |
| Talep API | ✅ | ✅ | |
| Bildirim + duyuru + FCM | ✅ | ✅ kod · E2E 🔶 | |
| Firebase mobil init | — | ✅ | B0–B1 |
| Dekont/OCR | ⬜ | ⬜ | Şema hazır |
| Abonelik/RevenueCat | ⬜ | ⬜ | |
| Web landing | ⬜ | — | |
| docker-compose | ✅ | — | AIDATPANEL eski not “yok” diyor — **güncel değil** |
| i18n TR/EN | — | ✅ | Faz 2 Slang anahtarları eklendi (2026-05-20) |

---

## Ek: Teknik borç özeti

| Alan | Borç |
|------|------|
| Mobil | Faz 2B+ (`reports`, `subscription` iskelet); E2E cihaz doğrulaması |
| Mobil | Kalan `.gitkeep` dosyaları (temizlik opsiyonel) |
| Backend | `authService.js` dead code, `strictLimiter` unused |
| Backend | PLAN vs kod: `createMany`/`sendBatch` drift |
| Test | Mobil test coverage ~%5; backend `test.py` güçlü ama typo |
| DevOps | PM2, CI pipeline, docker-test script eksik |
| Docs | 2026-05-20 senkron; uzak dal ile yerel workspace farkı commit ile yönetilmeli |

---

*Son senkron: 2026-05-20 — tüm proje `.md` dosyaları kod tabanı ile hizalandı. Güncel gap: `FLUTTER_GAP_RAPORU.md`.*
