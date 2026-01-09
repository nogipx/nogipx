part of '_index.dart';

// -----------------------------------------------------------------------------
// 3D value-noise + fbm utilities
// -----------------------------------------------------------------------------

/// Композитный 3D fBm шум из пяти октав на основе value noise.
///
/// Используйте для плавных органичных полей: результат нормирован к [0,1].
double fbm3(double x, double y, double z, int seed) {
  var amp = 0.5;
  var freq = 1.0;
  var sum = 0.0;
  var norm = 0.0;
  for (var o = 0; o < 5; o++) {
    sum += amp * valueNoise3(x * freq, y * freq, z * freq, seed + o * 1013);
    norm += amp;
    amp *= 0.5;
    freq *= 2.0;
  }
  return sum / max(1e-9, norm);
}

/// Билинейно-интерполированный 3D value noise на единичном кубе.
///
/// Используйте как строительный блок для fBm; принимает произвольные координаты.
double valueNoise3(double x, double y, double z, int seed) {
  final x0 = x.floor();
  final y0 = y.floor();
  final z0 = z.floor();
  final x1 = x0 + 1;
  final y1 = y0 + 1;
  final z1 = z0 + 1;

  final tx = x - x0;
  final ty = y - y0;
  final tz = z - z0;

  final u = fade(tx);
  final v = fade(ty);
  final w = fade(tz);

  double h(int xi, int yi, int zi) => hash01_3(xi, yi, zi, seed);

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

/// Хеш-функция, дающая детерминированный шум в диапазоне [0,1].
///
/// Используйте для генерации псевдо-рандомных значений в решетке value noise.
double hash01_3(int x, int y, int z, int seed) {
  var h = x * 374761393 ^ y * 668265263 ^ z * 2147483647 ^ seed * 0x27d4eb2d;
  h = (h ^ (h >> 13)) * 1274126177;
  h ^= (h >> 16);
  return (h & 0x7fffffff) / 0x7fffffff;
}

/// Кубическая плавная функция для интерполяции (smoothstep).
double fade(double t) => t * t * (3.0 - 2.0 * t);

/// Ограничивает [v] в [0,1] и возвращает плавную версию для UI/микшеров.
double smooth01(double v) {
  final x = v.clamp(0.0, 1.0);
  return x * x * (3.0 - 2.0 * x);
}

/// Билинейная выборка из сетки с клампом по краям, чтобы избежать швов.
///
/// Используйте для backtrace-адвекции, где нужны гладкие значения между узлами.
double sampleBilinearClamp(Float32List g, int w, int h, double u, double v) {
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

/// Потенциал "порыва" ветра, плавно затухающего от центра.
///
/// Используйте для добавления локализованных вихрей поверх основного потока.
double windPotential(double x, double y, double strength) {
  final r2 = x * x + y * y + 1e-4;
  final falloff = math.exp(-r2 * 1.8);
  final ang = math.atan2(y, x);
  return strength * falloff * ang;
}

/// Нормализует вектор или возвращает запасной вариант, если длина слишком мала.
///
/// Используйте при расчете направления ветра, чтобы избежать деления на ноль.
({double x, double y}) normalize(
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
