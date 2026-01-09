part of '_index.dart';

/// Собирает параметры, которые зависят только от времени и настроек запроса.
///
/// [w], [h] — размер сетки;
/// [seed] задает фазу шумов;
/// [pattern] переключает режимы (0 — ветер/буря, 1 — пульсации).
/// [speedX]/[speedY] задают глобальный дрейф,
/// [warpFreq]/[warpAmp] — частоту/амплитуду доменного варпа,
/// [baseFreq] — базовую частоту выборки шума.
/// Используйте результат в расчетах за цикл
/// кадра, чтобы не повторять одни и те же вычисления на каждый пиксель поля.
class TemporalParams {
  const TemporalParams({
    required this.phase,
    required this.tzPsi,
    required this.tzWarp,
    required this.tzPhi,
    required this.isPulsate,
    required this.slideX,
    required this.slideY,
    required this.windDir,
    required this.windStrength,
    required this.gustCX,
    required this.gustCY,
    required this.gustStrength,
  });

  final double phase;
  final double tzPsi;
  final double tzWarp;
  final double tzPhi;
  final bool isPulsate;
  final double slideX;
  final double slideY;
  final ({double x, double y}) windDir;
  final double windStrength;
  final double gustCX;
  final double gustCY;
  final double gustStrength;
}

/// Универсальная конфигурация поля, не зависящая от RPC- или DTO-типов проекта.
///
/// Используйте для передачи параметров шума/ветра в функции генерации. Можно
/// создавать напрямую или через [FieldConfig.fromRequest] для интеграции с
/// вашим транспортным DTO.
///
/// * [w]/[h]: размер сетки.
/// * [seed]: фазовый сдвиг шумов.
/// * [pattern]: 0 — буря, 1 — пульсации.
/// * [speedX]/[speedY]: скорость глобального дрейфа поля.
/// * [warpFreq]/[warpAmp]: частота/амплитуда доменного варпа.
/// * [baseFreq]: базовая частота выборки основного шума.
class FieldConfig {
  const FieldConfig({
    required this.w,
    required this.h,
    required this.seed,
    required this.pattern,
    required this.speedX,
    required this.speedY,
    required this.warpFreq,
    required this.warpAmp,
    required this.baseFreq,
  });

  factory FieldConfig.fromRequest(DriftFieldRequest req) => FieldConfig(
    w: req.w,
    h: req.h,
    seed: req.seed,
    pattern: req.pattern,
    speedX: req.speedX,
    speedY: req.speedY,
    warpFreq: req.warpFreq,
    warpAmp: req.warpAmp,
    baseFreq: req.baseFreq,
  );

  final int w;
  final int h;
  final int seed;
  final int pattern;
  final double speedX;
  final double speedY;
  final double warpFreq;
  final double warpAmp;
  final double baseFreq;
}
