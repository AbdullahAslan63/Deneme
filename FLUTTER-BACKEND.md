# AidatPanel — Flutter ↔ Backend Entegrasyon Rehberi (Faz 2A)

> **Amaç:** Arıza/talep, gider ve bildirim özelliklerini Flutter’da uygularken backend sözleşmesine **birebir** uyum.  
> **Hedef kitle:** Mobil geliştirici + yapay zeka analizi (bu dosyayı tek kaynak kabul edin).  
> **Backend referans:** `backend/src/`, `backend/prisma/schema.prisma`, `backend/test.py`  
> **Plan:** [`PLAN.md`](PLAN.md) Bölüm B (B0–B6) · Özet: [`AIDATPANEL.md`](AIDATPANEL.md)

**Son senkron:** Backend Faz 2A (A0–A6) tamamlandı · API tabanı: `/api/v1`

---

## 0. Altın kurallar (zorunlu)

1. **Backend tek doğruluk kaynağıdır.** Bu dosyada veya tasarımda yer alan ancak aşağıdaki endpoint/JSON örneklerinde **olmayan** alanları modele, UI’ya veya mock’a **eklemeyin**.
2. **Prisma şemasında olup API’de dönmeyen alanları kullanmayın** (ör. `User.fcmToken` yanıtta asla gelmez; `Expense.building` nesnesi liste yanıtında yok).
3. **Henüz implemente edilmeyen backend özelliklerini UI’da “hazır” göstermeyin:** dekont upload, `receiptUrl` dosya seçici (yalnızca HTTPS URL string), RevenueCat kilidi, aidat push (`DUE_PAID` / `DUE_REMINDER`), WhatsApp/SMS, PDF rapor, bildirim **offset** sayfalama.
4. **Enum değerleri** yalnızca backend’in kabul ettiği string’ler; ek değer uydurmayın.
5. **Tutar alanları:** Gider `amount` ve özet `totalAmount` / `byCategory[].amount` API’de **string** gelir (`"1250.50"`). Parse ederken `double.tryParse` kullanın; gönderirken gider create/update body’de **number** (JSON float) gönderin.
6. **Tarih alanları:** İstek gövdelerinde **ISO 8601** (`2026-05-15T10:00:00.000Z`). Yanıtlarda `createdAt`, `updatedAt`, `date` ISO string.
7. **Yetki:** Çapraz bina/daire erişiminde backend çoğunlukla **404** döner (enumeration önleme). Sakin, yönetici bina uçlarına **403** alır (`buildingRoutes` tamamı `MANAGER`).
8. **Hata mesajları:** `message` Türkçe; kullanıcıya `ApiException` ile gösterin (mevcut Dio katmanı).

---

## 1. Genel API sözleşmesi

| Özellik | Değer |
|--------|--------|
| Base URL (prod) | `https://api.aidatpanel.com/api/v1` |
| Base URL (yerel) | `http://127.0.0.1:4200/api/v1` |
| Auth | `Authorization: Bearer <accessToken>` |
| Başarı gövdesi | `{ "success": true, "message"?: string, "data": ... }` |
| Hata gövdesi | `{ "success": false, "message": string, "errors"?: [{ field, message }] }` (Zod 400) |
| Roller | `MANAGER` \| `RESIDENT` (JWT içinde) |

**Mount sırası** (`backend/index.js` — path çakışması yok):  
`notifications` → `tickets` → `apartments/:apartmentId/tickets` → `expenses` → `auth` → `buildings` → … → `me`

---

## 2. Ortak veri tipleri

### 2.1 `PublicUser` (gömülü kullanıcı)

Talep listesi/detayında `createdBy`, `resident` olarak döner. **Yalnızca şu alanlar:**

```json
{
  "id": "uuid",
  "email": "string",
  "name": "string",
  "role": "MANAGER | RESIDENT",
  "phone": "string | null",
  "language": "tr | en",
  "apartmentId": "uuid | null",
  "createdAt": "ISO-8601",
  "updatedAt": "ISO-8601"
}
```

