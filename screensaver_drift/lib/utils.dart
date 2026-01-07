import 'dart:typed_data';

double sampleBilinear(Float32List g, int w, int h, double u, double v) {
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
