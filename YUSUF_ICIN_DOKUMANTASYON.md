# Yusuf İçin Backend API Geliştirme Rehberi

## 🎯 Faz 1 Görevin: Bina ve Daire API'leri

**Hedef:** Yöneticinin kendi binalarını ve dairelerini yönetebileceği REST API endpoint'leri yazmak.

**Ne öğreneceksin:**
- REST API tasarım prensipleri
- Layered Architecture (Controller → Service → Repository)
- Authentication middleware kullanımı
- Prisma ORM ile veritabanı işlemleri
- Hata yönetimi ve validasyon

---

## 📚 Mimari Anlayışı

### Layered Architecture (Katmanlı Mimari)

Backend'de kodu katmanlara ayırıyoruz. Her katmanın tek bir sorumluluğu var:

```
┌─────────────────────────────────────────┐
│  HTTP Request (Postman / Flutter)       │
└─────────────────┬───────────────────────┘
                  │
┌─────────────────▼───────────────────────┐
│  1. ROUTES (Yol belirleyici)            │
│     - URL tanımları (/api/v1/buildings) │
│     - HTTP method (GET, POST, PUT, DEL) │
│     - Middleware bağlama                │
└─────────────────┬───────────────────────┘
                  │
┌─────────────────▼───────────────────────┐
│  2. CONTROLLERS (İstek işleyici)       │
│     - Request/Response yönetimi        │
│     - Input validasyonu                 │
│     - Status kodları (200, 201, 400)   │
│     - Service çağrıları                 │
└─────────────────┬───────────────────────┘
                  │
┌─────────────────▼───────────────────────┐
│  3. SERVICES (İş mantığı)              │
│     - Business logic                    │
│     - Veri dönüşümleri                  │
│     - İlişkili işlemler (örn: Bina     │
│       silinince daireleri de sil)       │
└─────────────────┬───────────────────────┘
                  │
┌─────────────────▼───────────────────────┐
│  4. REPOSITORY / PRISMA (Veritabanı)   │
│     - Database sorguları                │
│     - Prisma Client işlemleri           │
└─────────────────┬───────────────────────┘
                  │
┌─────────────────▼───────────────────────┐
│  PostgreSQL (Neon Database)             │
└─────────────────────────────────────────┘
```

### Neden Katmanlı?

**Sorularla Anla:**

**Soru 1:** "Kullanıcı yetkisi yok" kontrolünü nereye koyarsın?
- ❌ Routes: Hayır, sadece yönlendirme yapar
- ❌ Repository: Hayır, sadece DB işlemi yapar
- ✅ **Middleware/Service:** Doğru yer! İş mantığı burada

**Soru 2:** "Email formatı yanlış" kontrolünü nereye koyarsın?
- ❌ Repository: Hayır, DB sorgusu değil bu
- ✅ **Controller:** Doğru yer! Input validasyonu burada

**Soru 3:** "Bina silinince daireler de silinsin" mantığını nereye koyarsın?
- ❌ Controller: Hayır, controller sadece çağrı yapar
- ✅ **Service:** Doğru yer! İlişkili iş mantığı burada

**Ana prensip:** Her katman kendi işini yapar, başka katmanın işine karışmaz.

---

## 🏗️ REST API Tasarımı

### URL Yapısı (Kural: İsimler çoğul olsun)

| İşlem | HTTP Method | URL | Açıklama |
|-------|-------------|-----|----------|
| **Listele** | GET | `/api/v1/buildings` | Tüm binaları getir |
| **Detay** | GET | `/api/v1/buildings/:id` | Tek bina detayı |
| **Ekle** | POST | `/api/v1/buildings` | Yeni bina oluştur |
| **Güncelle** | PUT | `/api/v1/buildings/:id` | Bina bilgilerini güncelle |
| **Sil** | DELETE | `/api/v1/buildings/:id` | Bina sil |

**Nested Resource (İç içe kaynak):**

Bina'nın daireleri için:

| İşlem | HTTP Method | URL |
|-------|-------------|-----|
| Daireleri Listele | GET | `/api/v1/buildings/:buildingId/apartments` |
| Daire Ekle | POST | `/api/v1/buildings/:buildingId/apartments` |
| Daire Sil | DELETE | `/api/v1/buildings/:buildingId/apartments/:id` |

### HTTP Status Kodları

