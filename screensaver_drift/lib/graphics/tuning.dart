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
/// * [tuning]: все тонкие коэффициенты (ветер, warp, адвекция и т.д.).
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
    this.tuning = const FieldTuning(),
  });

  factory FieldConfig.fromRequest(
    DriftFieldRequest req, {
    FieldTuning tuning = const FieldTuning(),
  }) => FieldConfig(
    w: req.w,
    h: req.h,
    seed: req.seed,
    pattern: req.pattern,
    speedX: req.speedX,
    speedY: req.speedY,
    warpFreq: req.warpFreq,
    warpAmp: req.warpAmp,
    baseFreq: req.baseFreq,
    tuning: tuning,
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
  final FieldTuning tuning;
}

/// Настройки, позволяющие менять поведение математики без правок кода.
///
/// Сгруппированы по смыслу: шумы/временные частоты, ветер/порывы, warp,
/// поток psi, источники, адвекция и пост-обработка высоты/потока.
class FieldTuning {
  const FieldTuning({
    this.phaseScale = 0.031, // множитель seed -> фаза шумов
    this.tzPsiSpeed = 0.30, // скорость по времени для шума psi
    this.tzWarpSpeed = 0.18, // скорость по времени для шума варпа
    this.tzWarpPhaseScale = 1.3, // влияние фазы на tz варпа
    this.tzPhiSpeedPulsate =
        0.25, // скорость по времени для источников в пульсе
    this.tzPhiSpeedNormal = 0.08, // скорость по времени для источников в буре
    this.tzPhiPhaseScale = 0.7, // влияние фазы на tz источников
    this.slideFactorPulsate = 0.20, // множитель сдвига координат при пульсе
    this.slideFactorNormal = 0.75, // множитель сдвига координат при буре
    this.wind = const WindTuning(),
    this.gust = const GustTuning(),
    this.warp = const WarpTuning(),
    this.stream = const StreamTuning(),
    this.source = const SourceTuning(),
    this.advection = const AdvectionTuning(),
    this.heightPower = 1.2, // степень для расчета высоты из плотности
    this.flowAmp = 2.0, // усиление скорости из psi
    this.flowClamp = 0.55, // ограничение скорости, защита от выбросов
  });

  /// Случайная генерация тюнинга с контролем диапазонов.
  ///
  /// Используйте, чтобы быстро получить новый образ поля. [seed] делает выбор
  /// детерминированным. Значения варьируются около дефолтов, чтобы не ломать
  /// стабильность анимации.
  factory FieldTuning.random({int? seed, double variance = 0.25}) {
    final rng = Random(seed);
    double around(double base, double spread) =>
        base + (rng.nextDouble() * 2 - 1) * spread * variance;
    return FieldTuning(
      phaseScale: around(0.031, 0.01),
      tzPsiSpeed: around(0.30, 0.06),
      tzWarpSpeed: around(0.18, 0.05),
      tzWarpPhaseScale: around(1.3, 0.3),
      tzPhiSpeedPulsate: around(0.25, 0.08),
      tzPhiSpeedNormal: around(0.08, 0.03),
      tzPhiPhaseScale: around(0.7, 0.15),
      slideFactorPulsate: around(0.20, 0.08),
      slideFactorNormal: around(0.75, 0.18),
      wind: WindTuning.random(rng, variance: variance),
      gust: GustTuning.random(rng, variance: variance),
      warp: WarpTuning.random(rng, variance: variance),
      stream: StreamTuning.random(rng, variance: variance),
      source: SourceTuning.random(rng, variance: variance),
      advection: AdvectionTuning.random(rng, variance: variance),
      heightPower: around(1.2, 0.25),
      flowAmp: around(2.0, 0.4),
      flowClamp: around(0.55, 0.12),
    );
  }

  final double phaseScale;
  final double tzPsiSpeed;
  final double tzWarpSpeed;
  final double tzWarpPhaseScale;
  final double tzPhiSpeedPulsate;
  final double tzPhiSpeedNormal;
  final double tzPhiPhaseScale;
  final double slideFactorPulsate;
  final double slideFactorNormal;
  final WindTuning wind;
  final GustTuning gust;
  final WarpTuning warp;
  final StreamTuning stream;
  final SourceTuning source;
  final AdvectionTuning advection;
  final double heightPower;
  final double flowAmp;
  final double flowClamp;
}

