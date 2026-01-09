part of '../_index.dart';

class DriftStrategy extends StandardFieldStrategy {
  const DriftStrategy();

  @override
  String get id => 'drift';

  @override
  TemporalParams buildTemporalParams(FieldConfig config, double t) {
    final tuning = config.tuning;
    final phase = config.seed * tuning.phaseScale;
    final tzPsi = t * tuning.tzPsiSpeed + phase;
    final tzWarp = t * tuning.tzWarpSpeed + phase * tuning.tzWarpPhaseScale;
    final tzPhi = t * tuning.tzPhiSpeedNormal + phase * tuning.tzPhiPhaseScale;

    final slideX = t * config.speedX * tuning.slideFactorNormal;
    final slideY = t * config.speedY * tuning.slideFactorNormal;

    final wind = tuning.wind;
    final dirX =
        math.cos(t * wind.normalDirXFreqA + phase) +
        wind.normalDirXWeightB *
            math.sin(
              t * wind.normalDirXFreqB + phase * wind.normalDirXPhaseScaleB,
            );
    final dirY =
        math.sin(
          t * wind.normalDirYFreqA + phase * wind.normalDirYPhaseScaleB,
        ) +
        wind.normalDirYWeightB *
            math.cos(
              t * wind.normalDirYFreqB + phase * wind.normalDirYPhaseScaleB,
            );
    final windDir = normalize(
      dirX,
      dirY,
      fallbackX: wind.windDirFallbackX,
      fallbackY: wind.windDirFallbackY,
    );
    final windStrength =
        wind.normalStrengthBase +
        wind.normalStrengthAmp *
            math.sin(
              t * wind.normalStrengthFreq +
                  phase * wind.normalStrengthPhaseScale,
            );

    final gust = tuning.gust;
    final gustCX =
        gust.centerBase +
        gust.centerAmp *
            math.sin(t * gust.centerFreqX + phase * gust.centerPhaseScaleX);
    final gustCY =
        gust.centerBase +
        gust.centerAmp *
            math.cos(t * gust.centerFreqY + phase * gust.centerPhaseScaleY);

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
      gustStrength: gust.strengthNormal,
      warpScale: tuning.warp.scaleNormal,
      warpAmp: tuning.warp.ampNormal,
      driftScale: tuning.warp.driftScale,
      baseFreqScale: 1.0,
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
    final psiLinear =
        params.windStrength * (params.windDir.x * y - params.windDir.y * x);
    final psiCurlLow = fbm3(
      px * stream.psiCurlLowScaleX,
      py * stream.psiCurlLowScaleY,
      params.tzPsi * stream.psiCurlLowTzScale,
      config.seed ^ 17,
    );
    final psiCurlHi = fbm3(
      px * stream.psiCurlHiScaleX,
      py * stream.psiCurlHiScaleY,
      params.tzPsi * stream.psiCurlHiTzScale + stream.psiCurlHiPhaseOffset,
      config.seed ^ 911,
    );
    final gx = ((x / config.w) - params.gustCX) * stream.gustExtentScale;
    final gy = ((y / config.h) - params.gustCY) * stream.gustExtentScale;
    final psiGust = windPotential(gx, gy, params.gustStrength);
    return psiLinear +
        psiCurlLow * stream.psiCurlLowWeight +
        psiCurlHi *
            (stream.psiCurlHiBase +
                stream.psiCurlHiModAmp *
                    math.sin(t * stream.psiCurlHiModFreq)) +
        psiGust * stream.psiGustWeight;
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
    final rhoSrc =
        fbm3(
          px * source.rhoFreqNormal,
          py * source.rhoFreqNormal,
          params.tzPhi * source.rhoTzScaleNormal,
          config.seed ^ 0xDEADBEEF,
        ) -
        source.rhoCenterBias;

    final bulgeSrc =
        fbm3(
          px * source.bulgeFreq,
          py * source.bulgeFreq,
          params.tzPhi * source.bulgeTzScale + source.bulgePhaseOffset,
          config.seed ^ 0x12345,
        ) -
        source.bulgeCenterBias;
    return (rhoSrc: rhoSrc, bulgeSrc: bulgeSrc);
  }
}
