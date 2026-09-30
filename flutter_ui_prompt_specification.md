# Flutter UI Specification & Implementation Prompt: SIPAKU Jember

Dokumen ini dirancang sebagai instruksi detail untuk AI Coding Agent Flutter (seperti Cursor, GitHub Copilot, Roo Code, dll.) guna mengimplementasikan antarmuka aplikasi **SIPAKU Jember** ("Lapor Infrastruktur, Wujudkan Jember Lebih Baik") secara presisi berdasarkan desain UI yang diberikan.

---

## 1. System Overview & Core Guidelines

- **Framework**: Flutter (Target: Android & iOS)
- **Design Paradigm**: Clean Architecture / Feature-First Folder Structure.
- **State Management Recommendation**: Provider, Riverpod, atau BLoC.
- **Design Tokens & Theme**:
  - **Primary Brand Color**: Vibrant Magenta/Hot Pink (`#E91E63` / `#E6206F`)
  - **Gradient Header**: Linear Gradient dari `#D81B60` ke `#EC407A` (sudut miring ~135°)
  - **Background**: Soft White / Off-White (`#F8F9FD`)
  - **Card Surface**: Solid Pure White (`#FFFFFF`) dengan rounded corner besar ($16-24$ pt) dan soft shadow (`BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 16, offset: Offset(0, 4))`)
  - **Typography**: Google Fonts `Poppins` atau `Plus Jakarta Sans`.
  - **Status Colors**:
    - Diproses: Orange (`#FF9800` / `#FFF3E0` untuk background tag)
    - Verifikasi: Blue (`#2196F3` / `#E3F2FD` untuk background tag)
    - Selesai: Green (`#4CAF50` / `#E8F5E9` untuk background tag)
    - Menunggu: Red/Pink (`#E91E63` / `#FCE4EC` untuk background tag)

---

## 2. Dependencies & Assets Setup

Tambahkan dependensi berikut ke dalam `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  google_fonts: ^6.1.0
  flutter_svg: ^2.0.9
  cached_network_image: ^3.3.0
  flutter_staggered_animations: ^1.1.1
  badges: ^3.1.2

flutter:
  assets:
    - assets/images/
    - assets/icons/
```

---

## 3. Screen Specifications

---

### Screen 1: Splash / Animated Loading Screen (`splash_screen.dart`)

#### Visual & Behavioral Specs:
1. **Background**: Fullscreen gradien pink/magenta (`#D81B60` ke `#EC407A`) dengan watermark lingkaran samar (`Opacity 0.08 - 0.15`).
2. **Center Element**:
   - Logo Container: Rounded rectangle (`borderRadius: BorderRadius.circular(28)`), warna magenta dengan border tipis transparan, glow lembut, dan icon rumah putih di tengahnya dengan atap beraksen kecil di atasnya.
   - Efek Ripple/Pulse: Animasi gelombang lingkaran meluas di balik logo container.
3. **Typography**:
   - Judul: **SIPAKU** (Bold, Putih, ukuran 32pt, tracking 1.2).
   - Badge: Kapsul di samping kanan judul bertuliskan "Jember" (background putih semi-transparan `Colors.white.withOpacity(0.25)`).
   - Tagline: *"Lapor Infrastruktur, Wujudkan Jember Lebih Baik"* (Putih, Italic, ukuran 13pt).
4. **Bottom Element**:
   - Loading Animation: 3 titik bouncing dots yang beranimasi berurutan (Bouncing Dot Indicator).
   - Footer: Icon checklist shield shield `Kabupaten Jember` dan teks sub: `Pemerintah Daerah — DISKOMINFO` (Putih, ukuran 11pt).

#### Animation Instructions for Agent:
- Implementasikan `AnimationController` dengan efek:
  - Fade-in & Scale-up untuk Logo Container.
  - Looping pulse animation pada ring di sekitar logo.
  - Three-dot horizontal pulsating loader di bagian bawah.
  - Navigasi otomatis setelah 3 detik menggunakan `PageRouteBuilder` transisi fade ke halaman Auth / Home.

---

### Screen 2: Authentication & Registration Screen (`register_screen.dart` & `login_screen.dart`)

