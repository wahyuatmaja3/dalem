# Dalem - Design Direction (Warm Editorial)

## Dial
Dial: ENERGY 1 / RHYTHM 2 / MOTION 1

## Identity & Personality
- **Product:** Dalem - Voice note capture, transcription, and AI conversational note assistant.
- **Personality:** Warm Editorial (Catatan & Teks Hangat).
- **Tone:** Tenang, jernih, reflektif, dan berfokus pada kemudahan membaca transkrip teks panjang. Menghindari ornamen digital yang bising, gradien ungu generik, atau badge AI mengambang.
- **Audience:** Profesional, kreator, dan pemikir yang merekam gagasan, rapat, dan percakapan suara untuk dipelajari kembali dengan nyaman.

## Color Palette

### Light Theme (Warm Paper & Ink)
- **Background Base:** `#FBF9F5` (Warm Cream / Soft Paper)
- **Surface / Card:** `#FFFFFF` (Crisp Paper Surface)
- **Surface Highlight / Subtle:** `#F3EFEA` (Warm Oat / Sand)
- **Text Primary (Ink):** `#1E1E1C` (Deep Charcoal Ink, contrast > 14:1)
- **Text Secondary (Muted):** `#5E5D59` (Warm Graphite, contrast > 5:1)
- **Border / Divider:** `#E5DFD7` (Subtle Warm Hairline)
- **Primary Accent (Terracotta / Amber):** `#C25E2E` (Warm Terracotta, contrast > 4.5:1 on light)
- **Accent Subtle Tint:** `#F6EAE3` (Terracotta tint for focused pills/badges)
- **Recording Red:** `#C93B2B` (Direct semantic recording indicator)

### Dark Theme (Deep Slate & Warm Amber)
- **Background Base:** `#151618` (Deep Charcoal Slate)
- **Surface / Card:** `#1E2023` (Charcoal Paper)
- **Surface Highlight / Subtle:** `#282A2E` (Muted Graphite)
- **Text Primary (Ink):** `#F3EFEA` (Warm Oat Paper Text, contrast > 13:1)
- **Text Secondary (Muted):** `#A3A09A` (Warm Sand Gray, contrast > 5.5:1)
- **Border / Divider:** `#32353B` (Subtle Graphite Hairline)
- **Primary Accent (Terracotta / Amber):** `#D97341` (Warm Amber Terracotta, contrast > 5:1 on dark)
- **Accent Subtle Tint:** `#35251F` (Dark Amber tint)
- **Recording Red:** `#E05343` (Direct semantic recording indicator)

## Typography & Hierarchy
- **Heading:** Serif / Editorial Warm Sans dengan bobot terukur (w600/w700), tracking proporsional, tanpa uppercase berjarak renggang berlebihan.
- **Body & Transcript:** Clean Sans legibel tinggi dengan line-height nyaman (1.5x) untuk membaca rekaman suara dan transkripsi panjang.
- **Metadata & Timestamp:** Sans terstruktur rapi dengan bobot w500, warna muted, menyatu secara tenang dengan catatan.

## Layout & Rhythm (RHYTHM 2)
- Whitespace terstruktur sebagai pembagi informasi (padding 16px - 24px teratur).
- Hirarki berbasis bobot teks dan kontras, bukan bayangan berlebihan.
- Satu titik fokus per layar:
  - Dashboard: Daftar catatan yang terorganisir dengan aksi rekam yang jelas.
  - Recorder: Indikator waktu & status rekam yang jelas dan tenang.
  - Note Detail: Transkrip dan ringkasan yang nyaman dibaca tanpa distraksi tab berlebih.

## Motion (MOTION 1)
- Animasi hanya untuk feedback pengguna: tap states, pergantian tab, dan perubahan status rekam langsung.
- Tanpa animasi loop abadi, tanpa efek floating melayang, tanpa bounce buatan.

## Integrity & Purpose
- Semua tombol dan kontrol memiliki fungsi nyata.
- State kosong, memuat, dan galat menjelaskan penyebab dan memberikan tindakan berikutnya yang jelas.
- Toggle tema berfungsi penuh (Light, Dark, System).
