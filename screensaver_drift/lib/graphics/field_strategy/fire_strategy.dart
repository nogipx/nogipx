part of '../_index.dart';

class FireFieldState extends FieldStrategyState {
  FireFieldState(int n, this.w, this.h)
    : vx = Float32List(n),
      vy = Float32List(n),
      vxTmp = Float32List(n),
      vyTmp = Float32List(n),
      temp = Float32List(n),
      tempTmp = Float32List(n),
      fuel = Float32List(n),
      fuelTmp = Float32List(n),
      channels = <String, Float32List>{} {
    channels.addAll({
      'flowX': vx,
      'flowY': vy,
      'height': temp,
      'bulge': fuel,
    });
  }

  final int w;
  final int h;
  final Float32List vx;
  final Float32List vy;
  final Float32List vxTmp;
  final Float32List vyTmp;
  final Float32List temp;
  final Float32List tempTmp;
  final Float32List fuel;
  final Float32List fuelTmp;
  final Map<String, Float32List> channels;
}

class FireStrategy extends FieldStrategy {
  const FireStrategy();

  @override
  String get id => 'fire';

  double _param(
    Map<String, dynamic>? p,
    String key,
    double def, {
    double min = double.negativeInfinity,
    double max = double.infinity,
  }) {
    final v = p?[key];
    if (v is num) {
      final d = v.toDouble();
      return d.clamp(min, max);
    }
    return def;
  }

  @override
  FieldStrategyState createState(FieldConfig config) {
    return FireFieldState(config.w * config.h, config.w, config.h);
  }

  @override
  FieldFrame generateFrame({
    required FieldConfig config,
    required FieldStrategyState state,
    required double t,
    required double dt,
    required BufferTransferMode transferMode,
  }) {
    final s = state as FireFieldState;
    final params = config.strategyParams;

    final buoyancy = _param(params, 'buoyancy', 2.3, min: 0.1, max: 5.0);
    final cooling = _param(params, 'cooling', 0.65, min: 0.0, max: 2.0);
    final fuelRate = _param(params, 'fuelRate', 2.0, min: 0.0, max: 5.0);
    final fuelJitter = _param(params, 'fuelJitter', 0.25, min: 0.0, max: 1.0);
    final vDamp = _param(params, 'damping', 0.05, min: 0.0, max: 1.0);
    final maxSpeed = _param(params, 'maxSpeed', 2.2, min: 0.5, max: 6.0);
    final twistStrength = _param(params, 'twist', 0.65, min: 0.0, max: 2.0);
    final twistScale = _param(params, 'twistScale', 1.1, min: 0.3, max: 3.0);
    final twistFreq = _param(params, 'twistFreq', 0.9, min: 0.1, max: 3.0);
    final fuelBand = _param(params, 'fuelBand', 0.14, min: 0.02, max: 0.4);
    final fuelSpread = _param(params, 'fuelSpread', 2.2, min: 0.5, max: 4.0);

    _injectFuelAndHeat(
      s,
      fuelRate,
      fuelJitter,
      dt,
      config.seed,
      bandNormHeight: fuelBand,
      spread: fuelSpread,
    );
    _advectVelocity(s, dt);
    _applyBuoyancy(s, buoyancy, dt, maxSpeed);
    _addTwist(
      s,
      t,
      twistStrength,
      twistScale,
      twistFreq,
      maxSpeed,
      config.seed,
    );
    _dampenVelocity(s, vDamp);
    _advectScalar(s, s.temp, s.tempTmp, dt);
    _advectScalar(s, s.fuel, s.fuelTmp, dt);
    _cool(s, cooling, dt);
    _normalizeToHeight(s.temp, s.fuel);

    final flowClamp = 3.0;
    _clampField(s.vx, -flowClamp, flowClamp);
    _clampField(s.vy, -flowClamp, flowClamp);

    return buildFieldFrame(
      transferMode,
      s.w,
      s.h,
      t,
      kind: 'standard',
      channels: s.channels,
      meta: _fireMeta,
    );
  }

  static const Map<String, String> _fireMeta = {'kind': 'fire'};

  void _injectFuelAndHeat(
    FireFieldState s,
    double rate,
    double jitter,
    double dt,
    int seed, {
    double bandNormHeight = 0.12,
    double spread = 2.2,
  }) {
    final w = s.w;
    final h = s.h;
    final band = math.max(2, (h * bandNormHeight).round());
    final invW = 1.0 / math.max(1, w - 1);
    for (var y = 0; y < band; y++) {
      final v = y / math.max(1, band - 1);
      for (var x = 0; x < w; x++) {
        final i = y * w + x;
        final u = x * invW;
        final jitterVal = hash01_3(x, y, 0, seed ^ 0xFACE) * 2 - 1;
        final profile = smooth01(1.0 - (u - 0.5).abs() * spread);
        final fuelAdd =
            rate * dt * (0.6 + profile * 0.8 + jitterVal * jitter * 0.4);
        s.fuel[i] = (s.fuel[i] + fuelAdd).clamp(0.0, 10.0);
        s.temp[i] = (s.temp[i] + fuelAdd * (0.7 + 0.3 * (1 - v))).clamp(
          0.0,
          10.0,
        );
      }
    }
  }

