# AidatPanel

Apartman ve site yönetimi için full-stack platform — Node.js API + Flutter mobil uygulama.

## Yapı

| Klasör | Açıklama |
|--------|----------|
| `backend/` | Node.js + Express + Prisma + PostgreSQL API |
| `mobile/` | Flutter (iOS / Android) mobil uygulama |
| `docker-compose.yml` | Yerel PostgreSQL |

## Hızlı başlangıç

### Backend

```bash
docker compose up -d
cd backend
cp .env.example .env   # gerekirse düzenle
npm install
npx prisma migrate deploy
npm run dev            # http://127.0.0.1:4200
```

### Mobile

```bash
cd mobile
flutter pub get
flutter run -t lib/main_dev.dart
```

## Dokümantasyon

Önce [DOKUMANTASYON.md](./DOKUMANTASYON.md) — dosyaların rolü ve güncellik hiyerarşisi.

| Dosya | Ne için? |
|-------|----------|
| [AIDATPANEL.md](./AIDATPANEL.md) | Master referans (API, modeller, fazlar) |
| [PLAN.md](./PLAN.md) | Geliştirme planı (backend A0–A6 ✅, Flutter B0–B6) |
| [PLAN_BACKEND_PUSH.md](./PLAN_BACKEND_PUSH.md) | Backend push tamamlama (A7–A12 ✅) |
| [FLUTTER-BACKEND.md](./FLUTTER-BACKEND.md) | Flutter ↔ API sözleşmesi |
| [FLUTTER_ENTEGRASYON_PLANI.md](./FLUTTER_ENTEGRASYON_PLANI.md) | Mobil ekip / AI: önce gap analizi, sonra B0–B6 |
| [YUSUF_YAPILANLAR_BİLDİRİM.md](./YUSUF_YAPILANLAR_BİLDİRİM.md) | Bildirim modülü Postman checkpoint |
| [ANALIZ_RAPORU.md](./ANALIZ_RAPORU.md) | Proje analizi (tarihli anlık görüntü) |

## API

Base URL (dev): `http://127.0.0.1:4200/api/v1`

Postman: `backend/postman/AidatPanel-Notifications.postman_collection.json`

Smoke test: `cd backend && python test.py` (yerel: `AIDATPANEL_API_BASE=http://127.0.0.1:4200/api/v1`)

## Lisans

Özel proje — Yusuf KARAGÜZEL / [Majestelerinizz](https://github.com/Majestelerinizz)
