# Flutter Gap Raporu (B-ANALYZE çıktısı)

> **Tarih:** 2026-05-20  
> **Kaynak:** `mobile/lib/` kod taraması + `FLUTTER-BACKEND.md` + `backend/test.py`  
> **Önceki şablon:** Bu dosya dolduruldu; sabit “tasarım eksikleri” listesi kullanılmadı.

---

## Meta

| Alan | Değer |
|------|--------|
| Tarih | 2026-05-20 |
| Workspace | `Deneme/` (backend + mobile birleşik) |
| Analizi yapan | Dokümantasyon senkronu (kod tabanı) |

---

## Özet

| Öncelik | Adet | Not |
|---------|------|-----|
| P0 (Faz 2A bloklayıcı) | 0 | API bağlantıları kodda mevcut |
| P1 (doğrulama / cihaz) | 2 | Gerçek cihazda FCM + manuel E2E |
| P2 (polish / Faz 2B+) | 4 | Tasarım, iOS plist, aidat deep link UI, ayarlar “yakında” |

**Sonuç:** Flutter **Faz 2A implementasyonu tamamlandı**; üretim güveni için [`mobile/E2E_CHECKLIST.md`](mobile/E2E_CHECKLIST.md) işaretlenmeli.

---

## Gap tablosu (B-ANALYZE)

| Kontrol | Backend | Mobil | Gap / not |
|---------|---------|-------|-----------|
| FCM init + token upload | ✅ | ✅ `main.dart`, `fcm_service`, `syncFcmAfterAuth` | Play Services’siz emülatörde token alınamaz (beklenen) |
| `PUT /me/fcm-token` | ✅ | ✅ | |
| Bildirim listesi + okundu + read-all | ✅ | ✅ `notifications_screen.dart` | |
| Deep link (`notification_payload`) | ✅ | ✅ FCM tap + liste tap | `DUE_*` → dashboard (route); özel aidat ekranı opsiyonel |
| Sakin talep sekmesi | ✅ | ✅ `ResidentTicketsTab` | Placeholder kaldırıldı |
| Yönetici talep liste/detay | ✅ | ✅ `/manager/tickets`, `/tickets/:id` | |
| Yönetici gider CRUD + özet | ✅ | ✅ `/manager/expenses`, `ExpenseFormSheet` | |
| Duyuru | ✅ | ✅ `AnnouncementFormSheet` | |
| Dashboard Faz 2 kısayolları | — | ✅ `_Faz2QuickActions` | |
| `main_dev` mock Faz 2 | — | ✅ `mock_faz2_datasources.dart` + `MockTicketRepository` | |
| `ApiConstants` Faz 2 | — | ✅ Tüm planlanan sabitler tanımlı | |
| Unit test `notification_payload` | — | ✅ `test/core/notification_payload_test.dart` | |
| Manuel E2E | — | 🔶 | Checklist hazır, cihazda koşulmalı |
| UI tasarım polish | — | 🔶 | Bilinçli ertelendi |

---

## ApiConstants — durum

| Sabit | Durum |
|-------|--------|
| `notificationsReadAll` | ✅ |
| `buildingExpensesSummary` | ✅ |
| `buildingAnnouncements` | ✅ |
| `apartmentTickets` | ✅ |
| `buildingDuesRemind` | ✅ |
| `ticketStatus` | ✅ |
| `expense(id)` | ✅ |

**Kullanılmamalı:** `expenseProof` (backend endpoint yok).

---

## Kalan işler (Faz 2A dışı veya doğrulama)

1. **Manuel E2E** — [`mobile/E2E_CHECKLIST.md`](mobile/E2E_CHECKLIST.md)
2. **iOS** — `GoogleService-Info.plist` (`flutterfire configure` ile cihaz/hedef için)
3. **Tasarım** — Faz 2A fonksiyon sonrası polish
4. **Ayarlar** — gizlilik / yardım / çoklu dil hâlâ `comingSoon` toast (ürün kararı)

---

*Güncellendi: 2026-05-20 — `DOKUMANTASYON.md` “Son senkron” ile uyumlu.*