| Kod | Anlamı | Ne Zaman Kullanılır |
|-----|--------|---------------------|
| **200** | OK | Listeleme, detay getirme başarılı |
| **201** | Created | Yeni kaynak oluşturuldu (POST) |
| **400** | Bad Request | Validasyon hatası (eksik alan, yanlış format) |
| **401** | Unauthorized | Token yok/geçersiz (login gerekli) |
| **403** | Forbidden | Token var ama yetki yok (başkasının binasına erişim) |
| **404** | Not Found | Kaynak bulunamadı (olmayan ID) |
| **500** | Server Error | Sunucu hatası (DB bağlantısı kopması vb.) |

---

## 📁 Proje Yapısı (Nereye Ne Yazılır?)

```
src/
├── config/              # (Abdullah hazırladı)
│   └── db.js           # Prisma client
├── controllers/        # SEN BURAYI DOLDURACAKSIN
│   ├── authControllers.js
│   ├── buildingControllers.js    # ← Yeni
│   └── apartmentControllers.js # ← Yeni
├── routes/             # SEN BURAYI DOLDURACAKSIN
│   ├── authRoutes.js
│   ├── buildingRoutes.js       # ← Yeni
│   └── apartmentRoutes.js      # ← Yeni
├── services/           # SEN BURAYI DOLDURACAKSIN (isteğe bağlı)
│   ├── authService.js
│   ├── buildingService.js      # ← Yeni
│   └── apartmentService.js     # ← Yeni
├── middlewares/        # (Abdullah hazırladı)
│   └── authMiddleware.js
└── utils/              # Yardımcı fonksiyonlar
```

### Prisma Schema (Veritabanı Yapısı)

```prisma
model Building {
  id         String      @id @default(uuid())
  name       String
  address    String
  city       String
  managerId  String      // Yönetici ID'si
  manager    User        @relation("BuildingManager", fields: [managerId], references: [id])
  apartments Apartment[] // Bir binanın birden fazla dairesi var
  expenses   Expense[]
  createdAt  DateTime    @default(now())
  updatedAt  DateTime    @updatedAt
}

model Apartment {
  id           String       @id @default(uuid())
  number       String       // "B-12", "3A"
  floor        Int?
  buildingId   String
  building     Building     @relation(fields: [buildingId], references: [id])
  residents    User[]       // Bir dairede birden fazla sakin olabilir
  dues         Due[]
  inviteCodes  InviteCode[]
  tickets      Ticket[]
  createdAt    DateTime     @default(now())
}
```

**Önemli Nokta:** Her `Building` bir `managerId` içeriyor. Bu sayede "Yönetici sadece kendi binalarını görebilir" kontrolü yapabiliriz.

---

## 🔐 Yetkilendirme Mantığı (Çok Önemli!)

**Problem:** Yönetici A login olmuş. Yönetici B'nin binalarını görmeye çalışırsa ne olmalı?

**Çözüm:** Her controller'da `req.user.id` ile `building.managerId` karşılaştırılacak.

```javascript
// Auth middleware token'dan user bilgisini alıp req.user'a ekliyor
req.user = {
  id: "abc-123",
  email: "yusuf@example.com",
  role: "MANAGER"
};

// Controller'da kullanım:
const userId = req.user.id;  // Token'dan gelen güvenli ID
```

**Yetki Kontrol Pattern'i:**

```javascript
// 1. Bina'yı bul
const building = await prisma.building.findUnique({
  where: { id: req.params.id }
});

// 2. Bina var mı kontrol et
if (!building) {
  return res.status(404).json({ error: "Bina bulunamadı." });
}

// 3. Bu bina bu kullanıcıya mı ait?
if (building.managerId !== req.user.id) {
  return res.status(403).json({ error: "Bu işlem için yetkiniz yok." });
}

// 4. Devam et...
```

---

## 📝 Adım Adım Kodlama Rehberi

### Adım 1: Building Routes Oluştur

**Dosya:** `src/routes/buildingRoutes.js`