`passwordHash`, `refreshTokenVersion`, `fcmToken`, `deletedAt` **yanıtta yok.**

### 2.2 `ApartmentSummary` (talep içinde)

```json
{
  "id": "uuid",
  "number": "1A",
  "floor": 1,
  "buildingId": "uuid"
}
```

### 2.3 Bildirim `data` (JSON, opsiyonel)

Backend `Notification.data` Prisma `Json?`. Faz 2A push + DB için örnek içerik:

| `type` | `data` anahtarları (hepsi string FCM’de; DB’de karışık tip olabilir) |
|--------|---------------------------------------------------------------------|
| `TICKET_UPDATE` | `ticketId`, `buildingId`, `status`, `route` (ör. `"/resident-dashboard"`) |
| `ANNOUNCEMENT` | `buildingId`, `route` |
| `SYSTEM` | E2E only; örn. `route` |

**Faz 2A’da oluşmayan tipler** (enum’da var, API üretmez): `DUE_REMINDER`, `DUE_PAID`, `DEKONT_*`. Listede görünürse genel bildirim olarak gösterin; özel ekran bağlamayın.

---

## 3. FCM ve token (B0–B1 ön koşul)

### 3.1 Token kaydı

| Method | Path | Rol | Body |
|--------|------|-----|------|
| PUT | `/me/fcm-token` | MANAGER, RESIDENT | `{ "fcmToken": string }` (10–4096 karakter) |

**Yanıt:** `{ success, message?, data: <PublicUser güncellenmiş> }` — `fcmToken` döndürülmez.

**Öneri:** Login/join sonrası + `FirebaseMessaging.instance.onTokenRefresh` → `PUT /me/fcm-token`. Logout’ta backend’de token temizleme endpoint’i **yok**; boş string göndermeyin.

### 3.2 FCM `data` payload (push)

Tüm değerler **string**. Backend `notificationService.buildPushData`:

| Anahtar | Zorunlu | Açıklama |
|---------|---------|----------|
| `type` | Evet | `TICKET_UPDATE`, `ANNOUNCEMENT`, … |
| `notificationId` | Evet | DB bildirim id |
| `ticketId` | Talep bildirimlerinde | Deep link |
| `buildingId` | Çoğu olayda | Bağlam |
| `status` | Opsiyonel | Talep durumu |
| `route` | Opsiyonel | GoRouter yolu (ör. `/resident-dashboard`) |

**Tap yönlendirme önerisi:**

- `TICKET_UPDATE` + `ticketId` → `/tickets/:ticketId` (veya dashboard alt rota)
- `ANNOUNCEMENT` → bildirim listesi veya `route`
- `notificationId` ile liste senkronu: `GET /notifications` sonra okundu işaretle

**Development:** `FIREBASE_SERVICE_ACCOUNT_JSON` yoksa push atlanır; in-app bildirim yine oluşur.

---

## 4. Bildirimler API

### 4.1 Endpoint’ler

| Method | Path | Rol | Query / Body |
|--------|------|-----|----------------|
| GET | `/notifications` | MANAGER, RESIDENT | `unreadOnly=true\|false`, `limit` 1–50 (varsayılan 20), `cursor` uuid |
| PATCH | `/notifications/:id/read` | Alıcı (JWT user) | — |
| PATCH | `/notifications/read-all` | Alıcı | — |

**E2E only (mobil üretimde kullanmayın):** `POST /notifications/_e2e/seed` — `AIDATPANEL_E2E=1` sunucu env.

### 4.2 `GET /notifications` yanıtı