/// Тюнинг направления и силы ветра.
///
/// - Частоты/веса для нормального режима: [normalDirX*], [normalDirY*].
/// - Частоты для пульсаций: [pulsateDir*].
/// - Запасное направление при нулевой длине: [windDirFallbackX]/[windDirFallbackY].
/// - Сила ветра: базовые и амплитуды для normal/pulsate + частоты/фазы.
class WindTuning {
  const WindTuning({
    this.normalDirXFreqA = 0.32, // частота косинуса X в буре
    this.normalDirXFreqB = 0.72, // частота синуса X в буре
    this.normalDirXWeightB = 0.55, // вес второй гармоники X
    this.normalDirXPhaseScaleB = 1.4, // фазовый множитель для синуса X
    this.normalDirYFreqA = 0.29, // частота синуса Y в буре
    this.normalDirYFreqB = 0.63, // частота косинуса Y в буре
    this.normalDirYWeightB = 0.55, // вес второй гармоники Y
    this.normalDirYPhaseScaleB = 1.2, // фазовый множитель для косинуса Y
    this.pulsateDirXFreq = 0.15, // частота косинуса X в пульсе
    this.pulsateDirYFreq = 0.17, // частота синуса Y в пульсе
    this.pulsateDirYPhaseScale = 0.8, // фазовый множитель для синуса Y в пульсе
    this.windDirFallbackX = 0.8, // запасной X для нормализации ветра
    this.windDirFallbackY = -0.6, // запасной Y для нормализации ветра
    this.normalStrengthBase = 1.05, // базовая сила ветра в буре
    this.normalStrengthAmp = 0.4, // амплитуда модуляции силы в буре
    this.normalStrengthFreq = 0.52, // частота модуляции силы в буре
    this.normalStrengthPhaseScale = 0.9, // фазовый множитель силы в буре
    this.pulsateStrengthBase = 0.35, // базовая сила ветра в пульсе
    this.pulsateStrengthAmp = 0.55, // амплитуда силы в пульсе
    this.pulsateStrengthFreq = 0.9, // частота силы в пульсе
    this.pulsateStrengthPhaseScale = 0.8, // фазовый множитель силы в пульсе
  });

  final double normalDirXFreqA;
  final double normalDirXFreqB;
  final double normalDirXWeightB;
  final double normalDirXPhaseScaleB;
  final double normalDirYFreqA;
  final double normalDirYFreqB;
  final double normalDirYWeightB;
  final double normalDirYPhaseScaleB;
  final double pulsateDirXFreq;
  final double pulsateDirYFreq;
  final double pulsateDirYPhaseScale;
  final double windDirFallbackX;
  final double windDirFallbackY;
  final double normalStrengthBase;
  final double normalStrengthAmp;
  final double normalStrengthFreq;
  final double normalStrengthPhaseScale;
  final double pulsateStrengthBase;
  final double pulsateStrengthAmp;
  final double pulsateStrengthFreq;
  final double pulsateStrengthPhaseScale;

  factory WindTuning.random(Random rng, {double variance = 0.25}) {
    double around(double base, double spread) =>
        base + (rng.nextDouble() * 2 - 1) * spread * variance;
    return WindTuning(
      normalDirXFreqA: around(0.32, 0.08),
      normalDirXFreqB: around(0.72, 0.15),
      normalDirXWeightB: around(0.55, 0.15),
      normalDirXPhaseScaleB: around(1.4, 0.25),
      normalDirYFreqA: around(0.29, 0.08),
      normalDirYFreqB: around(0.63, 0.15),
      normalDirYWeightB: around(0.55, 0.15),
      normalDirYPhaseScaleB: around(1.2, 0.2),
      pulsateDirXFreq: around(0.15, 0.05),
      pulsateDirYFreq: around(0.17, 0.05),
      pulsateDirYPhaseScale: around(0.8, 0.2),
      windDirFallbackX: around(0.8, 0.1),
      windDirFallbackY: around(-0.6, 0.1),
      normalStrengthBase: around(1.05, 0.2),
      normalStrengthAmp: around(0.4, 0.15),
      normalStrengthFreq: around(0.52, 0.12),
      normalStrengthPhaseScale: around(0.9, 0.2),
      pulsateStrengthBase: around(0.35, 0.12),
      pulsateStrengthAmp: around(0.55, 0.15),
      pulsateStrengthFreq: around(0.9, 0.2),
      pulsateStrengthPhaseScale: around(0.8, 0.2),
    );
  }
}

