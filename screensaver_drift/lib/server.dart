// screensaver_compute.dart
//
// Drop-in replacement for your current responder file.
// Changes vs your current version:
// - _fillPsiAndHeight now uses 3D value-noise + fbm (time is a 3rd dimension)
//   -> looks more “alive” than just scrolling x/y.
// - domain warp is also 3D.
// - psi->flow uses size-scaled central differences (flow strength stable vs grid size).
// - keeps your old 2D noise helpers (optional / debug), but main path uses 3D.
//
// Requires: dto.dart contains DriftFieldRequest / DriftFieldFrame, and rpc_dart generator parts.

import 'dart:isolate';
import 'dart:math' as math;
import 'dart:math';

import 'package:rpc_dart/rpc_dart.dart';
import 'package:screensaver_drift/dto.dart';
import 'package:uuid/uuid.dart';

part 'server.g.dart';

@RpcService(
  name: 'ScreensaverCompute',
  description: 'Контракт для вычислений анимации',
)
abstract interface class IScreensaverCompute {
  @RpcMethod.serverStream(name: 'framesStream')
  Stream<DriftFieldFrame> framesStream(
    DriftFieldRequest request, {
    RpcContext? context,
  });
}

final class ScreensaverCompute extends ScreensaverComputeResponder {
  ScreensaverCompute({super.dataTransferMode});

  String _framesStreamKey = '';

  @override
  Stream<DriftFieldFrame> framesStream(
    DriftFieldRequest request, {
    RpcContext? context,
  }) async* {
    final localStreamKey = const Uuid().v4();
    _framesStreamKey = localStreamKey;
    final w = request.w;
    final h = request.h;
    final n = w * h;

    final psi = Float32List(n);
    final flowX = Float32List(n);
    final flowY = Float32List(n);
    final height = Float32List(n);
    final rho = Float32List(n); // advected density (“breathing voids”)
    final rhoTmp = Float32List(n);

    final dt = 1.0 / max(1, request.fps);
    var t = 0.0;

    while (true) {
      if (context?.cancellationToken?.isCancelled == true) {
        return;
      }
      if (localStreamKey != _framesStreamKey) {
        return;
      }

      _fillFields(request, t, dt, psi, flowX, flowY, rho, rhoTmp, height);

      final mode = dataTransferMode ?? RpcDataTransferMode.zeroCopy;
      yield _buildFrame(mode, w, h, t, flowX, flowY, height);

      t += dt;
      await Future<void>.delayed(Duration(microseconds: (dt * 1e6).round()));
    }
  }
}

DriftFieldFrame _buildFrame(
  RpcDataTransferMode mode,
  int w,
  int h,
  double t,
  Float32List flowX,
  Float32List flowY,
  Float32List height,
) {
  Object pack(Float32List src) {
    if (mode == RpcDataTransferMode.zeroCopy) {
      return TransferableTypedData.fromList([src.buffer.asUint8List()]);
    }
    return Uint8List.fromList(src.buffer.asUint8List());
  }

  return DriftFieldFrame(
    w: w,
    h: h,
    t: t,
    flowX: pack(flowX),
    flowY: pack(flowY),
    height: pack(height),
  );
}

// -----------------------------------------------------------------------------
// Field algorithm (3D noise + 3D domain warp)
// -----------------------------------------------------------------------------

