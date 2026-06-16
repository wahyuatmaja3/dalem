# Import audio file as note — Design

**Date:** 2026-06-16
**Status:** Approved

## Problem

Saat ini sebuah note hanya bisa dibuat dengan merekam suara langsung di
recorder screen. Pengguna yang sudah punya file audio (mis. rekaman MP3 dari
aplikasi lain) tidak bisa menjadikannya note tanpa memutar ulang dan merekam
ulang. Tambahkan kemampuan untuk meng-import file audio dari penyimpanan
perangkat dan memprosesnya menjadi note.

## Goals

- Pengguna dapat memilih file audio dari perangkat dan menjadikannya note.
- Format yang didukung: `mp3`, `m4a`, `wav`, `aac`.
- Memakai ulang alur penamaan/kategori dan upload yang sudah ada.

## Non-goals

- Tidak ada transkripsi/preview audio sebelum upload.
- Tidak ada multi-file import (satu file per aksi).
- Tidak mengubah backend/API.

## Entry point

Di `recorder_screen.dart`, pada state idle (`RecorderIdle`), tambahkan tombol
sekunder **"Import file MP3"** di bawah tombol rekam utama. Merekam tetap aksi
primer; import adalah aksi sekunder.

## Flow

1. Pengguna menekan "Import file MP3".
2. Buka file picker yang difilter ke ekstensi audio: `mp3, m4a, wav, aac`.
3. Pengguna membatalkan → tetap di idle, tidak terjadi apa-apa.
4. Pengguna memilih file → tampilkan `showNoteEditSheet` (judul + kategori),
   sheet yang sama dengan yang dipakai setelah merekam.
5. Sheet dibatalkan → tetap di idle. **File asli pengguna TIDAK dihapus**
   (berbeda dari rekaman, sumbernya milik pengguna).
6. Sheet dikonfirmasi → pindah ke state "Uploading" yang sudah ada → panggil
   `createRecordedNote(pickedPath, title, category)` (jalur upload + simpan yang
   sama) → kembali (pop) ke dashboard, yang akan me-refresh otomatis.

## Code changes

### `recorder_screen.dart`

- Ekstrak logika "simpan audio sebagai note" yang sekarang inline di
  `_handleStartStop` (bagian setelah `stopRecording`) menjadi helper:
  `_saveAudioAsNote(String path, {required bool deleteSourceAfter})`.
  - Rekaman memanggil dengan `deleteSourceAfter: true`.
  - Import memanggil dengan `deleteSourceAfter: false`.
- Tambahkan `_handleImport()` yang membuka file picker dan memanggil
  `_saveAudioAsNote`.
- Tambahkan tombol import di `_buildIdleBody()`.

### `pubspec.yaml`

- Tambahkan dependency `file_picker`.

### Repository / API client

- Tidak ada perubahan. `createRecordedNote` sudah menerima path lokal apa pun
  dan meng-upload-nya via `ApiClient.uploadFile`.

## Error handling

- Picker dibatalkan: no-op, kembali ke idle.
- Path file null/kosong dari picker: abaikan, kembali ke idle.
- Kegagalan upload ditangani oleh jalur `createRecordedNote` yang sudah ada
  (fallback ke mock transcript/summary saat `_apiClient` gagal — perilaku yang
  sudah ada saat ini).

## Testing

- Repository sudah teruji bahwa `createRecordedNote` bekerja dengan path apa
  pun (lihat `notes_repository_test.dart`).
- Interaksi file picker adalah UI platform, perlu pengujian manual di
  perangkat. Verifikasi bahwa `flutter analyze` lolos dan logika recorder
  screen ter-compile.
