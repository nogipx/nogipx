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
  final tuning = config.tuning;
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
  psiToDivergenceFreeFlow(w, h, psiOut, flowX, flowY, tuning);

  advectAndDissipate(
    w,
    h,
    dt,
    flowX,
    flowY,
    rho,
    rhoTmp,
    bulge,
    bulgeTmp,
    tuning.advection,
  );
  finalizeHeightAndBulge(rho, rhoTmp, hOut, bulge, bulgeTmp, tuning.heightPower);
}

/// Высчитывает временные коэффициенты шума/ветра один раз за кадр.
///
/// [config] — параметры поля; [t] — текущее время. Возвращает [TemporalParams],
/// где уже учтены паттерн, фаза, сдвиг шумов и параметры порывов ветра.
/// Используйте в начале `fillFields`, чтобы не держать дублирующий код в
/// вложенных циклах по пикселям.
TemporalParams buildTemporalParams(FieldConfig config, double t) {
  final tuning = config.tuning;
  final phase = config.seed * tuning.phaseScale;
  final tzPsi = t * tuning.tzPsiSpeed + phase;
  final tzWarp = t * tuning.tzWarpSpeed + phase * tuning.tzWarpPhaseScale;
  final tzPhi = t * (config.pattern == 1 ? tuning.tzPhiSpeedPulsate : tuning.tzPhiSpeedNormal) +
      phase * tuning.tzPhiPhaseScale;
  final isPulsate = config.pattern == 1;

  final slideX = t * config.speedX * (isPulsate ? tuning.slideFactorPulsate : tuning.slideFactorNormal);
  final slideY = t * config.speedY * (isPulsate ? tuning.slideFactorPulsate : tuning.slideFactorNormal);
  final wind = tuning.wind;
  final dirX = isPulsate
      ? math.cos(t * wind.pulsateDirXFreq + phase)
      : math.cos(t * wind.normalDirXFreqA + phase) +
          wind.normalDirXWeightB *
              math.sin(t * wind.normalDirXFreqB + phase * wind.normalDirXPhaseScaleB);
  final dirY = isPulsate
      ? math.sin(t * wind.pulsateDirYFreq + phase * wind.pulsateDirYPhaseScale)
      : math.sin(t * wind.normalDirYFreqA + phase * wind.normalDirYPhaseScaleB) +
          wind.normalDirYWeightB *
              math.cos(t * wind.normalDirYFreqB + phase * wind.normalDirYPhaseScaleB);
  final windDir = normalize(
    dirX,
    dirY,
    fallbackX: wind.windDirFallbackX,
    fallbackY: wind.windDirFallbackY,
  );
  final windStrength = isPulsate
      ? (wind.pulsateStrengthBase +
          wind.pulsateStrengthAmp *
              math.sin(t * wind.pulsateStrengthFreq + phase * wind.pulsateStrengthPhaseScale))
      : (wind.normalStrengthBase +
          wind.normalStrengthAmp *
              math.sin(t * wind.normalStrengthFreq + phase * wind.normalStrengthPhaseScale));
  final gust = tuning.gust;
  final gustCX = isPulsate
      ? gust.centerBase
      : gust.centerBase + gust.centerAmp * math.sin(t * gust.centerFreqX + phase * gust.centerPhaseScaleX);
  final gustCY = isPulsate
      ? gust.centerBase
      : gust.centerBase + gust.centerAmp * math.cos(t * gust.centerFreqY + phase * gust.centerPhaseScaleY);
  final gustStrength = isPulsate ? gust.strengthPulsate : gust.strengthNormal;

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
  final warp = config.tuning.warp;
  final fx = x.toDouble();
  final fy = y.toDouble();

  final warpScale = params.isPulsate ? warp.scalePulsate : warp.scaleNormal;
  final wx = fbm3(
    (fx + params.slideX) * config.warpFreq * warpScale,
    (fy + params.slideY) * config.warpFreq * warpScale,
    params.tzWarp,
    config.seed ^ 0xA341316C,
  );
  final wy = fbm3(
    (fx + warp.noiseOffsetX + params.slideX) * config.warpFreq * warpScale,
    (fy + warp.noiseOffsetY + params.slideY) * config.warpFreq * warpScale,
    params.tzWarp + warp.tzOffset,
    config.seed ^ 0xC8013EA4,
  );

  final dx = (wx - 0.5) * config.warpAmp * (params.isPulsate ? warp.ampPulsate : warp.ampNormal);
  final dy = (wy - 0.5) * config.warpAmp * (params.isPulsate ? warp.ampPulsate : warp.ampNormal);
  final driftX = t * config.speedX * warp.driftScale;
  final driftY = t * config.speedY * warp.driftScale;

  final px = (fx + dx + driftX + t * warp.timeOffsetX) * config.baseFreq;
  final py = (fy + dy + driftY + t * warp.timeOffsetY) * config.baseFreq;
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
  final stream = config.tuning.stream;
  if (!params.isPulsate) {
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
                stream.psiCurlHiModAmp * math.sin(t * stream.psiCurlHiModFreq)) +
        psiGust * stream.psiGustWeight;
  }

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
                  math.sin(t * stream.psiPulseModFreq + params.phase * stream.psiPulsePhaseScale));
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
  final source = config.tuning.source;
  final rhoSrc = params.isPulsate
      ? (fbm3(
                  px * source.rhoFreqPulsate,
                  py * source.rhoFreqPulsate,
                  params.tzPhi * source.rhoTzScalePulsate,
                  config.seed ^ 0xDEADBEEF,
                ) -
                source.rhoCenterBias) *
            source.rhoPulsateGain
      : fbm3(
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
/// функция аккуратно клампит координаты, чтобы избежать выбросов. [tuning]
/// задает коэффициенты затухания, примесей и фоновых значений.
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

      var r = adv * dissipation +
          rhoTmp[i] * tuning.rhoSourceMix +
          tuning.rhoAmbientValue * (1 - dissipation);
      if (r < 0) r = 0;
      if (r > 1) r = 1;
      rhoTmp[i] = r;

      var b = advB * tuning.bulgeAdvectFactor +
          bulgeTmp[i] * tuning.bulgeSourceMix +
          tuning.bulgeAmbientValue * tuning.bulgeAmbientMix;
      if (b < 0) b = 0;
      if (b > 1) b = 1;
      bulgeTmp[i] = b;
    }
  }
}

/// Финализирует каналы: копирует плотность, строит высоту и обновляет bulge.
///
/// [rhoTmp] копируется в [rho], [hOut] заполняется степенью плотности,
/// [bulge] обновляется из [bulgeTmp]. [heightPower] управляет степенью
/// преобразования высоты. Вызывайте после `advectAndDissipate`, чтобы
/// подготовить данные к упаковке.
void finalizeHeightAndBulge(
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

/// Переводит функцию тока в бездивергентное поле скорости.
///
/// [w]/[h] — размер сетки, [psi] — функция тока, [flowX]/[flowY] — выход.
/// Используйте для генерации стабильного поля flowX/flowY перед адвекцией.
/// [tuning] управляет усилением и клампом скорости.
void psiToDivergenceFreeFlow(
  int w,
  int h,
  Float32List psi,
  Float32List flowX,
  Float32List flowY,
  FieldTuning tuning,
) {
  int ix(int x) => x.clamp(0, w - 1);
  int iy(int y) => y.clamp(0, h - 1);

  final flowAmp = tuning.flowAmp; // ещё живее
  final flowClamp = tuning.flowClamp; // защита от выбросов

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
