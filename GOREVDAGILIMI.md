# 📋 AidatPanel Geliştirme Yol Haritası ve Görev Dağılımı

Bu belge, **AidatPanel** projesinin geliştirme sürecini öğrencilerin yetenek seviyelerine (Abdullah > Furkan > Yusuf > Seyit) göre fazlara ayırır ve sorumlulukları tanımlar.

---

## 👥 Proje Ekibi ve Rolleri

| Öğrenci | Rol | Odak Noktası |
| :--- | :--- | :--- |
| **Abdullah** | Lead Developer | Backend Mimari, DevOps, Entegrasyonlar |
| **Furkan** | Senior Mobile | Flutter Core, Kritik Yönetici Modülleri |
| **Yusuf** | Junior Full-Stack | API Geliştirme, Sakin Dashboard |
| **Seyit** | Junior UI/UX | Tasarım Sistemi, Landing Page, Bildirimler |

---

## 🚀 Faz 1: Temel Altyapı ve Kimlik Doğrulama (MVP-1)
*Hedef: Veritabanının kurulması ve güvenli giriş/kayıt sisteminin tamamlanması.*

### **Abdullah (Backend Lead)**
- PostgreSQL veritabanı kurulumu ve Prisma şeması tasarımı.
- JWT tabanlı Auth sistemi (Access/Refresh token) ve şifreleme.
- API mimarisinin kurulması (`/api/v1` prefix).

### **Furkan (Mobile Core)**
- Flutter projesinin temiz mimari (Clean Architecture) ile başlatılması.
- Riverpod state management ve GoRouter navigasyon altyapısı.
- Login ve Register ekranlarının backend entegrasyonu.

### **Yusuf (Building API)**
- Bina ve Daire CRUD (Ekle/Sil/Listele) endpoint'lerinin yazılması.
- Yönetici bazlı veri filtreleme mantığının kurulması.

### **Seyit (UI & Web)**
- `AppColors`, `AppTypography` ve ortak widget'ların (Düğmeler, Inputlar) oluşturulması.
- HTML/CSS ile statik Landing Page (Tanıtım sayfası) hazırlanması.

---

## 🚀 Faz 2: Aidat Sistemi ve Onboarding (MVP-2)
*Hedef: Aidat döngüsünün başlatılması ve sakinlerin davet koduyla katılımı.*

### **Abdullah (Logic & Payment)**
- Davet kodu (Invite Code) üretim ve doğrulama algoritması.
- Toplu aidat oluşturma (Bulk creation) arka plan işleri.
- RevenueCat abonelik kontrol middleware'i.

### **Furkan (Manager Hub)**
- Yönetici ekranı: Daire listesi, davet kodu yönetimi (Pop-up).
- Aidat ödeme durumlarını (Ödendi/Bekliyor) manuel değiştirme arayüzü.

### **Yusuf (Resident Hub)**
- Sakin ekranı: "Davet Koduyla Katıl" akışı.
- Kendi aidat geçmişini görüntüleme ve filtreleme ekranı.

### **Seyit (Notify & i18n)**
- Firebase FCM (Push Notification) entegrasyonu.
- Uygulama içi yerelleştirme (TR/EN) için ARB dosyalarının yönetimi.

---

## 🚀 Faz 3: Giderler, Destek ve Raporlama (Final)
*Hedef: Finansal raporlama ve kullanıcı destek sisteminin eklenmesi.*

### **Abdullah (Reporting)**
- PDF Rapor oluşturma servisi (Aylık bina özeti).
- Twilio WhatsApp/SMS hatırlatıcı servisinin API entegrasyonu.

### **Furkan (Ticket System)**
- Arıza/Talep (Ticket) sistemi mobil arayüzü.
- Sakin hata bildirimi ve yönetici yanıt akışının (TicketUpdate) kurulması.

### **Yusuf (Finance)**
- Gider kayıt sistemi (Gider ekleme, kategori seçimi).
- Bina bazlı aylık gider özeti API'ları.

### **Seyit (UX Fixes)**
- Profil düzenleme ve şifre yenileme ekranları.
- Boş liste durumları (Empty State) ve hata mesajlarının UX iyileştirmesi.

---

## 🛠️ Teknik Standartlar ve Kurallar

1.  **Kod İncelemesi (Code Review):** Abdullah tüm Merge Request'leri (MR) inceleyerek onay verir.
2.  **Git Akışı:** Herkes kendi branch'inde çalışır (örn: `feature/furkan-tickets`).
3.  **Tasarım Kısıtı:** 50+ yaş kullanıcılar için:
    - Minimum font boyutu: **16sp**.
    - Minimum dokunma alanı: **48dp**.
    - Hamburger menü yerine **Bottom Navigation** kullanımı zorunludur.
4.  **Hata Yönetimi:** Tüm hatalar kullanıcıya teknik terimlerden arındırılmış, anlaşılır Türkçe ile sunulacaktır.

---

**Durum:** Beklemede 🟡 | **Sürüm:** v1.0.0