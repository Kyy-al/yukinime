# 🌌 YUKINIME — Premium Anime Streaming Application

<p align="center">
  <img src="https://raw.githubusercontent.com/flutter/assets/master/flutter_logo/flutter_logo.png" width="80" alt="Flutter Logo"/>
  <br/>
  <b>Midnight Anime Experience • Built with Flutter & Dart</b>
</p>

---

## 📖 Ringkasan Proyek
**YUKINIME** (青空) adalah aplikasi streaming anime Android berperforma tinggi dengan antarmuka bertema **Midnight Anime Experience** (Dark Slate Blue & Electric Cyan). Aplikasi dirancang dengan arsitektur bersih (*Feature-First Clean Architecture*), integrasi API nyata (Sankavollerei Otakudesu API), pemutar media kustom berfitur lengkap, dan sistem penyimpanan lokal (*Hive*).

---

## ✨ Fitur Utama

### 1. 🎬 Discovery & Beranda
- **Hero Banner Carousel**: Menampilkan anime unggulan dengan poster sinematik, tag genre, rating bintang, dan tombol aksi langsung.
- **Lanjutkan Menonton (Continue Watching)**: Menampilkan riwayat anime yang sedang ditonton dengan progress bar akurat, durasi tersisa, dan tombol lanjut ke detik terakhir.
- **Episode Terbaru (Update Terkini)**: Carousel horizontal update episode anime terbaru dengan label episode dan waktu rilis.
- **Rekomendasi Populer**: Grid 3 kolom anime dengan rating tertinggi dan badge studio.
- **Film Anime**: Koleksi film layar lebar anime pilihan.
- **Pull-to-Refresh**: Sinkronisasi data terkini dengan tarikan layar.

### 2. 🔍 Pencarian Pintar (Smart Search)
- **Live Search Debounce**: Pencarian otomatis dengan penundaan 500ms untuk efisiensi jaringan & menghindari rate-limit API.
- **Riwayat Pencarian Lokal**: Menyimpan riwayat pencarian dalam Hive dengan kemampuan menghapus per kata kunci atau hapus semua.
- **Pencarian Populer**: Chip saran pencarian cepat (Naruto, One Piece, Jujutsu Kaisen, dll).
- **Hasil Responsif**: Tampilan grid dengan informasi total hasil dan penanganan status kosong/error.

### 3. 📑 Halaman Detail Anime
- **Header Sinematik**: Backdrop gambar anime dengan overlay gradien gelap yang elegan.
- **Informasi Lengkap**: Rating MyAnimeList/API, Studio produksi, Status (Ongoing/Completed), Tahun rilis, dan Tipe (TV/Movie).
- **Tag Genre Interaktif**: Badge genre modern.
- **Tombol Pintar "Mulai Menonton"**: Otomatis mendeteksi riwayat; jika pernah ditonton akan menampilkan *"Lanjutkan: Episode X"*, jika baru akan memutar Episode 1.
- **Koleksi (Bookmarks)**: Tambah/hapus dari **Favorit** dan **Watchlist** secara instan.
- **Sinopsis Interaktif**: Teks sinopsis yang dapat diperluas (*expand/collapse*).
- **Daftar Episode & Pengurutan**: Urutkan episode dari Terlama (Ascending) atau Terbaru (Descending), dengan badge penanda episode yang sedang/terakhir ditonton.

### 4. 📺 Pemutar Media Tingkat Lanjut (Advanced Video Player)
- **Dukungan MP4 Asli**: Streaming langsung format MP4 menggunakan `video_player`.
- **Pemilihan Resolusi**: Penggantian resolusi dinamis (480p SD / 720p HD) melalui bottom sheet modal.
- **Kontrol Gestur & Tombol**:
  - Tombol Quick Seek **±5 Detik**.
  - Scrubber bar halus dengan penanda waktu berjalan vs total durasi.
  - Tombol **Kunci Layar (Screen Lock)** untuk mencegah sentuhan tidak sengaja saat menonton.
  - Mode **Layar Penuh (Fullscreen Landscape)** dengan navigasi imersif.
  - Layar tetap menyala (*Wakelock*) selama video diputar.