```javascript
import express from "express";
import { authMiddleware } from "../middlewares/authMiddleware.js";
import {
  getBuildings,
  getBuildingById,
  createBuilding,
  updateBuilding,
  deleteBuilding,
} from "../controllers/buildingControllers.js";

const router = express.Router();

// Tüm route'lar authMiddleware korumalı
// Yani token olmadan erişilemez

// GET /api/v1/buildings - Tüm binaları listele
router.get("/", authMiddleware, getBuildings);

// GET /api/v1/buildings/:id - Tek bina detayı
router.get("/:id", authMiddleware, getBuildingById);

// POST /api/v1/buildings - Yeni bina ekle
router.post("/", authMiddleware, createBuilding);

// PUT /api/v1/buildings/:id - Bina güncelle
router.put("/:id", authMiddleware, updateBuilding);

// DELETE /api/v1/buildings/:id - Bina sil
router.delete("/:id", authMiddleware, deleteBuilding);

export default router;
```

**Açıklamalar:**
- `authMiddleware`: Her istekten önce token kontrolü yapar
- `/:id`: URL parametresi. Örnek: `/api/v1/buildings/abc-123`
- HTTP method'ları: GET (oku), POST (oluştur), PUT (güncelle), DELETE (sil)

---

### Adım 2: Building Controllers Oluştur

**Dosya:** `src/controllers/buildingControllers.js`

**2.1 Listeleme (GET /api/v1/buildings)**

```javascript
import { prisma } from "../config/db.js";

/**
 * Tüm binaları listele
 * Sadece giriş yapmış yöneticinin binalarını getir
 */
const getBuildings = async (req, res) => {
  try {
    // Token'dan gelen kullanıcı ID'si
    const managerId = req.user.id;

    // Prisma ile sorgu
    // where: Sadece bu manager'a ait binalar
    // include: apartments ilişkisini de getir
    const buildings = await prisma.building.findMany({
      where: { managerId },
      include: {
        apartments: {
          select: {
            id: true,
            number: true,
            floor: true,
          },
        },
        _count: {
          select: { apartments: true },
        },
      },
      orderBy: { createdAt: "desc" },
    });

    res.status(200).json({
      success: true,
      data: buildings,
      count: buildings.length,
    });
  } catch (error) {
    console.error("Bina listeleme hatası:", error);
    res.status(500).json({
      success: false,
      error: "Binalar listelenirken bir hata oluştu.",
    });
  }
};

/**
 * Tek bina detayı
 */
const getBuildingById = async (req, res) => {
  try {
    const { id } = req.params;  // URL'den ID al
    const managerId = req.user.id;

    const building = await prisma.building.findUnique({
      where: { id },
      include: {
        apartments: {
          orderBy: { number: "asc" },
        },
        expenses: {
          orderBy: { date: "desc" },
          take: 5,  // Son 5 gideri getir
        },
      },
    });

    // Bina yoksa 404
    if (!building) {
      return res.status(404).json({
        success: false,
        error: "Bina bulunamadı.",
      });
    }

    // Başkasının binasına erişim yoksa 403
    if (building.managerId !== managerId) {
      return res.status(403).json({
        success: false,
        error: "Bu bina bilgilerine erişim yetkiniz yok.",
      });
    }

    res.status(200).json({
      success: true,
      data: building,
    });
  } catch (error) {
    console.error("Bina detay hatası:", error);
    res.status(500).json({
      success: false,
      error: "Bina bilgileri alınırken bir hata oluştu.",
    });
  }
};

/**
 * Yeni bina oluştur
 */
const createBuilding = async (req, res) => {
  try {
    const { name, address, city } = req.body;
    const managerId = req.user.id;

    // Validasyon: Zorunlu alanlar
    if (!name || !address || !city) {
      return res.status(400).json({
        success: false,
        error: "Bina adı, adresi ve şehri zorunludur.",
      });
    }

    // Prisma ile oluştur
    const building = await prisma.building.create({
      data: {
        name: name.trim(),
        address: address.trim(),
        city: city.trim(),
        managerId,
      },
    });

    // 201 Created döndür
    res.status(201).json({
      success: true,
      message: "Bina başarıyla oluşturuldu.",
      data: building,
    });
  } catch (error) {
    console.error("Bina oluşturma hatası:", error);
    res.status(500).json({
      success: false,
      error: "Bina oluşturulurken bir hata oluştu.",
    });
  }
};

/**
 * Bina güncelle
 */
const updateBuilding = async (req, res) => {
  try {
    const { id } = req.params;
    const { name, address, city } = req.body;
    const managerId = req.user.id;

    // Önce binayı bul ve yetki kontrolü yap
    const existingBuilding = await prisma.building.findUnique({
      where: { id },
    });

    if (!existingBuilding) {
      return res.status(404).json({
        success: false,
        error: "Bina bulunamadı.",
      });
    }

    if (existingBuilding.managerId !== managerId) {
      return res.status(403).json({
        success: false,
        error: "Bu bina bilgilerini güncelleme yetkiniz yok.",
      });
    }

    // Güncelleme verilerini hazırla
    // Sadece dolu alanları güncelle
    const updateData = {};
    if (name) updateData.name = name.trim();
    if (address) updateData.address = address.trim();
    if (city) updateData.city = city.trim();

    const building = await prisma.building.update({
      where: { id },
      data: updateData,
    });

    res.status(200).json({
      success: true,
      message: "Bina bilgileri güncellendi.",
      data: building,
    });
  } catch (error) {
    console.error("Bina güncelleme hatası:", error);
    res.status(500).json({
      success: false,
      error: "Bina güncellenirken bir hata oluştu.",
    });
  }
};

/**
 * Bina sil
 */
const deleteBuilding = async (req, res) => {
  try {
    const { id } = req.params;
    const managerId = req.user.id;

    // Yetki kontrolü
    const building = await prisma.building.findUnique({
      where: { id },
      include: {
        _count: {
          select: { apartments: true },
        },
      },
    });

    if (!building) {
      return res.status(404).json({
        success: false,
        error: "Bina bulunamadı.",
      });
    }

    if (building.managerId !== managerId) {
      return res.status(403).json({
        success: false,
        error: "Bu bina silme yetkiniz yok.",
      });
    }

    // Cascade delete: Bina silinince daireler de silinir
    // (Prisma schema'da @relation(onDelete: Cascade) ile ayarlanabilir)
    // Şimdilik manuel kontrol yapalım

    if (building._count.apartments > 0) {
      return res.status(400).json({
        success: false,
        error: `Bu binada ${building._count.apartments} daire var. Önce daireleri silmelisiniz.`,
      });
    }

    await prisma.building.delete({
      where: { id },
    });

    res.status(200).json({
      success: true,
      message: "Bina başarıyla silindi.",
    });
  } catch (error) {
    console.error("Bina silme hatası:", error);
    res.status(500).json({
      success: false,
      error: "Bina silinirken bir hata oluştu.",
    });
  }
};

export {
  getBuildings,
  getBuildingById,
  createBuilding,
  updateBuilding,
  deleteBuilding,
};
```

