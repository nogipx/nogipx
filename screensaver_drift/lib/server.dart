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
    final bulge = Float32List(n);
    final bulgeTmp = Float32List(n);

    final dt = 1.0 / max(1, request.fps);
    var t = 0.0;

    while (true) {
      if (context?.cancellationToken?.isCancelled == true) {
        return;
      }
      if (localStreamKey != _framesStreamKey) {
        return;
      }

      _fillFields(
        request,
        t,
        dt,
        psi,
        flowX,
        flowY,
        rho,
        rhoTmp,
        height,
        bulge,
        bulgeTmp,
      );

      final mode = dataTransferMode;
      yield _buildFrame(mode, w, h, t, flowX, flowY, height, bulge);

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
  Float32List bulge,
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
    bulge: pack(bulge),
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
  Float32List bulge,
  Float32List bulgeTmp,
) {
  final w = req.w;
  final h = req.h;
  final n = w * h;

  final phase = req.seed * 0.011;
  final tzPsi = t * 0.30 + phase;
  final tzWarp = t * 0.18 + phase * 1.3;
  final tzPhi = t * (req.pattern == 1 ? 0.25 : 0.08) + phase * 0.7;
  final isPulsate = req.pattern == 1;

  final slideX = t * req.speedX * (isPulsate ? 0.20 : 0.75);
  final slideY = t * req.speedY * (isPulsate ? 0.20 : 0.75);
  // Более быстрый и хаотичный ветер или мягкие пульсации.
  final dirX = isPulsate
      ? math.cos(t * 0.15 + phase)
      : math.cos(t * 0.32 + phase) + 0.55 * math.sin(t * 0.72 + phase * 1.4);
  final dirY = isPulsate
      ? math.sin(t * 0.17 + phase * 0.8)
      : math.sin(t * 0.29 + phase * 0.8) + 0.55 * math.cos(t * 0.63 + phase * 1.2);
  final windDir = _normalize(dirX, dirY, fallbackX: 0.8, fallbackY: -0.6);
  final windStrength = isPulsate
      ? (0.35 + 0.55 * math.sin(t * 0.9 + phase * 0.8))
      : (1.05 + 0.4 * math.sin(t * 0.52 + phase * 0.9));
  // Движущийся порыв: выключен в пульс режиме.
  final gustCX = isPulsate ? 0.5 : 0.5 + 0.40 * math.sin(t * 0.55 + phase * 2.1);
  final gustCY = isPulsate ? 0.5 : 0.5 + 0.40 * math.cos(t * 0.50 + phase * 1.9);
  final gustStrength = isPulsate ? 0.0 : 0.9;

  double sourceSum = 0.0;
  double bulgeSrcSum = 0.0;
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      final i = y * w + x;

      final fx = x.toDouble();
      final fy = y.toDouble();

      // 3D domain warp (слабый, чтобы избежать сеточных артефактов).
      final warpScale = isPulsate ? 0.06 : 0.12;
      final wx = _fbm3(
        (fx + slideX) * req.warpFreq * warpScale,
        (fy + slideY) * req.warpFreq * warpScale,
        tzWarp,
        req.seed ^ 0xA341316C,
      );
      final wy = _fbm3(
        (fx + 37.0 + slideX) * req.warpFreq * warpScale,
        (fy - 11.0 + slideY) * req.warpFreq * warpScale,
        tzWarp + 11.0,
        req.seed ^ 0xC8013EA4,
      );

      final dx = (wx - 0.5) * req.warpAmp * (isPulsate ? 0.20 : 0.32);
      final dy = (wy - 0.5) * req.warpAmp * (isPulsate ? 0.20 : 0.32);

      // Глобальный drift по скорости.
      final driftX = t * req.speedX * 0.35;
      final driftY = t * req.speedY * 0.35;

      // Добавляем общий сдвиг по времени, чтобы поле не «замирало».
      final px = (fx + dx + driftX + t * 0.22) * req.baseFreq;
      final py = (fy + dy + driftY + t * 0.27) * req.baseFreq;

      // Поток: либо хаотичный ветер, либо мягкая пульсация.
      if (!isPulsate) {
        final psiLinear = windStrength * (windDir.x * fy - windDir.y * fx);
        final psiCurlLow =
            _fbm3(px * 0.7, py * 0.6, tzPsi * 0.8, req.seed ^ 17);
        final psiCurlHi = _fbm3(
          px * 1.6,
          py * 1.3,
          tzPsi * 1.4 + 9.1,
          req.seed ^ 911,
        );
        final gx = ((x / w) - gustCX) * 2.0;
        final gy = ((y / h) - gustCY) * 2.0;
        final psiGust = _windPotential(gx, gy, gustStrength);
        psiOut[i] = psiLinear +
            psiCurlLow * 0.40 +
            psiCurlHi * (0.22 + 0.14 * math.sin(t * 0.61)) +
            psiGust * 0.65;
      } else {
        final psiCurl = _fbm3(px * 0.9, py * 0.9, tzPsi, req.seed ^ 101);
        final psiPulse =
            _fbm3(px * 0.4, py * 0.4, t * 0.35 + phase, req.seed ^ 202);
        psiOut[i] = psiCurl * 0.65 +
            psiPulse * 0.35 * (1.0 + 1.2 * math.sin(t * 0.85 + phase * 0.7));
      }

      // Source/stoke for density (zero-mean breathing).
      final src = isPulsate
          ? (_fbm3(px * 0.2, py * 0.2, tzPhi * 1.0, req.seed ^ 0xDEADBEEF) -
                  0.5) *
              1.5
          : _fbm3(px * 0.35, py * 0.35, tzPhi * 1.3, req.seed ^ 0xDEADBEEF) -
              0.5;
      sourceSum += src;
      rhoTmp[i] = src;

      // Независимое “bulge” поле для длины волосков (равномерное, пузырящееся).
      final bsrc =
          _fbm3(px * 0.12, py * 0.12, tzPhi * 1.1 + 13.7, req.seed ^ 0x12345) -
          0.5;
      bulgeSrcSum += bsrc;
      bulgeTmp[i] = bsrc;
    }
  }

  // normalize source to zero-mean
  final meanSrc = sourceSum / (w * h);
  for (var i = 0; i < rhoTmp.length; i++) {
    rhoTmp[i] = rhoTmp[i] - meanSrc;
  }
  // normalize bulge source to zero-mean too
  final meanB = bulgeSrcSum / (w * h);
  for (var i = 0; i < bulgeTmp.length; i++) {
    bulgeTmp[i] = bulgeTmp[i] - meanB;
  }

  // вычисляем divergence-free поток из psi (даже в пульсациях для наклона)
  _psiToDivergenceFreeFlow(w, h, psiOut, flowX, flowY);

  // advection + dissipation + source
  const dissipation = 0.99;
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
      final adv = _sampleBilinearClamp(rho, w, h, backX / (w - 1), backY / (h - 1));
      final advB = _sampleBilinearClamp(bulge, w, h, backX / (w - 1), backY / (h - 1));

      var r = adv * dissipation + rhoTmp[i] * 0.18 + 0.5 * (1 - dissipation);
      if (r < 0) r = 0;
      if (r > 1) r = 1;
      rhoTmp[i] = r;

      var b = advB * 0.92 + bulgeTmp[i] * 0.60 + 0.5 * 0.08;
      if (b < 0) b = 0;
      if (b > 1) b = 1;
      bulgeTmp[i] = b;
    }
  }

  // swap rho buffers and use as height
  for (var i = 0; i < rho.length; i++) {
    rho[i] = rhoTmp[i];
    hOut[i] = math.pow(rho[i], 1.2).toDouble();
    bulge[i] = bulgeTmp[i];
  }
}

