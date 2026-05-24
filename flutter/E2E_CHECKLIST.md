# AidatPanel Mobile — Manuel E2E Checklist (B6)

Gerçek cihaz veya Play Store’lu emülatör; yerel API:

```bash
cd backend && npm run dev
cd mobile && flutter run --dart-define=API_BASE_URL=http://10.0.2.2:4200
```

Backend regresyon: `cd backend && python test.py` (hedef: FAIL 0).

## Hesaplar

- [ ] Yönetici hesabı
- [ ] Aynı binada sakin hesabı (davet kodu ile join)

## FCM / oturum

- [ ] Yönetici giriş → log’da `[FCM] PUT /me/fcm-token başarılı`
- [ ] Sakin giriş → token kaydı
- [ ] Play Services’siz emülatörde FCM’nin atlandığını bil (beklenen)

## Talepler

- [ ] Sakin yeni talep (`POST /apartments/:id/tickets`)
- [ ] Yönetici **TICKET_CREATED** (push + bildirim kutusu)
- [ ] Yönetici not / durum → sakin **TICKET_UPDATE**
- [ ] Bildirimden talep detayına deep link

## Duyuru

- [ ] Yönetici duyuru (dashboard veya `/manager/announcement`)
- [ ] Sakin **ANNOUNCEMENT** bildirimi

## Giderler

- [ ] Gider ekle → liste + ay/yıl özet (`byCategory`)
- [ ] Gider düzenle / sil

## Aidat (opsiyonel)

- [ ] `POST .../dues/remind` → **DUE_REMINDER**
- [ ] Aidat PAID → sakin **DUE_PAID**

## Dev preview (sunucu yok)

```bash
flutter run -t lib/main_dev.dart
```

- [ ] Faz 2 kısayolları: talep, gider, duyuru
- [ ] Bildirim listesi örnek kayıtlar
- [ ] Gider listesi `b1` / `b2` seed verisi