- **Penyimpanan Progres Otomatis**: Progres tersimpan ke Hive setiap 10 detik dan saat layar ditutup.
- **Putar Otomatis Episode Berikutnya (Autoplay Next Episode)**:
  - Muncul overlay hitung mundur 10 detik ketika video mencapai >92%.
  - Tombol *"Putar Sekarang"* dan *"Batal"*.
  - Otomatis berpindah ke episode berikutnya tanpa keluar dari pemutar.

### 5. 📚 Koleksi Saya (Library)
- **Tab Riwayat**: Daftar tontonan dengan thumbnail, judul episode, progres waktu, dan tombol hapus.
- **Tab Favorit**: Grid anime yang disukai pengguna.
- **Tab Watchlist**: Grid anime yang disimpan untuk ditonton nanti.

### 6. ⚙️ Pengaturan & Preferensi
- **Toggle Putar Otomatis**: Aktifkan/nonaktifkan transisi episode otomatis.
- **Kualitas Default**: Pilih kualitas standar (720p / 480p).
- **Manajemen Penyimpanan**: Bersihkan riwayat tontonan dan kata kunci pencarian.
- **Info Aplikasi**: Versi, kredit, dan status sistem.

---

## 🎨 Sistem Desain (Design Tokens)

- **Latar Belakang**: `AppColors.background` (`#080D18`) — Midnight Charcoal
- **Permukaan (Surface)**: `AppColors.surface` (`#111B2E`) — Deep Navy Slate
- **Permukaan Terangkat (Elevated)**: `AppColors.surfaceElevated` (`#17243A`)
- **Aksen Utama**: `AppColors.primary` (`#2878F0`) — Electric Azure
- **Aksen Sekunder**: `AppColors.accent` (`#63B3FF`) — Sky Cyan
- **Tipografi**: Google Fonts **Outfit** untuk estetika anime modern berkarakter premium.

---

## 🛠️ Arsitektur & Teknologi

```
lib/
├── app/
│   ├── routes/
│   │   └── app_router.dart          # GoRouter setup
│   └── theme/
│       ├── app_colors.dart          # Palet warna Midnight
│       ├── app_typography.dart      # Sistem tipografi Outfit
│       └── app_theme.dart           # ThemeData Material 3
├── core/
│   ├── constants/
│   │   └── app_constants.dart       # Konstanta API, batas waktu, storage
│   └── network/
│       └── api_client.dart          # Dio client dengan timeout & error handling
├── data/
│   ├── datasources/
│   │   ├── local/
│   │   │   └── storage_service.dart # Layanan Hive untuk riwayat, bookmark, & preferensi
│   │   └── remote/
│   │       └── anime_remote_data_source.dart # Integrasi Sankavollerei Otakudesu API
│   ├── models/
│   │   ├── anime_models.dart        # Model data API Otakudesu
│   │   └── local_models.dart        # Model data Hive
│   └── repositories/
│       └── anime_repository.dart    # Repositori anime
├── presentation/
│   ├── providers/
│   │   └── anime_providers.dart     # Riverpod StateNotifier & FutureProviders
│   ├── screens/
│   │   ├── detail/
│   │   │   └── anime_detail_screen.dart
│   │   ├── home/
│   │   │   └── home_screen.dart
│   │   ├── library/
│   │   │   └── library_screen.dart
│   │   ├── player/
│   │   │   └── video_player_screen.dart
│   │   ├── search/
│   │   │   └── search_screen.dart
│   │   ├── settings/
│   │   │   └── settings_screen.dart
│   │   └── main_navigation_screen.dart
│   └── widgets/
│       ├── anime_card.dart
│       ├── continue_watching_card.dart
│       ├── custom_shimmer.dart
│       ├── empty_view.dart
│       ├── error_view.dart
│       ├── hero_banner.dart
│       └── section_header.dart
└── main.dart
```

---

## 🚀 Menjalankan Aplikasi

```bash
# Ambil dependencies
flutter pub get

# Jalankan dalam mode debug
flutter run

# Bangun file APK Android (Release)
flutter build apk --release
```
