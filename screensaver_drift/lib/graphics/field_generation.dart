part of '_index.dart';

/// Заполняет поля скорости, высоты и дополнительных каналов для одного кадра.
///
/// [config] задает геометрию, шумовые и скоростные параметры. [t] — текущее
/// время, [dt] — шаг кадра. Пишет результаты в [psiOut], [flowX], [flowY],
/// [hOut], а временные данные в [rho]/[rhoTmp]/[bulge]/[bulgeTmp]. Используйте
/// в стрим-петле: функция делит расчеты на этапы (время, warp, источники,
/// адвекция), чтобы упростить чтение и тестирование.
void fillFields(
  FieldConfig config,
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
  final w = config.w;
  final h = config.h;
  final n = w * h;
  final params = buildTemporalParams(config, t);

  double sourceSum = 0.0;
  double bulgeSrcSum = 0.0;
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      final i = y * w + x;

      final warped = computeWarpedPosition(x, y, config, t, params);
      psiOut[i] = computeStreamFunction(
        config,
        x,
        y,
        t,
        warped.px,
        warped.py,
        params,
      );
      final sources = computeSources(config, warped.px, warped.py, params);
      sourceSum += sources.rhoSrc;
      bulgeSrcSum += sources.bulgeSrc;
      rhoTmp[i] = sources.rhoSrc;
      bulgeTmp[i] = sources.bulgeSrc;
    }
  }

  normalizeZeroMean(rhoTmp, sourceSum, n);
  normalizeZeroMean(bulgeTmp, bulgeSrcSum, n);

  // Вычисляем divergence-free поток из psi (даже в пульсациях для наклона)
  psiToDivergenceFreeFlow(w, h, psiOut, flowX, flowY);

  advectAndDissipate(w, h, dt, flowX, flowY, rho, rhoTmp, bulge, bulgeTmp);
  finalizeHeightAndBulge(rho, rhoTmp, hOut, bulge, bulgeTmp);
}

/// Высчитывает временные коэффициенты шума/ветра один раз за кадр.
///
/// [config] — параметры поля; [t] — текущее время. Возвращает [TemporalParams],
/// где уже учтены паттерн, фаза, сдвиг шумов и параметры порывов ветра.
/// Используйте в начале `fillFields`, чтобы не держать дублирующий код в
/// вложенных циклах по пикселям.
TemporalParams buildTemporalParams(FieldConfig config, double t) {
  final phase = config.seed * 0.031;
  final tzPsi = t * 0.30 + phase;
  final tzWarp = t * 0.18 + phase * 1.3;
  final tzPhi = t * (config.pattern == 1 ? 0.25 : 0.08) + phase * 0.7;
  final isPulsate = config.pattern == 1;

  final slideX = t * config.speedX * (isPulsate ? 0.20 : 0.75);
  final slideY = t * config.speedY * (isPulsate ? 0.20 : 0.75);
  final dirX = isPulsate
      ? math.cos(t * 0.15 + phase)
      : math.cos(t * 0.32 + phase) + 0.55 * math.sin(t * 0.72 + phase * 1.4);
  final dirY = isPulsate
      ? math.sin(t * 0.17 + phase * 0.8)
      : math.sin(t * 0.29 + phase * 0.8) +
            0.55 * math.cos(t * 0.63 + phase * 1.2);
  final windDir = normalize(dirX, dirY, fallbackX: 0.8, fallbackY: -0.6);
  final windStrength = isPulsate
      ? (0.35 + 0.55 * math.sin(t * 0.9 + phase * 0.8))
      : (1.05 + 0.4 * math.sin(t * 0.52 + phase * 0.9));
  final gustCX = isPulsate
      ? 0.5
      : 0.5 + 0.40 * math.sin(t * 0.55 + phase * 2.1);
  final gustCY = isPulsate
      ? 0.5
      : 0.5 + 0.40 * math.cos(t * 0.50 + phase * 1.9);
  final gustStrength = isPulsate ? 0.0 : 0.9;

  return TemporalParams(
    phase: phase,
    tzPsi: tzPsi,
    tzWarp: tzWarp,
    tzPhi: tzPhi,
    isPulsate: isPulsate,
    slideX: slideX,
    slideY: slideY,
    windDir: windDir,
    windStrength: windStrength,
    gustCX: gustCX,
    gustCY: gustCY,
    gustStrength: gustStrength,
  );
}

/// Вычисляет смещенные (warp) координаты и итоговые частоты выборки шума.
///
/// [x]/[y] — индекс узла, [config] задает параметры варпа, [t]/[params] —
/// временные коэффициенты. Возвращает [px]/[py] — координаты в шумовом
/// пространстве. Используйте до расчета потока/источников, чтобы добиться
/// легкого дрожания без сеточных артефактов.
({double px, double py}) computeWarpedPosition(
  int x,
  int y,
  FieldConfig config,
  double t,
  TemporalParams params,
) {
  final fx = x.toDouble();
  final fy = y.toDouble();

  final warpScale = params.isPulsate ? 0.06 : 0.12;
  final wx = fbm3(
    (fx + params.slideX) * config.warpFreq * warpScale,
    (fy + params.slideY) * config.warpFreq * warpScale,
    params.tzWarp,
    config.seed ^ 0xA341316C,
  );
  final wy = fbm3(
    (fx + 37.0 + params.slideX) * config.warpFreq * warpScale,
    (fy - 11.0 + params.slideY) * config.warpFreq * warpScale,
    params.tzWarp + 11.0,
    config.seed ^ 0xC8013EA4,
  );

  final dx = (wx - 0.5) * config.warpAmp * (params.isPulsate ? 0.20 : 0.32);
  final dy = (wy - 0.5) * config.warpAmp * (params.isPulsate ? 0.20 : 0.32);
  final driftX = t * config.speedX * 0.35;
  final driftY = t * config.speedY * 0.35;

  final px = (fx + dx + driftX + t * 0.22) * config.baseFreq;
  final py = (fy + dy + driftY + t * 0.27) * config.baseFreq;
  return (px: px, py: py);
}

