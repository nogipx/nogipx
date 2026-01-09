part of '../_index.dart';

class FireStrategy extends FieldStrategy {
  const FireStrategy();

  @override
  TemporalParams buildTemporalParams(FieldConfig config, double t) {
    final tuning = config.tuning;
    final phase = config.seed * tuning.phaseScale;
    final tzPsi = t * tuning.tzPsiSpeed * 0.55 + phase;
    final tzWarp =
        t * tuning.tzWarpSpeed * 0.42 + phase * tuning.tzWarpPhaseScale;
    final tzPhi =
        t * tuning.tzPhiSpeedNormal * 1.35 + phase * tuning.tzPhiPhaseScale;

    final slideX = t * config.speedX * tuning.slideFactorPulsate * 0.5;
    final slideY = t * (-0.65 + config.speedY * 0.25);

    final wind = tuning.wind;
    final dirX = math.sin(t * wind.pulsateDirXFreq + phase * 0.6) * 0.35;
    final dirY = -1.0 + 0.08 * math.cos(t * wind.pulsateDirYFreq + phase * 0.5);
    final windDir = normalize(dirX, dirY, fallbackX: 0.0, fallbackY: -1.0);
    final windStrength =
        1.4 +
        0.6 *
            math.sin(
              t * wind.pulsateStrengthFreq * 1.1 +
                  phase * wind.pulsateStrengthPhaseScale * 1.2,
            );

    final gust = tuning.gust;
    final gustCX =
        0.52 +
        0.18 *
            math.sin(
              t * gust.centerFreqX * 0.9 + phase * gust.centerPhaseScaleX * 0.8,
            );
    final gustCY =
        0.18 +
        0.12 *
            math.cos(
              t * gust.centerFreqY * 0.8 + phase * gust.centerPhaseScaleY * 0.7,
            );

    return TemporalParams(
      phase: phase,
      tzPsi: tzPsi,
      tzWarp: tzWarp,
      tzPhi: tzPhi,
      slideX: slideX,
      slideY: slideY,
      windDir: windDir,
      windStrength: windStrength,
      gustCX: gustCX,
      gustCY: gustCY,
      gustStrength: gust.strengthNormal * 1.4,
      warpScale: tuning.warp.scalePulsate * 0.55,
      warpAmp: tuning.warp.ampNormal * 0.55,
      driftScale: tuning.warp.driftScale * 0.6,
      baseFreqScale: 1.25,
    );
  }

  @override
  ({double px, double py}) warp(
    int x,
    int y,
    FieldConfig config,
    double t,
    TemporalParams params,
  ) => _warpCommon(x, y, config, t, params);

  @override
  double stream(
    FieldConfig config,
    int x,
    int y,
    double t,
    double px,
    double py,
    TemporalParams params,
  ) {
    final stream = config.tuning.stream;
    final u = x / config.w;
    final v = y / config.h;
    final nearBase = smooth01(1.0 - v);
    final psiUp = (u - 0.5) * params.windStrength * (1.2 + nearBase * 1.4);
    final psiCurl = fbm3(
      px * stream.psiCurlLowScaleX * 1.4,
      py * stream.psiCurlLowScaleY * 1.2,
      params.tzPsi * stream.psiCurlLowTzScale * 1.1,
      config.seed ^ 717,
    );
    final tongues = fbm3(
      px * stream.psiPulseScale * 1.8,
      py * stream.psiPulseScale * 1.35,
      t * stream.psiPulseTimeFreq * 1.15 + params.phase,
      config.seed ^ 909,
    );
    final lean = math.sin((v + t * 0.45) * 5.5 + params.phase * 0.8) * 0.18;
    return psiUp +
        psiCurl * (stream.psiCurlLowWeight * 1.25) +
        tongues * (stream.psiPulseWeight * 1.6) * (0.4 + nearBase) +
        lean;
  }

  @override
  ({double rhoSrc, double bulgeSrc}) sources(
    FieldConfig config,
    double px,
    double py,
    TemporalParams params,
    int x,
    int y,
  ) {
    final source = config.tuning.source;
    final v = y / math.max(1, config.h - 1);
    final nearBase = smooth01(1.0 - v);
    final flicker =
        fbm3(
          px * source.rhoFreqPulsate * 1.4,
          py * source.rhoFreqPulsate * 1.1,
          params.tzPhi * source.rhoTzScalePulsate * 1.35,
          config.seed ^ 0xF1A6E,
        ) -
        source.rhoCenterBias * 0.65;
    final tongues = fbm3(
      px * (source.rhoFreqNormal * 1.65 + 0.01),
      py * (source.rhoFreqNormal * 1.1 + 0.02),
      params.tzPhi * source.rhoTzScaleNormal * 1.35,
      config.seed ^ 0xFA11E,
    );
    final rhoSrc =
        (flicker * (0.75 + nearBase * 1.2) + tongues * 0.85) *
        math.pow(nearBase, 1.2);

    final bulgeSrc =
        (fbm3(
              (px + x * 0.02) * source.bulgeFreq * 1.2,
              (py + y * 0.02) * source.bulgeFreq,
              params.tzPhi * source.bulgeTzScale * 1.2 +
                  source.bulgePhaseOffset,
              config.seed ^ 0xF17E,
            ) -
            source.bulgeCenterBias * 0.4) *
        (0.5 + nearBase) *
        math.pow(nearBase, 1.3);
    return (rhoSrc: rhoSrc, bulgeSrc: bulgeSrc);
  }
}
