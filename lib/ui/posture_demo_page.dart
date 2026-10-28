import 'dart:async';

import 'package:flutter/material.dart';

import '../core/mova_core.dart';

/// Halaman uji untuk modul Sensor & Position Logic.
///
/// Bukan desain final MOVA — tujuannya supaya logika sensor, kalibrasi, dan
/// deteksi koreksi bisa dilihat langsung di perangkat.
class PostureDemoPage extends StatefulWidget {
  const PostureDemoPage({super.key});

  @override
  State<PostureDemoPage> createState() => _PostureDemoPageState();
}

class _PostureDemoPageState extends State<PostureDemoPage> {
  final PostureMonitor _monitor = PostureMonitor();

  StreamSubscription<CalibrationState>? _calibSub;
  StreamSubscription<PostureEvaluation>? _evalSub;
  StreamSubscription<SensorSample>? _sampleSub;

  CalibrationState? _calibration;
  PostureEvaluation? _evaluation;
  SensorSample? _sample;

  @override
  void initState() {
    super.initState();
    _monitor.startSensors();

    // Tampilkan nilai sensor mentah walaupun monitoring belum jalan.
    _sampleSub = _monitor.samples.listen((s) {
      if (mounted) setState(() => _sample = s);
    });

    _evalSub = _monitor.evaluations.listen((e) {
      if (mounted) setState(() => _evaluation = e);
      if (e.correctionTriggered) _showCorrection(e);
    });
  }

  @override
  void dispose() {
    _calibSub?.cancel();
    _evalSub?.cancel();
    _sampleSub?.cancel();
    _monitor.dispose();
    super.dispose();
  }

  void _showCorrection(PostureEvaluation e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(e.deviation.hint),
        backgroundColor: Colors.orange.shade800,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _startCalibration() {
    _calibSub?.cancel();
    _calibSub = _monitor.calibrationStream().listen((state) {
      if (!mounted) return;
      setState(() => _calibration = state);
    });
  }

  void _toggleMonitoring() {
    setState(() {
      if (_monitor.isMonitoring) {
        _monitor.stopMonitoring();
      } else {
        _monitor.startMonitoring();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final sample = _sample;
    final evaluation = _evaluation;
    final baseline = _monitor.baseline;

    return Scaffold(
      appBar: AppBar(title: const Text('MOVA - Sensor & Position Logic')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _StatusCard(evaluation: evaluation, isCalibrated: _monitor.isCalibrated),
          const SizedBox(height: 12),
          _SectionCard(
            title: 'Pembacaan Sensor',
            children: [
              _row('Kemiringan layar',
                  '${sample?.screenTiltDeg.toStringAsFixed(1) ?? "-"}°'),
              _row('Sudut putar',
                  '${sample?.rotationDeg.toStringAsFixed(1) ?? "-"}°'),
              _row('Orientasi', sample?.stableOrientation.label ?? '-'),
              _row('Gyroscope',
                  '${sample?.angularSpeed.toStringAsFixed(2) ?? "-"} rad/s'),
              _row('Guncangan',
                  '${sample?.jitter.toStringAsFixed(2) ?? "-"} m/s²'),
            ],
          ),
          const SizedBox(height: 12),
          _SectionCard(
            title: 'Kalibrasi Personal',
            children: [
              if (_calibration != null) ...[
                Text(_calibration!.message),
                const SizedBox(height: 8),
                LinearProgressIndicator(value: _calibration!.progress),
                const SizedBox(height: 12),
              ],
              if (baseline != null) ...[
                _row('Baseline kemiringan',
                    '${baseline.tiltDeg.toStringAsFixed(1)}°'),
                _row('Baseline putaran',
                    '${baseline.rotationDeg.toStringAsFixed(1)}°'),
                _row('Orientasi awal', baseline.orientation.label),
                _row('Kualitas',
                    '${(baseline.stabilityScore * 100).toStringAsFixed(0)}% - ${baseline.description}'),
                if (baseline.isRiskyBaseline)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text(
                      'Posisi awal kamu sudah cukup menunduk. Coba angkat HP '
                      'sedikit lalu kalibrasi ulang.',
                      style: TextStyle(color: Colors.orange),
                    ),
                  ),
                const SizedBox(height: 12),
              ],
              FilledButton.tonal(
                onPressed: _startCalibration,
                child: Text(baseline == null
                    ? 'Mulai Kalibrasi'
                    : 'Kalibrasi Ulang'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (evaluation != null)
            _SectionCard(
              title: 'Evaluasi Posisi',
              children: [
                _row('Selisih kemiringan',
                    '${evaluation.deviation.tiltDeltaDeg.toStringAsFixed(1)}°'),
                _row('Kelebihan di luar toleransi',
                    '${evaluation.deviation.tiltExcessDeg.toStringAsFixed(1)}°'),
                _row('Di luar zona nyaman selama',
                    _fmt(evaluation.outOfComfortFor)),
                _row('Ambang koreksi', _fmt(evaluation.requiredDwell)),
                const SizedBox(height: 8),
                LinearProgressIndicator(value: evaluation.dwellProgress),
                const SizedBox(height: 12),
                _row('Aktivitas', evaluation.activity.label),
                _row('Position Score',
                    evaluation.stats.positionScore.toStringAsFixed(0)),
                _row('Durasi monitoring', _fmt(evaluation.stats.activeDuration)),
                _row('Durasi posisi baik', _fmt(evaluation.stats.goodDuration)),
                _row('Jumlah koreksi', '${evaluation.stats.correctionCount}'),
              ],
            ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _monitor.isCalibrated ? _toggleMonitoring : null,
            child: Text(_monitor.isMonitoring
                ? 'Stop Monitoring'
                : 'Start Monitoring'),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: Text(label)),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      );

  static String _fmt(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return m > 0 ? '${m}m ${s}s' : '${s}s';
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.evaluation, required this.isCalibrated});

  final PostureEvaluation? evaluation;
  final bool isCalibrated;

  @override
  Widget build(BuildContext context) {
    final e = evaluation;
    final color = switch (e?.status) {
      PostureStatus.good => Colors.green,
      PostureStatus.drifting => Colors.amber,
      PostureStatus.needsCorrection => Colors.deepOrange,
      PostureStatus.paused => Colors.blueGrey,
      PostureStatus.unreliable => Colors.grey,
      null => Colors.grey,
    };

    return Card(
      color: color.withAlpha(30),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              e?.status.label ??
                  (isCalibrated ? 'Siap dimonitor' : 'Belum dikalibrasi'),
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(color: color, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(e?.message ??
                'Lakukan kalibrasi dulu dengan memegang HP pada posisi nyaman.'),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const Divider(),
            ...children,
          ],
        ),
      ),
    );
  }
}
