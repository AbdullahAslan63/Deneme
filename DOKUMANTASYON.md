# AidatPanel — Dokümantasyon Bütünlük Rehberi

> **Amaç:** Repodaki tüm `.md` dosyalarının rolünü, güncellik hiyerarşisini ve birbirleriyle uyumunu tanımlar.  
> **Son senkron:** 2026-05-20 (Flutter Faz 2A B0–B6 kod tamam · backend Faz 2A+ push ✅ · `test.py` 120 OK)

---

## Doğruluk hiyerarşisi (çakışmada)

1. **Çalışan kod:** `backend/src/`, `backend/prisma/`, `mobile/lib/`
2. **`backend/test.py`** — backend davranışının smoke kanıtı
3. **`FLUTTER-BACKEND.md`** — API/JSON sözleşmesi (Flutter ekibi)
4. **`AIDATPANEL.md`** — ürün + master referans
5. **Plan / analiz / checkpoint** dosyaları (`PLAN.md`, `PLAN_BACKEND_PUSH.md`, `ANALIZ_RAPORU.md`, …)

Tarihli analizler (`ANALIZ_RAPORU.md` 2026-05-19) anlık görüntüdür; mobil Faz 2A için **`FLUTTER_GAP_RAPORU.md`** (2026-05-20) ve bu dosyanın tablosu esas alınır.

---

## Dosya haritası

| Dosya | Kitle | İçerik |
|-------|--------|--------|
| [`README.md`](README.md) | Herkes | Repo giriş, hızlı başlangıç, dokümantasyon linkleri |
| [`AIDATPANEL.md`](AIDATPANEL.md) | Ürün + teknik master | Mimari, şema özeti, API tabloları, fazlar, FCM |
| [`PLAN.md`](PLAN.md) | Geliştirme | Faz 2A backend A0–A6 + Flutter B0–B6, DoD |
| [`PLAN_BACKEND_PUSH.md`](PLAN_BACKEND_PUSH.md) | Backend | Push tamamlama (A7–A12) — **tamamlandı** |
| [`FLUTTER-BACKEND.md`](FLUTTER-BACKEND.md) | Mobil + AI | Endpoint, modeller, FCM payload, UI rehberi |
| [`FLUTTER_ENTEGRASYON_PLANI.md`](FLUTTER_ENTEGRASYON_PLANI.md) | Mobil + AI | B-ANALYZE → B0–B6 uygulama planı |
| [`FLUTTER_GAP_RAPORU.md`](FLUTTER_GAP_RAPORU.md) | Mobil | B-ANALYZE çıktısı (2026-05-20, kodla uyumlu) |
| [`ANALIZ_RAPORU.md`](ANALIZ_RAPORU.md) | Yönetim / review | 2026-05-20 senkron; üst bölüm güncel özet |
| [`YUSUF_YAPILANLAR_BİLDİRİM.md`](YUSUF_YAPILANLAR_BİLDİRİM.md) | Bildirim modülü | Postman checkpoint, FCM notları |
| [`mobile/README.md`](mobile/README.md) | Mobil geliştirici | Flutter paket girişi |
| [`mobile/E2E_CHECKLIST.md`](mobile/E2E_CHECKLIST.md) | QA / geliştirici | Manuel uçtan uca test listesi (B6) |

*Atlanan:* `mobile/ios/.../LaunchImage.imageset/README.md` — yalnızca Xcode asset açıklaması.

---

## Kod ↔ doküman uyum tablosu (2026-05-20)

### Backend

| Konu | Kodda | Dokümanda güncel mi? |
|------|--------|----------------------|
| Gider / talep / bildirim REST | ✅ | ✅ |
| Push tetikleyiciler (`TICKET_*`, `ANNOUNCEMENT`, `DUE_*`) | ✅ | ✅ |
| `POST .../dues/remind` | ✅ | ✅ |
| Logout → `fcmToken` null | ✅ | ✅ |
| Firebase env: JSON veya dosya yolu | ✅ | ✅ `.env.example` |
| Prisma migration | 2 klasör (`20260519001941_init`, `20260519010242_…`) | ✅ (eski “5 migration” ifadeleri düzeltildi) |

### Mobile (Faz 2A)

| Konu | Kodda | Dokümanda |
|------|--------|-----------|
| `core/notifications/` (FCM, payload) | ✅ | ✅ |
| `firebase_options.dart`, `google-services.json` | ✅ | ✅ (iOS `GoogleService-Info.plist` cihaz başına `flutterfire configure`) |
| `features/notifications/` | ✅ liste, okundu, duyuru sheet | ✅ |
| `features/tickets/` | ✅ sakin + yönetici + detay | ✅ |
| `features/expenses/` | ✅ CRUD + özet + sheet | ✅ |
| Sakin talep sekmesi | ✅ `ResidentTicketsTab` | ✅ |
| `ApiConstants` Faz 2 sabitleri | ✅ (`notificationsReadAll`, `buildingExpensesSummary`, …) | ✅ |
| `main_dev.dart` Faz 2 mock | ✅ `mock_faz2_datasources.dart` | ✅ |
| Manuel E2E doğrulama | 🔶 checklist hazır, cihazda işaretlenmeli | [`mobile/E2E_CHECKLIST.md`](mobile/E2E_CHECKLIST.md) |
| UI tasarım polish | 🔶 bilinçli ertelendi | — |

### Bilinçli kapsam dışı (tüm dokümanlarda tutarlı)

| Konu | Durum |
|------|--------|
| Dekont API, `DEKONT_*` push UI | Faz 2B |
| RevenueCat, WhatsApp, PDF | Faz 3+ |
| `expenseProof` mobil sabiti | Backend’de endpoint yok — kullanılmayın |
| Ayarlar: gizlilik / yardım / çoklu dil (toast) | Faz 1+ polish, Faz 2A dışı |

---

## Güncelleme kontrol listesi (PR öncesi)

Doküman değişikliği yaparken şunları güncelle:

- [ ] `AIDATPANEL.md` — yeni endpoint veya push tetikleyici
- [ ] `FLUTTER-BACKEND.md` — JSON şekli / enum
- [x] `PLAN.md` — aşama durumu (✅/⬜) — 2026-05-20 güncellendi
- [ ] `backend/test.py` — yeni senaryo
- [x] Bu dosya (`DOKUMANTASYON.md`) — “Son senkron” tarihi
- [ ] `FLUTTER_GAP_RAPORU.md` — mobil gap değiştiyse
- [ ] `mobile/E2E_CHECKLIST.md` — yeni manuel senaryo

---

## Hızlı referans — push tetikleyicileri (tek tablo)

| Olay | `NotificationType` | Alıcı |
|------|-------------------|--------|
| Sakin yeni talep | `TICKET_CREATED` | Yönetici |
| Talep notu / durum | `TICKET_UPDATE` | Talep sahibi sakin |
| Yönetici duyuru | `ANNOUNCEMENT` | Binadaki aktif sakinler |
| Aidat `PAID` | `DUE_PAID` | Daire sakini |
| `POST .../dues/remind` | `DUE_REMINDER` | İlgili sakinler |
| Dekont akışı | `DEKONT_*` | Faz 2B |

---

*Bu dosya dokümantasyon setinin “içindekiler” sayfasıdır; iş mantığı detayı için `AIDATPANEL.md` ve `FLUTTER-BACKEND.md` kullanılır.*