void _fillFields(
  DriftFieldRequest req,
  double t,
  double dt,
  Float32List psiOut,
  Float32List flowX,
  Float32List flowY,
  Float32List rho,
  Float32List rhoTmp,
  Float32List hOut,
) {
  final w = req.w;
  final h = req.h;

  // Divergence-free поток: глобальное “ветровое” направление + curl-noise.
  final phase = req.seed * 0.011;
  final tzPsi = t * 0.30 + phase;
  final tzWarp = t * 0.18 + phase * 1.3;
  final tzPhi = t * 0.08 + phase * 0.7; // breathing potential (very low freq)
  final slideX = t * req.speedX * 0.6;
  final slideY = t * req.speedY * 0.6;
  final windDir = _normalize(
    req.speedX + math.sin(t * 0.17) * 0.4,
    req.speedY + math.cos(t * 0.13) * 0.4,
    fallbackX: 0.8,
    fallbackY: -0.6,
  );
  final windStrength = 1.15;

  double sourceSum = 0.0;
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      final i = y * w + x;

      final fx = x.toDouble();
      final fy = y.toDouble();

      // 3D domain warp (слабый, чтобы избежать сеточных артефактов).
      final wx = _fbm3(
        (fx + slideX) * req.warpFreq * 0.12,
        (fy + slideY) * req.warpFreq * 0.12,
        tzWarp,
        req.seed ^ 0xA341316C,
      );
      final wy = _fbm3(
        (fx + 37.0 + slideX) * req.warpFreq * 0.12,
        (fy - 11.0 + slideY) * req.warpFreq * 0.12,
        tzWarp + 11.0,
        req.seed ^ 0xC8013EA4,
      );

      final dx = (wx - 0.5) * req.warpAmp * 0.32;
      final dy = (wy - 0.5) * req.warpAmp * 0.32;

      // Глобальный drift по скорости.
      final driftX = t * req.speedX * 0.35;
      final driftY = t * req.speedY * 0.35;

      // Добавляем общий сдвиг по времени, чтобы поле не «замирало».
      final px = (fx + dx + driftX + t * 0.22) * req.baseFreq;
      final py = (fy + dy + driftY + t * 0.27) * req.baseFreq;

      // Поток: линейный ветер (curl от линейной фазы) + curl noise.
      final psiLinear = windStrength * (windDir.x * fy - windDir.y * fx);
      final psiCurlLow = _fbm3(px * 0.7, py * 0.6, tzPsi * 0.8, req.seed ^ 17);
      final psiCurlHi = _fbm3(px * 1.6, py * 1.3, tzPsi * 1.4 + 9.1, req.seed ^ 911);
      final psi = psiLinear +
          psiCurlLow * 0.40 +
          psiCurlHi * (0.22 + 0.08 * math.sin(t * 0.37));

      // Маленькая grad-компонента (compressible) из phi — для “дыхания”.
      psiOut[i] = psi;

      // Source/stoke for density (zero-mean breathing).
      final src = _fbm3(px * 0.35, py * 0.35, tzPhi * 1.3, req.seed ^ 0xDEADBEEF) - 0.5;
      sourceSum += src;
      rhoTmp[i] = src;
    }
  }

  // normalize source to zero-mean
  final meanSrc = sourceSum / (w * h);
  for (var i = 0; i < rhoTmp.length; i++) {
    rhoTmp[i] = rhoTmp[i] - meanSrc;
  }

  // вычисляем divergence-free поток из psi
  _psiToDivergenceFreeFlow(w, h, psiOut, flowX, flowY);

  // advection + dissipation + source
  const dissipation = 0.99;
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      final i = y * w + x;
      final vx = flowX[i];
      final vy = flowY[i];

      final backX = (x.toDouble() - vx * dt * w).clamp(0.0, w - 1.0);
      final backY = (y.toDouble() - vy * dt * h).clamp(0.0, h - 1.0);
      final adv = _sampleBilinear(rho, w, h, backX / (w - 1), backY / (h - 1));

      var r = adv * dissipation + rhoTmp[i] * 0.18 + 0.5 * (1 - dissipation);
      if (r < 0) r = 0;
      if (r > 1) r = 1;
      rhoTmp[i] = r;
    }
  }

  // swap rho buffers and use as height
  for (var i = 0; i < rho.length; i++) {
    rho[i] = rhoTmp[i];
    hOut[i] = math.pow(rho[i], 1.2).toDouble();
  }
}

