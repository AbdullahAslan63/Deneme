# Yusuf — Bildirimler (Notifications) Checkpoint Rehberi

> **Proje:** AidatPanel  
> **Son güncelleme:** 2026-05-20 (mobil Faz 2A UI eklendi — bu dosyanın Flutter satırları güncellendi)  
> **Referans:** `AIDATPANEL.md` · `FLUTTER-BACKEND.md` · `backend/src/`  
> **API tabanı:** `http://127.0.0.1:4200/api/v1` (yerel)

---

## Tamamlanma durumu — özet

| Kapsam | Durum | Not |
|--------|-------|-----|
| **Backend REST API (Faz 2A)** | ✅ **Bitti** | AIDATPANEL.md § Notifications hedefleri karşılandı |
| **Postman manuel test (Yusuf)** | ✅ **Bitti** | 7/7 ana adım doğrulandı (aşağıda kayıt) |
| **Otomatik test (`test.py`)** | ✅ | 120 OK (Faz 2A+ push senaryoları dahil) |
| **Gerçek duyuru → sakin (Postman)** | 🔶 Opsiyonel | Klasör 3; backend + mobil kod hazır |
| **Firebase push (gerçek cihaz)** | 🔶 E2E | Dev'de `pushSkipped` normal; fiziksel cihaz gerekir |
| **Flutter bildirim ekranı** | ✅ Kod | `/notifications`, FCM scope — E2E: [`flutter/E2E_CHECKLIST.md`](../flutter/E2E_CHECKLIST.md) |
| **DUE_REMINDER / DUE_PAID / TICKET_CREATED push** | ✅ Backend | Mobil deep link ✅ kod; cihaz doğrulaması E2E |

**Sonuç:** Backend bildirim modülü **tamam**. Mobil Faz 2A **kod tamam** (2026-05-20); kalan: gerçek cihazda FCM + E2E işaretleme.

---

## Bu doküman ne?

Bildirim modülünün **kurulum → kod mimarisi → Postman testi → AIDATPANEL uyumu** adımlarını checkpoint checkpoint kaydeder.

---

## Checkpoint 0 — Ön koşullar ✅

| Gereksinim | Durum | Komut / Not |
|------------|-------|-------------|
| Docker Desktop açık | ✅ | Sistem tepsisinde balina ikonu |
| PostgreSQL container | ✅ | `docker compose up -d` (proje kökü) |
| Backend bağımlılıkları | ✅ | `cd backend && npm install` |
| Prisma client | ✅ | `npx prisma generate` (`postinstall` script eklendi) |
| DB migration | ✅ | `npx prisma migrate deploy` |
| API ayakta | ✅ | `npm run dev` → port **4200** |
| E2E / dev seed | ✅ | `.env` → `NODE_ENV=development` + `AIDATPANEL_E2E=1` |

---

## Checkpoint 1 — Bildirim sistemi mantığı (AIDATPANEL.md)

### Ne işe yarar?

Apartman yöneticisi ve sakinler uygulama içinde **bildirim kutusu** görür. Push (FCM) telefon bildirimi; in-app liste API üzerinden gelir.

### İki kanal

```
Olay (duyuru / talep güncellemesi)
        │
        ▼
┌───────────────────────┐
│ notificationService   │
│ createForUsers()      │
└───────────┬───────────┘
            │
     ┌──────┴──────┐
     ▼             ▼
 PostgreSQL      Firebase FCM
 Notification    (fcmToken varsa)
 tablosu         push gönder
```

| Kanal | Açıklama |
|-------|----------|
| **In-app (DB)** | Her olayda `Notification` kaydı oluşur — `GET /notifications` bunu döner |
| **Push (FCM)** | Kullanıcının `fcmToken`'ı varsa telefona push gider; yoksa atlanır (200 devam) |

Development'ta `FIREBASE_SERVICE_ACCOUNT_JSON` yoksa push **atlanır** — bu normal.

### Bildirim tipleri (`NotificationType`)

| Tip | Ne zaman oluşur? | Backend | Postman (Yusuf) |
|-----|------------------|---------|-----------------|
| `SYSTEM` | `POST /notifications/dev/seed` | ✅ | ✅ test edildi |
| `ANNOUNCEMENT` | Yönetici duyuru | ✅ kod | ⬜ sakin akışı opsiyonel |
| `TICKET_CREATED` | Sakin yeni talep | ✅ | ✅ `test.py` |
| `TICKET_UPDATE` | Talep notu / durum | ✅ | ✅ `test.py` |
| `DUE_REMINDER` | `POST .../dues/remind` | ✅ | ✅ `test.py` |
| `DUE_PAID` | Aidat `PAID` | ✅ | ✅ `test.py` |

