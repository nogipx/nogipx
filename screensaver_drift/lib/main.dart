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
  late final ValueNotifier<double> _fps;
  StreamSubscription? _sub;
  late StrategyUIOption _strategy;
  late DriftFieldRequest _request;
  late PainterSettings _painterSettings;
  final GlobalKey<NavigatorState> _navKey = GlobalKey<NavigatorState>();
  final _rng = Random();
  final _fpsWatch = Stopwatch();
  int _fpsFrames = 0;

  @override
  void initState() {
    _lastFrame = ValueNotifier(DriftFrameData.empty());
    _fps = ValueNotifier(0);
    _strategy = kStrategies.first;
    _request = _strategy.buildRequest(_rng);
    _painterSettings = _strategy.buildPainter(_rng);
    super.initState();
  }

  void _randomizeCurrent() {
    setState(() {
      _request = _strategy.buildRequest(_rng);
      _painterSettings = _strategy.buildPainter(_rng);
      _startStream();
    });
  }

  void _setStrategy(StrategyUIOption option) {
    if (option == _strategy) return;
    setState(() {
      _strategy = option;
      _request = option.buildRequest(_rng);
      _painterSettings = option.buildPainter(_rng);
      _startStream();
    });
  }

  Future<void> _showStrategySheet() async {
    if (!mounted) return;
    final navContext = _navKey.currentContext;
    if (navContext == null) return;
    final selected = await showModalBottomSheet<StrategyUIOption>(
      context: navContext,
      backgroundColor: Colors.black87,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            const Text(
              'Choose strategy',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            ...kStrategies.map((option) {
              final selected = option == _strategy;
              return ListTile(
                leading: Icon(
                  selected ? Icons.radio_button_checked : Icons.radio_button_off,
                  color: selected ? Colors.amber : Colors.white70,
                ),
                title: Text(
                  option.label,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                  ),
                ),
                subtitle: Text(
                  option.subtitle,
                  style: const TextStyle(color: Colors.white60),
                ),
                onTap: () => Navigator.of(ctx).pop(option),
              );
            }),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
    if (selected != null) {
      _setStrategy(selected);
    }
  }

  void _startStream() {
    _sub?.cancel();
    _fpsFrames = 0;
    _fpsWatch
      ..reset()
      ..start();
    _stream = widget.worker.stream(_request);
    _sub = _stream.listen((frame) {
      _lastFrame.value = DriftFrameData.fromRawFrame(frame);
      _fpsFrames++;
      final elapsedMs = _fpsWatch.elapsedMilliseconds;
      if (elapsedMs >= 500) {
        _fps.value = _fpsFrames * 1000 / elapsedMs;
        _fpsFrames = 0;
        _fpsWatch
          ..reset()
          ..start();
      }
    });
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
    _fps.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navKey,
      home: Scaffold(
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        floatingActionButton: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              Expanded(
                child: FloatingActionButton.extended(
                  heroTag: 'strategyPicker',
                  backgroundColor: Colors.black.withOpacity(0.8),
                  icon: const Icon(Icons.auto_awesome),
                  label: Text(_strategy.label),
                  onPressed: _showStrategySheet,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FloatingActionButton.extended(
                  heroTag: 'randomize',
                  label: Text('Random ${_strategy.label}'),
                  icon: const Icon(Icons.shuffle),
                  onPressed: _randomizeCurrent,
                ),
              ),
            ],
          ),
        ),
        body: ValueListenableBuilder(
          valueListenable: _lastFrame,
          builder: (context, frame, _) {
            return Stack(
              children: [
                SizedBox.expand(
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
                ),
                Positioned(
                  left: 12,
                  top: 12,
                  child: ValueListenableBuilder<double>(
                    valueListenable: _fps,
                    builder: (context, fps, _) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.55),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'FPS ${fps.toStringAsFixed(1)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

enum StrategyKind {
  fire('fire', 'Fire'),
  drift('drift', 'Drift'),
  pulsate('pulsate', 'Pulsate');

  const StrategyKind(this.id, this.label);
  final String id;
  final String label;
}

class StrategyUIOption {
  const StrategyUIOption({
    required this.kind,
    required this.buildRequest,
    required this.buildPainter,
  });

final StrategyKind kind;
  String get id => kind.id;
  String get label => kind.label;
  String get subtitle => kind == StrategyKind.fire
      ? 'Buoyant flames'
      : kind == StrategyKind.pulsate
          ? 'Breathing pulses'
          : 'Windy drift';
  final DriftFieldRequest Function(Random rng) buildRequest;
  final PainterSettings Function(Random rng) buildPainter;
}

final List<StrategyUIOption> kStrategies = [
  StrategyUIOption(
    kind: StrategyKind.fire,
    buildRequest: DriftFieldRequest.fire,
    buildPainter: PainterSettings.fire,
  ),
  StrategyUIOption(
    kind: StrategyKind.drift,
    buildRequest: DriftFieldRequest.randomWeb,
    buildPainter: PainterSettings.randomWeb,
  ),
  StrategyUIOption(
    kind: StrategyKind.pulsate,
    buildRequest: (rng) => DriftFieldRequest.random(_rngPulsate(rng)),
    buildPainter: PainterSettings.random,
  ),
];

// Пульсации хотим более медленный дрейф и другой диапазон — подкручиваем RNG.
Random _rngPulsate(Random base) => Random(base.nextInt(0x7fffffff));

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
      palette: _flutterPalette(rng),
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
      palette: _flutterPalette(rng),
      bulgeScale: lerp(0.4, 0.8),
    );
  }

  factory PainterSettings.fire(Random rng) {
    double lerp(double a, double b) => a + (b - a) * rng.nextDouble();
    int lerpInt(int a, int b) => a + (rng.nextDouble() * (b - a)).round();
    return PainterSettings(
      baseAlpha: lerp(0.78, 0.9),
      lineWidth: lerp(1.15, 1.45),
      tiltGain: lerp(14, 20),
      tiltBrightnessGain: lerp(0.75, 1.05),
      tiltZFloor: lerp(0.12, 0.2),
      hairCountX: lerpInt(110, 140),
      hairCountY: lerpInt(180, 220),
      jitter: lerp(0.16, 0.26),
      gamma: lerp(1.35, 1.55),
      normalGain: lerp(3.2, 4.0),
      ambient: lerp(0.30, 0.40),
      diffuseK: lerp(0.98, 1.10),
      specularK: lerp(0.14, 0.24),
      shininess: lerp(18, 28),
      heightCut: lerp(-0.05, 0.06),
      heightCutFeather: lerp(0.14, 0.24),
      projX: lerp(0.12, 0.18),
      projY: lerp(0.88, 0.98),
      drawBackground: true,
      backgroundColor: const Color(0xFF080402),
      palette: _firePalette(rng),
      bulgeScale: lerp(0.75, 1.05),
    );
  }

  static List<Color> _flutterPalette(Random rng) {
    const presets = [
      [
        Color(0xFF025BFE), // flutter blue
        Color(0xFF00C4B3), // teal accent
        Color(0xFF7B61FF), // purple accent
        Color(0xFFE3F2FD), // light sky
      ],
      [
        Color(0xFF0175C2), // flutter blue primary
        Color(0xFF13B9FD), // cyan accent
        Color(0xFF5CE1E6), // aqua
        Color(0xFFFFD166), // warm accent
      ],
      [
        Color(0xFF0F172A), // near black
        Color(0xFF1E293B), // slate
        Color(0xFF38BDF8), // sky blue
        Color(0xFF5C7CFA), // indigo accent
      ],
      [
        Color(0xFF111827), // dark slate
        Color(0xFF2563EB), // blue
        Color(0xFF22D3EE), // cyan
        Color(0xFF60F6D2), // mint
      ],
    ];
    return presets[rng.nextInt(presets.length)];
  }

  static List<Color> _firePalette(Random rng) {
    const presets = [
      [
        Color(0xFF0D0302), // charcoal
        Color(0xFF5B1207), // ember red
        Color(0xFFBC2F10), // hot orange
        Color(0xFFE86F0C), // bright flame
        Color(0xFFFFE8B8), // soft white tip
      ],
      [
        Color(0xFF0A0507), // dark plum
        Color(0xFF7A1E0A), // lava
        Color(0xFFCC3A0F), // orange core
        Color(0xFFF59F0A), // golden
        Color(0xFFFFF4D2), // pale tip
      ],
      [
        Color(0xFF050305), // near black
        Color(0xFF4E0E0C), // deep ember
        Color(0xFFB22710), // vermilion
        Color(0xFFF1740A), // flame orange
        Color(0xFFFFE0A6), // light tip
      ],
    ];
    return presets[rng.nextInt(presets.length)];
  }
}