void _psiToDivergenceFreeFlow(
  int w,
  int h,
  Float32List psi,
  Float32List flowX,
  Float32List flowY,
) {
  int ix(int x) => x.clamp(0, w - 1);
  int iy(int y) => y.clamp(0, h - 1);

  const flowAmp = 2.0; // ещё живее
  const flowClamp = .55; // защита от выбросов

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

double _sampleBilinearClamp(Float32List g, int w, int h, double u, double v) {
  // u,v in [0,1], clamp at borders to avoid seams
  u = u.clamp(0.0, 1.0);
  v = v.clamp(0.0, 1.0);

  final x = u * (w - 1);
  final y = v * (h - 1);

  final x0 = x.floor().clamp(0, w - 1);
  final y0 = y.floor().clamp(0, h - 1);
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

({double x, double y}) _normalize(
  double x,
  double y, {
  double fallbackX = 1.0,
  double fallbackY = 0.0,
}) {
  final len2 = x * x + y * y;
  if (len2 < 1e-6) {
    final inv = 1.0 / math.sqrt(fallbackX * fallbackX + fallbackY * fallbackY);
    return (x: fallbackX * inv, y: fallbackY * inv);
  }
  final inv = 1.0 / math.sqrt(len2);
  return (x: x * inv, y: y * inv);
}