---

## Checkpoint 2 — API uçları (AIDATPANEL ↔ gerçek path)

> AIDATPANEL.md'de `/api/...` yazıyor; gerçek prefix **`/api/v1`**.

| Method | Path | Rol | AIDATPANEL | Postman Yusuf |
|--------|------|-----|------------|---------------|
| `GET` | `/api/v1/notifications` | MANAGER, RESIDENT | ✅ | ✅ |
| `PATCH` | `/api/v1/notifications/:id/read` | Alıcı | ✅ | ✅ |
| `PATCH` | `/api/v1/notifications/read-all` | Alıcı | ✅ | ⬜ opsiyonel |
| `PUT` | `/api/v1/me/fcm-token` | MANAGER, RESIDENT | ✅ | ✅ |
| `POST` | `/api/v1/notifications/dev/seed` | Dev test | — | ✅ |

### Query parametreleri (`GET /notifications`)

| Param | Tip | Varsayılan | Açıklama |
|-------|-----|------------|----------|
| `unreadOnly` | `true` / `false` | — | Sadece okunmamışlar |
| `limit` | 1–50 | 20 | Sayfa boyutu |
| `cursor` | UUID | — | Sonraki sayfa (offset **yok**) |

### Postman ipucu — Body vs Response

| Bölüm | Ne işe yarar |
|-------|--------------|
| **Body (üst)** | Sunucuya **gönderdiğin** veri |
| **Response (alt)** | Sunucudan **gelen** yanıt |

GET ve PATCH read isteklerinde Body → **none**. Beklenen JSON'u Body'ye yapıştırma — Send sonrası altta gelir.

---

## Checkpoint 3 — Kod haritası (backend)

```
backend/src/
├── constants/notificationConstants.js
├── validators/notificationValidator.js
├── utils/notificationPayload.js
├── controllers/notificationController.js
├── services/
│   ├── notificationService.js
│   ├── fcmTokenService.js
│   ├── pushService.js
│   └── announcementService.js
├── routes/notificationRoutes.js
└── scripts/notificationDemo.js    → npm run demo:notifications
```

### Akış özeti

```
GET /notifications
  → authMiddleware → validate → notificationController
  → notificationService.listForUser → { items, nextCursor, unreadCount }

PUT /me/fcm-token
  → authMiddleware → validate → meController
  → fcmTokenService.saveFcmToken

POST /notifications/dev/seed
  → notificationService.seedDevNotification → createForUsers (SYSTEM)
```

**Güvenlik:** Yanıtta `fcmToken` **asla dönmez** (Flutter sözleşmesi).

---

## Checkpoint 4 — Veritabanı modeli ✅

Prisma `Notification` + `User.fcmToken` — migration uygulandı, Postman testleri DB'ye yazdı.

---

## Checkpoint 5 — Postman (Cursor eklentisi) ✅

### Import

`backend/postman/AidatPanel-Notifications.postman_collection.json`

### Collection Variables

| Variable | Değer |
|----------|--------|
| `baseUrl` | `http://127.0.0.1:4200/api/v1` |
| `managerEmail` | `yusuf.postman@test.local` |
| `managerPassword` | `Test123456` |
| `accessToken` | Login sonrası otomatik |
| `notificationId` | seed/list sonrası otomatik |

---

## Checkpoint 6 — Yusuf Postman test kaydı (2026-05-19) ✅

**Test hesabı:**
- Email: `yusuf.postman@test.local`
- User ID: `b9a96baf-7e75-4a29-8a3c-943556f962a4`
- Rol: `MANAGER`
- Telefon: `+905315635049`

| # | İstek | HTTP | Sonuç | Not |
|---|-------|------|-------|-----|
| 1 | Register Manager | 201 | ✅ | Hesap oluşturuldu |
| 2 | Login Manager | 200 | ✅ | `accessToken` alındı |
| 3 | PUT /me/fcm-token | 200 | ✅ | `"FCM token kaydedildi."` |
| 4 | GET /notifications | 200 | ✅ | `items: []`, `unreadCount: 0` |
| 5 | POST /notifications/dev/seed | 201 | ✅ | `dbCount: 1`, `pushSkipped: 1` |
| 6 | GET /notifications?unreadOnly=true | 200 | ✅ | `unreadCount: 1` |
| 7 | PATCH /notifications/:id/read | 200 | ✅ | `isRead: true` |

**Oluşturulan test bildirimi:**
- ID: `164c9bc9-1bb5-4ba3-983f-b5f8223ff2b5`
- Tip: `SYSTEM`
- Başlık: `AidatPanel test bildirimi`

