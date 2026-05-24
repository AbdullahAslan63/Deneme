# AidatPanel — Dokümantasyon Bütünlük Rehberi

> **Amaç:** Repodaki tüm `.md` dosyalarının rolünü, güncellik hiyerarşisini ve birbirleriyle uyumunu tanımlar.  
> **Son senkron:** 2026-05-22 (dokümantasyon `flutter/` ve `API/` klasörlerine ayrıldı)

---

## Klasör yapısı

| Klasör | İçerik |
|--------|--------|
| [`flutter/`](flutter/README.md) | Mobil entegrasyon, gap analizi, E2E checklist |
| [`API/`](API/README.md) | Backend sözleşmesi, push planı, bildirim checkpoint |
| Kök | `AIDATPANEL.md`, `PLAN.md`, `ANALIZ_RAPORU.md`, `README.md` |

---

## Doğruluk hiyerarşisi (çakışmada)

1. **Çalışan kod:** `backend/src/`, `backend/prisma/`, `mobile/lib/`
2. **`backend/test.py`** — backend davranışının smoke kanıtı
3. **`API/FLUTTER-BACKEND.md`** — API/JSON sözleşmesi (Flutter ekibi)
4. **`AIDATPANEL.md`** — ürün + master referans
5. **Plan / analiz / checkpoint** dosyaları (`PLAN.md`, `API/PLAN_BACKEND_PUSH.md`, `ANALIZ_RAPORU.md`, …)

Tarihli analizler (`ANALIZ_RAPORU.md`) anlık görüntüdür; mobil Faz 2A için **`flutter/FLUTTER_GAP_RAPORU.md`** ve bu dosyanın tablosu esas alınır.

---

## Dosya haritası

| Dosya | Kitle | İçerik |
|-------|--------|--------|
| [`README.md`](README.md) | Herkes | Repo giriş, hızlı başlangıç, dokümantasyon linkleri |
| [`AIDATPANEL.md`](AIDATPANEL.md) | Ürün + teknik master | Mimari, şema özeti, API tabloları, fazlar, FCM |
| [`PLAN.md`](PLAN.md) | Geliştirme | Faz 2A backend A0–A6 + Flutter B0–B6, DoD |
| [`API/PLAN_BACKEND_PUSH.md`](API/PLAN_BACKEND_PUSH.md) | Backend | Push tamamlama (A7–A12) — **tamamlandı** |
| [`API/FLUTTER-BACKEND.md`](API/FLUTTER-BACKEND.md) | Mobil + AI | Endpoint, modeller, FCM payload, UI rehberi |
| [`flutter/FLUTTER_ENTEGRASYON_PLANI.md`](flutter/FLUTTER_ENTEGRASYON_PLANI.md) | Mobil + AI | B-ANALYZE → B0–B6 uygulama planı |
| [`flutter/FLUTTER_GAP_RAPORU.md`](flutter/FLUTTER_GAP_RAPORU.md) | Mobil | B-ANALYZE çıktısı (2026-05-20, kodla uyumlu) |
| [`ANALIZ_RAPORU.md`](ANALIZ_RAPORU.md) | Yönetim / review | 2026-05-20 senkron; üst bölüm güncel özet |
| [`API/YUSUF_YAPILANLAR_BİLDİRİM.md`](API/YUSUF_YAPILANLAR_BİLDİRİM.md) | Bildirim modülü | Postman checkpoint, FCM notları |
| [`mobile/README.md`](mobile/README.md) | Mobil geliştirici | Flutter paket girişi |
| [`flutter/E2E_CHECKLIST.md`](flutter/E2E_CHECKLIST.md) | QA / geliştirici | Manuel uçtan uca test listesi (B6) |

*Atlanan:* `mobile/ios/.../LaunchImage.imageset/README.md` — yalnızca Xcode asset açıklaması.

---

## Güncelleme kontrol listesi (PR öncesi)

Doküman değişikliği yaparken şunları güncelle:

- [ ] `AIDATPANEL.md` — yeni endpoint veya push tetikleyici
- [ ] `API/FLUTTER-BACKEND.md` — JSON şekli / enum
- [ ] `PLAN.md` — aşama durumu (✅/⬜)
- [ ] `backend/test.py` — yeni senaryo
- [ ] Bu dosya (`DOKUMANTASYON.md`) — “Son senkron” tarihi
- [ ] `flutter/FLUTTER_GAP_RAPORU.md` — mobil gap değiştiyse
- [ ] `flutter/E2E_CHECKLIST.md` — yeni manuel senaryo

---

*Bu dosya dokümantasyon setinin “içindekiler” sayfasıdır; iş mantığı detayı için `AIDATPANEL.md` ve `API/FLUTTER-BACKEND.md` kullanılır.*