#### Visual Specs:
1. **Header**:
   - Curved bottom / wavy header dengan gradien pink/magenta khas SIPAKU.
   - Logo lingkaran kecil di tengah atas (icon rumah putih).
   - Teks Judul: **Buat Akun Baru**, subjudul: **SIPAKU Jember** (warna teks putih).
2. **Stepper Indicator**:
   - Stepper horizontal 2-langkah:
     - `1 Data Diri` (Aktif: badge angka lingkaran 1)
     - `2 Lokasi & Konfirmasi`
3. **Form Card (Floating Card)**:
   - Container putih melengkung (`borderRadius: BorderRadius.circular(24)`), padding 20pt.
   - Input Fields bergaya rounded pill/box outline (`borderRadius: BorderRadius.circular(16)`), warna border abu-abu sangat muda (`#E0E5ED`), background putih transparan.
   - Form Fields:
     1. **Nama Lengkap**: Prefix icon `Icons.person_outline`
     2. **Alamat Email**: Prefix icon `Icons.mail_outline`
     3. **No. HP / WhatsApp**: Prefix icon `Icons.phone_outlined`
     4. **Password**: Prefix icon `Icons.lock_outline`, suffix icon mata toggle `Icons.visibility_off_outlined`
     5. **Konfirmasi Password**: Prefix icon `Icons.lock_outline`, suffix icon mata toggle.
4. **Actions**:
   - Tombol Utama: Gradient / solid hot-pink pill button (`borderRadius: BorderRadius.circular(30)`), teks: **Lanjut →** dengan elevated shadow pink lembut.
   - Footer Text: *"Sudah punya akun? "* (Abu-abu) + *"Masuk"* (Bold Pink link).

#### Form Sign In (Login) Variant:
- Header serupa dengan teks: **Masuk ke Akun**.
- Input: Email/No. HP dan Password.
- Opsi: *Lupa Kata Sandi?* dan tombol **Masuk**.
- Tautan bawah: *"Belum punya akun? "* + *"Daftar Sekarang"*.

---

### Screen 3: Home Dashboard Screen (`home_screen.dart`)

#### Visual Specs (Top to Bottom):

1. **Top Curved Header**:
   - Gradien magenta, pojok kiri-bawah melengkung dinamis.
   - Greeting: *"Halo, Andi! 👋"*, Subjudul: *"Ada yang bisa dilaporkan hari ini?"* (Bold, 20pt, Putih).
   - Info Lokasi: Dot hijau + `Kab. Jember • 3 Sep 2026` (Ukuran 12pt, putih/semi-transparan).
   - Header Actions (Kanan):
     - Icon Bell (Notifikasi) dengan badge counter angka merah (`3`).
     - Avatar bulat foto profil user.

2. **Search Bar**:
   - Floating di batas antara header dan body.
   - Rounded pill (`borderRadius: BorderRadius.circular(20)`), box shadow lembut.
   - Prefix: Icon search. Placeholder: *"Cari laporan infrastruktur..."*.
   - Suffix: Tombol filter kotak rounded berwarna soft pink (`#FCE4EC`) dengan icon filter pink.

3. **Summary KPI Cards (3 Kolom Row)**:
   - Card 1: Icon box memo pink muda + Angka `12` + Label `Laporan Saya`.
   - Card 2: Icon gear oranye muda + Angka `3` + Label `Diproses`.
   - Card 3: Icon check hijau muda + Angka `9` + Label `Selesai`.

4. **Aksi Cepat (Quick Actions Horizontal Menu)**:
   - Row icon kategori dalam rounded squircle button:
     1. **Lapor Sekarang**: Icon kamera putih di dalam kotak gradien pink mencolok.
     2. **Laporan Saya**: Icon file/dokumen outline.
     3. **Peta**: Icon peta lipat.
     4. **Info**: Icon huruf i info circle.

5. **Section: Laporan Terbaru Saya**:
   - Header section: Title *"Laporan Terbaru Saya"* + sub *"Update real-time"* + link kanan *"Lihat Semua >"* (Pink).
   - Item Card (List Vertikal):
     - Thumbnail foto di kiri (persegi rounded `BorderRadius.circular(12)`).
     - Title (e.g., *"Jalan Berlubang di Jl. PB Sudirman"*).
     - Location subtitle: Icon pin + *"Patrang, Jember"*.
     - Status Tag: Dot + label (e.g. `Diproses`, `Verifikasi`, `Selesai`).
     - Date label di kanan (e.g., `12 Sep 2026`).
     - Progress line bar di bagian bawah card mencerminkan tahapan status.