```json
{
  "success": true,
  "data": {
    "items": [
      {
        "id": "uuid",
        "userId": "uuid",
        "title": "string",
        "body": "string",
        "type": "TICKET_UPDATE | ANNOUNCEMENT | SYSTEM | ...",
        "isRead": false,
        "data": { "ticketId": "...", "buildingId": "...", "status": "IN_PROGRESS", "route": "/resident-dashboard" },
        "createdAt": "ISO-8601"
      }
    ],
    "nextCursor": "uuid | null",
    "unreadCount": 3
  }
}
```

**Sayfalama:** `nextCursor` doluysa bir sonraki istek: `?cursor=<nextCursor>&limit=20`. **Offset yok.**

### 4.3 Okundu

- `PATCH /notifications/:id/read` → `data` = güncellenmiş bildirim kaydı (`isRead: true`).
- `PATCH /notifications/read-all` → `data: { "updated": number }`.

**404:** Başka kullanıcının bildirimi veya geçersiz id.

---

## 5. Talepler (Ticket) API

### 5.1 Endpoint özeti

| Method | Path | Rol | Açıklama |
|--------|------|-----|----------|
| GET | `/me/tickets` | RESIDENT | Kendi talepleri; query: `status`, `category` |
| GET | `/buildings/:buildingId/tickets` | MANAGER | Bina talepleri; query: `status`, `category` |
| GET | `/tickets/:ticketId` | MANAGER veya talep sahibi | Detay + `updates[]` |
| POST | `/apartments/:apartmentId/tickets` | RESIDENT | Yeni talep (`apartmentId` = kullanıcının dairesi) |
| POST | `/tickets/:ticketId/updates` | MANAGER | Not ekle → sakin `TICKET_UPDATE` |
| PATCH | `/tickets/:ticketId/status` | MANAGER | Durum değiştir → uygun durumda `TICKET_UPDATE` |

**Yok (kullanmayın):** Talep silme, sakin notu, dosya eki, atanan teknisyen alanı, öncelik skoru.

### 5.2 Enum’lar

**`TicketCategory`:** `COMPLAINT` | `REQUEST` | `MALFUNCTION` | `OTHER`

**`TicketStatus`:** `OPEN` | `IN_PROGRESS` | `RESOLVED` | `CLOSED`

**Durum geçişleri (yalnızca ileri):**

```
OPEN         → IN_PROGRESS | RESOLVED | CLOSED
IN_PROGRESS  → RESOLVED | CLOSED
RESOLVED     → CLOSED
CLOSED       → (yok)
```

**İş kuralları:**

- Not (`POST .../updates`): yalnızca `OPEN` veya `IN_PROGRESS`. Aksi **409**.
- `CLOSED` sonrası status PATCH **409**.
- Geçersiz geçiş **400** (`Geçersiz durum geçişi.`).
- Sakin başka dairede talep açarsa **403**.

### 5.3 Talep oluşturma

`POST /apartments/:apartmentId/tickets`

```json
{
  "title": "string (1-120)",
  "description": "string (1-2000)",
  "category": "MALFUNCTION"
}
```

**201 `data` — liste satırı formatı (`formatTicketRow`):**

```json
{
  "id": "uuid",
  "apartmentId": "uuid",
  "userId": "uuid",
  "title": "string",
  "description": "string",
  "category": "MALFUNCTION",
  "status": "OPEN",
  "createdAt": "ISO-8601",
  "updatedAt": "ISO-8601",
  "apartmentNumber": "1A",
  "apartment": { "id", "number", "floor", "buildingId" },
  "resident": { /* PublicUser */ },
  "createdBy": { /* PublicUser */ }
}
```

**Not:** Liste uçlarında `updates` **döndürülmez.** Detay için `GET /tickets/:id`.

### 5.4 Talep detayı

`GET /tickets/:ticketId` — yukarıdaki alanlar +:

```json
{
  "updates": [
    {
      "id": "uuid",
      "ticketId": "uuid",
      "message": "string",
      "fromRole": "MANAGER",
      "createdAt": "ISO-8601"
    }
  ]
}
```

