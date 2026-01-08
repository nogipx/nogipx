import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';

import 'model.dart';

typedef DriftFrameGetter = DriftFrameData? Function();

/// Итоговый painter под твой пайплайн:
/// - quads через drawVertices (без мерцания линий)
/// - 2.5D проекция (z -> screen shift)
/// - jitter основания (убрать клеточность)
/// - плавное исчезновение по наклону (dir.z)
/// - простое освещение (diff+spec) по градиенту height
/// - batching, чтобы не упереться в лимит Uint16 индексов (65535 вершин)
class DriftFinalPainter extends CustomPainter {
  DriftFinalPainter({
    required this.getFrame,
    required Listenable repaint,

    // dense hair grid (сколько “волосков” рисуем)
    this.hairCountX = 240,
    this.hairCountY = 135,

    // внешний вид
    this.lineWidth = 1.2,
    this.baseAlpha = 0.25,
    this.additive = true,
    this.drawBackground = true,
    this.backgroundColor = const Color(0xFF000000),
    List<Color>? palette,
    this.bulgeScale = 0.35,

    // геометрия
    this.L0 = 1.5,
    this.L1 = 10.0,
    this.gamma = 2.2,
    this.tiltGain = 120.0,
    this.tiltZFloor = 0.2,
    this.tiltBrightnessGain = 0.8,

    // видимость по наклону
    this.maxTiltDeg = 65.0,
    this.featherCos = 0.08,

    // 2.5D проекция
    this.projX = 0.25,
    this.projY = 1.10,

    // jitter (убрать идеальную сетку)
    this.jitter = 0.35,

    // освещение
    this.normalGain = 6.0,
    this.ambient = 0.25,
    this.diffuseK = 0.85,
    this.specularK = 0.35,
    this.shininess = 24.0,

    // “дырки” по высоте (опционально)
    this.heightCut = 0.02,
    this.heightCutFeather = 0.10,
  }) : palette = palette ?? defaultPalette,
       super(repaint: repaint) {
    _initBatchBuffers();
  }

  /// Функция, отдающая актуальный кадр для рендера.
  final DriftFrameGetter getFrame;

  /// Количество “волосков” по X/Y (размер визуальной сетки).
  final int hairCountX;

  /// Количество “волосков” по X/Y (размер визуальной сетки).
  final int hairCountY;

  /// Толщина сегмента и базовая прозрачность.
  final double lineWidth;

  /// Толщина сегмента и базовая прозрачность.
  final double baseAlpha;

  /// Аддитивное смешивание (true) или обычное srcOver (false).
  final bool additive;

  /// Рисовать фон и его цвет.
  final bool drawBackground;

  /// Рисовать фон и его цвет.
  final Color backgroundColor;

  /// Палитра для градиента по высоте (5 точек).
  final List<Color> palette;
  // Факториальный множитель по bulge для длины.
  final double bulgeScale;

  /// Базовая длина (L0), добавка от height (L1), гамма height и усиление наклона.
  final double L0;

  /// Базовая длина (L0), добавка от height (L1), гамма height и усиление наклона.
  final double L1;

  /// Базовая длина (L0), добавка от height (L1), гамма height и усиление наклона.
  final double gamma;

  /// Базовая длина (L0), добавка от height (L1), гамма height и усиление наклона.
  final double tiltGain;

  /// Минимальная вертикальная компонента (не даём z падать ниже, чтобы не пропадали).
  final double tiltZFloor;

  /// Усиление яркости/альфы при большем наклоне по flow.
  final double tiltBrightnessGain;

  /// Ограничение видимости по наклону и плавность отсечки.
  final double maxTiltDeg;

  /// Ограничение видимости по наклону и плавность отсечки.
  final double featherCos;

  /// Параметры псевдо-3D проекции (сдвиг по экрану при росте по Z).
  final double projX;

  /// Параметры псевдо-3D проекции (сдвиг по экрану при росте по Z).
  final double projY;

  /// Случайный сдвиг основания волоска.
  final double jitter;

  /// Освещение: усиление нормали, амбиент и diffuse/specular/shine.
  final double normalGain;

  /// Освещение: усиление нормали, амбиент и diffuse/specular/shine.
  final double ambient;

  /// Освещение: усиление нормали, амбиент и diffuse/specular/shine.
  final double diffuseK;

  /// Освещение: усиление нормали, амбиент и diffuse/specular/shine.
  final double specularK;

  /// Освещение: усиление нормали, амбиент и diffuse/specular/shine.
  final double shininess;

  /// Отсечка по height и её растушёвка.
  final double heightCut;

  /// Отсечка по height и её растушёвка.
  final double heightCutFeather;