6. **Section: Laporan di Sekitar**:
   - Header: *"Laporan di Sekitar"* + sub *"Radius 1 km dari lokasi Anda"* + action *"Lihat Peta >"*.
   - Horizontal ListView Card:
     - Image card dengan badge jarak di pojok kanan atas (misal: `120 m`, `340 m`).
     - Overlay status dot di atas gambar (misal: `Menunggu`, `Diproses`).
     - Judul laporan di bawah gambar (misal: *"Drainase Tersumbat Gang Melati"*).

7. **Banner Kontribusi ("Kontribusi Kamu Berarti!")**:
   - Banner lebar dengan latar gradien pink magenta dan dekorasi bunga / ilustrasi.
   - Text kiri: *"Kontribusi Kamu Berarti! 12 laporan kamu sudah membantu memperbaiki infrastruktur Jember."*.
   - Badge kanan: Lingkaran pink berisi angka total selesai `9 Selesai`.

8. **Custom Bottom Navigation Bar**:
   - White docked navigation bar dengan curved notch atau floating action.
   - 4 Nav Items:
     - **Beranda** (Aktif - icon home pink + indicator line).
     - **Peta** (Icon map).
     - **Tracking** (Icon radar/progress).
     - **Profil** (Icon user person).
   - Center Floating Action Button (FAB):
     - Tombol tengah kamera pink besar ber-glow (`BoxShadow(color: primaryColor.withOpacity(0.4), blurRadius: 12)`) dengan label *"Lapor"*.

---

## 4. Suggested Project Folder Structure

```text
lib/
├── core/
│   ├── constants/
│   │   ├── colors.dart
│   │   └── text_styles.dart
│   └── theme/
│       └── app_theme.dart
├── features/
│   ├── splash/
│   │   ├── presentation/
│   │   │   └── screens/
│   │   │       └── splash_screen.dart
│   │   └── widgets/
│   │       └── pulsing_logo.dart
│   ├── auth/
│   │   └── presentation/
│   │       ├── screens/
│   │       │   ├── login_screen.dart
│   │       │   └── register_step1_screen.dart
│   │       └── widgets/
│   │           └── custom_text_field.dart
│   └── home/
│       └── presentation/
│           ├── screens/
│           │   └── home_screen.dart
│           └── widgets/
│               ├── home_header.dart
│               ├── kpi_card.dart
│               ├── quick_action_item.dart
│               ├── report_tile.dart
│               └── nearby_report_card.dart
└── main.dart
```

---

## 5. Sample Core Constants (`app_colors.dart`)

```dart
import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFFE61B69);
  static const Color primaryDark = Color(0xFFC2185B);
  static const Color primaryLight = Color(0xFFF06292);
  static const Color accentPink = Color(0xFFFCE4EC);

  static const Color background = Color(0xFFF8F9FE);
  static const Color cardSurface = Colors.white;
  
  static const Color textPrimary = Color(0xFF1E2432);
  static const Color textSecondary = Color(0xFF757F95);
  static const Color textMuted = Color(0xFF9EA6BA);

  // Status Indicators
  static const Color statusPending = Color(0xFFE91E63);
  static const Color statusProcessing = Color(0xFFFF9800);
  static const Color statusVerification = Color(0xFF2196F3);
  static const Color statusCompleted = Color(0xFF4CAF50);

  // Gradient
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFD81B60), Color(0xFFE91E63), Color(0xFFEC407A)],
  );
}
```

---

## 6. Prompt Instruction for Flutter AI Agent

Gunakan prompt instruksi di bawah ini saat menyerahkan file ini ke AI:

> *"Tolong buatkan implementasi kode Flutter lengkap untuk 3 halaman berdasarkan spesifikasi file Markdown ini: Splash Screen beranimasi (`splash_screen.dart`), Form Registrasi Step 1 (`register_screen.dart`), dan Beranda (`home_screen.dart`). Pastikan UI rapi, responsif menggunakan `SingleChildScrollView`, warna dan bentuk widget persis seperti deskripsi desain SIPAKU Jember, dan kode dipisah ke dalam widget modular yang bersih."*