Faz 2A’da `fromRole` pratikte yalnızca `MANAGER` (sakin not endpoint’i yok).

### 5.5 Yönetici notu

`POST /tickets/:ticketId/updates` — `{ "message": "string (1-2000)" }`

**Önemli — yanıt şekli tutarsız:** Bu uç ham Prisma ticket döner (`formatTicketRow` **değil**). `data` içinde `updates` dizisi vardır; `apartmentNumber`, `createdBy`, `resident` **olmayabilir**.

**Flutter önerisi:** Başarı sonrası `GET /tickets/:ticketId` ile detayı yeniden yükleyin.

### 5.6 Durum güncelleme

`PATCH /tickets/:ticketId/status` — `{ "status": "IN_PROGRESS" }`

**200 `data`:** `formatTicketRow` (liste ile aynı alan seti, `updates` yok).

Bildirim metinleri (backend sabit) — sakin push/in-app:

| Yeni durum | title (örnek) |
|------------|----------------|
| IN_PROGRESS | Talebiniz inceleniyor |
| RESOLVED | Talebiniz çözüldü |
| CLOSED | Talebiniz kapatıldı |

Not eklendiğinde: `Talebiniz güncellendi` + mesaj özeti.

---

## 6. Giderler (Expense) API

### 6.1 Endpoint özeti

| Method | Path | Rol |
|--------|------|-----|
| GET | `/buildings/:buildingId/expenses` | MANAGER |
| GET | `/buildings/:buildingId/expenses/summary` | MANAGER |
| POST | `/buildings/:buildingId/expenses` | MANAGER |
| PUT | `/expenses/:expenseId` | MANAGER (bina sahibi) |
| DELETE | `/expenses/:expenseId` | MANAGER — **kalıcı silme** |

**Sakin `GET /buildings/.../expenses` → 403** (route seviyesinde MANAGER).

### 6.2 Enum `ExpenseCategory`

`CLEANING` | `ELEVATOR` | `ELECTRICITY` | `WATER` | `INSURANCE` | `REPAIR` | `GARDEN` | `OTHER`

### 6.3 Liste

`GET /buildings/:buildingId/expenses?month=&year=&category=`

- `month` + `year` birlikte: o ay filtre
- yalnızca `year`: o yıl
- `category`: enum

**`data`:** dizi, `date` desc:

```json
{
  "id": "uuid",
  "buildingId": "uuid",
  "title": "string",
  "amount": "1250.50",
  "category": "ELEVATOR",
  "date": "ISO-8601",
  "note": "string | null",
  "receiptUrl": "https://... | null",
  "createdAt": "ISO-8601"
}
```

`building` nesnesi **yok.**

### 6.4 Özet

`GET /buildings/:buildingId/expenses/summary?month=5&year=2026`  
**`month` ve `year` zorunlu** (yoksa 400).

```json
{
  "success": true,
  "data": {
    "month": 5,
    "year": 2026,
    "totalAmount": "1250.50",
    "currency": "TRY",
    "byCategory": [
      { "category": "ELEVATOR", "amount": "1250.50", "count": 1 }
    ]
  }
}
```

### 6.5 Oluşturma / güncelleme

**POST body:**

```json
{
  "title": "string (1-200)",
  "amount": 1250.5,
  "category": "ELEVATOR",
  "date": "2026-05-15T10:00:00.000Z",
  "note": "opsiyonel, max 500",
  "receiptUrl": "https://example.com/f.pdf"
}
```

`receiptUrl`: opsiyonel, **HTTPS URL**, max 2048, `null` gönderilebilir. **Dosya upload yok.**

**PUT** `/expenses/:expenseId` — kısmi alanlar; en az bir alan zorunlu. `note` / `receiptUrl` `null` ile temizlenebilir.

**DELETE** → `data: { "id": "uuid" }`

**404:** Başka yöneticinin gideri veya bina.