  void _advectVelocity(FireFieldState s, double dt) {
    final w = s.w;
    final h = s.h;
    final invW = 1.0 / math.max(1, w - 1);
    final invH = 1.0 / math.max(1, h - 1);
    final maxX = w - 1.0;
    final maxY = h - 1.0;
    for (var y = 0; y < h; y++) {
      for (var x = 0; x < w; x++) {
        final i = y * w + x;
        final vx = s.vx[i];
        final vy = s.vy[i];

        var backX = x.toDouble() - vx * dt * w;
        if (backX < 0) {
          backX = 0;
        } else if (backX > maxX) {
          backX = maxX;
        }
        var backY = y.toDouble() - vy * dt * h;
        if (backY < 0) {
          backY = 0;
        } else if (backY > maxY) {
          backY = maxY;
        }
        final u = backX * invW;
        final v = backY * invH;

        s.vxTmp[i] = sampleBilinearClamp(s.vx, w, h, u, v);
        s.vyTmp[i] = sampleBilinearClamp(s.vy, w, h, u, v);
      }
    }
    s.vx.setAll(0, s.vxTmp);
    s.vy.setAll(0, s.vyTmp);
  }

  void _advectScalar(
    FireFieldState s,
    Float32List field,
    Float32List tmp,
    double dt,
  ) {
    final w = s.w;
    final h = s.h;
    final invW = 1.0 / math.max(1, w - 1);
    final invH = 1.0 / math.max(1, h - 1);
    final maxX = w - 1.0;
    final maxY = h - 1.0;
    for (var y = 0; y < h; y++) {
      for (var x = 0; x < w; x++) {
        final i = y * w + x;
        final vx = s.vx[i];
        final vy = s.vy[i];

        var backX = x.toDouble() - vx * dt * w;
        if (backX < 0) {
          backX = 0;
        } else if (backX > maxX) {
          backX = maxX;
        }
        var backY = y.toDouble() - vy * dt * h;
        if (backY < 0) {
          backY = 0;
        } else if (backY > maxY) {
          backY = maxY;
        }
        final u = backX * invW;
        final v = backY * invH;

        tmp[i] = sampleBilinearClamp(field, w, h, u, v);
      }
    }
    field.setAll(0, tmp);
  }

  void _applyBuoyancy(
    FireFieldState s,
    double buoyancy,
    double dt,
    double maxSpeed,
  ) {
    final w = s.w;
    final h = s.h;
    for (var i = 0; i < s.temp.length; i++) {
      final tNorm = s.temp[i];
      // Координата y растёт вниз, поэтому для подъёма используем отрицательное направление.
      s.vy[i] = (s.vy[i] - buoyancy * tNorm * dt).clamp(-maxSpeed, maxSpeed);
    }
    _projectVelocity(s, dt);
  }

  void _addTwist(
    FireFieldState s,
    double t,
    double strength,
    double scale,
    double freq,
    double maxSpeed,
    int seed,
  ) {
    if (strength <= 0) return;
    final w = s.w;
    final h = s.h;
    final invW = 1.0 / math.max(1, w - 1);
    final invH = 1.0 / math.max(1, h - 1);
    for (var y = 0; y < h; y++) {
      final v = y * invH;
      final swirl =
          fbm3(0.5 * scale, v * scale, t * freq + seed * 0.01, seed ^ 0xF00F) *
          (1.0 - v) *
          strength;
      for (var x = 0; x < w; x++) {
        final i = y * w + x;
        s.vx[i] = (s.vx[i] + swirl * (0.6 + math.sin(t * 0.5 + v * 8.0) * 0.4))
            .clamp(-maxSpeed, maxSpeed);
      }
    }
    _projectVelocity(s, 0);
  }

  void _projectVelocity(FireFieldState s, double dt) {
    final w = s.w;
    final h = s.h;
    for (var y = 1; y < h - 1; y++) {
      for (var x = 1; x < w - 1; x++) {
        final i = y * w + x;
        final vx = (s.vx[i - 1] + s.vx[i + 1]) * 0.5;
        final vy = (s.vy[i - w] + s.vy[i + w]) * 0.5;
        s.vxTmp[i] = vx;
        s.vyTmp[i] = vy;
      }
    }
    for (var i = 0; i < s.vx.length; i++) {
      s.vx[i] = s.vxTmp[i].clamp(-5.0, 5.0);
      s.vy[i] = s.vyTmp[i].clamp(-5.0, 5.0);
    }
  }

  void _dampenVelocity(FireFieldState s, double damping) {
    final factor = (1.0 - damping).clamp(0.0, 1.0);
    for (var i = 0; i < s.vx.length; i++) {
      s.vx[i] *= factor;
      s.vy[i] *= factor;
    }
  }

  void _cool(FireFieldState s, double cooling, double dt) {
    final decay = (1.0 - cooling * dt).clamp(0.0, 1.0);
    for (var i = 0; i < s.temp.length; i++) {
      s.temp[i] *= decay;
      s.fuel[i] *= decay * 0.97;
    }
  }

  void _normalizeToHeight(Float32List temp, Float32List fuel) {
    double maxT = 1e-6;
    double maxF = 1e-6;
    for (var i = 0; i < temp.length; i++) {
      if (temp[i] > maxT) maxT = temp[i];
      if (fuel[i] > maxF) maxF = fuel[i];
    }
    final invT = 1.0 / maxT;
    final invF = 1.0 / maxF;
    for (var i = 0; i < temp.length; i++) {
      temp[i] = (temp[i] * invT).clamp(0.0, 1.0);
      fuel[i] = (fuel[i] * invF).clamp(0.0, 1.0);
    }
  }

  void _clampField(Float32List f, double min, double max) {
    for (var i = 0; i < f.length; i++) {
      if (f[i] < min) {
        f[i] = min;
      } else if (f[i] > max) {
        f[i] = max;
      }
    }
  }
}
