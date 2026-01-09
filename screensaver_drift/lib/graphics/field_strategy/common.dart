part of '../_index.dart';

/// Стандартное состояние для стратегий, работающих с flow/height/bulge.
class StandardFieldState extends FieldStrategyState {
  StandardFieldState(int n)
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

/// Базовая стратегия для “стандартных” полей: работает с flow/height/bulge.
abstract class StandardFieldStrategy extends FieldStrategy {
  const StandardFieldStrategy();

  @override
  FieldStrategyState createState(FieldConfig config) =>
      StandardFieldState(config.w * config.h);

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

  @override
  FieldFrame generateFrame({
    required FieldConfig config,
    required FieldStrategyState state,
    required double t,
    required double dt,
    required BufferTransferMode transferMode,
  }) {
    final s = state as StandardFieldState;
    _simulateStandard(
      config,
      t,
      dt,
      s,
      this,
    );

    return buildFieldFrame(
      transferMode,
      config.w,
      config.h,
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
}

void _simulateStandard(
  FieldConfig config,
  double t,
  double dt,
  StandardFieldState state,
  StandardFieldStrategy strategy,
) {
  final params = strategy.buildTemporalParams(config, t);
  final tuning = config.tuning;

  final w = config.w;
  final h = config.h;
  final n = w * h;

  double sourceSum = 0.0;
  double bulgeSrcSum = 0.0;
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      final i = y * w + x;

      final warped = strategy.warp(x, y, config, t, params);
      state.psi[i] = strategy.stream(
        config,
        x,
        y,
        t,
        warped.px,
        warped.py,
        params,
      );
      final src = strategy.sources(
        config,
        warped.px,
        warped.py,
        params,
        x,
        y,
      );
      sourceSum += src.rhoSrc;
      bulgeSrcSum += src.bulgeSrc;
      state.rhoTmp[i] = src.rhoSrc;
      state.bulgeTmp[i] = src.bulgeSrc;
    }
  }

  _normalizeZeroMean(state.rhoTmp, sourceSum, n);
  _normalizeZeroMean(state.bulgeTmp, bulgeSrcSum, n);

  _psiToDivergenceFreeFlow(w, h, state.psi, state.flowX, state.flowY, tuning);

  _advectAndDissipate(
    w,
    h,
    dt,
    state.flowX,
    state.flowY,
    state.rho,
    state.rhoTmp,
    state.bulge,
    state.bulgeTmp,
    tuning.advection,
  );
  _finalizeHeightAndBulge(
    state.rho,
    state.rhoTmp,
    state.height,
    state.bulge,
    state.bulgeTmp,
    tuning.heightPower,
  );
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
        backX / (w - 1),
        backY / (h - 1),
      );
      final advB = sampleBilinearClamp(
        bulge,
        w,
        h,
        backX / (w - 1),
        backY / (h - 1),
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
  for (var i = 0; i < rho.length; i++) {
    rho[i] = rhoTmp[i];
    hOut[i] = math.pow(rho[i], heightPower).toDouble();
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