---

## 7. Yönetici duyurusu

| Method | Path | Rol | Body |
|--------|------|-----|------|
| POST | `/buildings/:buildingId/announcements` | MANAGER | `{ "title": "1-120", "body": "1-2000" }` |

**201 `data`:**

```json
{
  "created": 2,
  "pushSent": 1,
  "pushFailed": 0
}
```

- `created`: DB’ye yazılan bildirim sayısı (binadaki aktif sakinler: `deletedAt` null, `apartmentId` dolu).
- `pushSent` / `pushFailed`: FCM sonuçları; token yoksa `pushSent` 0 olabilir.

**Alıcılar:** Binadaki tüm aktif sakinler. Tip: `ANNOUNCEMENT`.

**Ayrı “duyuru listesi” endpoint’i yok** — duyurular sakin/yönetici `GET /notifications` içinde görünür.

---

## 8. HTTP durum kodları (Faz 2A)

| Kod | Ne zaman |
|-----|----------|
| 200 | Başarılı GET/PATCH |
| 201 | Oluşturma |
| 400 | Zod / geçersiz geçiş |
| 401 | JWT yok/geçersiz |
| 403 | Rol yetersiz (ör. sakin bina listesi) |
| 404 | Kayıt yok veya yetkisiz (gider/talep/bina) |
| 409 | Talep CLOSED / not eklenemez |
| 429 | Rate limit |

---

## 9. Flutter `ApiConstants` eşlemesi

Mevcut mobil sabitler (`mobile/lib/core/constants/api_constants.dart`) backend ile **path birebir** olmalı. Önerilen şablon:

```dart
// Base: .../api/v1
static const notifications = '/notifications';
static const notificationRead = '/notifications'; // + '/$id/read'
static const notificationsReadAll = '/notifications/read-all';

static const myTickets = '/me/tickets';
static String buildingTickets(String buildingId) =>
    '/buildings/$buildingId/tickets';
static String apartmentTickets(String apartmentId) =>
    '/apartments/$apartmentId/tickets';
static String ticket(String ticketId) => '/tickets/$ticketId';
static String ticketUpdates(String ticketId) =>
    '/tickets/$ticketId/updates';
static String ticketStatus(String ticketId) =>
    '/tickets/$ticketId/status';

static String buildingExpenses(String buildingId) =>
    '/buildings/$buildingId/expenses';
static String buildingExpensesSummary(String buildingId) =>
    '/buildings/$buildingId/expenses/summary';
static String expense(String expenseId) => '/expenses/$expenseId';

static String buildingAnnouncements(String buildingId) =>
    '/buildings/$buildingId/announcements';

static const fcmToken = '/me/fcm-token';
```

Path’leri repodaki gerçek dosyayla diff edin; sapma varsa **backend’e göre** düzeltin.

---

## 10. Önerilen Flutter mimarisi

Mevcut proje: Clean Architecture + Riverpod + Dio + GoRouter + Slang.

### 10.1 Klasör yapısı (PLAN B2–B4)

```
mobile/lib/
├── core/notifications/
│   ├── firebase_bootstrap.dart
│   ├── fcm_service.dart
│   └── notification_payload.dart   # FCM data → typed + route
├── features/notifications/
│   ├── data/models/notification_model.dart
│   ├── data/datasources/notification_remote_datasource.dart
│   ├── data/repositories/notification_repository_impl.dart
│   └── presentation/...
├── features/tickets/
│   └── ... (aynı katmanlar)
└── features/expenses/
    └── ... (aynı katmanlar)
```

`freezed` zorunlu değil; mevcut aidat modelleri gibi manuel `fromJson` yeterli.

### 10.2 Model kuralları