**Controller'da Öğrenmen Gerekenler:**

| Kavram | Açıklama |
|--------|----------|
| `req.user.id` | Auth middleware'den gelen kullanıcı ID'si |
| `req.params.id` | URL'den gelen parametre (`:id`) |
| `req.body` | HTTP request body (JSON veri) |
| `prisma.building.findMany()` | Tüm kayıtları getir |
| `prisma.building.findUnique()` | Tek kayıt getir |
| `prisma.building.create()` | Yeni kayıt oluştur |
| `prisma.building.update()` | Kayıt güncelle |
| `prisma.building.delete()` | Kayıt sil |
| `where: { managerId }` | Filtreleme (sadece bu yöneticiye ait) |
| `include: { apartments: true }` | İlişkili verileri getir |
| `orderBy: { createdAt: "desc" }` | Sıralama (en yeniden eskiye) |
| `trim()` | String baş/son boşluk temizleme |

---

### Adım 3: Route'ları index.js'e Bağla

**index.js'e ekle:**

```javascript
import express from "express";
import { config } from "dotenv";
import { connectDB } from "./src/config/db.js";
import authRouter from "./src/routes/authRoutes.js";
import buildingRouter from "./src/routes/buildingRoutes.js";  // ← Ekle

config();
const app = express();
app.use(express.json());

// Mevcut route
app.use("/api/v1/auth", authRouter);

// Yeni route - Binalar
app.use("/api/v1/buildings", buildingRouter);  // ← Ekle

connectDB();
app.listen(4200, () => {
  console.log("Server 4200 portunda çalışıyor");
});
```

---

### Adım 4: Postman ile Test Et

**1. Login Ol ve Token Al:**
```http
POST /api/v1/auth/login
{
  "email": "yusuf@example.com",
  "password": "123456"
}

Response:
{
  "accessToken": "eyJhbGci...",
  "refreshToken": "eyJhbGci..."
}
```

**2. Token'ı Postman'e Ekle:**
- Headers tab'ına git
- Key: `Authorization`
- Value: `Bearer eyJhbGci...` (token buraya)

