part of '../_index.dart';

class PulsateStrategy extends StandardFieldStrategy {
  const PulsateStrategy();

  @override
  String get id => 'pulsate';

  @override
  TemporalParams buildTemporalParams(FieldConfig config, double t) {
    final tuning = config.tuning;
    final phase = config.seed * tuning.phaseScale;
    final tzPsi = t * tuning.tzPsiSpeed + phase;
    final tzWarp = t * tuning.tzWarpSpeed + phase * tuning.tzWarpPhaseScale;
    final tzPhi = t * tuning.tzPhiSpeedPulsate + phase * tuning.tzPhiPhaseScale;

    final slideX = t * config.speedX * tuning.slideFactorPulsate;
    final slideY = t * config.speedY * tuning.slideFactorPulsate;

    final wind = tuning.wind;
    final dirX = math.cos(t * wind.pulsateDirXFreq + phase);
    final dirY = math.sin(
      t * wind.pulsateDirYFreq + phase * wind.pulsateDirYPhaseScale,
    );
    final windDir = normalize(
      dirX,
      dirY,
      fallbackX: wind.windDirFallbackX,
      fallbackY: wind.windDirFallbackY,
    );
    final windStrength =
        wind.pulsateStrengthBase +
        wind.pulsateStrengthAmp *
            math.sin(
              t * wind.pulsateStrengthFreq +
                  phase * wind.pulsateStrengthPhaseScale,
            );

    final gust = tuning.gust;

    return TemporalParams(
      phase: phase,
      tzPsi: tzPsi,
      tzWarp: tzWarp,
      tzPhi: tzPhi,
      slideX: slideX,
      slideY: slideY,
      windDir: windDir,
      windStrength: windStrength,
      gustCX: gust.centerBase,
      gustCY: gust.centerBase,
      gustStrength: gust.strengthPulsate,
      warpScale: tuning.warp.scalePulsate,
      warpAmp: tuning.warp.ampPulsate,
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
    final psiCurl = fbm3(
      px * stream.psiCurlScalePulsate,
      py * stream.psiCurlScalePulsate,
      params.tzPsi,
      config.seed ^ 101,
    );
    final psiPulse = fbm3(
      px * stream.psiPulseScale,
      py * stream.psiPulseScale,
      t * stream.psiPulseTimeFreq + params.phase,
      config.seed ^ 202,
    );
    return psiCurl * stream.psiCurlWeightPulsate +
        psiPulse *
            stream.psiPulseWeight *
            (1.0 +
                stream.psiPulseModAmp *
                    math.sin(
                      t * stream.psiPulseModFreq +
                          params.phase * stream.psiPulsePhaseScale,
                    ));
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
        (fbm3(
              px * source.rhoFreqPulsate,
              py * source.rhoFreqPulsate,
              params.tzPhi * source.rhoTzScalePulsate,
              config.seed ^ 0xDEADBEEF,
            ) -
            source.rhoCenterBias) *
        source.rhoPulsateGain;

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