**dev/seed yanıt özeti:**
```json
{
  "dbCount": 1,
  "pushSent": 0,
  "pushFailed": 0,
  "pushSkipped": 1
}
```
→ DB kaydı oluştu; Firebase yerelde kapalı olduğu için push atlandı — **beklenen davranış**.

**PATCH read yanıtı (doğrulandı):**
```json
{
  "success": true,
  "message": "Bildirim okundu olarak işaretlendi.",
  "data": { "isRead": true, "id": "164c9bc9-1bb5-4ba3-983f-b5f8223ff2b5", ... }
}
```

### Henüz Postman'de yapılmayan (opsiyonel)

| İstek | Amaç |
|-------|------|
| PATCH /notifications/read-all | Tümünü okundu işaretle |
| PATCH .../read (404) | Hatalı ID testi |
| Klasör 3 — duyuru → sakin | Gerçek `ANNOUNCEMENT` akışı |

---

## Checkpoint 7 — AIDATPANEL.md uyum kontrolü

### ✅ Backend'de tamamlanan (Faz 2A — senin kapsamın)

AIDATPANEL.md satır 389–397, 825, 970–975 ile uyumlu:

- [x] `GET /api/v1/notifications` (+ cursor, unreadOnly, limit)
- [x] `PATCH /api/v1/notifications/:id/read`
- [x] `PATCH /api/v1/notifications/read-all`
- [x] `PUT /api/v1/me/fcm-token`
- [x] `notificationService.createForUsers` (DB + FCM denemesi)
- [x] `pushService` + `firebase.js` (production zorunlu, dev atlanır)
- [x] Otomatik `ANNOUNCEMENT` (duyuru endpoint'i)
- [x] Otomatik `TICKET_UPDATE` (talep servisi)
- [x] Modüler `src/` yapısı (constants, validators, utils, services)

### Mobil ve doğrulama (2026-05-20 güncelleme)

| Madde | Durum |
|-------|--------|
| Flutter bildirim ekranı | ✅ `/notifications` + FCM (`mobile/lib/`) |
| Duyuru UI | ✅ `AnnouncementFormSheet` |
| `DUE_REMINDER` / `DUE_PAID` / `TICKET_CREATED` | ✅ Backend + mobil deep link kodu |
| Gerçek cihazda FCM push | 🔶 E2E: [`flutter/E2E_CHECKLIST.md`](../flutter/E2E_CHECKLIST.md) |
| WhatsApp / SMS hatırlatma | ⬜ Faz 3 |
| Production deploy (VPS) | ⬜ DevOps |

### Karar

**Backend bildirim API'si tamam.** **Mobil Faz 2A kod tamam** (2026-05-20). Kalan: gerçek cihazda push doğrulaması ve isteğe bağlı Postman duyuru→sakin senaryosu.

---

## Checkpoint 7B — Firebase (FCM) nasıl çalışıyor?

### Genel akış (uçtan uca)

```
┌─────────────────────────────────────────────────────────────┐
│  Olay: duyuru / talep güncellemesi / dev/seed                │
└──────────────────────────┬──────────────────────────────────┘
                           ▼
              notificationService.createForUsers()
                           │
              ┌────────────┴────────────┐
              ▼                         ▼
     PostgreSQL'e yaz              pushService.sendToToken()
     (Notification tablosu)              │
              │                         ▼
              │                   Firebase FCM → telefon
              ▼
     GET /notifications (in-app kutu)
```

| Kanal | Ne işe yarar | Şu an |
|-------|--------------|-------|
| **In-app (DB)** | Uygulama içi bildirim kutusu | ✅ Postman'de test edildi |
| **Push (FCM)** | Telefon bildirim çubuğu | ⏸ Yerelde kapalı (`pushSkipped`) |

### Adım adım

**1. Mobil uygulama token alır (Flutter — ✅ `fcm_service` + `PUT /me/fcm-token`)**
```
Telefon → Firebase SDK → fcmToken üretir
       → PUT /api/v1/me/fcm-token → backend DB'ye kaydeder
```
Postman'de sahte token (`ffff...`) kaydedildi — DB'de `User.fcmToken` dolu.

**2. Backend olay tetikler**  
Duyuru, talep güncellemesi veya `dev/seed` → `createForUsers()` çalışır.

**3. Her kullanıcı için sıra:**
```
1. Notification kaydı DB'ye yazılır     ← her zaman
2. Kullanıcının fcmToken'ı var mı?        ← Postman'de var
3. Firebase Admin SDK hazır mı?          ← development'ta genelde HAYIR
4. pushService.sendToToken() çağrılır
```

**4. `pushSkipped: 1` ne demek?**

```json
{
  "dbCount": 1,
  "pushSent": 0,
  "pushFailed": 0,
  "pushSkipped": 1
}
```

| Alan | Anlam |
|------|--------|
| `dbCount: 1` | Bildirim veritabanına yazıldı ✅ |
| `pushSent: 0` | Telefona push gitmedi |
| `pushSkipped: 1` | Firebase yerelde kapalı — **normal, hata değil** |

Backend logu (development):
```
[firebase] FIREBASE_SERVICE_ACCOUNT_JSON tanımlı değil — push devre dışı (development).
[push] Firebase hazır değil — gönderim atlandı.
```

### Kod tarafı (hazır)

| Dosya | Görev |
|-------|--------|
| `backend/index.js` | `initFirebase()` — sunucu başlarken |
| `backend/src/config/firebase.js` | Admin SDK başlatma |
| `backend/src/services/pushService.js` | `sendToToken()`, `sendToUser()` |
| `backend/src/services/fcmTokenService.js` | Token kaydet / geçersiz token temizle |
| `backend/src/utils/notificationPayload.js` | FCM `data` payload (tüm değerler string) |

**Production kuralı:** `FIREBASE_SERVICE_ACCOUNT_JSON` yoksa sunucu **başlamaz**.  
**Development kuralı:** Env yoksa push atlanır, API ve DB kaydı **normal çalışır**.

### FCM `data` payload sözleşmesi (AIDATPANEL.md)

Tüm değerler **string** olmalı:

| Anahtar | Örnek | Açıklama |
|---------|--------|----------|
| `type` | `TICKET_UPDATE` | Bildirim tipi |
| `notificationId` | UUID | Okundu işaretleme için |
| `ticketId` | UUID | Talep ekranına git (varsa) |
| `buildingId` | UUID | Bina bağlamı |
| `route` | `/resident-dashboard` | GoRouter hedefi (opsiyonel) |

### Firebase'i şimdi açabilir miyiz?

| Senaryo | Yapılabilir mi? | Not |
|---------|-----------------|-----|
| Backend'e service account ekle | ✅ Evet | Firebase Console → JSON → `.env` |
| Postman sahte token ile gerçek push | ❌ Hayır | `ffff...` geçerli FCM token değil → `pushFailed` |
| Gerçek telefona push | 🔶 E2E checklist | `firebase_messaging` + Play AVD veya fiziksel cihaz |
| In-app bildirim (DB) Firebase'siz | ✅ Evet | Zaten çalışıyor |

**Backend Firebase açma (kısmi test):**

1. [Firebase Console](https://console.firebase.google.com) → proje oluştur
2. Project Settings → Service accounts → Generate new private key
3. `backend/.env`:
```env
FIREBASE_SERVICE_ACCOUNT_JSON='{"type":"service_account","project_id":"...",...}'
```
4. `npm run dev` → log: `[firebase] Admin SDK başlatıldı.`

Gerçek push için ayrıca Flutter (`flutterfire configure`, login sonrası token upload) ve fiziksel cihaz gerekir — AIDATPANEL.md § Faz 2A Flutter B0–B1.

---

## Checkpoint 7C — Backend için kalan iş var mı?

### Kısa cevap

**Hayır — bildirim için backend Faz 2A kapsamında kod yazılacak bir şey kalmadı.**

AIDATPANEL.md satır 825, 846:
> Bildirim listesi + okundu + yönetici duyuru + FCM — **Faz 2A backend ✅**

### Tamamlanan backend özellikleri

| Özellik | Durum |
|---------|--------|
| `GET /api/v1/notifications` (+ cursor, unreadOnly, limit) | ✅ |
| `PATCH /notifications/:id/read` | ✅ |
| `PATCH /notifications/read-all` | ✅ |
| `PUT /me/fcm-token` | ✅ |
| `notificationService.createForUsers` | ✅ |
| `pushService` + `firebase.js` | ✅ |
| Duyuru → `ANNOUNCEMENT` otomatik | ✅ |
| Talep → `TICKET_UPDATE` otomatik | ✅ |
| `POST /notifications/dev/seed` | ✅ |
| Modüler `src/` yapısı | ✅ |

### Faz 2A dışında kalan (backend kod yazılmadı / gelecek)

| Konu | Faz | Backend kod? |
|------|-----|--------------|
| `DUE_REMINDER` / `DUE_PAID` / `TICKET_CREATED` | Faz 2A+ push | ✅ |
| Dekont bildirimleri (`DEKONT_*`) | Faz 2B | ❌ |
| WhatsApp / SMS hatırlatma | Faz 2 | ❌ |
| Production `.env` Firebase JSON | Deploy | ⚙️ Konfigürasyon |
| Flutter bildirim ekranı | Mobil | — (backend değil) |

### Opsiyonel — kod yazmadan yapılabilecekler

| İş | Amaç |
|----|------|
| Postman Klasör 3 (duyuru → sakin) | Gerçek `ANNOUNCEMENT` akışı test |
| `PATCH read-all` Postman testi | Son endpoint doğrulama |
| `python test.py` | Otomatik smoke (ticket + duyuru dahil) |
| Firebase Console + `.env` | Backend push denemesi (Flutter olmadan kısmi) |

### Final durum özeti

```
Backend bildirim API (Faz 2A)     →  ✅ Bitti
Yusuf Postman ana akış (7 adım)   →  ✅ Bitti
Flutter bildirim + FCM kodu       →  ✅ mobile/lib (2026-05-20)
Firebase gerçek push (cihaz)        →  🔶 E2E checklist + Firebase Console
Aidat hatırlatma push (backend)   →  ✅ Kod; mobil deep link ✅
```

---

## Checkpoint 8 — Hata kodları

| HTTP | Mesaj | Ne zaman? |
|------|-------|-----------|
| 401 | Token gerekli | JWT yok / süresi doldu → Login tekrar |
| 400 | JSON parse / geçersiz cursor | Body'ye hatalı JSON yapıştırma |
| 404 | Bildirim bulunamadı | Yanlış notification ID |
| 429 | Rate limit | Çok fazla istek |

---

## Checkpoint 9 — Otomatik test (opsiyonel)

```powershell
cd backend
$env:AIDATPANEL_API_BASE = "http://127.0.0.1:4200/api/v1"
$env:AIDATPANEL_E2E = "1"
python test.py
```

veya:

```powershell
npm run demo:notifications
```

---

## Checkpoint 10 — Sıradaki adımlar

| Öncelik | İş | Kim | Backend kod? |
|---------|-----|-----|--------------|
| 1 | Postman klasör 3 — duyuru → sakin bildirimi | Yusuf | ❌ Kod hazır, sadece test |
| 2 | `PATCH read-all` Postman testi | Yusuf | ❌ Kod hazır |
| 3 | `python test.py` smoke test | Yusuf | ❌ Kod hazır |
| 4 | E2E checklist (FCM + 2 hesap) | Mobil + Yusuf | [`flutter/E2E_CHECKLIST.md`](../flutter/E2E_CHECKLIST.md) |
| 5 | Firebase Console + gerçek FCM test | Mobil + `.env` | Konfigürasyon |
| 6 | Production VPS deploy | DevOps | Deploy |

**Backend bildirim modülü için yeni kod yazma önceliği yok.**

---

## Özet tablo (güncel)

| Özellik | Backend kod | AIDATPANEL | Postman Yusuf |
|---------|-------------|------------|---------------|
| GET /notifications | ✅ | ✅ | ✅ |
| PATCH .../read | ✅ | ✅ | ✅ |
| PATCH read-all | ✅ | ✅ | ✅ kod |
| PUT /me/fcm-token | ✅ | ✅ | ✅ |
| dev/seed | ✅ | — | ✅ |
| FCM push (kod) | ✅ | ✅ | ⏸ yerelde pushSkipped normal |
| Duyuru → ANNOUNCEMENT | ✅ | ✅ | 🔶 Postman opsiyonel |
| Talep → TICKET_UPDATE | ✅ | ✅ | ✅ test.py |
| Flutter UI | — | ✅ | E2E 🔶 |

---

## Dosya referansları

| Dosya | Amaç |
|-------|------|
| `backend/postman/AidatPanel-Notifications.postman_collection.json` | Postman collection |
| `backend/src/config/firebase.js` | Firebase Admin SDK init |
| `backend/src/services/pushService.js` | FCM push gönderim |
| `backend/src/services/fcmTokenService.js` | Token kayıt / temizleme |
| `backend/src/services/notificationService.js` | Ana iş mantığı |
| `backend/src/routes/notificationRoutes.js` | Route tanımları |
| `backend/src/scripts/notificationDemo.js` | `npm run demo:notifications` |
| `backend/test.py` | Otomatik smoke test |
| `AIDATPANEL.md` § Notifications, § FCM, § Faz 2A | Proje master referans |
| `FLUTTER-BACKEND.md` §4 | Flutter entegrasyon sözleşmesi |

---

*Son güncelleme: 2026-05-20 — Mobil Faz 2A UI ile uyumlu; Postman kayıtları korundu.*