**3. Bina Oluştur:**
```http
POST /api/v1/buildings
Authorization: Bearer <token>

{
  "name": "Güneş Apartmanı",
  "address": "Atatürk Cad. No:15",
  "city": "İstanbul"
}
```

**4. Binaları Listele:**
```http
GET /api/v1/buildings
Authorization: Bearer <token>
```

**5. Tek Bina Getir:**
```http
GET /api/v1/buildings/abc-123
Authorization: Bearer <token>
```

---

## 🏠 Daire (Apartment) API'leri

Daireler bina içinde nested resource olarak çalışır. Mantık aynı, sadece `buildingId` ilişkisi var.

### Route: `src/routes/apartmentRoutes.js`

```javascript
import express from "express";
import { authMiddleware } from "../middlewares/authMiddleware.js";
import {
  getApartments,
  createApartment,
  deleteApartment,
} from "../controllers/apartmentControllers.js";

const router = express.Router({ mergeParams: true });
// mergeParams: true → Üst route'dan :buildingId alınır

// GET /api/v1/buildings/:buildingId/apartments
router.get("/", authMiddleware, getApartments);

// POST /api/v1/buildings/:buildingId/apartments
router.post("/", authMiddleware, createApartment);

// DELETE /api/v1/buildings/:buildingId/apartments/:id
router.delete("/:id", authMiddleware, deleteApartment);

export default router;
```

**Nested Route Bağlama (index.js):**

```javascript
import apartmentRouter from "./src/routes/apartmentRoutes.js";

// Building route'unun altına apartment'ları bağla
app.use("/api/v1/buildings/:buildingId/apartments", apartmentRouter);
```

### Controller: `src/controllers/apartmentControllers.js`

```javascript
import { prisma } from "../config/db.js";

/**
 * Bir binanın tüm dairelerini listele
 */
const getApartments = async (req, res) => {
  try {
    const { buildingId } = req.params;
    const managerId = req.user.id;

    // Önce binanın bu kullanıcıya ait olduğunu doğrula
    const building = await prisma.building.findUnique({
      where: { id: buildingId },
    });

    if (!building) {
      return res.status(404).json({ error: "Bina bulunamadı." });
    }

    if (building.managerId !== managerId) {
      return res.status(403).json({ error: "Yetkiniz yok." });
    }

    // Daireleri getir
    const apartments = await prisma.apartment.findMany({
      where: { buildingId },
      include: {
        _count: {
          select: { residents: true },
        },
      },
      orderBy: { number: "asc" },
    });

    res.status(200).json({
      success: true,
      data: apartments,
    });
  } catch (error) {
    console.error("Daire listeleme hatası:", error);
    res.status(500).json({ error: "Bir hata oluştu." });
  }
};

/**
 * Yeni daire ekle
 */
const createApartment = async (req, res) => {
  try {
    const { buildingId } = req.params;
    const { number, floor } = req.body;
    const managerId = req.user.id;

    // Validasyon
    if (!number) {
      return res.status(400).json({ error: "Daire numarası zorunludur." });
    }

    // Bina yetki kontrolü
    const building = await prisma.building.findUnique({
      where: { id: buildingId },
    });

    if (!building) {
      return res.status(404).json({ error: "Bina bulunamadı." });
    }

    if (building.managerId !== managerId) {
      return res.status(403).json({ error: "Bu binaya daire ekleme yetkiniz yok." });
    }

    // Aynı numarada daire var mı kontrol et
    const existingApartment = await prisma.apartment.findFirst({
      where: {
        buildingId,
        number: number.trim(),
      },
    });

    if (existingApartment) {
      return res.status(400).json({
        error: "Bu numarada bir daire zaten var.",
      });
    }

    // Daire oluştur
    const apartment = await prisma.apartment.create({
      data: {
        number: number.trim(),
        floor: floor ? parseInt(floor) : null,
        buildingId,
      },
    });

    res.status(201).json({
      success: true,
      message: "Daire başarıyla eklendi.",
      data: apartment,
    });
  } catch (error) {
    console.error("Daire oluşturma hatası:", error);
    res.status(500).json({ error: "Bir hata oluştu." });
  }
};

/**
 * Daire sil
 */
const deleteApartment = async (req, res) => {
  try {
    const { buildingId, id } = req.params;
    const managerId = req.user.id;

    // Bina yetki kontrolü
    const building = await prisma.building.findUnique({
      where: { id: buildingId },
    });

    if (!building || building.managerId !== managerId) {
      return res.status(403).json({ error: "Yetkiniz yok." });
    }

    // Daire kontrolü
    const apartment = await prisma.apartment.findFirst({
      where: {
        id,
        buildingId,
      },
      include: {
        _count: {
          select: { residents: true },
        },
      },
    });

    if (!apartment) {
      return res.status(404).json({ error: "Daire bulunamadı." });
    }

    // Sakin var mı kontrolü
    if (apartment._count.residents > 0) {
      return res.status(400).json({
        error: "Bu dairede sakinler var. Önce sakini daireden çıkarın.",
      });
    }

    await prisma.apartment.delete({
      where: { id },
    });

    res.status(200).json({
      success: true,
      message: "Daire silindi.",
    });
  } catch (error) {
    console.error("Daire silme hatası:", error);
    res.status(500).json({ error: "Bir hata oluştu." });
  }
};

export { getApartments, createApartment, deleteApartment };
```

