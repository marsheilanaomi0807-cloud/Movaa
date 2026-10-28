# MOVA — Modul Sensor & Position Logic

Bagian dari aplikasi **MOVA (Phone Usage Posture Detector)**. Modul ini menangani
pembacaan sensor, kalibrasi personal, deteksi orientasi, dan penentuan kapan
posisi perangkat dianggap perlu dikoreksi.

## Struktur

```
lib/core/
├── sensors/
│   ├── vector3.dart              # tipe vektor 3 sumbu
│   ├── device_orientation.dart   # enum portrait / landscape / flat
│   ├── sensor_sample.dart        # satu titik data terolah + utilitas sudut
│   └── sensor_service.dart       # baca accelerometer + gyroscope
└── posture/
    ├── posture_config.dart        # semua parameter yang bisa disetel
    ├── posture_baseline.dart      # baseline personal (+ JSON)
    ├── calibration_controller.dart# proses kalibrasi
    ├── posture_state.dart         # status, deviasi, statistik sesi
    ├── posture_analyzer.dart      # logika inti: kapan perlu dikoreksi
    ├── activity_estimator.dart    # taksiran aktivitas sementara
    └── posture_monitor.dart       # titik masuk untuk UI

lib/ui/posture_demo_page.dart      # halaman uji (bukan desain final)
test/                              # 17 test, jalan tanpa perangkat fisik
```

## Dua besaran utama

Gravitasi hasil low-pass filter diubah menjadi dua sudut:

| Besaran | Rumus | Arti |
|---|---|---|
| `screenTiltDeg` | `acos(gz / \|g\|)` | 0° = layar menghadap langit (kepala paling menunduk), 90° = layar tegak lurus, 180° = layar menghadap lantai |
| `rotationDeg` | `atan2(gx, gy)` | 0° = portrait, +90° = landscape kiri, ±180° = portrait terbalik, −90° = landscape kanan |

`screenTiltDeg` sengaja dipilih karena **tidak terpengaruh portrait/landscape**,
sehingga satu baseline berlaku untuk kedua orientasi. Rumus pitch/roll biasa
akan berubah nilainya begitu HP diputar ke landscape.

## Alur pemakaian

```dart
final monitor = PostureMonitor();

monitor.startSensors();

// Kalibrasi: pengguna menahan HP pada posisi nyaman selama 5 detik.
final baseline = await monitor.calibrate();
if (baseline == null) { /* gagal, minta ulang */ }

monitor.startMonitoring();

monitor.evaluations.listen((e) {
  if (e.correctionTriggered) showNudge(e.deviation.hint);
  if (e.breakReminderDue)   showBreakReminder();
});

// Selesai
final stats = monitor.stopMonitoring();
print(stats.positionScore);   // 0..100
```

Baseline bisa disimpan lintas sesi:

```dart
prefs.setString('baseline', jsonEncode(baseline.toJson()));
monitor.restoreBaseline(PostureBaseline.fromJson(jsonDecode(raw)));
```

## Kapan posisi dianggap perlu dikoreksi

1. **Selisih terhadap baseline** dihitung dengan toleransi **asimetris** —
   HP yang jadi lebih mendatar (`downwardToleranceDeg = 15°`) dinilai lebih ketat
   daripada HP yang jadi lebih tegak (`upwardToleranceDeg = 25°`), karena hanya
   arah pertama yang membebani leher.
2. **Toleransi dilebarkan menurut aktivitas** — berjalan dikali `1.6`,
   di kendaraan monitoring dijeda sepenuhnya.
3. **Timer dijalankan, bukan langsung menegur.** Peringatan baru muncul setelah
   posisi bertahan `correctionDwell = 20 detik` di luar zona nyaman. Inilah yang
   membuat gerakan sesaat tidak dianggap masalah.
4. **Timer dibekukan saat HP sedang digerakkan** (gyroscope di atas `1.2 rad/s`) —
   tidak bertambah, juga tidak direset.
5. **Penyimpangan parah memperpendek ambang** menjadi separuh waktu.
6. Setelah menegur, ada **cooldown 60 detik** agar tidak bertubi-tubi.
7. Saat posisi kembali nyaman, timer **meluruh dua kali lebih cepat**, bukan
   langsung nol, supaya posisi yang keluar-masuk zona nyaman tetap tercatat.

Semua angka di atas ada di `PostureConfig` dan bisa diubah lewat `copyWith()`.

## Status yang dihasilkan

| Status | Arti |
|---|---|
| `good` | Posisi di dalam zona nyaman |
| `drifting` | Di luar zona nyaman, belum melewati ambang durasi |
| `needsCorrection` | Sudah bertahan melewati ambang — saatnya memberi arahan |
| `paused` | Dijeda (pengguna di kendaraan) |
| `unreliable` | Pembacaan gravitasi tidak masuk akal, evaluasi ditangguhkan |

## Menjalankan

Project sudah di-scaffold dan diverifikasi pada:

| Komponen | Versi |
|---|---|
| Flutter | 3.47.5 (stable) |
| Dart | 3.13.4 |
| sensors_plus | 7.1.0 |
| flutter_lints | 6.0.0 |

Folder `android/` dan `ios/` sudah dibuat, dependency sudah terpasang.
Cukup jalankan:

```bash
flutter run
```

Accelerometer dan gyroscope tidak memerlukan permission khusus pada laju 25 Hz
yang dipakai modul ini. Permission `HIGH_SAMPLING_RATE_SENSORS` di Android 12+
baru wajib kalau laju melebihi 200 Hz.

### Catatan lokasi SDK

SDK Flutter kebetulan diekstrak ke dalam folder project ini (`MOVA/flutter`).
Semuanya tetap berjalan, dan folder itu sudah dikecualikan dari analyzer serta
dari `.gitignore`. Tapi kalau nanti project ini di-push ke GitHub atau
dipindah-pindah, lebih rapi kalau SDK dipindahkan keluar, misalnya ke
`C:\srclutter`, lalu PATH diarahkan ke `C:\srclutterin`.

### Belum bisa build APK

`flutter doctor` masih menandai Android toolchain belum lengkap:

```
[X] Android toolchain - Unable to locate Android SDK.
```

Pasang Android Studio (sekalian Android SDK + platform-tools), lalu jalankan:

```bash
flutter doctor --android-licenses
```

Sesudah itu `flutter run` bisa menembak HP Android sungguhan. Sensor postur
tidak bisa diuji di Chrome atau Windows desktop karena keduanya tidak punya
accelerometer.

## Pengujian

Logika posisi dibuat murni (tanpa Stream dan tanpa Flutter) sehingga bisa diuji
tanpa perangkat fisik:

```bash
flutter test
```

Status terakhir: **17 test lulus**, `flutter analyze` bersih.

| Berkas uji | Cakupan |
|---|---|
| `test/posture_logic_test.dart` | 16 test: orientasi, zona nyaman asimetris, ambang durasi, timer beku, konteks aktivitas, statistik sesi |
| `test/posture_demo_page_test.dart` | 1 test: halaman demo ter-compile dan tampil tanpa sensor |

## Integrasi dengan modul lain

- **Activity Recognition** → panggil `monitor.setActivity(ActivityContext.walking)`.
  Selama belum dipanggil, `ActivityEstimator` internal dipakai sebagai cadangan.
- **Ambient Light** → modul terpisah, tidak menyentuh file di sini.
- **Dashboard & History** → pakai `PostureSessionStats` yang dikembalikan
  `stopMonitoring()` (position score, durasi monitoring, durasi posisi baik,
  jumlah koreksi).