void _psiToDivergenceFreeFlow(
  int w,
  int h,
  Float32List psi,
  Float32List flowX,
  Float32List flowY,
) {
  int ix(int x) => (x < 0)
      ? x + w
      : (x >= w)
      ? x - w
      : x;
  int iy(int y) => (y < 0)
      ? y + h
      : (y >= h)
      ? y - h
      : y;

  const flowAmp = 1.6; // мягче, но без статики
  const flowClamp = .48; // защита от выбросов

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

// -----------------------------------------------------------------------------
// 3D value-noise + fbm
// -----------------------------------------------------------------------------

double _fbm3(double x, double y, double z, int seed) {
  var amp = 0.5;
  var freq = 1.0;
  var sum = 0.0;
  var norm = 0.0;
  for (var o = 0; o < 5; o++) {
    sum += amp * _valueNoise3(x * freq, y * freq, z * freq, seed + o * 1013);
    norm += amp;
    amp *= 0.5;
    freq *= 2.0;
  }
  return sum / max(1e-9, norm);
}

double _valueNoise3(double x, double y, double z, int seed) {
  final x0 = x.floor();
  final y0 = y.floor();
  final z0 = z.floor();
  final x1 = x0 + 1;
  final y1 = y0 + 1;
  final z1 = z0 + 1;

  final tx = x - x0;
  final ty = y - y0;
  final tz = z - z0;

  final u = _fade(tx);
  final v = _fade(ty);
  final w = _fade(tz);

  double h(int xi, int yi, int zi) => _hash01_3(xi, yi, zi, seed);

  final c000 = h(x0, y0, z0);
  final c100 = h(x1, y0, z0);
  final c010 = h(x0, y1, z0);
  final c110 = h(x1, y1, z0);

  final c001 = h(x0, y0, z1);
  final c101 = h(x1, y0, z1);
  final c011 = h(x0, y1, z1);
  final c111 = h(x1, y1, z1);

  final x00 = c000 + (c100 - c000) * u;
  final x10 = c010 + (c110 - c010) * u;
  final x01 = c001 + (c101 - c001) * u;
  final x11 = c011 + (c111 - c011) * u;

  final y0v = x00 + (x10 - x00) * v;
  final y1v = x01 + (x11 - x01) * v;

  return y0v + (y1v - y0v) * w;
}

double _hash01_3(int x, int y, int z, int seed) {
  var h = x * 374761393 ^ y * 668265263 ^ z * 2147483647 ^ seed * 0x27d4eb2d;
  h = (h ^ (h >> 13)) * 1274126177;
  h ^= (h >> 16);
  return (h & 0x7fffffff) / 0x7fffffff;
}

double _fade(double t) => t * t * (3.0 - 2.0 * t); // smoothstep

double _smooth01(double v) {
  final x = v.clamp(0.0, 1.0);
  return x * x * (3.0 - 2.0 * x);
}

double _sampleBilinear(
  Float32List g,
  int w,
  int h,
  double u,
  double v,
) {
  u = u.clamp(0.0, 1.0);
  v = v.clamp(0.0, 1.0);

  final x = u * (w - 1);
  final y = v * (h - 1);

  final x0 = x.floor();
  final y0 = y.floor();
  final x1 = (x0 + 1).clamp(0, w - 1);
  final y1 = (y0 + 1).clamp(0, h - 1);

  final tx = x - x0;
  final ty = y - y0;

  final i00 = y0 * w + x0;
  final i10 = y0 * w + x1;
  final i01 = y1 * w + x0;
  final i11 = y1 * w + x1;

  final a = g[i00];
  final b = g[i10];
  final c = g[i01];
  final d = g[i11];

  final ab = a + (b - a) * tx;
  final cd = c + (d - c) * tx;
  return ab + (cd - ab) * ty;
}

double _windPotential(double x, double y, double strength) {
  final r2 = x * x + y * y + 1e-4;
  final falloff = math.exp(-r2 * 1.8);
  final ang = math.atan2(y, x);
  return strength * falloff * ang;
}

({double x, double y}) _normalize(double x, double y,
    {double fallbackX = 1.0, double fallbackY = 0.0}) {
  final len2 = x * x + y * y;
  if (len2 < 1e-6) {
    final inv = 1.0 / math.sqrt(fallbackX * fallbackX + fallbackY * fallbackY);
    return (x: fallbackX * inv, y: fallbackY * inv);
  }
  final inv = 1.0 / math.sqrt(len2);
  return (x: x * inv, y: y * inv);
}
