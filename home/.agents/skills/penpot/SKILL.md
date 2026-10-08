---
name: penpot
description: Build or edit Penpot designs through the Penpot MCP. Use when creating or editing Penpot frames, components, variants, or design tokens; when writing Penpot plugin code; or when diagnosing Penpot layout that renders wrong.
---

# Penpot lewat MCP

Pengetahuan **alat**, bukan proyek. Aturan spesifik proyek tinggal di repo masing-masing.

## Panggilan pertama

1. `penpot_high_level_overview` — wajib, sekali per sesi.
2. `penpot_penpot_api_info` untuk tipe yang belum dikenal, **sebelum** menulis kode.
   Dokumentasinya tipis di titik penting (`lineHeight: string` itu multiplier atau px?),
   jadi siap menyimpulkan dari perilaku.
3. `penpot_execute_code` untuk menjalankan.

Kode dijalankan sebagai **body sebuah fungsi** — `return` di akhir itu sah, dan itulah cara
mengambil hasil.

## Peringatan pertama: `export_shape` rusak

Di setup yang kami pakai, `export_shape` gagal dengan timeout playwright
(`locator.waitFor` pada `#screenshot-<id>` yang tetap 0.01×0.01) — **bahkan untuk kotak
polos**. Jangan buang beberapa panggilan mencobanya. Setelah satu kegagalan, **minta
pengguna mengekspor PNG-nya sendiri.**

Konsekuensinya: kamu menulis tanpa bisa melihat. Verifikasi jadi numerik, dan **pengguna
adalah renderer-nya**. Katakan itu di depan, jangan berpura-pura sudah memeriksa visual.

## Aturan yang menyelamatkan

**Skrip build adalah satu-satunya sumber kebenaran.** Simpan kode pembangun di file repo,
jalankan sebagai skrip idempoten (bersihkan lalu bangun ulang). **Jangan menambal state
hidup dengan skrip sekali pakai.** Tambalan bedah menciptakan penyimpangan antara file dan
kanvas, dan penyimpangan itu bersarang: satu perbaikan memunculkan bug baru, perbaikan
berikutnya merusak yang tadi benar. Lebih lambat per iterasi, tapi nol drift.

**Ukur di panggilan terpisah.** Auto-sizing Penpot tidak instan. Pengukuran di panggilan
yang sama dengan perubahan akan basi — dan bisa melaporkan "tidak ada overflow" padahal
isinya menumpuk di 0,0. Ini pernah meloloskan bug nyata.

**Sasaran lewat peran, bukan sifat kebetulan.** "Anak langsung `konten` bernama
`BarisSurah`" — bukan "apa pun yang tingginya di bawah 60px". Dan setiap perbaikan massal
wajib mencetak **jumlah yang terpengaruh** supaya angkanya bisa diperiksa.

**Verifikasi dengan `isContainedIn`, lewati yang tersembunyi.** Jangan aritmetika
`boardY + tinggi`.

## Jebakan

Sebelas ini tidak ada di dokumentasi, dan sebagian besar gagal **senyap** — tanpa error,
hanya hasilnya salah.

1. **`applyTypography()` menerapkan family/size/weight tapi BUKAN `lineHeight`.** Set ulang
   setelahnya. Gagal senyap total: seluruh skala line-height jadi hiasan dan semua teks
   kembali ke `1.2` bawaan.
2. **`resize()` me-reset `verticalSizing` ke `"fix"`** (dan `growType` ke `"fixed"` pada
   teks). Urutan wajib: **`resize()` dulu, baru set sizing.** Kalau terbalik, spacer
   fleksibel berdiam di 1px sementara elemen lain menyerap seluruh ruang.
3. **`insertChild(index, shape)` menaruh shape di indeks 0**, bukan di `index`. Untuk
   mengurutkan ulang: ambil `children.slice()` lalu `insertChild(i, …)` untuk **semua** anak
   secara berurutan.
4. **`createVariantContainer()` menamai sendiri grup dan variannya.** Grup mengambil nama
   varian pertama (`"Chip / Default"`), tiap varian cukup nilainya (`"Default"`).
   **Jangan timpa `component.name`** — itu merusaknya. Cukup buang sufiks `" / Default"`
   dari nama kontainer di akhir.
5. **`library.components` cuma menampilkan kepala tiap grup varian.** Daftar lengkapnya lewat
   `container.variants.variantComponents()`, nilainya lewat `component.variantProps`.
6. **Instance komponen membawa koordinat kanvas main instance-nya.** Setelah
   `instance()` lalu `appendChild` ke container ber-flex, instance itu **tidak** otomatis
   diposisikan layout — dia tetap duduk di koordinat main instance-nya (mis. `boardX` 780)
   dan dianggap keluar bounds. Bendera `layoutChild.absolute` bukan penyebabnya.

   **Dan `setParentXY` sekali setelah `appendChild` tidak cukup.** Instance yang baru dibuat
   belum dikelola layout sampai dia disentuh lagi. Setelah seluruh skrip selesai, jalankan
   pass kedua yang memosisikan ulang **semua** instance:

   ```js
   penpotUtils.analyzeDescendants(root, (r, d) => {
     if (typeof d.isComponentInstance === "function" && d.isComponentInstance())
       penpotUtils.setParentXY(d, 0, 0);
   });
   ```

   Tanpa pass kedua, layar yang berisi banyak instance (daftar, grid chip) akan rusak —
   komponennya menumpuk di luar layar.