| Model | Alanlar |
|-------|---------|
| `NotificationModel` | `id`, `userId`, `title`, `body`, `type`, `isRead`, `data` → `Map<String, dynamic>?`, `createdAt` |
| `NotificationListPage` | `items`, `nextCursor`, `unreadCount` |
| `TicketModel` | Bölüm 5.3 alanları; `updates` nullable liste |
| `TicketUpdateModel` | `id`, `ticketId`, `message`, `fromRole`, `createdAt` |
| `ExpenseModel` | Bölüm 6.3; `amount` → `String` veya parse edilmiş `Decimal` wrapper |
| `ExpenseSummaryModel` | Bölüm 6.4 |

**Eklemeyin:** `priority`, `assignedTo`, `attachments[]`, `readBy`, `deletedAt` (expense), `announcementId` ayrı tablo.

### 10.3 Provider / akış önerileri

| Özellik | Öneri |
|---------|--------|
| Bildirim listesi | `AsyncNotifier` + cursor load more |
| Okunmamış badge | `unreadCount` veya liste sonrası local decrement |
| Talep detay | `ticketId` route param; pull-to-refresh |
| Yönetici talep | Seçili `buildingId` (mevcut bina seçim state’inden) |
| Gider özeti | Ay/yıl seçici → summary + liste aynı ay |
| Duyuru | Modal form → POST announcement → snack + (opsiyonel) sakin tarafında test |

---

## 11. UI / UX rehberi (mevcut tasarım sistemi)

Kaynak: `AIDATPANEL.md` — `AppColors`, `AppTypography`, `AppSizes`.

### 11.1 Yerleşim

| Rol | Özellik | Önerilen giriş |
|-----|---------|----------------|
| Sakin | Talepler | `resident_dashboard` — **placeholder kaldır** → gerçek liste + FAB “Yeni talep” |
| Sakin | Bildirimler | Ayarlar → Bildirimler ekranı; badge `unreadCount` |
| Yönetici | Talepler | Bina bağlamı: `building_residents` veya bina kartından “Talepler” |
| Yönetici | Giderler | Bina detayı / Binalar sekmesi alt menü “Giderler” |
| Yönetici | Duyuru | Bina bağlamında “Duyuru gönder” (form: başlık + metin) |

**Yeni alt tab açmayın** (mevcut 4 sekme korunur); özellikler sekme içi veya bina detayından erişilir.

### 11.2 Bileşen önerileri

| Bileşen | Spesifikasyon |
|---------|----------------|
| Liste satırı | Min yükseklik `AppSizes.listItemHeight` (72); başlık `body2`, alt satır `caption` |
| Durum chip’i | `OPEN` → `info` / `warningBg`; `IN_PROGRESS` → `warning`; `RESOLVED` → `success`; `CLOSED` → `textSecondary` |
| Kategori | Slang etiketi; ikon opsiyonel (backend ikon göndermez) |
| Birincil CTA | `ElevatedButton` 56dp, `AppColors.primary` |
| Tehlike | Sil (gider) → onay dialog; `AppColors.error` |
| Boş durum | İllüstrasyon şart değil; net Türkçe/İngilizce metin (Slang) |
| Hata | Mevcut `FriendlyErrorScreen` / `ToastOverlay` |

### 11.3 Slang anahtarları (öneri)

```
features.tickets.title
features.tickets.status.open | in_progress | resolved | closed
features.tickets.category.complaint | request | malfunction | other
features.tickets.create.title
features.tickets.manager.note_hint
features.expenses.title
features.expenses.category.cleaning | elevator | ...
features.expenses.summary.total
features.notifications.title
features.notifications.empty
features.notifications.mark_all_read
features.announcements.send_title
```

**UI’da ham enum göstermeyin** (`IN_PROGRESS` değil, çeviri).

### 11.4 Erişilebilirlik

- Minimum 16sp gövde (`AppTypography` kuralı).
- `textScaleFactor` kısıtlamayın.
- Dokunma hedefi ≥ 48dp.

---

## 12. GoRouter önerileri

