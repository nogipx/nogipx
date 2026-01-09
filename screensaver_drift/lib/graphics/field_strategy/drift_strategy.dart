part of '../_index.dart';

class DriftStrategy extends FieldStrategy {
  const DriftStrategy();

  @override
  String get id => 'drift';

  @override
  FieldStrategyState createState(FieldConfig config) =>
      _DriftState(config.w * config.h);

  @override
  FieldFrame generateFrame({
    required FieldConfig config,
    required FieldStrategyState state,
    required double t,
    required double dt,
    required BufferTransferMode transferMode,
  }) {
    final s = state as _DriftState;
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
        s.psi[i] = _stream(
          config,
          x,
          y,
          t,
          warped.px,
          warped.py,
          params,
        );
        final src = _sources(
          config,
          warped.px,
          warped.py,
          params,
          x,
          y,
        );
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

class _DriftState extends FieldStrategyState {
  _DriftState(int n)
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

void _normalizeZeroMean(Float32List buffer, double sum, int count) {
  final mean = sum / count;
  for (var i = 0; i < buffer.length; i++) {
    buffer[i] -= mean;
  }
}

void _advectAndDissipate(
  int w,
  int h,
  double dt,
  Float32List flowX,
  Float32List flowY,
  Float32List rho,
  Float32List rhoTmp,
  Float32List bulge,
  Float32List bulgeTmp,
  AdvectionTuning tuning,
) {
  final dissipation = tuning.dissipation;
  final invW = 1.0 / math.max(1, w - 1);
  final invH = 1.0 / math.max(1, h - 1);
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      final i = y * w + x;
      final vx = flowX[i];
      final vy = flowY[i];

      double clampCoord(double v, double max) {
        if (v < 0) return 0;
        if (v > max - 1) return max - 1;
        return v;
      }

      final backX = clampCoord(x.toDouble() - vx * dt * w, w.toDouble());
      final backY = clampCoord(y.toDouble() - vy * dt * h, h.toDouble());
      final adv = sampleBilinearClamp(
        rho,
        w,
        h,
        backX * invW,
        backY * invH,
      );
      final advB = sampleBilinearClamp(
        bulge,
        w,
        h,
        backX * invW,
        backY * invH,
      );

      var r =
          adv * dissipation +
          rhoTmp[i] * tuning.rhoSourceMix +
          tuning.rhoAmbientValue * (1 - dissipation);
      if (r < 0) r = 0;
      if (r > 1) r = 1;
      rhoTmp[i] = r;

      var b =
          advB * tuning.bulgeAdvectFactor +
          bulgeTmp[i] * tuning.bulgeSourceMix +
          tuning.bulgeAmbientValue * tuning.bulgeAmbientMix;
      if (b < 0) b = 0;
      if (b > 1) b = 1;
      bulgeTmp[i] = b;
    }
  }
}

void _finalizeHeightAndBulge(
  Float32List rho,
  Float32List rhoTmp,
  Float32List hOut,
  Float32List bulge,
  Float32List bulgeTmp,
  double heightPower,
) {
  final lut = _HeightPowLut.of(heightPower);
  for (var i = 0; i < rho.length; i++) {
    rho[i] = rhoTmp[i];
    hOut[i] = lut.sample(rho[i]);
    bulge[i] = bulgeTmp[i];
  }
}

void _psiToDivergenceFreeFlow(
  int w,
  int h,
  Float32List psi,
  Float32List flowX,
  Float32List flowY,
  FieldTuning tuning,
) {
  int ix(int x) => x.clamp(0, w - 1);
  int iy(int y) => y.clamp(0, h - 1);

  final flowAmp = tuning.flowAmp;
  final flowClamp = tuning.flowClamp;

  for (var y = 0; y < h; y++) {
    final ym = iy(y - 1);
    final yp = iy(y + 1);
    for (var x = 0; x < w; x++) {
      final xm = ix(x - 1);
      final xp = ix(x + 1);

      final c = y * w + x;
      final l = y * w + xm;
      final r = y * w + xp;
      final d = ym * w + x;
      final u = yp * w + x;

      final dpsiDx = (psi[r] - psi[l]) * 0.5;
      final dpsiDy = (psi[u] - psi[d]) * 0.5;

      var fx = dpsiDy * flowAmp;
      var fy = -dpsiDx * flowAmp;

      if (fx > flowClamp) fx = flowClamp;
      if (fx < -flowClamp) fx = -flowClamp;
      if (fy > flowClamp) fy = flowClamp;
      if (fy < -flowClamp) fy = -flowClamp;

      flowX[c] = fx;
      flowY[c] = fy;
    }
  }
}

class _HeightPowLut {
  _HeightPowLut._(this.power)
      : values = Float32List(_size) {
    for (var i = 0; i < _size; i++) {
      final x = i / (_size - 1);
      values[i] = math.pow(x, power).toDouble();
    }
  }

  static const int _size = 1024;
  final double power;
  final Float32List values;

  double sample(double x) {
    final clamped = x.clamp(0.0, 1.0);
    final idx = (clamped * (_size - 1)).round();
    return values[idx];
  }

  static final Map<int, _HeightPowLut> _cache = {};

  static _HeightPowLut of(double power) {
    final key = (power * 1000).round();
    return _cache.putIfAbsent(key, () => _HeightPowLut._(power));
  }
}
