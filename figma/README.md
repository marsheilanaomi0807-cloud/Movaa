# MOVA — Frame Figma

5 file SVG ukuran **375 × 812** (iPhone 14 Pro), siap di-import ke Figma.
Setiap file jadi **1 frame** dengan layer teks & vektor yang masih bisa diedit.

| File | Layar |
|---|---|
| `01-onboarding.svg` | Onboarding |
| `02-calibration.svg` | Calibration |
| `03-live-monitoring.svg` | Live Monitoring |
| `04-alert-feedback.svg` | Alert / Feedback |
| `05-dashboard.svg` | Dashboard |

`_preview.html` = pratinjau kelima frame sekaligus (buka di browser, bukan untuk Figma).

---

## Langkah import

1. Buka Figma → **New design file**.
2. **Drag kelima file SVG** sekaligus ke kanvas.
3. Figma minta konfirmasi font → pilih **Poppins** dan **Nunito**
   (keduanya gratis & tersedia di Figma). Kalau diminta ganti, klik *Replace*.
4. Tiap SVG masuk sebagai satu grup. Pilih grup → klik kanan → **Frame selection**
   supaya jadi frame betulan, lalu atur ukurannya ke 375 × 812.
5. Rapikan urutan frame di kanvas sesuai nomor 01–05.

> Sesudah ini semua teks bisa di-klik dua kali dan diketik ulang, warna bisa diganti
> lewat panel Fill, dan tiap kartu/ikon adalah layer terpisah.

---

## Menyambung jadi prototype

Buka tab **Prototype** (kanan atas), lalu tarik panah dari tombol ke frame tujuan:

| Dari frame | Elemen yang diklik | Ke frame |
|---|---|---|
| 01 Onboarding | `Get Started` | 02 Calibration |
| 01 Onboarding | `Skip` | 03 Live Monitoring |
| 02 Calibration | `Start Calibration` | 03 Live Monitoring |
| 03 Live Monitoring | *(After delay 15000ms)* | 04 Alert / Feedback |
| 03 Live Monitoring | nav `History` | 05 Dashboard |
| 04 Alert | `Got it!` | 03 Live Monitoring |
| 04 Alert | `Remind me in 5 minutes` | 03 Live Monitoring |
| 04 Alert | ikon `X` | 03 Live Monitoring |
| 05 Dashboard | nav `Home` | 03 Live Monitoring |

**Trigger otomatis 15 detik** (sesuai threshold MOVA): pilih frame 03 → tab Prototype →
klik ikon `+` pada frame (bukan pada elemen) → Trigger **After delay** → `15000ms` →
Navigate to **04 Alert**.

Animasi yang cocok: **Smart animate**, *Ease out*, `300ms`.

---

## Palet warna

| Token | Hex | Dipakai untuk |
|---|---|---|
| Cream | `#FDF9F5` | Latar layar |
| Maroon | `#6E4048` | Logo MOVA |
| Button | `#8E6B68` | Tombol utama |
| Blue | `#5AA0E0` | Ring posisi, ikon |
| Blue deep | `#3C82C9` | Aksen angka & link |
| Purple | `#6B5FA8` | Nav aktif, low-light |
| Teal | `#35B8A0` | Status baik |
| Ink | `#2C3550` | Teks utama |
| Ink-2 | `#5C6680` | Teks sekunder |
| Ink-3 | `#8A93A8` | Teks tersier |

Font: **Poppins** (judul, angka) + **Nunito** (teks isi).

---

## Alternatif: import langsung dari HTML

Kalau mau hasil lebih presisi (termasuk auto-layout), pakai plugin Figma
**html.to.design**: buka plugin → tab *Code* → paste isi `../mova_ui.html` → Import.
Hasilnya lebih rapi strukturnya, tapi perlu pasang plugin dulu.
