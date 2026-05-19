# AidatPanel — Dokümantasyon Bütünlük Rehberi

> **Amaç:** Repodaki tüm `.md` dosyalarının rolünü, güncellik hiyerarşisini ve birbirleriyle uyumunu tanımlar.  
> **Son senkron:** 2026-05-19 (backend Faz 2A+ push tamam · `test.py` 120 OK · Flutter Faz 2A UI bekliyor)

---

## Doğruluk hiyerarşisi (çakışmada)

1. **Çalışan kod:** `backend/src/`, `backend/prisma/`, `mobile/lib/`
2. **`backend/test.py`** — backend davranışının smoke kanıtı
3. **`FLUTTER-BACKEND.md`** — API/JSON sözleşmesi (Flutter ekibi)
4. **`AIDATPANEL.md`** — ürün + master referans
5. **Plan / analiz / checkpoint** dosyaları (`PLAN.md`, `PLAN_BACKEND_PUSH.md`, `ANALIZ_RAPORU.md`, …)

Eski analiz tarihli olabilir; şüphede **kodu oku**, özellikle mobil UI için **`FLUTTER_ENTEGRASYON_PLANI.md` → B-ANALYZE**.

---

## Dosya haritası

| Dosya | Kitle | İçerik |
|-------|--------|--------|
| [`README.md`](README.md) | Herkes | Repo giriş, hızlı başlangıç, dokümantasyon linkleri |
| [`AIDATPANEL.md`](AIDATPANEL.md) | Ürün + teknik master | Mimari, şema özeti, API tabloları, fazlar, FCM |
| [`PLAN.md`](PLAN.md) | Geliştirme | Faz 2A backend A0–A6 + Flutter B0–B6, DoD |
| [`PLAN_BACKEND_PUSH.md`](PLAN_BACKEND_PUSH.md) | Backend | Push tamamlama (A7–A12) — **tamamlandı** |
| [`FLUTTER-BACKEND.md`](FLUTTER-BACKEND.md) | Mobil + AI | Endpoint, modeller, FCM payload, UI rehberi |
| [`FLUTTER_ENTEGRASYON_PLANI.md`](FLUTTER_ENTEGRASYON_PLANI.md) | Mobil + AI | **Önce B-ANALYZE**, sonra B0–B6 uygulama planı |
| [`FLUTTER_GAP_RAPORU.md`](FLUTTER_GAP_RAPORU.md) | Mobil | *(Opsiyonel)* B-ANALYZE çıktısı — ekip doldurur |
| [`ANALIZ_RAPORU.md`](ANALIZ_RAPORU.md) | Yönetim / review | 2026-05-19 anlık görüntü; mobil gap için B-ANALYZE öncelikli |
| [`YUSUF_YAPILANLAR_BİLDİRİM.md`](YUSUF_YAPILANLAR_BİLDİRİM.md) | Bildirim modülü | Postman checkpoint, FCM notları |
| [`mobile/README.md`](mobile/README.md) | Mobil geliştirici | Flutter paket girişi |

---

## Kod ↔ doküman uyum tablosu (2026-05-19)

### Backend

| Konu | Kodda | Dokümanda güncel mi? |
|------|--------|----------------------|
| Gider / talep / bildirim REST | ✅ | ✅ |
| `TICKET_CREATED` push | ✅ | ✅ (AIDATPANEL, FLUTTER-BACKEND, PLAN_BACKEND_PUSH) |
| `DUE_PAID`, `DUE_REMINDER` push | ✅ | ✅ |
| `POST .../dues/remind` | ✅ | ✅ (AIDATPANEL tetikleyici; buildings tablosuna eklendi) |
| Logout → `fcmToken` null | ✅ | ✅ |
| Firebase env: JSON veya dosya yolu | ✅ | ✅ `.env.example` |
| Prisma migration sayısı | 5 klasör (`prisma/migrations/`) | AIDATPANEL “3 migration” ifadesi güncellendi |

### Mobile

| Konu | Kodda | Dokümanda |
|------|--------|-----------|
| FCM init / token upload | ⬜ | Tüm planlar ⬜ |
| `features/notifications|tickets|expenses` | ⬜ `.gitkeep` | ⬜ |
| Sakin talep sekmesi placeholder | ⬜ (kod kontrol) | B-ANALYZE ile doğrula |
| `ApiConstants` Faz 2 eksik sabitler | ⬜ kısmen | FLUTTER_ENTEGRASYON_PLANI listesi |

### Bilinçli tutarsızlık yok

| Konu | Durum |
|------|--------|
| Dekont API, `DEKONT_*` push UI | Faz 2B — tüm dokümanlarda kapsam dışı |
| RevenueCat, WhatsApp, PDF | Faz 3+ |
| `expenseProof` mobil sabiti | Backend’de endpoint yok — kullanma |

---

## Güncelleme kontrol listesi (PR öncesi)

Doküman değişikliği yaparken şunları güncelle:

- [ ] `AIDATPANEL.md` — yeni endpoint veya push tetikleyici
- [ ] `FLUTTER-BACKEND.md` — JSON şekli / enum
- [ ] `PLAN.md` — aşama durumu (✅/⬜)
- [ ] `backend/test.py` — yeni senaryo
- [ ] Bu dosya (`DOKUMANTASYON.md`) — “Son senkron” tarihi
- [ ] Mobil UI değiştiyse: `FLUTTER_GAP_RAPORU.md` veya B-ANALYZE notu

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
