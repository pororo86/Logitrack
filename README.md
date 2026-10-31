# Logitrack 🚚

**Logitrack** adalah aplikasi mobile berbasis Flutter yang dirancang untuk membantu proses pengelolaan dan pemantauan pengiriman barang. Aplikasi ini menyediakan antarmuka bagi pengguna untuk mengatur tujuan pengiriman, memantau tahapan perjalanan, serta melakukan validasi pengiriman melalui kamera dan lokasi.

## ✨ Fitur Utama

- **Authentication** — Halaman login pengguna.
- **Dashboard** — Menampilkan ringkasan aktivitas pengiriman.
- **Shipment Management** — Mengatur dan menambahkan tujuan pengiriman.
- **In Transit** — Melihat daftar pengiriman yang sedang berjalan.
- **Process Monitoring** — Memantau proses pengiriman.
- **Next Destination** — Menampilkan tujuan pengiriman berikutnya.
- **Completed Shipment** — Menampilkan pengiriman yang telah selesai.
- **Location Picker** — Memilih lokasi tujuan pengiriman.
- **Photo Validation** — Validasi pengiriman menggunakan kamera.
- **Location Service** — Mendukung pengambilan informasi lokasi perangkat.

## 🛠️ Tech Stack

| Teknologi       | Kegunaan                        |
| --------------- | ------------------------------- |
| Flutter         | Framework pengembangan aplikasi |
| Dart            | Bahasa pemrograman              |
| Material Design | Antarmuka aplikasi              |
| Android SDK     | Platform Android                |
| Geolocation     | Layanan informasi lokasi        |
| Camera          | Pengambilan foto untuk validasi |

## 📁 Project Structure

```text
lib/
├── core/
│   ├── config/
│   ├── theme/
│   ├── utils/
│   └── widgets/
│
├── data/
│   └── mock_data.dart
│
├── features/
│   ├── auth/
│   ├── dashboard/
│   ├── shipment/
│   └── validation/
│
├── services/
│   ├── location_service.dart
│   └── photo_service.dart
│
└── main.dart

android/
ios/
linux/
macos/
web/
windows/
test/

pubspec.yaml
pubspec.lock
analysis_options.yaml
```

## ⚙️ Requirements

Pastikan perangkat pengembangan sudah memiliki:

- Flutter SDK
- Dart SDK
- Android Studio atau Visual Studio Code
- Android SDK
- Git

## 🚀 Installation

**1. Clone repository**

```bash
git clone https://github.com/pororo86/Logitrack.git
```

**2. Masuk ke direktori project**

```bash
cd Logitrack
```

**3. Install dependencies**

```bash
flutter pub get
```

**4. Periksa konfigurasi Flutter**

```bash
flutter doctor
```

**5. Jalankan aplikasi**

```bash
flutter run
```

Untuk menjalankan aplikasi pada perangkat Android tertentu:

```bash
flutter devices
flutter run -d DEVICE_ID
```

## 📱 Supported Platforms

Project memiliki direktori konfigurasi untuk beberapa platform:

- Android
- iOS
- Web
- Windows
- Linux
- macOS

Ketersediaan konfigurasi platform tidak selalu berarti seluruh fitur sudah diuji atau siap digunakan pada setiap platform.

## 🔄 Development Workflow

Untuk mengirimkan perubahan terbaru ke repository:

```bash
git add .
git commit -m "feat: update application feature"
git push
```

## 📌 Project Status

**Development**

Logitrack masih dalam tahap pengembangan. Fitur dan arsitektur aplikasi dapat mengalami perubahan seiring proses pengembangan.

## 👨‍💻 Repository

GitHub: https://github.com/pororo86/Logitrack

---

_Built with Flutter & Dart._
