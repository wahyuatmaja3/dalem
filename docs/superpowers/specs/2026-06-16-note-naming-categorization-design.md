# Note Naming & Categorization — Design Spec

**Date:** 2026-06-16
**Status:** Approved for planning

## Overview

Tambahkan tiga kemampuan ke fitur notes aplikasi Dalem:

1. **Set nama note sebelum save** — saat user selesai merekam, tampilkan bottom sheet untuk mengisi nama & memilih kategori sebelum note diupload/diproses.
2. **Pengkategorian (hybrid)** — kategori preset default + kategori custom yang bisa dibuat user.
3. **Edit nama & kategori dari dashboard** — via swipe pada note card, plus badge kategori di card dan filter kategori di atas list.

Penyimpanan dipindah dari mock in-memory ke **Hive** (ringan, NoSQL, tanpa TypeAdapter codegen).

## Goals

- Note bisa diberi nama bermakna sejak awal, bukan default "New Recording".
- Note bisa dikategorikan dengan preset atau kategori buatan sendiri.
- Nama & kategori bisa diedit dari dashboard tanpa membuka detail.
- Badge kategori tampil di card; list bisa difilter per kategori.
- Data persist setelah app restart (Hive).

## Non-Goals

- Tidak ada sinkronisasi backend nyata (API masih stub/placeholder seperti sekarang).
- Tidak ada hapus/rename kategori secara global (hanya tambah custom saat dipakai).
- Tidak ada multi-kategori per note (satu note = satu kategori).

## Data Model

### NoteModel (`lib/features/dashboard/data/models/note_model.dart`)

Tambah field:

- `final String? category;` — nama kategori. `null` berarti "Uncategorized".

Update `fromJson`, `toJson`, dan `copyWith` untuk menyertakan `category`.

- `toJson`: tambahkan `'category': category`.
- `fromJson`: `category: json['category'] as String?`.
- `copyWith`: tambahkan parameter `String? category` dengan pola `category ?? this.category`.

> Catatan: karena `copyWith` memakai pola `?? this.category`, tidak bisa men-set category kembali ke null lewat copyWith. Untuk kebutuhan saat ini (set/edit selalu memberi nilai non-null atau mempertahankan), ini cukup. Tidak perlu sentinel.

## Kategori (Hybrid)

### Preset default (konstanta)

Definisikan di file konstanta, mis. `lib/features/dashboard/data/category_constants.dart` (atau letakkan di tempat yang konsisten dengan struktur konstanta yang ada):

```
const List<String> kPresetCategories = [
  'Meeting',
  'Personal',
  'Ideas',
  'Work',
  'Other',
];
```

### Custom

- User bisa mengetik nama kategori baru di bottom sheet (save/edit).
- Kategori custom yang pernah dipakai disimpan di Hive box `categories`.
- Daftar kategori yang ditampilkan di picker = `kPresetCategories` ∪ `customCategories` (dedup, urut: preset dulu lalu custom).

## Penyimpanan (Hive)

### Dependencies (pubspec.yaml)

- `hive` (versi stabil terbaru kompatibel SDK).
- `hive_flutter`.

Verifikasi versi via context7/pub sebelum menulis. Jalankan `flutter pub get`.

### Inisialisasi (`lib/main.dart`)

Sebelum `runApp`:

- `await Hive.initFlutter();`
- Buka box: `await Hive.openBox('notes');` dan `await Hive.openBox('categories');`
- Inject box ke Riverpod lewat provider yang di-override di `ProviderScope` (atau provider yang membaca box yang sudah terbuka).

### Box

- **`notes`** — key = note `id` (String), value = `Map` hasil `toJson()`. Saat baca, rekonstruksi via `NoteModel.fromJson(Map<String, dynamic>.from(value))`.
- **`categories`** — menyimpan `List<String>` kategori custom yang pernah dipakai (mis. di key `'custom'`), atau gunakan box sebagai set key. Pilih pola paling sederhana; dokumentasikan di kode.

### NotesRepository (`lib/features/dashboard/data/repositories/notes_repository.dart`)

Rombak total dari mock in-memory ke Hive:

- Konstruktor menerima `Box notesBox` dan `Box categoriesBox` (via provider), plus `ApiClient?` tetap dipertahankan untuk stub upload.
- `Future<List<NoteModel>> fetchNotes()` → baca semua value dari `notesBox`, map ke `NoteModel`, urutkan `createdAt` desc.
- `Future<NoteModel> fetchNoteDetail(String id)` → baca by key.
- `Future<NoteModel> createRecordedNote(String localAudioPath, {required String title, String? category})` → (stub upload seperti sekarang), buat `NoteModel` dengan title & category dari argumen, tulis ke `notesBox`, simpan category custom bila bukan preset, return note.
- `Future<NoteModel> updateNote(String id, {required String title, String? category})` → baca note, `copyWith`, tulis kembali, simpan category custom bila perlu, return note.
- `Future<void> deleteNote(String id)` → hapus dari box. (Opsional dipakai; sediakan agar lengkap.)
- `List<String> getCustomCategories()` / `void _saveCustomCategory(String name)` → kelola box categories.
- `deleteLocalAudio` tetap.