7. **`verticalSizing: "fix"` tanpa tinggi eksplisit meng-clip kontennya.** Gejalanya sama
   seperti salah posisi: konten mengambang di kotak raksasa. Untuk baris yang tingginya
   mengikuti isi pakai `"auto"`.
8. **`isComponentInstance()` juga `true` untuk anak di dalam salinan komponen.** Loop
   `findShapes(isComponentInstance, …)` akan ikut menyentuh **isi** komponen. Me-resize
   label di dalam tombol jadi setinggi tombol akan membuat teksnya menempel di atas.
9. **Struktur salinan komponen terkunci.** `appendChild` ke instance dilarang
   (`Cannot change the structure of a component copy`). Elemen opsional harus hidup di
   **main instance**, dan visibilitasnya yang jadi override per instance.
10. **`storage` hilang saat Penpot reload.** Jangan andalkan untuk apa pun yang perlu
    bertahan. Simpan helper di file.
11. **`boardY` relatif ke board terdekat, bukan ke board layar.** Untuk elemen bersarang di
    dalam komponen, `boardY = 3` berarti 3px di dalam barisnya. Untuk posisi absolut pakai
    `d.x - board.x`.
12. **JANGAN pakai `clone()` untuk membuat varian komponen.** `.clone()` dari sebuah main
    instance menghasilkan **board pembungkus setinggi 6px tanpa flex layout**, dan pembungkus
    itu yang jadi komponennya. Gejalanya di layar: baris bertinggi 6px, kontennya meluber,
    dan saling menumpuk — sementara pengecekan containment tetap lolos. Bangun **setiap
    varian dari nol** lewat fungsi pembangun, lalu gabung dengan
    `penpotUtils.createVariantContainer()`.
13. **Komponen varian lahir di `0,0` kalau tidak diletakkan manual.** Kalau konvensimu
    memisahkan area (mis. system di `y >= 2000`, layar di `y < 2000`), komponen yang lahir di
    area layar akan dihapus oleh skrip layar. Set `x`/`y` sebelum `createComponent()`.
14. **Pass kedua yang men-nudge instance harus MELEWATI main instance komponen**
    (`isMainComponent()`). Mereka bukan anak layout; `setParentXY` akan memindahkannya ke
    0,0 sehingga bertumpuk dengan layar.
15. **`isContainedIn` memberi positif palsu untuk anak flex.** Dia melaporkan anak sebagai
    keluar dari induknya walaupun geometrinya persis. Untuk memeriksa induk-anak, bandingkan
    `d.bounds` dengan `p.bounds` dan beri toleransi ~2px. `isContainedIn` tetap andal untuk
    tingkat board.
16. **Sumber `fontId` bisa ikut terhapus.** Menghapus komponen membuat instance di layar
    kehilangan teksnya, dan dengan itu sumber `fontId`/`fontVariantId`-nya. Ambil contoh font
    **paling awal**, dan bootstrap dari teks sementara kalau file sudah kosong:
    ```js
    const t = penpot.createText("Aa");
    t.fontFamily = "Roboto"; t.fontWeight = "600";
    // baca t.fontId dan t.fontVariantId, lalu t.remove()
    ```

## Verifikasi

Dua tingkat: di dalam board, dan di dalam induk. Yang kedua itu yang menangkap baris yang
kehilangan flex layout.

```js
const lewat = (d, p) => { const a = d.bounds, b = p.bounds;
  return Math.max(0, b.x - a.x, b.y - a.y,
    (a.x + a.width) - (b.x + b.width), (a.y + a.height) - (b.y + b.height)); };
```

**Jangan pakai `isContainedIn` untuk tingkat induk** — dia melaporkan anak flex sebagai
keluar walaupun geometrinya persis. Bandingkan bounds dengan toleransi ~2px.

**Lewati elemen tersembunyi.** Karena tidak dikelola layout, posisinya membeku di koordinat
lama dan akan dilaporkan keluar bounds padahal tidak dirender sama sekali.

Untuk mengukur tinggi isi sebenarnya pada board yang punya spacer fleksibel, jangan
mengukurnya langsung: `maxBottom` akan selalu sama dengan tinggi board. Netralkan dulu
spacer-nya, atau pindahkan tinggi board ke pemeriksaan terpisah.

## Salin nilai, jangan mengarang

Untuk tipografi, ambil `fontId`/`fontVariantId` dari teks yang **sudah ada** di file:

```js
const contoh = {};
penpotUtils.analyzeDescendants(page.root, (r, d) => {
  if (d.type === "text") contoh[d.fontFamily + "|" + d.fontWeight] = d;
});
```

Menebak nama varian font jauh lebih rapuh daripada menyalin yang sudah terpasang. Prinsip
yang sama berlaku untuk gaya lain: cari contoh di kanvas, jangan tebak.

## Kerangka helper

Lihat `assets/kerangka.js`. Isi paling penting yang gampang terlupa: setiap `appendChild`
ke parent **tanpa flex layout** wajib diikuti `penpotUtils.setParentXY(child, 0, 0)`.
Baik untuk board biasa maupun instance komponen.
