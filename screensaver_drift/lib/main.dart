import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:screensaver_drift/painter.dart';
import 'package:screensaver_drift/worker.dart';

import 'dto.dart';
import 'model.dart';

void main() async {
  final client = await DriftWorkerClient.spawn();
  runApp(MyApp(worker: client));
}

class MyApp extends StatefulWidget {
  final DriftWorkerClient worker;
  const MyApp({super.key, required this.worker});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late Stream<DriftFieldFrame> _stream;
  late final ValueNotifier<DriftFrameData> _lastFrame;
  StreamSubscription? _sub;
  late DriftFieldRequest _request;
  late PainterSettings _painterSettings;
  final _rng = Random();

  @override
  void initState() {
    _lastFrame = ValueNotifier(DriftFrameData.empty());
    _request = DriftFieldRequest.randomWeb(_rng);
    _painterSettings = PainterSettings.randomWeb(_rng);
    super.initState();
  }

  void _startStream() {
    _sub?.cancel();
    _stream = widget.worker.stream(_request);
    _sub = _stream.listen(
      (frame) => _lastFrame.value = DriftFrameData.fromRawFrame(frame),
    );
  }

  @override
  void didChangeDependencies() {
    _startStream();
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    _sub?.cancel();
    widget.worker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        floatingActionButton: FloatingActionButton.extended(
          label: const Text('Randomize'),
          icon: const Icon(Icons.shuffle),
          onPressed: () {
            setState(() {
              _request = DriftFieldRequest.randomWeb(_rng);
              _painterSettings = PainterSettings.randomWeb(_rng);
              _startStream();
            });
          },
        ),
        body: ValueListenableBuilder(
          valueListenable: _lastFrame,
          builder: (context, frame, _) {
            return SizedBox.expand(
              child: CustomPaint(
                painter: DriftFinalPainter(
                  baseAlpha: _painterSettings.baseAlpha,
                  lineWidth: _painterSettings.lineWidth,
                  tiltGain: _painterSettings.tiltGain,
                  tiltBrightnessGain: _painterSettings.tiltBrightnessGain,
                  tiltZFloor: _painterSettings.tiltZFloor,
                  hairCountX: _painterSettings.hairCountX,
                  hairCountY: _painterSettings.hairCountY,
                  jitter: _painterSettings.jitter,
                  gamma: _painterSettings.gamma,
                  normalGain: _painterSettings.normalGain,
                  ambient: _painterSettings.ambient,
                  diffuseK: _painterSettings.diffuseK,
                  specularK: _painterSettings.specularK,
                  shininess: _painterSettings.shininess,
                  heightCut: _painterSettings.heightCut,
                  heightCutFeather: _painterSettings.heightCutFeather,
                  projX: _painterSettings.projX,
                  projY: _painterSettings.projY,
                  drawBackground: _painterSettings.drawBackground,
                  backgroundColor: _painterSettings.backgroundColor,
                  palette: _painterSettings.palette,
                  bulgeScale: _painterSettings.bulgeScale,
                  repaint: _lastFrame,
                  getFrame: () => frame,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class PainterSettings {
  const PainterSettings({
    required this.baseAlpha,
    required this.lineWidth,
    required this.tiltGain,
    required this.tiltBrightnessGain,
    required this.tiltZFloor,
    required this.hairCountX,
    required this.hairCountY,
    required this.jitter,
    required this.gamma,
    required this.normalGain,
    required this.ambient,
    required this.diffuseK,
    required this.specularK,
    required this.shininess,
    required this.heightCut,
    required this.heightCutFeather,
    required this.projX,
    required this.projY,
    required this.drawBackground,
    required this.backgroundColor,
    required this.palette,
    required this.bulgeScale,
  });

  final double baseAlpha;
  final double lineWidth;
  final double tiltGain;
  final double tiltBrightnessGain;
  final double tiltZFloor;
  final int hairCountX;
  final int hairCountY;
  final double jitter;
  final double gamma;
  final double normalGain;
  final double ambient;
  final double diffuseK;
  final double specularK;
  final double shininess;
  final double heightCut;
  final double heightCutFeather;
  final double projX;
  final double projY;
  final bool drawBackground;
  final Color backgroundColor;
  final List<Color> palette;
  final double bulgeScale;

  factory PainterSettings.driftDefault() => const PainterSettings(
    baseAlpha: 0.78,
    lineWidth: 1.3,
    tiltGain: 16,
    tiltBrightnessGain: 0.7,
    tiltZFloor: 0.22,
    hairCountX: 220,
    hairCountY: 130,
    jitter: 0.12,
    gamma: 1.6,
    normalGain: 3.6,
    ambient: 0.42,
    diffuseK: 0.96,
    specularK: 0.28,
    shininess: 26,
    heightCut: 0.05,
    heightCutFeather: 0.24,
    projX: 0.18,
    projY: 0.90,
    drawBackground: true,
    backgroundColor: Color(0xFF06070D),
    palette: DriftFinalPainter.defaultPalette,
    bulgeScale: 0.35,
  );

  factory PainterSettings.random(Random rng) {
    double lerp(double a, double b) => a + (b - a) * rng.nextDouble();
    int lerpInt(int a, int b) => a + (rng.nextDouble() * (b - a)).round();
    return PainterSettings(
      baseAlpha: lerp(0.65, 0.9),
      lineWidth: lerp(1.0, 1.5),
      tiltGain: lerp(18, 30),
      tiltBrightnessGain: lerp(0.4, 1.0),
      tiltZFloor: lerp(0.18, 0.32),
      hairCountX: lerpInt(120, 220),
      hairCountY: lerpInt(50, 110),
      jitter: lerp(0.08, 0.2),
      gamma: lerp(1.4, 1.9),
      normalGain: lerp(3.0, 5.0),
      ambient: lerp(0.35, 0.48),
      diffuseK: lerp(0.9, 1.05),
      specularK: lerp(0.22, 0.42),
      shininess: lerp(22, 34),
      heightCut: lerp(-0.02, 0.12),
      heightCutFeather: lerp(0.18, 0.3),
      projX: lerp(0.14, 0.24),
      projY: lerp(0.85, 0.98),
      drawBackground: true,
      backgroundColor: const Color(0xFF06070D),
      palette: _randomPalette(rng),
      bulgeScale: lerp(0.2, 0.55),
    );
  }

  factory PainterSettings.randomWeb(Random rng) {
    double lerp(double a, double b) => a + (b - a) * rng.nextDouble();
    int lerpInt(int a, int b) => a + (rng.nextDouble() * (b - a)).round();
    return PainterSettings(
      baseAlpha: lerp(0.7, 0.9),
      lineWidth: lerp(1.0, 1.3),
      tiltGain: lerp(14, 22),
      tiltBrightnessGain: lerp(0.5, 0.9),
      tiltZFloor: lerp(0.18, 0.30),
      hairCountX: lerpInt(90, 110),
      hairCountY: lerpInt(80, 90),
      jitter: lerp(0.18, 0.26),
      gamma: lerp(1.4, 1.8),
      normalGain: lerp(3.0, 4.5),
      ambient: lerp(0.36, 0.46),
      diffuseK: lerp(0.9, 1.0),
      specularK: lerp(0.22, 0.36),
      shininess: lerp(22, 32),
      heightCut: lerp(-0.02, 0.1),
      heightCutFeather: lerp(0.16, 0.28),
      projX: lerp(0.15, 0.22),
      projY: lerp(0.86, 0.95),
      drawBackground: true,
      backgroundColor: const Color(0xFF06070D),
      palette: _randomPalette(rng),
      bulgeScale: lerp(0.4, 0.8),
    );
  }

  static List<Color> _randomPalette(Random rng) {
    double clamp01(double v) => v.clamp(0.0, 1.0);
    double hueWrap(double h) {
      h %= 360.0;
      if (h < 0) h += 360.0;
      return h;
    }

    final baseHue = rng.nextDouble() * 360.0;
    final sat = clamp01(0.60 + rng.nextDouble() * 0.25);
    final lightBase = clamp01(0.35 + rng.nextDouble() * 0.25);

    // Выбираем схему: 0 — аналогичная, 1 — триада.
    final scheme = rng.nextBool() ? 0 : 1;
    List<double> hues;
    if (scheme == 0) {
      // аналогичная
      final spread = 25 + rng.nextDouble() * 15;
      hues = [
        baseHue,
        hueWrap(baseHue + spread),
        hueWrap(baseHue - spread),
        hueWrap(baseHue + spread * 1.6),
      ];
    } else {
      // триада
      hues = [
        baseHue,
        hueWrap(baseHue + 120),
        hueWrap(baseHue - 120),
        hueWrap(baseHue + 180),
      ];
    }

    // Лёгкая вариация яркости внутри палитры.
    List<Color> colors = [];
    for (int i = 0; i < hues.length; i++) {
      final t = i / (hues.length - 1).clamp(1, 10);
      final l = clamp01(lightBase + (0.18 * t) - 0.06 * rng.nextDouble());
      colors.add(HSLColor.fromAHSL(1.0, hues[i], sat, l).toColor());
    }
    return colors;
  }
}