/// Тюнинг порывов ветра: позиция центра и сила.
///
/// - [centerBase]/[centerAmp]/[centerFreqX|Y]/[centerPhaseScaleX|Y] управляют бегущим центром.
/// - [strengthNormal]/[strengthPulsate] задают амплитуду порывов.
class GustTuning {
  const GustTuning({
    this.centerBase = 0.5, // базовый центр порыва (нормированные координаты)
    this.centerAmp = 0.40, // амплитуда колебаний центра
    this.centerFreqX = 0.55, // частота смещения центра по X
    this.centerFreqY = 0.50, // частота смещения центра по Y
    this.centerPhaseScaleX = 2.1, // фазовый множитель смещения X
    this.centerPhaseScaleY = 1.9, // фазовый множитель смещения Y
    this.strengthNormal = 0.9, // сила порыва в буре
    this.strengthPulsate = 0.0, // сила порыва в пульсе
  });

  final double centerBase;
  final double centerAmp;
  final double centerFreqX;
  final double centerFreqY;
  final double centerPhaseScaleX;
  final double centerPhaseScaleY;
  final double strengthNormal;
  final double strengthPulsate;

  factory GustTuning.random(Random rng, {double variance = 0.25}) {
    double around(double base, double spread) =>
        base + (rng.nextDouble() * 2 - 1) * spread * variance;
    return GustTuning(
      centerBase: around(0.5, 0.05),
      centerAmp: around(0.40, 0.15),
      centerFreqX: around(0.55, 0.2),
      centerFreqY: around(0.50, 0.2),
      centerPhaseScaleX: around(2.1, 0.6),
      centerPhaseScaleY: around(1.9, 0.6),
      strengthNormal: around(0.9, 0.25),
      strengthPulsate: around(0.0, 0.15),
    );
  }
}

/// Тюнинг доменного варпа и глобального дрейфа.
///
/// - Масштаб/амплитуда для обычного и пульсационного режимов.
/// - [driftScale] — коэффициент глобального дрейфа по скорости.
/// - [timeOffsetX]/[timeOffsetY] — временные сдвиги базовых координат.
/// - [noiseOffsetX]/[noiseOffsetY]/[tzOffset] — смещения для независимых выборок шума.
class WarpTuning {
  const WarpTuning({
    this.scalePulsate = 0.06, // масштаб варпа в пульсе
    this.scaleNormal = 0.12, // масштаб варпа в буре
    this.ampPulsate = 0.20, // амплитуда варпа в пульсе
    this.ampNormal = 0.32, // амплитуда варпа в буре
    this.driftScale = 0.35, // множитель глобального дрейфа
    this.timeOffsetX = 0.22, // временной сдвиг координаты X
    this.timeOffsetY = 0.27, // временной сдвиг координаты Y
    this.noiseOffsetX = 37.0, // смещение шума по X для независимости каналов
    this.noiseOffsetY = -11.0, // смещение шума по Y для независимости каналов
    this.tzOffset = 11.0, // смещение по z для второй выборки шума
  });

  final double scalePulsate;
  final double scaleNormal;
  final double ampPulsate;
  final double ampNormal;
  final double driftScale;
  final double timeOffsetX;
  final double timeOffsetY;
  final double noiseOffsetX;
  final double noiseOffsetY;
  final double tzOffset;

  factory WarpTuning.random(Random rng, {double variance = 0.25}) {
    double around(double base, double spread) =>
        base + (rng.nextDouble() * 2 - 1) * spread * variance;
    return WarpTuning(
      scalePulsate: around(0.06, 0.02),
      scaleNormal: around(0.12, 0.03),
      ampPulsate: around(0.20, 0.07),
      ampNormal: around(0.32, 0.08),
      driftScale: around(0.35, 0.08),
      timeOffsetX: around(0.22, 0.05),
      timeOffsetY: around(0.27, 0.05),
      noiseOffsetX: around(37.0, 8.0),
      noiseOffsetY: around(-11.0, 6.0),
      tzOffset: around(11.0, 3.0),
    );
  }
}