  // ---- batching (индексы Uint16 -> максимум 65535 вершин) ----
  static const int _maxVerts = 65535;
  static const int _maxBatchHairs = _maxVerts ~/ 4; // 16383
  late final Float32List _posXY; // max batch
  late final Int32List _colors; // max batch
  late final Uint16List _indices; // max batch (6 per hair)

  final Paint _paint = Paint()..isAntiAlias = true;

  void _initBatchBuffers() {
    final maxBatchVerts = _maxBatchHairs * 4;
    _posXY = Float32List(maxBatchVerts * 2);
    _colors = Int32List(maxBatchVerts);
    _indices = Uint16List(_maxBatchHairs * 6);

    var ii = 0;
    for (int h = 0; h < _maxBatchHairs; h++) {
      final v = h * 4;
      _indices[ii++] = v;
      _indices[ii++] = v + 1;
      _indices[ii++] = v + 2;
      _indices[ii++] = v + 2;
      _indices[ii++] = v + 1;
      _indices[ii++] = v + 3;
    }
  }

  Offset _project(double x, double y, double z) =>
      Offset(x + z * projX, y - z * projY);

  @override
  void paint(Canvas canvas, Size size) {
    final f = getFrame();
    if (f == null) return;

    final fieldW = f.w;
    final fieldH = f.h;
    final flowX = f.flowX;
    final flowY = f.flowY;
    final height = f.height;
    final bulgeField = f.bulge;

    final n = fieldW * fieldH;
    if (fieldW <= 1 || fieldH <= 1) return;
    if (flowX.length < n ||
        flowY.length < n ||
        height.length < n ||
        bulgeField.length < n) return;

    if (drawBackground) {
      canvas.drawRect(Offset.zero & size, Paint()..color = backgroundColor);
    }

    final totalHairs = hairCountX * hairCountY;
    if (totalHairs <= 0) return;

    final dxCell = size.width / hairCountX;
    final dyCell = size.height / hairCountY;
    final halfW = lineWidth * 0.5;

    // шаг для оценки градиента height (в UV)
    final du = 1.0 / fieldW;
    final dv = 1.0 / fieldH;

    // фиксированный свет/вид
    const lx = -0.35, ly = -0.25, lz = 0.90;
    final lInv = 1.0 / math.sqrt(lx * lx + ly * ly + lz * lz);
    final lightX = lx * lInv, lightY = ly * lInv, lightZ = lz * lInv;
    const viewX = 0.0, viewY = 0.0, viewZ = 1.0;

    int batchStart = 0;
    while (batchStart < totalHairs) {
      final usedHairs = math.min(_maxBatchHairs, totalHairs - batchStart);
      final usedVerts = usedHairs * 4;
      final usedPosLen = usedVerts * 2;
      final usedIdxLen = usedHairs * 6;

      for (int b = 0; b < usedHairs; b++) {
        final global = batchStart + b;
        final i = global % hairCountX;
        final j = global ~/ hairCountX;

        // jittered base
        final jx = (_hash01(i, j) - 0.5) * jitter * dxCell;
        final jy = (_hash01(i + 1013, j - 991) - 0.5) * jitter * dyCell;

        final x0 = (i + 0.5) * dxCell + jx;
        final y0 = (j + 0.5) * dyCell + jy;

        final u0 = (x0 / size.width).clamp(0.0, 1.0);
        final v0 = (y0 / size.height).clamp(0.0, 1.0);

        // sample flow + height
        final fx = _sampleBilinear(flowX, fieldW, fieldH, u0, v0);
        final fy = _sampleBilinear(flowY, fieldW, fieldH, u0, v0);

        var hh = _sampleBilinear(
          height,
          fieldW,
          fieldH,
          u0,
          v0,
        ).clamp(0.0, 1.0);
        hh = math.pow(hh, gamma).toDouble();

        var bb = _sampleBilinear(bulgeField, fieldW, fieldH, u0, v0).clamp(0.0, 1.0);
        bb = _smoothstep(0.0, 1.0, bb);

        // optional: height-based holes
        final hMask = _smoothstep(heightCut, heightCut + heightCutFeather, hh);

        // dir3 = normalize(vec3(flow*tiltGain, 1))
        var vx = fx * tiltGain;
        var vy = fy * tiltGain;
        var vz = 1.0;
        final inv = 1.0 / math.sqrt(vx * vx + vy * vy + vz * vz);
        vx *= inv;
        vy *= inv;
        vz *= inv;
        vz = vz.clamp(tiltZFloor, 1.0);

        // tilt visibility: скрываем почти вертикальные, усиливаем наклонённые
        final tilt = (1.0 - vz).clamp(0.0, 1.0);
        final tiltAlpha = _smoothstep(0.02, 0.32, tilt);
        var alpha = (baseAlpha * tiltAlpha * hMask).clamp(0.0, 1.0);

        final vBase = b * 4;
        final pBase = vBase * 2;

        if (alpha <= 0.001) {
          _posXY[pBase] = x0;
          _posXY[pBase + 1] = y0;
          _posXY[pBase + 2] = x0;
          _posXY[pBase + 3] = y0;
          _posXY[pBase + 4] = x0;
          _posXY[pBase + 5] = y0;
          _posXY[pBase + 6] = x0;
          _posXY[pBase + 7] = y0;
          _colors[vBase] = 0;
          _colors[vBase + 1] = 0;
          _colors[vBase + 2] = 0;
          _colors[vBase + 3] = 0;
          continue;
        }

        // “height” as vertical z (L)
        final L = (L0 + L1 * hh) * (1.0 + bulgeScale * (bb - 0.5));

        // scale along dir so that vertical component corresponds to L
        var s = L / vz;
        s = s.clamp(0.0, L * 3.0);

        final x1 = x0 + vx * s;
        final y1 = y0 + vy * s;
        final zTip = vz * s; // ~= L

        // 2.5D projection
        final A = _project(x0, y0, 0.0);
        final B = _project(x1, y1, zTip);

        // screen-space thickness
        var tx = B.dx - A.dx;
        var ty = B.dy - A.dy;
        final segLen = math.sqrt(tx * tx + ty * ty).clamp(1e-6, 1e9);
        tx /= segLen;
        ty /= segLen;

        final nx2 = -ty;
        final ny2 = tx;
        final ox = nx2 * halfW;
        final oy = ny2 * halfW;

        _posXY[pBase] = A.dx + ox;
        _posXY[pBase + 1] = A.dy + oy;

        _posXY[pBase + 2] = A.dx - ox;
        _posXY[pBase + 3] = A.dy - oy;

        _posXY[pBase + 4] = B.dx + ox;
        _posXY[pBase + 5] = B.dy + oy;

        _posXY[pBase + 6] = B.dx - ox;
        _posXY[pBase + 7] = B.dy - oy;

        // lighting from height gradient (normal ≈ (-hx,-hy,1))
        final hx =
            (_sampleBilinear(
              height,
              fieldW,
              fieldH,
              (u0 + du).clamp(0.0, 1.0),
              v0,
            ) -
            _sampleBilinear(
              height,
              fieldW,
              fieldH,
              (u0 - du).clamp(0.0, 1.0),
              v0,
            ));
        final hy =
            (_sampleBilinear(
              height,
              fieldW,
              fieldH,
              u0,
              (v0 + dv).clamp(0.0, 1.0),
            ) -
            _sampleBilinear(
              height,
              fieldW,
              fieldH,
              u0,
              (v0 - dv).clamp(0.0, 1.0),
            ));

        var nx = -hx * normalGain;
        var ny = -hy * normalGain;
        var nz = 1.0;
        final nInv = 1.0 / math.sqrt(nx * nx + ny * ny + nz * nz);
        nx *= nInv;
        ny *= nInv;
        nz *= nInv;

        final diff = math.max(0.0, nx * lightX + ny * lightY + nz * lightZ);

        // Blinn-Phong specular
        var hxv = lightX + viewX;
        var hyv = lightY + viewY;
        var hzv = lightZ + viewZ;
        final hInv = 1.0 / math.sqrt(hxv * hxv + hyv * hyv + hzv * hzv);
        hxv *= hInv;
        hyv *= hInv;
        hzv *= hInv;

        final specBase = math.max(0.0, nx * hxv + ny * hyv + nz * hzv);
        final spec = math.pow(specBase, shininess).toDouble();

        var shade = (ambient + diffuseK * diff + specularK * spec);
        shade *= 1.0 + tilt * tiltBrightnessGain;
        shade = shade.clamp(0.0, 3.0);

        final base = _palette(hh);

        // taper: основание слабее, кончик ярче
        final aBase = (alpha * 0.55).clamp(0.0, 1.0);
        final aTip = (alpha * 1.00).clamp(0.0, 1.0);

        _colors[vBase] = _shadeToArgb(base, shade, (aBase * 255).round());
        _colors[vBase + 1] = _shadeToArgb(base, shade, (aBase * 255).round());
        _colors[vBase + 2] = _shadeToArgb(base, shade, (aTip * 255).round());
        _colors[vBase + 3] = _shadeToArgb(base, shade, (aTip * 255).round());
      }

      final posView = Float32List.sublistView(_posXY, 0, usedPosLen);
      final colView = Int32List.sublistView(_colors, 0, usedVerts);
      final idxView = Uint16List.sublistView(_indices, 0, usedIdxLen);

      final vertices = Vertices.raw(
        VertexMode.triangles,
        posView,
        colors: colView,
        indices: idxView,
      );

      canvas.drawVertices(
        vertices,
        additive ? BlendMode.plus : BlendMode.srcOver,
        _paint,
      );

      batchStart += usedHairs;
    }
  }

