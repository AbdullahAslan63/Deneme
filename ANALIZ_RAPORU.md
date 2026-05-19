# AidatPanel — Kapsamlı Proje Analiz Raporu

> **Tarih:** 2026-05-19 (anlık görüntü)  
> **Kaynaklar:** `AIDATPANEL.md`, `PLAN.md`, `FLUTTER-BACKEND.md`, kod tabanı  
> **Güncel bütünlük indeksi:** [`DOKUMANTASYON.md`](DOKUMANTASYON.md)  
> **Mobil entegrasyon (AI/ekip):** [`FLUTTER_ENTEGRASYON_PLANI.md`](FLUTTER_ENTEGRASYON_PLANI.md) — **önce B-ANALYZE** (tasarım eksikleri bu rapora göre değil, o anki koda göre tespit edilir)

**Not:** Backend push A7–A12 (`PLAN_BACKEND_PUSH.md`) bu rapordan sonra tamamlandı; aşağıdaki “eksik push” maddeleri **güncel değilse** `DOKUMANTASYON.md` ve `test.py` (120 OK) esas alınır.

---

## Proje Genel Durumu

**AidatPanel**, Türk apartman/site yöneticileri için Flutter mobil + Node.js API + PostgreSQL tabanlı bir aidat yönetim platformudur. Proje üç Git dalında parçalı tutuluyor:

| Dal | İçerik |
|-----|--------|
| `main` | Yalnızca `AIDATPANEL.md` |
| [`backend/api`](https://github.com/AbdullahAslan63/Deneme/tree/backend/api) | Backend, `PLAN.md`, `docker-compose.yml`, güncel dokümantasyon |
| [`mobile/flutter`](https://github.com/AbdullahAslan63/Deneme/tree/mobile/flutter) | Flutter uygulaması |

Yerel workspace’te **her iki dal birleştirilmiş** durumda: `mobile/` + `backend/` aynı kök dizinde.

### Genel tamamlanma özeti

| Katman | Faz 1 (MVP) | Faz 2A (Gider/Talep/Bildirim) | Faz 2B+ |
|--------|-------------|-------------------------------|---------|
| **Backend API** | ✅ ~%100 | ✅ ~%100 | ⬜ Dekont, abonelik, rapor |
| **Database şema** | ✅ | ✅ (tablolar hazır) | Dekont/OCR alanları şemada, API yok |
| **Flutter mobil** | ✅ ~%90 | ⬜ ~%0 | ⬜ |
| **Firebase FCM (uçtan uca)** | ⬜ | Backend ✅ / Mobil ⬜ | — |
| **Web landing** | ⬜ | — | — |
| **Deployment (PM2/prod)** | ⬜ | — | — |

**Kritik bulgu:** Backend Faz 2A production-ready; Flutter Faz 2A **henüz başlamamış**. Dokümantasyon (`AIDATPANEL.md` + `PLAN.md`) ile backend kodu **yüksek uyumlu**; mobil kod ile dokümantasyon arasında **büyük gap** var.

### Çalışır durum doğrulaması

| Bileşen | Durum | Kanıt |
|---------|--------|-------|
| Backend sunucu | ✅ Çalışıyor | `npm run dev` → port 4200, DB bağlı |
| PostgreSQL | ✅ | `docker-compose.yml` (5433), Prisma migrate |
| Postman bildirim testleri | ✅ | Önceki oturum: register, FCM token, seed, read |
| `test.py` | ✅ | 120 OK (yerel: `AIDATPANEL_API_BASE=http://127.0.0.1:4200/api/v1`) |
| Flutter prod build | ⚠️ Faz 1 akışları | FCM/Faz 2 ekranları yok |
| Gerçek FCM push | ⬜ | `FIREBASE_SERVICE_ACCOUNT_JSON` + mobil init gerekli |

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
- Prisma 7 + PostgreSQL; migration’lar `backend/prisma/migrations/` (5 klasör, 2026-05-19)
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
- Talepler: **placeholder** (bkz. eksikler)
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
| `DUE_REMINDER`, `DUE_PAID` push | ✅ | ⬜ UI/deep link | 2A Flutter |
| Yeni talep → yönetici (`TICKET_CREATED`) | ✅ | ⬜ UI/deep link | 2A Flutter |

### PLAN.md Faz 2A — Flutter (B0–B6) — tamamı eksik

| Aşama | İçerik | Durum |
|-------|--------|-------|
| B0 | Firebase dosyaları, `flutterfire configure` | ⬜ |
| B1 | FCM çekirdek (`fcm_service`, token upload) | ⬜ |
| B2 | Bildirim feature (data + UI) | ⬜ |
| B3 | Talep feature (sakin + yönetici) | ⬜ |
| B4 | Gider feature | ⬜ |
| B5 | Dashboard entegrasyonu, `main_dev` mock | ⬜ |
| B6 | Flutter test & E2E checklist | ⬜ |

### Mobil spesifik eksikler

- Firebase init, push izinleri, foreground/background/tap handler
- `PUT /me/fcm-token` çağrısı (storage hazır, upload yok)
- Bildirim listesi ekranı, okundu badge, deep link
- Yönetici duyuru UI
- Talep listesi, oluşturma, detay, not, durum ekranları
- Gider listesi, form, aylık özet kartı
- `PUT /me/language` backend senkronizasyonu
- Gizlilik/KVKK/yardım sayfaları (coming soon toast)
- Sakin: ödeme yap, faturalarım, destek hızlı aksiyonları (no-op)
- İşlem geçmişi (her zaman boş → coming soon)
- Environment/flavor (`baseUrl` hardcoded production)
- `ApiConstants.notificationsReadAll` sabiti bile tanımlı değil

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

### Placeholder / sahte implementasyon envanteri

| Konum | Tür |
|-------|-----|
| `features/notifications/` (6 alt klasör) | `.gitkeep` iskelet |
| `features/tickets/` | `.gitkeep` iskelet |
| `features/expenses/` | `.gitkeep` iskelet |
| `features/reports/`, `subscription/` | `.gitkeep` iskelet |
| `resident_dashboard._buildIssuesTab()` | Yalnızca metin |
| `settings_tab` × 4 satır | `_showComingSoon()` toast |
| Sakin quick actions | `onTap: () {}` no-op |
| `widget_test.dart` | `expect(true, isTrue)` |
| `SecureStorage.saveFcmToken()` | Hiç çağrılmıyor |
| `firebase_core/messaging` pubspec | Import/init yok |

### TODO/FIXME taraması

`backend/src` ve `mobile/lib` içinde anlamlı `TODO`/`FIXME` **bulunamadı**. Eksiklikler açık placeholder ve boş klasörlerle görünür durumda.

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
│   ├── dashboard/     🔶 UI var, data/domain iskelet
│   ├── notifications/ ⬜ iskelet
│   ├── tickets/       ⬜ iskelet
│   ├── expenses/      ⬜ iskelet
│   ├── reports/       ⬜ iskelet
│   └── subscription/  ⬜ iskelet
├── shared/widgets/    ✅ settings, toast, empty state, error
└── dev/dev_mocks.dart ✅ Faz 1 mock’ları
```

### State management & routing

- **Riverpod:** `StateNotifier` + `Provider`; `riverpod_annotation` pubspec’te var, kodda kullanılmıyor
- **GoRouter:** 8 rota; alt ekranlar `Navigator.push` ile (tutarsız back stack)
- **Dio:** Bearer interceptor, 401’de refresh, ayrı `_refreshDio`

### API entegrasyon haritası

| ApiConstants grubu | Kullanılıyor | Kullanılmıyor |
|--------------------|--------------|---------------|
| Auth, buildings, apartments, dues, profile | ✅ | — |
| Expenses, tickets, notifications, fcmToken | — | ❌ |
| changeLanguage, subscription, reports | — | ❌ |

### Firebase / FCM durumu

| Bileşen | Durum |
|---------|--------|
| `pubspec.yaml` bağımlılıkları | ✅ tanımlı |
| `firebase_options.dart` | ❌ |
| `google-services.json` / iOS plist | ❌ |
| `Firebase.initializeApp()` | ❌ |
| Android POST_NOTIFICATIONS | ❌ |
| Token → backend upload | ❌ |

### UI/UX değerlendirmesi

**Güçlü yanlar:** Material 3, tutarlı renk/tipografi token’ları, TR/EN, loading/error state’leri (bina/aidat), KVKK hesap silme dialog

**Zayıf yanlar:**
- Sakin “Talepler” sekmesi kullanıcıya değer sunmuyor
- Ayarlarda 4 özellik “yakında” — güven eksikliği
- `issuesTab` metni geliştirici placeholder (“Arızalar Sekmesi”)
- Production API URL hardcoded — local backend test için `--dart-define` veya flavor yok
- Nunito font adı tanımlı, asset yok → sistem fontu

### Test durumu

| Dosya | Kapsam |
|-------|--------|
| `auth_validators_test.dart` | ✅ invite code validasyon |
| `widget_test.dart` | ⬜ anlamsız placeholder |

---

## Database Analizi

### Migration geçmişi

1. `20260510005756_init` — çekirdek modeller
2. `20260510023405_user_deleted_at_password_reset` — KVKK + şifre sıfırlama
3. `20260515120000_dekont_system` — Dekont, DuePayment, tahsilat alanları, bildirim enum genişlemesi

### Şema vs API uyumu

| Model | Şema | API | Mobil |
|-------|------|-----|-------|
| User (+ fcmToken, refreshTokenVersion, deletedAt) | ✅ | ✅ | 🔶 fcmToken alanı var, upload yok |
| Building (+ collectionIban alanları) | ✅ | ✅ CRUD | ✅ |
| Apartment (tek sakin @unique) | ✅ | ✅ | ✅ |
| Due (+ dueDate, overdueDays) | ✅ | ✅ | ✅ |
| Expense (+ receiptUrl) | ✅ | ✅ | ⬜ |
| Ticket + TicketUpdate | ✅ | ✅ | ⬜ |
| Notification (+ data Json) | ✅ | ✅ | ⬜ |
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
│   ├── services/            12+ servis (+ fcmTokenService WIP)
│   ├── middlewares/         auth, validate, rateLimit, error, role
│   ├── utils/               access, httpError, trDueDate, notificationPayload
│   ├── validators/          authValidator, notificationValidator
│   └── constants/           notificationConstants (WIP)
├── test.py                  # ~1300 satır smoke test
└── postman/                 # Notifications collection (WIP, untracked)
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

### Bildirim modülü (ek WIP)

Stash’ten geri gelen yerel iyileştirmeler (henüz commit edilmemiş):
- `notificationValidator.js`, `notificationConstants.js`, `notificationPayload.js`
- `fcmTokenService.js`, `notificationDemo.js`
- `POST /notifications/dev/seed` + `/_e2e/seed` geriye dönük uyumluluk
- Postman collection

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
| Resident dashboard | RESIDENT | 🔶 (aidat ✅, talep ⬜) |
| Add building, building residents, invite code | MANAGER | ✅ (Navigator.push) |

### Eksik ekranlar (dokümantasyon + PLAN)

- NotificationsScreen
- Ticket list / detail / create (sakin + yönetici)
- Expenses list / form / summary
- Manager announcement compose
- Reports, subscription paywall
- Legal pages (privacy, KVKK, help)

### Frontend / backend sözleşme uyumu

`ApiConstants` backend path’leriyle **uyumlu tanımlanmış** ancak Faz 2 sabitlerinin **%60’ı kullanılmıyor**. Flutter login/register response key’leri `test.py` içinde `FLUTTER_*_KEYS` ile doğrulanmış — **Faz 1 sözleşmesi sağlam**.

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

**Eksik (ürün):** Yeni talep açıldığında yönetici push — PLAN/AIDATPANEL’de zorunlu değil.

### Mobile — ⬜ Yok

- `features/tickets/` tamamen `.gitkeep`
- Sakin “Arızalar” sekmesi: `Center(child: Text(context.t.common.issuesTab))`
- GoRouter’da ticket rotası yok
- `myTickets`, `buildingTickets`, `ticket`, `ticketUpdates` — **sıfır kullanım**

### Database — ✅ Hazır

`Ticket`, `TicketUpdate` modelleri, enum’lar (`OPEN` → `CLOSED`), indeksler migration’da mevcut.

---

## Öncelik Sırasına Göre Yapılması Gerekenler

### P0 — Kritik (Faz 2A tamamlama)

1. **B0–B1:** Firebase Console + `flutterfire configure` + FCM token → `PUT /me/fcm-token`
2. **B2:** Bildirim listesi UI + okundu + ayarlardan gerçek ekrana geçiş
3. **B3:** Sakin talep sekmesi + yönetici talep yönetimi
4. **`test.py`:** Yerel koşumda `AIDATPANEL_API_BASE` env kullanın (120 OK doğrulandı)
5. **Dal birleştirme:** `mobile/` + `backend/` tek dalda commit (şu an staged/unstaged karışık)

### P1 — Yüksek

6. **B4:** Gider UI (yönetici)
7. **B5:** Dashboard kısayolları, duyuru UI, `main_dev` mock genişletme
8. **`ApiConstants.notificationsReadAll`** ekle ve B2’de kullan
9. **`PUT /me/language`** mobil senkronizasyonu
10. **Environment config:** dev/staging/prod `baseUrl` (flavor veya `--dart-define`)

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

1. Firebase projesi oluştur → Android/iOS config dosyaları
2. `core/notifications/fcm_service.dart` → login sonrası token upload
3. `NotificationsScreen` + provider → `GET/PATCH /notifications`
4. `ResidentTicketsTab` + `ManagerTicketsScreen` → ticket API
5. `ExpensesListScreen` → gider API
6. Yönetici duyuru bottom sheet → `POST .../announcements`
7. Slang: `features.notifications`, `features.tickets`, `features.expenses` anahtarları

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
| Gider API | ✅ | ⬜ | Faz 2A backend done |
| Talep API | ✅ | ⬜ | |
| Bildirim + duyuru + FCM | ✅ | ⬜ | |
| Firebase mobil init | — | ⬜ | PLAN B0–B1 |
| Dekont/OCR | ⬜ | ⬜ | Şema hazır |
| Abonelik/RevenueCat | ⬜ | ⬜ | |
| Web landing | ⬜ | — | |
| docker-compose | ✅ | — | AIDATPANEL eski not “yok” diyor — **güncel değil** |
| i18n TR/EN | — | ✅ | Faz 2 domain key’leri eksik |

---

## Ek: Teknik borç özeti

| Alan | Borç |
|------|------|
| Mobil | 5 boş feature modülü, kullanılmayan Firebase deps, unused pubspec codegen |
| Mobil | `.gitkeep` + gerçek dosya karışık klasörler |
| Backend | `authService.js` dead code, `strictLimiter` unused |
| Backend | PLAN vs kod: `createMany`/`sendBatch` drift |
| Test | Mobil test coverage ~%5; backend `test.py` güçlü ama typo |
| DevOps | PM2, CI pipeline, docker-test script eksik |
| Docs | Dal bazlı AIDATPANEL sürüm farkı; birleşik dal gerekli |

---

*Rapor: `AIDATPANEL.md`, `PLAN.md`, `FLUTTER-BACKEND.md`, backend route/service kaynak kodu, Prisma şema, Flutter `lib/` (~92 dart), git durumu ve çalışan dev sunucusu esas alınarak üretilmiştir.*
