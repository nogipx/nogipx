part of '../_index.dart';

/// Стратегия расчёта полей: позволяет держать разные режимы (дрейф/пульсация/огонь)
/// отдельно от конфигурации сетки и шумов.
abstract class FieldStrategy {
  const FieldStrategy();

  TemporalParams buildTemporalParams(FieldConfig config, double t);

  ({double px, double py}) warp(
    int x,
    int y,
    FieldConfig config,
    double t,
    TemporalParams params,
  );

  double stream(
    FieldConfig config,
    int x,
    int y,
    double t,
    double px,
    double py,
    TemporalParams params,
  );

  ({double rhoSrc, double bulgeSrc}) sources(
    FieldConfig config,
    double px,
    double py,
    TemporalParams params,
    int x,
    int y,
  );
}

final Map<String, FieldStrategy> _strategyRegistry = {
  'drift': const DriftStrategy(),
  'pulsate': const PulsateStrategy(),
  'fire': const FireStrategy(),
};

FieldStrategy _strategyForId(String id) =>
    _strategyRegistry[id.toLowerCase()] ?? const DriftStrategy();

({double px, double py}) _warpCommon(
  int x,
  int y,
  FieldConfig config,
  double t,
  TemporalParams params,
) {
  final warp = config.tuning.warp;
  final fx = x.toDouble();
  final fy = y.toDouble();

  final wx = fbm3(
    (fx + params.slideX) * config.warpFreq * params.warpScale,
    (fy + params.slideY) * config.warpFreq * params.warpScale,
    params.tzWarp,
    config.seed ^ 0xA341316C,
  );
  final wy = fbm3(
    (fx + warp.noiseOffsetX + params.slideX) *
        config.warpFreq *
        params.warpScale,
    (fy + warp.noiseOffsetY + params.slideY) *
        config.warpFreq *
        params.warpScale,
    params.tzWarp + warp.tzOffset,
    config.seed ^ 0xC8013EA4,
  );

  final dx = (wx - 0.5) * config.warpAmp * params.warpAmp;
  final dy = (wy - 0.5) * config.warpAmp * params.warpAmp;
  final driftX = t * config.speedX * params.driftScale;
  final driftY = t * config.speedY * params.driftScale;

  final baseFreq = config.baseFreq * params.baseFreqScale;
  final px = (fx + dx + driftX + t * warp.timeOffsetX) * baseFreq;
  final py = (fy + dy + driftY + t * warp.timeOffsetY) * baseFreq;
  return (px: px, py: py);
}