/// Строит функцию тока psi в текущей точке с учетом паттерна и порывов ветра.
///
/// [config] и [params] задают режим (буря/пульс), силу и направление ветра;
/// [x]/[y] — индекс ячейки, [t] — время, [px]/[py] — warped координаты.
/// Возвращенное значение пойдет в `psiToDivergenceFreeFlow` для вычисления
/// скорости.
double computeStreamFunction(
  FieldConfig config,
  int x,
  int y,
  double t,
  double px,
  double py,
  TemporalParams params,
) {
  if (!params.isPulsate) {
    final psiLinear =
        params.windStrength * (params.windDir.x * y - params.windDir.y * x);
    final psiCurlLow = fbm3(
      px * 0.7,
      py * 0.6,
      params.tzPsi * 0.8,
      config.seed ^ 17,
    );
    final psiCurlHi = fbm3(
      px * 1.6,
      py * 1.3,
      params.tzPsi * 1.4 + 9.1,
      config.seed ^ 911,
    );
    final gx = ((x / config.w) - params.gustCX) * 2.0;
    final gy = ((y / config.h) - params.gustCY) * 2.0;
    final psiGust = windPotential(gx, gy, params.gustStrength);
    return psiLinear +
        psiCurlLow * 0.40 +
        psiCurlHi * (0.22 + 0.14 * math.sin(t * 0.61)) +
        psiGust * 0.65;
  }

  final psiCurl = fbm3(px * 0.9, py * 0.9, params.tzPsi, config.seed ^ 101);
  final psiPulse = fbm3(
    px * 0.4,
    py * 0.4,
    t * 0.35 + params.phase,
    config.seed ^ 202,
  );
  return psiCurl * 0.65 +
      psiPulse * 0.35 * (1.0 + 1.2 * math.sin(t * 0.85 + params.phase * 0.7));
}

/// Считает источники плотности и поля bulge и возвращает их без нормализации.
///
/// [config]/[params] определяют частоты/амплитуды; [px]/[py] — warped координаты.
/// Возвращает сырые значения, их нужно прогнать через `normalizeZeroMean`,
/// чтобы дыхание оставалось нулевой средней.
({double rhoSrc, double bulgeSrc}) computeSources(
  FieldConfig config,
  double px,
  double py,
  TemporalParams params,
) {
  final rhoSrc = params.isPulsate
      ? (fbm3(
                  px * 0.2,
                  py * 0.2,
                  params.tzPhi * 1.0,
                  config.seed ^ 0xDEADBEEF,
                ) -
                0.5) *
            1.5
      : fbm3(
              px * 0.35,
              py * 0.35,
              params.tzPhi * 1.3,
              config.seed ^ 0xDEADBEEF,
            ) -
            0.5;

  final bulgeSrc =
      fbm3(
        px * 0.12,
        py * 0.12,
        params.tzPhi * 1.1 + 13.7,
        config.seed ^ 0x12345,
      ) -
      0.5;
  return (rhoSrc: rhoSrc, bulgeSrc: bulgeSrc);
}

/// Делает источники нулевой средней для устойчивого дыхания/пузырей.
///
/// [buffer] — временный массив; [sum] — предварительно накопленная сумма;
/// [count] — количество элементов (обычно w*h). Используйте для любого
/// временного буфера, где сумма должна быть нулевой.
void normalizeZeroMean(Float32List buffer, double sum, int count) {
  final mean = sum / count;
  for (var i = 0; i < buffer.length; i++) {
    buffer[i] -= mean;
  }
}

/// Выполняет backtrace-адвекцию и затухание для плотности и bulge.
///
/// [w]/[h] — размер сетки, [dt] — шаг времени. [flowX]/[flowY] — поле скорости,
/// [rho]/[rhoTmp] и [bulge]/[bulgeTmp] — двойные буферы для плотности и
/// пузырьков. Вызывайте после вычисления flowX/flowY и заполнения источников;
/// функция аккуратно клампит координаты, чтобы избежать выбросов.
void advectAndDissipate(
  int w,
  int h,
  double dt,
  Float32List flowX,
  Float32List flowY,
  Float32List rho,
  Float32List rhoTmp,
  Float32List bulge,
  Float32List bulgeTmp,
) {
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
}

/// Финализирует каналы: копирует плотность, строит высоту и обновляет bulge.
///
/// [rhoTmp] копируется в [rho], [hOut] заполняется степенью плотности,
/// [bulge] обновляется из [bulgeTmp]. Вызывайте после `advectAndDissipate`,
/// чтобы подготовить данные к упаковке.
void finalizeHeightAndBulge(
  Float32List rho,
  Float32List rhoTmp,
  Float32List hOut,
  Float32List bulge,
  Float32List bulgeTmp,
) {
  for (var i = 0; i < rho.length; i++) {
    rho[i] = rhoTmp[i];
    hOut[i] = math.pow(rho[i], 1.2).toDouble();
    bulge[i] = bulgeTmp[i];
  }
}

/// Переводит функцию тока в бездивергентное поле скорости.
///
/// [w]/[h] — размер сетки, [psi] — функция тока, [flowX]/[flowY] — выход.
/// Используйте для генерации стабильного поля flowX/flowY перед адвекцией.
void psiToDivergenceFreeFlow(
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
