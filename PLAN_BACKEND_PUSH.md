# Backend Push Tamamlama Planı (Faz 2A+)

> **Kaynak:** Proje analizi + `AIDATPANEL.md`  
> **Son güncelleme:** 2026-05-20 (değişiklik yok; mobil senkron notu: Flutter B0–B6 kod tamam)  
> **Durum:** A7–A12 tamamlandı (2026-05-19)

---

## Mevcut durum (özet)

| Alan | Durum |
|------|--------|
| Expense / Ticket / Notification REST | ✅ Tamam |
| FCM: `createForUsers` + `pushService` | ✅ Tamam |
| Tetikleyiciler | `TICKET_CREATED`, `TICKET_UPDATE`, `ANNOUNCEMENT`, `DUE_PAID`, `DUE_REMINDER` |
| `DEKONT_*` | ⬜ Faz 2B (dekont API yok) |
| Yeni talep → yönetici (A8) | ✅ `TICKET_CREATED` |
| Talep notu yanıtı (A7) | ✅ `formatTicketRow` |
| Logout FCM temizliği (A9) | ✅ |

**Kapsam dışı (Faz 2B):** Dekont OCR, WhatsApp/SMS, RevenueCat.

---

## Aşamalar ve ilerleme

| Aşama | İş | Tahmini | Durum |
|-------|-----|---------|--------|
| **A7** | Talep notu yanıtı → `formatTicketRow` | 0,25 gün | ✅ |
| **A8** | Yeni talep → yönetici (`TICKET_CREATED`) | 0,5–0,75 gün | ✅ |
| **A9** | Logout → `fcmToken` null | 0,25 gün | ✅ |
| **A10** | `DUE_PAID` (aidat ödendi) | 0,5 gün | ✅ |
| **A11** | `DUE_REMINDER` endpoint | 1 gün | ✅ |
| **A12** | Push şablonları + dev FCM ergonomisi | 0,5 gün | ✅ |
| **A13** | Dekont push (`DEKONT_*`) | Faz 2B | ⬜ |
| **A14** | Doküman + test kapanışı | 0,5 gün | ✅ |

---

## A7 — API tutarlılığı

`addTicketUpdateService` başarı sonrası `formatTicketRow` döndürür.

---

## A8 — Yeni talep → yönetici

- Prisma: `TICKET_CREATED` enum
- `createTicketService` → `notifyBuildingManager`
- FCM `data`: `ticketId`, `buildingId`, `apartmentId`, `category`, `status`, `route`

---

## A9 — FCM token hijyeni

`POST /auth/logout` → `fcmToken: null`

---

## A10 — DUE_PAID

`PATCH .../dues/:dueId/status` → `PAID` → sakin bildirimi

---

## A11 — DUE_REMINDER

`POST /buildings/:buildingId/dues/remind`

---

## A12 — Push altyapı

`notificationTemplates.js`, `pushSkipped` duyuru yanıtı, opsiyonel `FIREBASE_SERVICE_ACCOUNT_PATH`

---

## Definition of Done

- [x] A7–A12 tamam
- [x] A14 — `AIDATPANEL.md` tetikleyici tablosu güncellendi; `test.py` senaryoları eklendi (yerel API veya deploy sonrası çalıştırın)
- [ ] `test.py` yeşil
- [ ] `AIDATPANEL.md` tetikleyici tablosu güncel
