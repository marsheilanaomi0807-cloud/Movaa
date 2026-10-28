import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mova/ui/posture_demo_page.dart';

/// Uji ringan halaman demo: memastikan UI ter-compile dan tampil tanpa error
/// walaupun tidak ada sensor sungguhan (di lingkungan test, plugin sensor
/// tidak tersedia dan alirannya memang kosong).
void main() {
  testWidgets('halaman demo tampil dalam keadaan belum dikalibrasi',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: PostureDemoPage()));
    await tester.pump();

    expect(find.text('Belum dikalibrasi'), findsOneWidget);
    expect(find.text('Mulai Kalibrasi'), findsOneWidget);
    expect(find.text('Pembacaan Sensor'), findsOneWidget);
    expect(find.text('Kalibrasi Personal'), findsOneWidget);

    // Monitoring belum boleh dijalankan sebelum ada baseline.
    final startButton =
        tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Start Monitoring'));
    expect(startButton.onPressed, isNull);

    // Lepaskan widget supaya langganan sensor ikut dibersihkan.
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
