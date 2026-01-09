part of '../_index.dart';

class PulsateStrategy extends FieldStrategy {
  const PulsateStrategy();

  @override
  String get id => 'pulsate';

  @override
  FieldStrategyState createState(FieldConfig config) =>
      _PulsateState(config.w * config.h);

  @override
  FieldFrame generateFrame({
    required FieldConfig config,
    required FieldStrategyState state,
    required double t,
    required double dt,
    required BufferTransferMode transferMode,
  }) {
    final s = state as _PulsateState;
    final params = _buildTemporalParams(config, t);
    final tuning = config.tuning;

    final w = config.w;
    final h = config.h;
    final n = w * h;

    double sourceSum = 0.0;
    double bulgeSrcSum = 0.0;
    for (var y = 0; y < h; y++) {
      for (var x = 0; x < w; x++) {
        final i = y * w + x;

        final warped = _warp(x, y, config, t, params);
        s.psi[i] = _stream(config, x, y, t, warped.px, warped.py, params);
        final src = _sources(config, warped.px, warped.py, params, x, y);
        sourceSum += src.rhoSrc;
        bulgeSrcSum += src.bulgeSrc;
        s.rhoTmp[i] = src.rhoSrc;
        s.bulgeTmp[i] = src.bulgeSrc;
      }
    }

    _normalizeZeroMean(s.rhoTmp, sourceSum, n);
    _normalizeZeroMean(s.bulgeTmp, bulgeSrcSum, n);

    _psiToDivergenceFreeFlow(w, h, s.psi, s.flowX, s.flowY, tuning);

    _advectAndDissipate(
      w,
      h,
      dt,
      s.flowX,
      s.flowY,
      s.rho,
      s.rhoTmp,
      s.bulge,
      s.bulgeTmp,
      tuning.advection,
    );
    _finalizeHeightAndBulge(
      s.rho,
      s.rhoTmp,
      s.height,
      s.bulge,
      s.bulgeTmp,
      tuning.heightPower,
    );

    return buildFieldFrame(
      transferMode,
      w,
      h,
      t,
      kind: 'standard',
      channels: {
        'flowX': s.flowX,
        'flowY': s.flowY,
        'height': s.height,
        'bulge': s.bulge,
      },
    );
  }

  TemporalParams _buildTemporalParams(FieldConfig config, double t) {
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

  ({double px, double py}) _warp(
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

  double _stream(
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

  ({double rhoSrc, double bulgeSrc}) _sources(
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

class _PulsateState extends FieldStrategyState {
  _PulsateState(int n)
    : psi = Float32List(n),
      flowX = Float32List(n),
      flowY = Float32List(n),
      rho = Float32List(n),
      rhoTmp = Float32List(n),
      height = Float32List(n),
      bulge = Float32List(n),
      bulgeTmp = Float32List(n);

  final Float32List psi;
  final Float32List flowX;
  final Float32List flowY;
  final Float32List rho;
  final Float32List rhoTmp;
  final Float32List height;
  final Float32List bulge;
  final Float32List bulgeTmp;
}