/// Тюнинг функции тока psi и вкладов порывов/пульсаций.
///
/// - Масштабы и веса curl-слоев: [psiCurlLow*], [psiCurlHi*].
/// - Настройки пульсаций: [psiCurlScalePulsate], [psiPulseScale/TimeFreq/Mod*].
/// - Веса итогов: [psiCurlLowWeight], [psiCurlHiBase], [psiGustWeight], [psiCurlWeightPulsate], [psiPulseWeight].
/// - Прочее: [gustExtentScale] влияет на радиус порывов; [psiPulsePhaseScale] сдвигает фазу модуляции.
class StreamTuning {
  const StreamTuning({
    this.psiCurlLowScaleX = 0.7, // масштаб низкочастотного curl по X
    this.psiCurlLowScaleY = 0.6, // масштаб низкочастотного curl по Y
    this.psiCurlLowTzScale = 0.8, // масштаб z для низкочастотного curl
    this.psiCurlLowWeight = 0.40, // вес низкочастотного curl
    this.psiCurlHiScaleX = 1.6, // масштаб высокочастотного curl по X
    this.psiCurlHiScaleY = 1.3, // масштаб высокочастотного curl по Y
    this.psiCurlHiTzScale = 1.4, // масштаб z для высокочастотного curl
    this.psiCurlHiPhaseOffset = 9.1, // фазовый сдвиг z для high curl
    this.psiCurlHiBase = 0.22, // базовый вес high curl
    this.psiCurlHiModAmp = 0.14, // амплитуда модуляции high curl
    this.psiCurlHiModFreq = 0.61, // частота модуляции high curl
    this.psiGustWeight = 0.65, // вес вклада порывов
    this.psiCurlScalePulsate = 0.9, // масштаб curl в пульсе
    this.psiPulseScale = 0.4, // масштаб psi-пульса по координатам
    this.psiPulseTimeFreq = 0.35, // частота по времени для psi-пульса
    this.psiPulseModAmp = 1.2, // амплитуда модуляции пульса
    this.psiPulseModFreq = 0.85, // частота модуляции пульса
    this.psiCurlWeightPulsate = 0.65, // вес curl в пульсе
    this.psiPulseWeight = 0.35, // вес пульса в пульсе
    this.gustExtentScale = 2.0, // масштаб радиуса порывов
    this.psiPulsePhaseScale = 0.7, // множитель фазы для модуляции пульса
  });

  final double psiCurlLowScaleX;
  final double psiCurlLowScaleY;
  final double psiCurlLowTzScale;
  final double psiCurlLowWeight;
  final double psiCurlHiScaleX;
  final double psiCurlHiScaleY;
  final double psiCurlHiTzScale;
  final double psiCurlHiPhaseOffset;
  final double psiCurlHiBase;
  final double psiCurlHiModAmp;
  final double psiCurlHiModFreq;
  final double psiGustWeight;
  final double psiCurlScalePulsate;
  final double psiPulseScale;
  final double psiPulseTimeFreq;
  final double psiPulseModAmp;
  final double psiPulseModFreq;
  final double psiCurlWeightPulsate;
  final double psiPulseWeight;
  final double gustExtentScale;
  final double psiPulsePhaseScale;

  factory StreamTuning.random(Random rng, {double variance = 0.25}) {
    double around(double base, double spread) =>
        base + (rng.nextDouble() * 2 - 1) * spread * variance;
    return StreamTuning(
      psiCurlLowScaleX: around(0.7, 0.15),
      psiCurlLowScaleY: around(0.6, 0.15),
      psiCurlLowTzScale: around(0.8, 0.2),
      psiCurlLowWeight: around(0.40, 0.1),
      psiCurlHiScaleX: around(1.6, 0.3),
      psiCurlHiScaleY: around(1.3, 0.25),
      psiCurlHiTzScale: around(1.4, 0.25),
      psiCurlHiPhaseOffset: around(9.1, 2.5),
      psiCurlHiBase: around(0.22, 0.07),
      psiCurlHiModAmp: around(0.14, 0.05),
      psiCurlHiModFreq: around(0.61, 0.15),
      psiGustWeight: around(0.65, 0.15),
      psiCurlScalePulsate: around(0.9, 0.2),
      psiPulseScale: around(0.4, 0.1),
      psiPulseTimeFreq: around(0.35, 0.1),
      psiPulseModAmp: around(1.2, 0.3),
      psiPulseModFreq: around(0.85, 0.2),
      psiCurlWeightPulsate: around(0.65, 0.15),
      psiPulseWeight: around(0.35, 0.1),
      gustExtentScale: around(2.0, 0.5),
      psiPulsePhaseScale: around(0.7, 0.2),
    );
  }
}