Seed data: karena pindah ke Hive kosong, tidak ada lagi mock notes default. (Opsional: seed beberapa contoh saat box kosong pada first run — diputuskan saat implementasi; default TIDAK seed agar bersih.)

## UI — Komponen Reusable: Bottom Sheet "Nama & Kategori"

Buat satu widget reusable, mis. `lib/features/dashboard/presentation/widgets/note_edit_sheet.dart`:

- Input: `initialTitle`, `initialCategory`, daftar kategori (preset + custom), serta callback `onSave(title, category)`.
- Isi:
  - `TextField` nama note (pakai `AppTextField` yang ada bila sesuai).
  - Pemilih kategori: deretan `ChoiceChip` untuk tiap kategori + chip **"+ Tambah"** yang memunculkan input teks untuk kategori custom baru.
  - Tombol **Save** (pakai `AppButton`) dan **Discard/Cancel**.
- Mengembalikan hasil via callback atau `Navigator.pop(context, result)`.
- Dipakai oleh: Recorder (save) dan Dashboard (edit).

## UI — Alur Save (Recorder)

File: `lib/features/dashboard/presentation/screens/recorder_screen.dart`

- Tambah state baru ke sealed `RecorderState`: `RecorderReview` (setelah stop, sebelum upload).
- Alur `_handleStartStop` saat stop:
  1. Stop recording, dapatkan `audioPath`, set state `RecorderReview`.
  2. Tampilkan bottom sheet "Nama & Kategori" (`note_edit_sheet`).
  3. **Save** → set state `RecorderUploading`, panggil `createRecordedNote(audioPath, title: ..., category: ...)`, `deleteLocalAudio`, `pop`.
  4. **Discard** → `deleteLocalAudio`, `pop` tanpa simpan.
- Default nama: kosong atau "New Recording" (user bisa ubah). Validasi: bila kosong saat save, fallback ke "New Recording".

## UI — Dashboard

File: `dashboard_screen.dart`, `note_card.dart`, `dashboard_controller.dart`.

### Badge kategori di NoteCard

- Tampilkan label kategori (mis. chip kecil) di samping/bawah judul, selain badge status yang sudah ada.
- Bila `category == null`, tampilkan "Uncategorized" atau sembunyikan (pilih saat implementasi; default: tampilkan "Uncategorized" dengan warna netral).

### Swipe untuk Edit

- Bungkus `NoteCard` dengan `Dismissible`:
  - `key: ValueKey(note.id)`.
  - Arah swipe (mis. `endToStart`) menampilkan background aksi **Edit**.
  - `confirmDismiss`: saat swipe selesai, buka bottom sheet edit (pra-isi nama & kategori note), lalu **return false** agar card tidak benar-benar ter-dismiss.
  - Setelah save di sheet → `updateNote(...)` → refresh list.
- Pendekatan ini tanpa dependency tambahan (`flutter_slidable` tidak diperlukan), menjaga app ringan.

### Filter kategori

- Baris **filter chips** horizontal di atas list: "Semua" + tiap kategori (preset + custom yang ada di notes).
- State filter disimpan di controller (`DashboardController`) atau provider terpisah.
- `DashboardLoaded` menyimpan `notes` lengkap; tampilan memfilter berdasarkan kategori terpilih. Tambahkan field selected category & logika filter.
- Tap chip → update filter → list ter-filter. "Semua" → tampilkan semua.

### DashboardController

- Tambah method/aksi: `updateNote(id, title, category)` (panggil repo lalu refresh), `setCategoryFilter(String? category)`.
- State `DashboardLoaded` mungkin perlu menyimpan `selectedCategory` + daftar kategori yang tersedia, atau pisahkan ke provider filter. Pilih yang paling rapi saat implementasi.

## Testing

- **Model**: unit test `toJson`/`fromJson`/`copyWith` dengan field `category` (termasuk null).
- **Repository**: unit test dengan Hive box di mode test (`Hive.init` ke temp dir atau in-memory) — `createRecordedNote`, `updateNote`, `fetchNotes` sorting, simpan custom category.
- **Kategori**: test gabungan preset ∪ custom (dedup).
- Test recorder service yang ada (`test/core/services/recorder_service_test.dart`) tidak boleh regresi.
- Widget test bottom sheet (opsional, bila waktu memungkinkan).

## Error Handling

- Operasi Hive dibungkus try/catch di repository; kegagalan → propagate ke `DashboardError` seperti pola sekarang.
- Save dengan nama kosong → fallback "New Recording".
- Box belum terbuka → dijamin terbuka di `main.dart` sebelum app jalan.

## Risiko / Catatan

- `copyWith` tidak bisa set category ke null (pola `??`). Cukup untuk scope ini.
- Migrasi data: tidak ada data lama nyata (sebelumnya mock), jadi tidak perlu migrasi.
- Pastikan versi `hive`/`hive_flutter` kompatibel dengan Dart SDK `^3.11.4`.
```