---

## 🔍 Hata Ayıklama (Debugging) İpuçları

### 1. Konsol Logları

```javascript
// Her zaman console.log kullan
console.log("Request body:", req.body);
console.log("User ID:", req.user.id);
console.log("Params:", req.params);

// Prisma sorgusunu logla
const result = await prisma.building.findMany({
  where: { managerId },
});
console.log("Sorgu sonucu:", result);
```

### 2. Prisma Studio ile Veritabanını Gör

```bash
npx prisma studio
```
Tarayıcıda açılır, tabloları ve verileri görürsün.

### 3. Postman'de "Console" Kullan

Postman → View → Show Postman Console
Burada request/response detaylarını görürsün.

### 4. Sık Yapılan Hatalar

| Hata | Sebep | Çözüm |
|------|-------|-------|
| `Cannot read property 'findMany' of undefined` | Prisma client import hatası | `import { prisma } from "../config/db.js"` kontrol et |
| `Unique constraint failed` | Aynı veri tekrar ekleniyor | `findFirst` ile önce kontrol et |
| `Foreign key constraint failed` | Olmayan ID'ye referans | Önce kaynağın var olduğundan emin ol |
| `401 Unauthorized` | Token eksik/geçersiz | Header'da `Authorization: Bearer ...` olduğundan emin ol |
| `403 Forbidden` | Yetki yok | `managerId` kontrolünü doğru yapıp yapmadığın kontrol et |

---

## 📝 Ödev: Service Katmanı Ekle

Şu an controller'lar hem HTTP hem de business logic ile uğraşıyor. Gerçek projelerde Service katmanı eklenir.

**Görev:** `src/services/buildingService.js` oluştur ve controller'dan ayır.

```javascript
// src/services/buildingService.js
import { prisma } from "../config/db.js";

export const buildingService = {
  async getAllBuildings(managerId) {
    return await prisma.building.findMany({
      where: { managerId },
      include: { apartments: true },
    });
  },

  async getBuildingById(id, managerId) {
    const building = await prisma.building.findUnique({
      where: { id },
      include: { apartments: true },
    });

    if (!building) {
      throw new Error("Bina bulunamadı");
    }

    if (building.managerId !== managerId) {
      throw new Error("Yetkiniz yok");
    }

    return building;
  },

  // ... diğer metodlar
};
```

**Controller'da kullanım:**
```javascript
import { buildingService } from "../services/buildingService.js";

const getBuildings = async (req, res) => {
  try {
    const buildings = await buildingService.getAllBuildings(req.user.id);
    res.status(200).json({ success: true, data: buildings });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};
```

**Faydası:** Controller sadece HTTP işlemleriyle uğraşır, business logic Service'de olur.

---

## 🔀 API Versioning (v2 Nasıl Oluşturulur?)

Gelecekte API v2 yazmak istersen, şu adımları izle. Şu an için sadece bilgi amaçlı.

### Neden Versioning?

- Eski mobil app'ler v1 kullanmaya devam eder
- Yeni özellikler v2'de test edilir
- Client'lar kendi hızlarında geçiş yapar

### Strateji: Farklı Controller (Önerilen)

