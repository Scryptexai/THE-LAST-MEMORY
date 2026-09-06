# 🎬 THE LAST MEMORY

**Genre:** Life is Strange + Mystery — game naratif investigasi 3D (Godot 4, GDScript).

Seorang arsitek muda bernama **Ardi** kembali ke **Kota Tua Pesisir** untuk merenovasi rumah neneknya.
Di loteng, ia menemukan surat-surat lama tentang kecelakaan kereta 40 tahun lalu — dan rumah itu
sepertinya *mengingat* sesuatu. Ungkap kebenaran, jaga hubunganmu, dan pilih ending-mu.

## ✨ Fitur (Full Release)

- 🗺️ **5 lokasi 3D** bergaya diorama miniatur prosedural: Rumah Nenek, Kafe Rara, Pasar Lama, Stasiun, Pantai
- 💬 **~80 simpul dialog bercabang** (Indonesia + Inggris) dengan efek mengetik & pratinjau hubungan
- 🔍 **18 petunjuk + 4 deduksi** berantai di papan investigasi ala *Golden Idol*
- 💛 **Sistem hubungan** (Rara, Pak Harto, Mira) yang membuka dialog & kesaksian spesial
- 👻 **Psychometry**: objek memicu kilas balik 1983 (overlay sepia + musik memori)
- 📓 **Jurnal otomatis**: catatan, profil tokoh, linimasa
- 🎒 **Inventory fungsional**: kunci, senter, dan hadiah yang diserahkan otomatis
- 🏁 **4 ending** (Kebenaran Utuh / Rahasia Terkubur / Pengorbanan / Luka Lama) + statistik
- 🎞️ **Kartu bab sinematik**, galeri ending, layar kredit, vignette, debu loteng, laut animasi, lampu berkedip
- 🧩 **Panduan teka-teki** di papan deduksi, dialog reaktif pasca-pengakuan, 10 kilas balik, slider teks/kamera
- 📷 **5 Momen foto** ala Life is Strange: abadikan vista kota, tersimpan sebagai PNG + galeri jurnal
- ✨ **New Game+** (foto & hint bonus terbawa), **% penyelesaian**, warga bereaksi per-bab
- 🏆 **11 pencapaian** (toast + fanfare + tab jurnal), 2 memori rahasia NG+, SFX achievement
- 📷 **Mode foto bebas** (tombol P): letterbox + grid sepertiga + zoom + galeri jurnal + pencapaian Fotografer
- 🎁 **5 hadiah untuk 3 tokoh** (reaksi spesial + petunjuk kesukaan di jurnal + pencapaian Murah Hati); perbaiki `_check_gift` NPC yang hilang
- 🕯 **Ruang Memori**: galeri 4 ending + statistik lintas-sesi (memori global), tombol dari menu & layar tamat, pencapaian Sempurna (100%)
- 💾 **3 slot save + autosave**, pengaturan audio & bahasa (ID/EN)
- 🎵 **Musik & SFX prosedural** (synth runtime — tanpa file audio eksternal, bisa di-override dengan `.ogg` di `assets/audio/`)

## 🕹️ Kontrol

| Aksi | Keyboard | Gamepad |
|---|---|---|
| Gerak | WASD / Panah | Stick kiri / D-pad |
| Lari | Shift | LB (tombol 8) |
| Interaksi | E | A |
| Jurnal | J / Tab | X |
| Tas | I | Y |
| Investigasi | L | B |
| Peta perjalanan | M | RB |
| Lanjut dialog | Klik / Spasi / Enter | — |
| Jeda / kembali | Esc | — |
| Kamera | Gerak mouse (terkunci saat main) | — |

Alur: **E** untuk bicara/periksa → baca jurnal **[J]** → hubungkan clue di papan **[L]** →
rangkai 4 deduksi → kembali ke loteng untuk pilihan akhir.

## 🚀 Cara Menjalankan

1. Install **Godot 4.3+** (disarankan 4.3–4.5, renderer GL Compatibility didukung).
2. Clone repo ini, lalu buka folder proyek di Godot (*Import* → pilih `project.godot`).
3. Tekan **F5** (Run). Main scene: `res://scenes/Main.tscn`.

Tidak perlu mengunduh apa pun: model 3D, musik, dan SFX dibuat prosedural oleh kode.

## 📁 Struktur Proyek