/// Тюнинг источников плотности и bulge.
///
/// - Частоты и масштабы по z для rho: [rhoFreqPulsate]/[rhoFreqNormal], [rhoTzScale*].
/// - Базовый сдвиг и усиление: [rhoCenterBias], [rhoPulsateGain].
/// - Настройки bulge: [bulgeFreq], [bulgeTzScale], [bulgePhaseOffset], [bulgeCenterBias].
class SourceTuning {
  const SourceTuning({
    this.rhoFreqPulsate = 0.2, // частота источников rho в пульсе
    this.rhoFreqNormal = 0.35, // частота источников rho в буре
    this.rhoTzScalePulsate = 1.0, // масштаб z источников rho в пульсе
    this.rhoTzScaleNormal = 1.3, // масштаб z источников rho в буре
    this.rhoCenterBias = 0.5, // смещение центра rho (делает нулевую среднюю)
    this.rhoPulsateGain = 1.5, // усиление rho в пульсе
    this.bulgeFreq = 0.12, // частота источников bulge
    this.bulgeTzScale = 1.1, // масштаб z источников bulge
    this.bulgePhaseOffset = 13.7, // фазовый сдвиг z для bulge
    this.bulgeCenterBias = 0.5, // смещение центра bulge (нормализация)
  });

  final double rhoFreqPulsate;
  final double rhoFreqNormal;
  final double rhoTzScalePulsate;
  final double rhoTzScaleNormal;
  final double rhoCenterBias;
  final double rhoPulsateGain;
  final double bulgeFreq;
  final double bulgeTzScale;
  final double bulgePhaseOffset;
  final double bulgeCenterBias;

  factory SourceTuning.random(Random rng, {double variance = 0.25}) {
    double around(double base, double spread) =>
        base + (rng.nextDouble() * 2 - 1) * spread * variance;
    return SourceTuning(
      rhoFreqPulsate: around(0.2, 0.06),
      rhoFreqNormal: around(0.35, 0.1),
      rhoTzScalePulsate: around(1.0, 0.2),
      rhoTzScaleNormal: around(1.3, 0.25),
      rhoCenterBias: around(0.5, 0.1),
      rhoPulsateGain: around(1.5, 0.4),
      bulgeFreq: around(0.12, 0.04),
      bulgeTzScale: around(1.1, 0.25),
      bulgePhaseOffset: around(13.7, 3.5),
      bulgeCenterBias: around(0.5, 0.1),
    );
  }
}

/// Тюнинг адвекции и затухания.
///
/// - [dissipation]: общий коэффициент затухания.
/// - Смешение источника/фона для rho: [rhoSourceMix], [rhoAmbientValue].
/// - Смешение для bulge: [bulgeAdvectFactor], [bulgeSourceMix], [bulgeAmbientValue], [bulgeAmbientMix].
class AdvectionTuning {
  const AdvectionTuning({
    this.dissipation = 0.99, // общее затухание
    this.rhoSourceMix = 0.18, // доля свежего источника rho
    this.rhoAmbientValue = 0.5, // фоновое значение rho при затухании
    this.bulgeAdvectFactor = 0.92, // доля переноса bulge
    this.bulgeSourceMix = 0.60, // доля источника bulge
    this.bulgeAmbientValue = 0.5, // фоновое значение bulge
    this.bulgeAmbientMix = 0.08, // доля фонового bulge при смешивании
  });

  final double dissipation;
  final double rhoSourceMix;
  final double rhoAmbientValue;
  final double bulgeAdvectFactor;
  final double bulgeSourceMix;
  final double bulgeAmbientValue;
  final double bulgeAmbientMix;

  factory AdvectionTuning.random(Random rng, {double variance = 0.25}) {
    double around(double base, double spread) =>
        base + (rng.nextDouble() * 2 - 1) * spread * variance;
    return AdvectionTuning(
      dissipation: around(0.99, 0.05),
      rhoSourceMix: around(0.18, 0.07),
      rhoAmbientValue: around(0.5, 0.15),
      bulgeAdvectFactor: around(0.92, 0.06),
      bulgeSourceMix: around(0.60, 0.15),
      bulgeAmbientValue: around(0.5, 0.15),
      bulgeAmbientMix: around(0.08, 0.03),
    );
  }
}