```
src/
├── routes/
│   ├── authRoutes.js          # v1
│   └── authRoutesV2.js        # v2 (yeni)
├── controllers/
│   ├── authControllers.js     # v1
│   └── authControllersV2.js   # v2 (yeni)
└── index.js                   # Her ikisini de bağla
```

### index.js'de Route Bağlama

```javascript
import authRouterV1 from "./src/routes/authRoutes.js";
import authRouterV2 from "./src/routes/authRoutesV2.js";

// V1 ve V2 birlikte çalışır
app.use("/api/v1/auth", authRouterV1);
app.use("/api/v2/auth", authRouterV2);
```

### V1 vs V2 Response Farkı

**V1 Login Response (Mevcut):**
```json
{
  "message": "Giriş başarılı.",
  "accessToken": "eyJ...",
  "refreshToken": "eyJ...",
  "user": { "id": "...", "email": "..." }
}
```

**V2 Login Response (Daha Standart):**
```json
{
  "success": true,
  "message": "Giriş başarılı.",
  "data": {
    "session": {
      "accessToken": "eyJ...",
      "refreshToken": "eyJ...",
      "expiresIn": 900
    },
    "user": { "id": "...", "email": "...", "apartment": {...} }
  },
  "meta": {
    "timestamp": "2026-04-26T14:30:00.000Z",
    "apiVersion": "v2"
  }
}
```

### V2 Controller'ın Yapısı

```javascript
// src/controllers/authControllersV2.js
const loginV2 = async (req, res) => {
  try {
    // ... aynı login mantığı

    // Fark: Daha zengin response
    res.status(200).json({
      success: true,
      message: "Giriş başarılı.",
      data: { session: {...}, user: {...} },
      meta: { timestamp: new Date().toISOString(), apiVersion: "v2" }
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: "Internal server error",
      data: null,
      meta: { timestamp: new Date().toISOString(), apiVersion: "v2" }
    });
  }
};
```

### Önemli Kurallar

1. **Asla version'sız route bırakma**
   ```javascript
   // YANLIŞ:
   app.use("/api/v1/auth", authRouter);
   app.use("/auth", authRouter);  // ← Kaldır
   ```

2. **V1'i hemen kapatma**
   - Eski client'lar v1 kullanmaya devam etsin
   - V2 stabil olduktan sonra v1'i deprecate et

3. **Her versiyon ayrı dosyada**
   - `authControllers.js` (v1)
   - `authControllersV2.js` (v2)
   - Karışıklığı önler

### Ne Zaman v2 Gerekir?

| Senaryo | Aksiyon |
|---------|---------|
| Response format değişecek | v2 oluştur |
| Yeni alanlar eklenecek (opsiyonel) | v1'de de eklenebilir |
| Eski alan kaldırılacak | v2'de kaldır, v1'de tut |
| Breaking change varsa | Mutlaka v2 |

**Şu an için:** v1 ile devam et. v2 gerektiğinde bu bölümü takip et.

---

## ✅ Tamamlama Kontrol Listesi

Her maddeyi tamamladığında işaretle:

- [ ] `buildingRoutes.js` oluşturuldu
- [ ] `buildingControllers.js` oluşturuldu (5 endpoint)
- [ ] `apartmentRoutes.js` oluşturuldu
- [ ] `apartmentControllers.js` oluşturuldu (3 endpoint)
- [ ] Route'lar `index.js`'e bağlandı
- [ ] Postman'de tüm endpoint'ler test edildi
- [ ] Auth middleware doğru çalışıyor (token olmadan erişim yok)
- [ ] Yetki kontrolü çalışıyor (başkasının binasına erişim yok)
- [ ] 200, 201, 400, 401, 403, 404 status kodları doğru dönüyor
- [ ] Validasyonlar çalışıyor (eksik alan, yanlış format)

---

## 🆘 Yardım İhtiyacı

Takıldığın yerlerde:
1. Bu dokümanı tekrar oku
2. Abdullah'ın yazdığı `authControllers.js`'e bak (örnek olarak)
3. Prisma dokümantasyonuna bak: https://www.prisma.io/docs
4. Bana (Abdullah) sor

**Unutma:** Hata yapmak normal. Console.log kullan, adım adım ilerle.

---

**Hazırlayan:** Abdullah (Backend Lead)  
**Hedef:** Yusuf (Junior Full-Stack)  
**Amaç:** Backend API geliştirmeyi öğrenmek ve Faz 1 görevlerini tamamlamak
