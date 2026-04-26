# AidatPanel Backend API

Türk apartman ve site yöneticileri için geliştirilmiş aidat yönetim platformunun backend API'si.

## 🚀 Hızlı Başlangıç

### Gereksinimler
- Node.js 20+
- PostgreSQL veritabanı (Neon.tech önerilir)
- npm veya yarn

### Kurulum

1. **Repoyu klonla:**
```bash
git clone <repo-url>
cd aidatpanel
```

2. **Bağımlılıkları yükle:**
```bash
npm install
```

3. **Environment değişkenlerini ayarla:**
```bash
cp .env.example .env
# .env dosyasını düzenle ve kendi değerlerini gir
```

4. **Veritabanını senkronize et:**
```bash
npx prisma generate
npx prisma db push
```

5. **Sunucuyu başlat:**
```bash
# Geliştirme modu (nodemon ile otomatik yenileme)
npm run dev

# veya normal mod
node index.js
```

Sunucu `http://localhost:4200` adresinde çalışmaya başlayacak.

---

## 📁 Proje Yapısı

```
├── index.js                 # Ana giriş noktası
├── src/
│   ├── config/
│   │   └── db.js           # Prisma/Veritabanı bağlantısı
│   ├── controllers/
│   │   └── authControllers.js    # Auth endpoint mantığı
│   ├── middlewares/
│   │   └── authMiddleware.js   # JWT doğrulama
│   ├── routes/
│   │   └── authRoutes.js       # Route tanımları
│   └── utils/
│       └── generateTokens.js    # JWT token üretimi
├── prisma/
│   └── schema.prisma       # Veritabanı şeması
├── .env.example            # Environment şablonu
└── README.md               # Bu dosya
```

---

## 🔐 Kimlik Doğrulama (Auth)

JWT tabanlı authentication sistemi kullanılır.

### Token Türleri
- **Access Token**: 15 dakika geçerli, API isteklerinde kullanılır
- **Refresh Token**: 30 gün geçerli, access token yenilemek için kullanılır

### Endpoint'ler

| Method | Endpoint | Açıklama | Auth Gerekli |
|--------|----------|----------|--------------|
| POST | `/api/v1/auth/register` | Yeni kullanıcı kaydı | Hayır |
| POST | `/api/v1/auth/login` | Giriş yap, token al | Hayır |
| POST | `/api/v1/auth/refresh` | Access token yenile | Hayır |
| POST | `/api/v1/auth/logout` | Çıkış yap | Evet |

### Örnek İstekler

**Register:**
```bash
curl -X POST http://localhost:4200/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{"name":"Ali","email":"ali@example.com","password":"123456"}'
```

**Login:**
```bash
curl -X POST http://localhost:4200/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"ali@example.com","password":"123456"}'
```

**Korumalı Endpoint (Auth gerekli):**
```bash
curl -X POST http://localhost:4200/api/v1/auth/logout \
  -H "Authorization: Bearer <access_token>"
```

---

## 📊 HTTP Status Kodları

| Kod | Anlamı | Kullanım |
|-----|--------|----------|
| 200 | OK | Başarılı GET/PUT/DELETE |
| 201 | Created | Başarılı POST (yeni kaynak) |
| 400 | Bad Request | Validasyon hatası |
| 401 | Unauthorized | Token eksik/geçersiz |
| 403 | Forbidden | Yetki yok (başkasının kaynağı) |
| 404 | Not Found | Kaynak bulunamadı |
| 500 | Server Error | Sunucu hatası |

---

## 🛠️ Geliştirme

### Veritabanı Şemasını Görüntüle
```bash
npx prisma studio
```
Tarayıcıda http://localhost:5555 açılır.

### Şema Değişikliği Sonrası
```bash
npx prisma db push
```

### Logları İzle
Geliştirme modunda (`npm run dev`) konsol logları otomatik gösterilir.

---

## 📚 Dokümantasyon

- **Yusuf için:** `YUSUF_ICIN_DOKUMANTASYON.md` - Backend API geliştirme rehberi
- **Furkan için:** `FURKAN_ICIN_DOKUMANTASYON.md` - Flutter JWT entegrasyonu
- **Proje Detayları:** `AIDATPANEL.md` - Master reference
- **Görev Dağılımı:** `GOREVDAGILIMI.md` - Fazlar ve sorumluluklar

---

## ⚙️ Environment Değişkenleri

| Değişken | Açıklama | Zorunlu |
|----------|----------|---------|
| `PORT` | Sunucu portu (varsayılan: 4200) | Hayır |
| `NODE_ENV` | Ortam (development/production) | Hayır |
| `DATABASE_URL` | PostgreSQL connection string | Evet |
| `JWT_SECRET` | JWT imzalama anahtarı | Evet |
| `REFRESH_TOKEN_SECRET` | Refresh token anahtarı | Evet |

---

## 📝 Notlar

- **CORS**: Flutter'dan gelen istekler için yapılandırıldı (`localhost:3000` ve `localhost:4200`)
- **Güvenlik**: Asla `.env` dosyasını GitHub'a push etme (`.gitignore`'da ignore ediliyor)
- **Token**: JWT secret'ları üretmek için: `openssl rand -base64 32`

---

**Hazırlayan:** Abdullah (Backend Lead)  
**Proje:** AidatPanel - Faz 1