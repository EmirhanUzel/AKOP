# AKOP
### Akıllı İhbar ve Saha Operasyon Yönetim Platformu

AKOP, vatandaşların karşılaştıkları fiziksel sorunları
fotoğraf, konum ve açıklama ile bildirebildikleri;
bildirimlerin ilgili kurumlara yönlendirildiği ve
saha operasyonlarının takip edilebildiği
yapay zekâ destekli bir platformdur.

**Üniversite:** Ankara Üniversitesi  
**Bölüm:** Bilgisayar Mühendisliği  
**Proje Türü:** Bitirme Projesi  
**Geliştiriciler:** Emirhan Üzel, Enes Bayar  
**Akademik Yıl:** 2026–2027

---

## 1. Projenin Amacı

AKOP, vatandaş bildirimlerinden saha müdahalesine kadar
tüm sürecin tek platform üzerinden yönetilmesini amaçlar.

Temel süreç:

1. Vatandaş fotoğraf, konum ve açıklama ile ihbar oluşturur.
2. İhbar yapay zekâ destekli analizlerden geçirilir.
3. Sistem ilgili olabilecek kurumları önerir.
4. Kurum ihbarı kabul eder veya gerekçeli olarak reddeder.
5. Kabul edilen ihbar için iş emri oluşturulur.
6. Yetkili yönetici uygun saha ekibini görevlendirir.
7. Saha ekibi müdahaleyi gerçekleştirir.
8. Çözüm görselleri ve vatandaş doğrulamasıyla süreç tamamlanır.

---

## 2. Kullanılan Teknolojiler

| Katman | Teknoloji |
|---|---|
| Backend | ASP.NET Core (.NET 10) |
| Mimari | Microservices |
| Mobil Uygulama | Flutter / Dart |
| Web Yönetim Paneli | React / TypeScript |
| Veritabanı | PostgreSQL |
| ORM | Entity Framework Core |
| Coğrafi İşlemler | PostGIS |
| Görsel Depolama | S3 Uyumlu Object Storage |
| Kimlik Doğrulama | JWT (Planlanan) |

---

## 3. Sistem Mimarisi

AKOP backend sistemi beş bağımsız mikroservisten oluşacak
şekilde tasarlanmıştır.

### IdentityService
Kullanıcı hesapları, kimlik doğrulama ve rol yönetimi.

### InstitutionService
Kurumlar, kurum birimleri ve coğrafi sorumluluk alanları.

### ReportService
Vatandaş ihbarlarının oluşturulması, görselleri ve takibi.

### RoutingService
İhbarların ilgili kurumlara önerilmesi, kabul ve ret süreçleri.

### WorkOrderService
İş emirleri, saha ekipleri, görevlendirme ve çözüm süreçleri.

Her mikroservisin kendisine ait mantıksal PostgreSQL
veritabanı bulunması planlanmaktadır.

Servisler birbirlerinin veritabanlarına doğrudan erişmeyecek;
iletişim API ve gerektiğinde olay tabanlı mekanizmalarla
sağlanacaktır.

---

## 4. Proje Klasör Yapısı

```text
AKOP/
│
├── backend/
│   ├── AKOP.slnx
│   └── src/
│       ├── IdentityService/
│       ├── InstitutionService/
│       ├── ReportService/
│       ├── RoutingService/
│       └── WorkOrderService/
│
├── mobile/
│   └── akop_mobile/
│
├── web/
│   └── akop_admin/
│
├── docs/
│   ├── 01-On-Proje/
│   └── 02-Teknik-Tasarim/
│
├── .gitignore
└── README.md
```

---

## 5. Kurulum ve Çalıştırma

### 5.1 Gereksinimler

Geliştirme ortamında aşağıdaki araçlar gereklidir:

- .NET SDK 10
- Flutter SDK
- Node.js ve npm
- Git
- Android SDK ve Android emülatörü (mobil testler için)

PostgreSQL, veritabanı entegrasyonları geliştirildiğinde
gerekli olacaktır.

### 5.2 Repository'yi Klonlama

```bash
git clone https://github.com/EmirhanUzel/AKOP.git
cd AKOP
```

### 5.3 Backend

```bash
cd backend

dotnet restore AKOP.slnx
dotnet build AKOP.slnx
```

Örnek olarak IdentityService'i çalıştırmak:

```bash
dotnet run --project src/IdentityService --launch-profile http
```

Mikroservislerin geliştirme portları:

| Mikroservis | Port |
|---|---|
| IdentityService | 5101 |
| InstitutionService | 5102 |
| ReportService | 5103 |
| RoutingService | 5104 |
| WorkOrderService | 5105 |

Her mikroservis ayrı terminalde çalıştırılabilir.

### 5.4 Flutter

Repository ana dizininden:

```bash
cd mobile/akop_mobile

flutter pub get
flutter devices
flutter run
```

Birden fazla cihaz bağlıysa:

```bash
flutter run -d <device-id>
```

Android emülatörlerini listelemek için:

```bash
flutter emulators
```

### 5.5 React Yönetim Paneli

Repository ana dizininden:

```bash
cd web/akop_admin

npm install
npm run dev
```

Geliştirme sunucusunun gösterdiği yerel adres
üzerinden yönetim paneline erişilebilir.

React kod kontrolleri:

```bash
npm run lint
npm run build
```

---

## 6. Git ve Branch Yönetimi

AKOP, tek bir GitHub repository'si içerisinde
geliştirilmektedir.

`main` branch'i projenin kararlı sürümünü içerir.

Yeni özellikler için ayrı geliştirme branch'leri kullanılır.

Örnek:

```bash
git switch main
git pull --ff-only origin main

git switch -c feature/identity-auth
```

Geliştirme tamamlandığında değişiklikler commit edilir,
GitHub'a gönderilir ve Pull Request üzerinden
main branch'ine birleştirilir.

---

## 7. Dokümantasyon

Projenin teknik ve akademik belgeleri `docs/`
klasöründe bulunmaktadır.

### Ön Proje Dokümanı

[AKOP Ön Proje Dokümanı](docs/01-On-Proje/AKOP_On_Proje_Dokumani.docx)

### Teknik Tasarım Dokümanı

[AKOP Teknik Tasarım](docs/02-Teknik-Tasarim/AKOP_12-18_Ekim_2026_Teknik_Tasarim_API_Sadelestirilmis.pdf)

Not: Ön proje belgesi ilk tasarım kararlarını içerir.
Güncel backend yaklaşımı beş bağımsız mikroservistir.

---

## 8. Geliştirme Durumu

### Tamamlanan Altyapı Çalışmaları

- [x] Beş ASP.NET Core mikroservisinin oluşturulması
- [x] .NET Solution yapılandırması
- [x] Mikroservislerin derleme ve çalışma testleri
- [x] Flutter proje altyapısı
- [x] Flutter tema ve klasör yapısı
- [x] Android emülatör testi
- [x] React + TypeScript proje altyapısı
- [x] React tema ve klasör yapısı
- [x] GitHub repository ve branch düzeni

### Planlanan Geliştirmeler

- [ ] Kimlik doğrulama ve kullanıcı yönetimi
- [ ] Kurum yönetimi ve veritabanı entegrasyonları
- [ ] İhbar oluşturma ve takip sistemi
- [ ] Akıllı kurum yönlendirme
- [ ] Saha ekibi ve iş emri yönetimi
- [ ] Yapay zekâ analizlerinin entegrasyonu
- [ ] Mobil ve web uygulamalarının backend entegrasyonu
- [ ] Sistem testleri

---

## 9. Geliştiriciler

**Emirhan Üzel**  
**Enes Bayar**

