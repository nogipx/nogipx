part of '../_index.dart';

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
  final strategy = _strategyForId(config.strategy);
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
      psiOut[i] = strategy.stream(
        config,
        x,
        y,
        t,
        warped.px,
        warped.py,
        params,
      );
      final sources = strategy.sources(
        config,
        warped.px,
        warped.py,
        params,
        x,
        y,
      );
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
  finalizeHeightAndBulge(
    rho,
    rhoTmp,
    hOut,
    bulge,
    bulgeTmp,
    tuning.heightPower,
  );
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