  @override
  bool shouldRepaint(covariant DriftFinalPainter old) {
    return old.getFrame != getFrame ||
        old.hairCountX != hairCountX ||
        old.hairCountY != hairCountY ||
        old.lineWidth != lineWidth ||
        old.baseAlpha != baseAlpha ||
        old.additive != additive ||
        old.drawBackground != drawBackground ||
        old.backgroundColor != backgroundColor ||
        old.tiltZFloor != tiltZFloor ||
        old.palette != palette ||
        old.L0 != L0 ||
        old.L1 != L1 ||
        old.gamma != gamma ||
        old.tiltGain != tiltGain ||
        old.tiltBrightnessGain != tiltBrightnessGain ||
        old.maxTiltDeg != maxTiltDeg ||
        old.featherCos != featherCos ||
        old.projX != projX ||
        old.projY != projY ||
        old.jitter != jitter ||
        old.normalGain != normalGain ||
        old.ambient != ambient ||
        old.diffuseK != diffuseK ||
        old.specularK != specularK ||
        old.shininess != shininess ||
        old.heightCut != heightCut ||
        old.heightCutFeather != heightCutFeather ||
        old.bulgeScale != bulgeScale;
  }

  static double _sampleBilinear(
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

  static double _smoothstep(double e0, double e1, double x) {
    final t = ((x - e0) / (e1 - e0)).clamp(0.0, 1.0);
    return t * t * (3.0 - 2.0 * t);
  }

  static double _hash01(int x, int y) {
    var h = x * 374761393 ^ y * 668265263;
    h = (h ^ (h >> 13)) * 1274126177;
    h ^= (h >> 16);
    return (h & 0x7fffffff) / 0x7fffffff;
  }

  static int _shadeToArgb(Color c, double shade, int a8) {
    int clamp255(double v) => v < 0 ? 0 : (v > 255 ? 255 : v.round());
    final r = clamp255(c.red * shade);
    final g = clamp255(c.green * shade);
    final b = clamp255(c.blue * shade);
    a8 = a8.clamp(0, 255);
    return (a8 << 24) | (r << 16) | (g << 8) | b;
  }

  Color _palette(double t) {
    // Подробный градиент через Catmull-Rom по узлам палитры (>=3 узлов).
    if (palette.length < 3) {
      final a = palette.isNotEmpty ? palette.first : const Color(0xFFFFFFFF);
      return a.withOpacity(1.0);
    }

    final n = palette.length;
    t = t.clamp(0.0, 1.0);
    final scaled = t * (n - 1);
    final idx = scaled.floor().clamp(0, n - 2);
    final localT = scaled - idx;

    Color c(int i) => palette[i.clamp(0, n - 1)];

    final p0 = c(idx - 1);
    final p1 = c(idx);
    final p2 = c(idx + 1);
    final p3 = c(idx + 2);

    Color catmullRom(Color a, Color b, Color c, Color d, double t) {
      double cr(double a, double b, double c, double d, double t) {
        final t2 = t * t;
        final t3 = t2 * t;
        return 0.5 *
            (2 * b +
                (-a + c) * t +
                (2 * a - 5 * b + 4 * c - d) * t2 +
                (-a + 3 * b - 3 * c + d) * t3);
      }

      return Color.fromARGB(
        255,
        cr(a.red.toDouble(), b.red.toDouble(), c.red.toDouble(),
                d.red.toDouble(), t)
            .clamp(0, 255)
            .round(),
        cr(a.green.toDouble(), b.green.toDouble(), c.green.toDouble(),
                d.green.toDouble(), t)
            .clamp(0, 255)
            .round(),
        cr(a.blue.toDouble(), b.blue.toDouble(), c.blue.toDouble(),
                d.blue.toDouble(), t)
            .clamp(0, 255)
            .round(),
      );
    }

    return catmullRom(p0, p1, p2, p3, localT);
  }

  static const List<Color> defaultPalette = [
    Color(0xFF081026), // deep navy
    Color(0xFF0E6BFF), // electric blue
    Color(0xFF2DE0C9), // aqua
    Color(0xFFF971D2), // pink
    Color(0xFFFFB86C), // amber
  ];
}

/// Синоним для обратной совместимости.
typedef DriftPainter = DriftFinalPainter;