```
THE-LAST-MEMORY/
├── project.godot                 # autoload, input map, main scene
├── icon.svg
├── assets/data/                  # dialogues, characters, clues, items, scenes,
│                                 # deductions, endings, objectives, ui_strings (JSON)
├── assets/audio/{music,sfx,ambient}/  # opsional: taruh .ogg/.wav <id>.ogg untuk override synth
├── scripts/
│   ├── autoload/  SignalBus, DataManager, SaveManager, AudioManager,
│   │              RelationshipManager, InvestigationManager, DialogueManager, GameManager
│   ├── entities/  Player, NPC, InteractiveObject
│   ├── locations/ LocationBase + RumahNenek, KafeRara, PasarLama, Stasiun, Pantai
│   ├── systems/   DialogueParser, ClueSystem, DeductionSystem, RelationshipSystem
│   ├── ui/        UIManager, HUD, MainMenuUI, DialogueUI, InvestigationUI,
│   │              InventoryUI, JournalUI, SettingUI, LoadingUI, EndingUI
│   └── utils/     Logger, MathUtils, SaveUtils, PropFactory, CharacterFactory, ThemeFactory
├── scripts/Main.gd               # orkestrasi scene & perjalanan
└── scenes/                       # Main, entities, locations, ui (.tscn)
```

## 🎨 Menambah Konten (Data-Driven)

- **Dialog baru**: tambah node di `assets/data/dialogues.json`, rujuk dari `dialogue_id` / `next` / `choices[].next` / `variants`.
- **Clue baru**: tambah di `clues.json`, pasang `clue_id` pada objek di `scenes.json`, opsional masukkan ke resep `deductions.json`.
- **Lokasi baru**: tambah entri `scenes.json` + script `scripts/locations/X.gd` (extends `LocationBase`) + `scenes/locations/X.tscn`.
- **Musik/SFX sendiri**: taruh `assets/audio/music/<track_id>.ogg` (mis. `music_kafe.ogg`) — otomatis dipakai menggantikan synth.

## 🏁 Syarat Ending

| Ending | Kondisi |
|---|---|
| 🌅 Kebenaran Utuh | Pilihan UNGKAP + 18/18 clue + 4/4 deduksi + Rara ≥14, Harto ≥9, Mira ≥7 |
| 🕯 Pengorbanan | Pilihan SEBAGIAN (lindungi keluarga Rara) dengan bukti cukup |
| 🌑 Rahasia Terkubur | Pilihan KUBUR |
| 🌧 Luka Lama | Bukti/hubungan kurang saat memilih |

## 📜 Epilog Kota (berbasis flag)

- `epilogues.json` kini mendukung entri **tanpa karakter**: tier dipilih dari `flags` (semua harus true) + opsional `met`. Nama entri via `name_key` (ui_strings).
- Tiga entri baru: **Stasiun** (lampu loket menyala / tetap gelap), **Para Tetangga** (Bu RT kembali ke pasar), **Makam Bukit** (kamboja & Kamis sore). Hasil side-quest dan kunjungan makam ikut mewarnai layar ending.

## 🧭 Menu Perjalanan Informatif

- Setiap lokasi tampil sebagai kartu: nama + lencana (📍 di sini, 🎯 tujuan aktif, 🔒 terkunci, 🕯️ loket menyala), progres **petunjuk & momen per lokasi**, penanda "belum dikunjungi"; lokasi terkunci ditampilkan sebagai `???`.
- Mode Detektif menyembunyikan progres (hanya deskripsi lokasi). Judul/tombol kini via `ui_strings` (id/en); daftar dapat digulir.

## ⛰️ Lokasi ke-6: Makam Bukit

- `scenes/locations/MakamBukit.tscn` + `MakamBukit.gd` — pemakaman di lereng bukit: nisan Nenek & Kakek berdampingan, 12 nisan korban 1983, pohon kamboja, gubuk juru kunci, bangku pandang ke stasiun & laut.
- Terbuka setelah **bab 3** (`unlock_flag` di scenes.json; menu perjalanan menyaring lokasi terkunci; toast saat terbuka).
- Konten: NPC Juru Kunci (3 varian), petunjuk ke-19 `daftar_korban`, item `bunga_kamboja` → pamit di nisan Nenek (pilihan `requires_items`), kilas balik 1984 `dlg_mem_makam` (psychometry di nisan Kakek), momen ke-6 `m_bukit`, musik `music_makam` + ambient `ambient_bukit` (angin bukit, jangkrik, lonceng jauh), override suasana bab final.
- Pencapaian **Pamit**; **Penjelajah** kini dihitung dari jumlah scene aktual.

## 🌗 Suasana Berubah per Bab

- `scenes.json` → `chapter_env: {bab: {override env}}` (bab terbaru yang sudah dilihat menang). Rumah Nenek: senja di bab 3, **malam berbintang** di bab final; Pantai: gerimis muram di bab 4; Kafe: jingga sore di bab 4; Stasiun: gerimis reda di bab final. Termasuk override `weather`.

## 🤝 Side-Quest Warga