Mevcut: `/manager-dashboard`, `/resident-dashboard`.

| Rota | Amaç |
|------|------|
| `/notifications` | Bildirim listesi (her iki rol) |
| `/tickets/:ticketId` | Talep detay |
| `/buildings/:buildingId/tickets` | Yönetici talep listesi (opsiyonel) |
| `/buildings/:buildingId/expenses` | Gider listesi + özet |

FCM tap: `notification_payload.dart` içinde `type` + `ticketId` → `context.push('/tickets/$ticketId')`.

---

## 13. Implementasyon sırası (PLAN B0–B6)

| Aşama | İş | Bağımlılık |
|-------|-----|------------|
| **B0** | `flutterfire configure`, `firebase_options.dart` | — |
| **B1** | FCM init, izin, `PUT /me/fcm-token`, tap handler | B0 |
| **B2** | `features/notifications` + ayarlar linki | B1 (push için), API tek başına B2 |
| **B3** | `features/tickets` sakin + yönetici | Auth, `apartmentId` |
| **B4** | `features/expenses` yönetici | Seçili bina |
| **B5** | Dashboard placeholder kaldır; duyuru UI; `main_dev` mock | B2–B4 |
| **B6** | Manuel E2E checklist | Backend + cihaz |

### 13.1 `main_dev` mock

`dev/dev_mocks.dart`: Sunucusuz UI için **aynı JSON şekillerini** kullanın; fazladan alan eklemeyin.

---

## 14. Manuel E2E checklist

1. [ ] Yönetici giriş → `PUT /me/fcm-token` 200  
2. [ ] Sakin join → token kayıt  
3. [ ] Sakin talep oluştur → `GET /me/tickets`’ta görünür  
4. [ ] Yönetici `GET /buildings/:id/tickets`  
5. [ ] Yönetici not → sakin `GET /notifications` → `TICKET_UPDATE` + `data.ticketId`  
6. [ ] Yönetici duyuru → sakin `ANNOUNCEMENT`  
7. [ ] Yönetici gider CRUD + summary  
8. [ ] Çapraz yönetici gider/talep → 404 (backend `test.py` ile uyumlu)

Yerel backend:

```bash
docker compose up -d          # proje kökü
cd backend && npx prisma migrate deploy && npm run dev
export AIDATPANEL_API_BASE=http://127.0.0.1:4200/api/v1
python3 test.py
```

---

## 15. Bilinçli olarak yapılmayacaklar (özet)

| Konu | Neden |
|------|--------|
| Fiş/fatura **dosya yükleme** | Faz 2B; şimdilik yalnızca `receiptUrl` string |
| Bildirim offset sayfalama | Backend cursor kullanır |
| Talep silme / sakin yanıt | Endpoint yok |
| Gider soft-delete | `deletedAt` şemada yok |
| Abonelik kilidi | Faz 2A dışı |
| `DUE_PAID` push UI | Backend üretmiyor |
| Dekont bildirim tipleri | Dekont API yok |
| `GET /announcements` | Yok; bildirim kutusu kullanılır |
| Resident gider ekranı | API 403 |
| `POST /tickets` (root) | Yalnızca `POST /apartments/:id/tickets` |

---

## 16. Kaynak dosya indeksi (backend)

| Konu | Dosya |
|------|--------|
| Zod şemaları | `backend/src/middlewares/validate.js` |
| Talep iş kuralları | `backend/src/services/ticketService.js` |
| Gider | `backend/src/services/expenseService.js` |
| Bildirim + push | `backend/src/services/notificationService.js` |
| Duyuru | `backend/src/services/announcementService.js` |
| Şema | `backend/prisma/schema.prisma` |
| Smoke test | `backend/test.py` |

---

*Bu belge yalnızca backend Faz 2A gerçeğini yansıtır. Backend değişince önce `test.py` ve bu dosya güncellenmeli; Flutter sonra uyumlanmalıdır.*
