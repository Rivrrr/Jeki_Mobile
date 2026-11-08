# Dokumentasi Fitur Aplikasi Mobile - Modul Masyarakat

Dokumen ini berisi penjelasan menyeluruh mengenai seluruh fitur yang tersedia pada modul **Masyarakat**, mencakup alur kerja, logika teknis, dan lokasi source code.

---

## 1. Sistem Pelaporan Kerusakan (Core Feature)
Fitur utama yang memungkinkan masyarakat melaporkan kerusakan infrastruktur secara valid.

### Alur Kerja
Pengguna mengisi formulir laporan melalui proses *multi-step* untuk memudahkan pengisian data:
**Langkah $\rightarrow$ Foto $\rightarrow$ Deskripsi $\rightarrow$ Kategori $\rightarrow$ Konfirmasi $\rightarrow$ Selesai**.

### Cara Kerja Teknis
- **GPS Integration:** Saat pengguna mengambil foto melalui kamera internal aplikasi, sistem secara otomatis mengambil koordinat GPS (Latitude & Longitude) menggunakan `geolocator`. Ini mencegah laporan palsu atau lokasi yang tidak akurat.
- **Multi-Step State:** Data disimpan sementara dalam state management selama proses pengisian langkah demi langkah sebelum akhirnya dikirim secara kolektif ke server.
- **API Submission:** Data dikirim melalui metode `POST` ke backend Laravel menggunakan `LaporanService`.

### Lokasi Kode
- **Halaman Utama Form:** `lib/features/masyarakat/presentation/pages/laporan/create/create_laporan_page.dart`
- **Kamera GPS:** `lib/features/masyarakat/presentation/pages/laporan/gps_camera_page.dart`
- **Widget Langkah-langkah:** `lib/features/masyarakat/presentation/widgets/laporan/` (semua file `step_*.dart`)
- **Logika API:** `lib/features/masyarakat/data/laporan_service.dart`

---

## 2. Pelacakan Riwayat Laporan (My Reports)
Fitur untuk memantau status penanganan laporan yang telah dikirimkan oleh pengguna.

### Alur Kerja
Menampilkan daftar seluruh laporan yang dikirim oleh akun yang sedang login, dengan opsi filter berdasarkan status (Baru, Ditinjau, Diproses, Selesai) dan fitur pencarian.

### Cara Kerja Teknis
- **Data Fetching:** `LaporanService` memanggil endpoint API untuk mengambil data laporan berdasarkan ID User yang tersimpan di `StorageService`.
- **Client-side Filtering:** Daftar laporan difilter menggunakan `TabBar` untuk mengelompokkan laporan berdasarkan statusnya.
- **Search Logic:** Implementasi pencarian teks sederhana yang mencocokkan kata kunci dengan nomor laporan, judul, atau lokasi.

### Lokasi Kode
- **Halaman Daftar:** `lib/features/masyarakat/presentation/pages/laporan/list/my_laporan_page.dart`
- **Halaman Detail:** `lib/features/masyarakat/presentation/pages/laporan/detail/laporan_detail_page.dart`

---

## 3. Peta Interaktif (Map View)
Visualisasi distribusi laporan infrastruktur di seluruh wilayah.

### Alur Kerja
Menampilkan peta dengan marker berwarna yang merepresentasikan status laporan. Pengguna dapat mengklik marker untuk melihat ringkasan laporan tersebut.

### Cara Kerja Teknis
- **Map Engine:** Menggunakan `flutter_map` dengan dukungan tile dari Google Maps.
- **Dynamic Markers:** Mengambil semua data laporan dari server dan mengubah koordinat latitude/longitude menjadi `Marker` pada peta.
- **User Tracking:** Menggunakan stream dari `geolocator` untuk menampilkan posisi pengguna secara real-time dengan efek *pulsing dot*.
- **Navigation Compass:** Menggunakan `flutter_compass` untuk memutar arah peta sesuai dengan hadapan fisik pengguna.

### Lokasi Kode
- **Halaman Peta:** `lib/features/masyarakat/presentation/pages/peta/peta_page.dart`

---

## 4. Manajemen Profil & Pengaturan
Pengelolaan identitas pengguna dan akses ke informasi pendukung.

### Alur Kerja
Menampilkan informasi profil pengguna dan menyediakan akses ke dokumen kebijakan privasi, syarat dan ketentuan, serta halaman bantuan.

### Cara Kerja Teknis
- **Session Management:** Mengambil data user dari `StorageService` (yang sebelumnya disimpan saat login).
- **Static Content Pages:** Halaman-halaman informasi legal menggunakan layout sederhana untuk menampilkan teks dokumen.

### Lokasi Kode
- **Halaman Profil:** `lib/features/masyarakat/presentation/pages/profil/profil_page.dart`
- **Halaman Legal/Bantuan:** `lib/features/masyarakat/presentation/pages/profil/` (files: `privacy_page.dart`, `terms_page.dart`, `help_page.dart`, dll.)

---

## 5. Sistem Notifikasi
Pusat informasi pemberitahuan mengenai perkembangan status laporan.

### Alur Kerja
Memberikan peringatan kepada pengguna ketika ada perubahan status laporan (misal: "Laporan Anda sedang diproses").

### Cara Kerja Teknis
- **Push Notification:** Menggunakan Firebase Cloud Messaging (FCM).
- **Deep Linking:** Saat notifikasi diketuk, aplikasi menggunakan `navigatorKey` untuk mengarahkan pengguna langsung ke halaman detail laporan yang spesifik.

### Lokasi Kode
- **Halaman Notifikasi:** `lib/features/masyarakat/presentation/pages/notifikasi/notifikasi_page.dart`

---

## 6. Onboarding (Pengenalan Aplikasi)
Panduan singkat untuk pengguna baru.

### Alur Kerja
Menampilkan slide pengenalan fitur-fitur utama aplikasi sebelum masuk ke dashboard utama.

### Cara Kerja Teknis
- **PageView:** Menggunakan `PageView` untuk navigasi antar slide.
- **Persistence:** Setelah pengguna menyelesaikan onboarding, sebuah flag disimpan di `StorageService` agar onboarding tidak muncul kembali saat aplikasi dibuka di lain waktu.

### Lokasi Kode
- **Halaman Onboarding:** `lib/features/masyarakat/presentation/pages/onboarding/onboarding_page.dart`

---

## 7. Data & Service Layer (Fondasi Aplikasi)
Kumpulan fungsi pendukung yang menangani data dan komunikasi server.

### Deskripsi Fungsi
- **UserService:** Mengelola data akun, token autentikasi, dan sinkronisasi token FCM.
- **LaporanService:** Menangani seluruh request HTTP untuk pembuatan laporan dan penarikan data laporan.
- **StorageService:** Wrapper untuk `shared_preferences` untuk menyimpan data sesi secara lokal.

### Lokasi Kode
- `lib/features/masyarakat/data/user_service.dart`
- `lib/features/masyarakat/data/laporan_service.dart`
- `lib/core/services/storage_service.dart`