- **Klepon untuk Bu RT** — beli jajan di Pedagang Antik (dapat `klepon`), serahkan ke Bu RT (hadiah otomatis, +3 relasi, linimasa).
- **Lampu Loket** — setelah gerbong dibuka, Penjaga Stasiun meminta tolong (`lampu_minyak`); gantung di Kait Lampu Loket → lampu loket menyala permanen (flag `loket_terang`, `FlickerLight` dinamis), penjaga berterima kasih.
- Pencapaian **Tetangga Baik** saat keduanya selesai. Pilihan dialog kini mendukung `remove_items`.

## 🎬 Kamera Sinematik Kilas Balik

- Saat node `memory` aktif: kamera dolly-in pelan + FOV menyempit 14° + orbit halus (Player), letterbox meluncur masuk, shader layar sepia + vignette + grain film (HUD), label "— 1983 —" memudar masuk; semua dipulihkan dengan tween saat kilas balik berakhir (+ `sfx_memory_exit`).

## 📊 Statistik Lintas-Sesi

- `user://memory.json` → `stats`: jumlah permainan, total waktu bermain (diakumulasi saat berhenti melacak/keluar), penyelesaian terbaik, ending tercepat, jumlah ending dicapai. Ditampilkan di Ruang Memori.

## 🚶 NPC Hidup

- NPC melambai sekali saat pemain mendekat (< 4 m). Warga generik (dan NPC dengan `wander` di `scenes.json`) berjalan santai di sekitar posnya, berhenti saat pemain dekat/dialog aktif.

## 📖 Kartu "Sebelumnya…"

- Saat melanjutkan simpanan, HUD menampilkan ringkasan 14 detik (bab, objektif, 3 catatan jurnal terakhir, statistik & relasi) — bisa ditutup manual.

## ◈ Album Kenangan 1983

- Jurnal tab **Kenangan**: semua kilas balik (node `memory`) yang pernah dialami (flag `memseen_*`) bisa **diputar ulang** dari jurnal tanpa efek ganda (efek node sekali-pakai). Yang belum dialami tampil terkunci. Pencapaian **Penjaga Kenangan** saat semua kilas balik dialami.

## 🧭 Kompas Tujuan

- `objectives.json` → `location`: HUD menampilkan panah relatif kamera + nama + jarak ke portal keluar (bila tujuan di lokasi lain) atau ke objek petunjuk terdekat yang belum ditemukan (bila di lokasi yang sama). Nonaktif di Mode Detektif.

## 💬 Kenyamanan Dialog & Pengaturan Persisten

- Tombol **1–4** memilih opsi dialog; **A** toggle auto-advance (badge ▶▶ AUTO, jeda proporsional panjang teks); **H** / ☰ membuka riwayat dialog (40 baris terakhir).
- `user://settings.json`: volume, mute, bahasa, kecepatan teks, sensitivitas kamera, auto-advance — dimuat saat boot, disimpan saat panel pengaturan ditutup.

## 📜 Epilog & Riwayat Pilihan

- `assets/data/epilogues.json`: nasib tiap tokoh (Rara, Pak Harto, Mira, Bu RT) berdasarkan nilai hubungan akhir (tier `min`), ditampilkan di bawah teks ending — hanya untuk tokoh yang pernah ditemui.
- Jurnal tab **Pilihan**: riwayat semua pilihan dialog (waktu bermain + pembicara + teks), terbaru di atas.

## 🕵 Mode Detektif

- Terbuka setelah satu ending (menu utama). Tanpa hint, tanpa penanda objek (kecuali portal), tanpa pratinjau efek relasi di pilihan dialog. Tersimpan di save (`hard_mode`). Pencapaian **Detektif Sejati** saat mencapai ending apa pun.

## 🏡 Prolog Diperluas — Bu RT Sumi

- NPC baru di teras Rumah Nenek (`bu_rt`): perawat rumah selama 6 bulan; dialog berubah per bab (`burt_bicara` → salam, `chseen_bab3` → peringatan, `chseen_final` → restu). Menambah entri Tokoh & Linimasa di jurnal.

## 🌦 Cuaca & Langit Hidup

- `scenes.json` → `env.weather`: `"drizzle"` (gerimis partikel + kilat & guntur acak, layer hujan di ambient) atau `"gulls"` (kawanan camar `GullFlock` berputar di langit).
- Semua lokasi: matahari "bernapas" (awan berlalu) lewat `LocationBase._update_sky()`.

## 📝 Catatan Teknis

- Bahasa: Indonesia (default) & Inggris (dialog + UI). Ganti di Pengaturan.
- Save tersimpan di `user://save_slot_*.json` + `user://autosave.json`.
- Semua error penting dicatat via `Logger` (matikan `Logger.enabled` untuk production).
- Efek dialog sekali-pakai (anti-farming hubungan), token anti-ending-basi, precache audio saat loading.
- Dibangun & diuji sintaks dengan `gdparse` (gdtoolkit) + validasi silang data JSON.

Selamat menyelidiki Kota Tua Pesisir. 🕵️
