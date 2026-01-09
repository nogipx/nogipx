import 'dart:convert';
import 'dart:isolate';
import 'dart:math';

import 'package:rpc_dart/rpc_dart.dart';

/// Параметры coarse-поля (это НЕ "волоски", это сетка полей).
class DriftFieldRequest implements IRpcSerializable {
  /// Ширина coarse-сетки.
  final int w;

  /// Высота coarse-сетки.
  final int h;

  /// Частота обновления поля (кадров в секунду).
  final int fps;

  /// Сид шума.
  final int seed;

  /// Базовая частота шума (drift шаг).
  final double baseFreq;

  /// Частота домен-варпа (чем выше, тем мельче изгибы).
  final double warpFreq;

  /// Амплитуда домен-варпа (силы изгиба).
  final double warpAmp;

  /// Скорость дрейфа по X (в UV).
  final double speedX;

  /// Скорость дрейфа по Y (в UV).
  final double speedY;

  /// Идентификатор стратегии (например, drift / pulsate / fire).
  final String strategy;

  /// Произвольные параметры для выбранной стратегии.
  final Map<String, dynamic>? strategyParams;

  /// Случайный набор параметров (heavy).
  factory DriftFieldRequest.random(Random rng) {
    double lerp(double a, double b) => a + (b - a) * rng.nextDouble();
    int lerpInt(int a, int b) => a + (rng.nextDouble() * (b - a)).round();

    final w = lerpInt(220, 320);
    final h = (w * 9 / 16).round();

    return DriftFieldRequest(
      w: w,
      h: h,
      fps: 60,
      seed: rng.nextInt(0x7fffffff),
      baseFreq: lerp(0.018, 0.030),
      warpFreq: lerp(0.03, 0.06),
      warpAmp: lerp(8.0, 16.0),
      speedX: lerp(-1.5, 1.5),
      speedY: lerp(-1.5, 1.5),
      strategy: 'pulsate',
    );
  }

  /// Лёгкие настройки для Web.
  factory DriftFieldRequest.randomWeb(Random rng) {
    double lerp(double a, double b) => a + (b - a) * rng.nextDouble();
    int lerpInt(int a, int b) => a + (rng.nextDouble() * (b - a)).round();

    final w = 150;
    final h = (w * 9 / 16 / 2).round();

    return DriftFieldRequest(
      w: w,
      h: h,
      fps: 60,
      seed: rng.nextInt(0x7fffffff),
      baseFreq: lerp(0.016, 0.028),
      warpFreq: lerp(0.02, 0.05),
      warpAmp: lerp(5.5, 10.0),
      speedX: lerp(-1.0, 1.0),
      speedY: lerp(-1.0, 1.0),
      strategy: 'drift',
    );
  }

  /// Настройки для огненной симуляции: вытянутая сетка и устойчивый апдрафт.
  factory DriftFieldRequest.fire(Random rng) {
    double lerp(double a, double b) => a + (b - a) * rng.nextDouble();
    int lerpInt(int a, int b) => a + (rng.nextDouble() * (b - a)).round();

    final w = lerpInt(120, 180);
    final h = (w * 1.6).round();

    return DriftFieldRequest(
      w: w,
      h: h,
      fps: 60,
      seed: rng.nextInt(0x7fffffff),
      baseFreq: lerp(0.020, 0.030),
      warpFreq: lerp(0.03, 0.055),
      warpAmp: lerp(6.5, 11.0),
      speedX: lerp(-0.35, 0.35),
      speedY: lerp(-1.2, -0.6),
      strategy: 'fire',
    );
  }

  const DriftFieldRequest({
    required this.w,
    required this.h,
    required this.fps,
    required this.seed,
    required this.baseFreq,
    required this.warpFreq,
    required this.warpAmp,
    required this.speedX,
    required this.speedY,
    required this.strategy,
    this.strategyParams,
  });

  @override
  Map<String, dynamic> toJson() => {
    'w': w,
    'h': h,
    'fps': fps,
    'seed': seed,
    'baseFreq': baseFreq,
    'warpFreq': warpFreq,
    'warpAmp': warpAmp,
    'speedX': speedX,
    'speedY': speedY,
    'strategy': strategy,
    if (strategyParams != null) 'strategyParams': strategyParams,
  };

  factory DriftFieldRequest.fromJson(Map<String, dynamic> json) {
    double d(String k) => (json[k] as num).toDouble();
    int i(String k) => (json[k] as num).toInt();
    Map<String, dynamic>? params() {
      final raw = json['strategyParams'];
      if (raw is Map) {
        return Map<String, dynamic>.from(raw);
      }
      return null;
    }
    return DriftFieldRequest(
      w: i('w'),
      h: i('h'),
      fps: i('fps'),
      seed: i('seed'),
      baseFreq: d('baseFreq'),
      warpFreq: d('warpFreq'),
      warpAmp: d('warpAmp'),
      speedX: d('speedX'),
      speedY: d('speedY'),
      strategy: (json['strategy'] as String?) ?? 'drift',
      strategyParams: params(),
    );
  }
}

/// Один “кадр” полей. Все большие массивы — только TransferableTypedData.
class DriftFieldFrame implements IRpcSerializable {
  final int w;
  final int h;
  final double t; // время симуляции в секундах
  final String kind; // тип кадра, например standard
  final Map<String, Object> channels; // произвольные каналы (Float32 и т.п.)
  final Map<String, dynamic>? meta;

  const DriftFieldFrame({
    required this.w,
    required this.h,
    required this.t,
    required this.kind,
    required this.channels,
    this.meta,
  });

  @override
  Map<String, dynamic> toJson() => {
    'w': w,
    'h': h,
    't': t,
    'kind': kind,
    'channels': {
      for (final e in channels.entries) e.key: _encodeBytes(e.value),
    },
    if (meta != null) 'meta': meta,
  };

  factory DriftFieldFrame.fromJson(Map<String, dynamic> json) {
    final Map<String, Object> decodedChannels = {};
    final rawChannels = json['channels'] as Map<String, dynamic>? ?? {};
    rawChannels.forEach((key, value) {
      decodedChannels[key] = _decodeBytes(value);
    });
    return DriftFieldFrame(
      w: (json['w'] as num).toInt(),
      h: (json['h'] as num).toInt(),
      t: (json['t'] as num).toDouble(),
      kind: json['kind'] as String? ?? 'standard',
      channels: decodedChannels,
      meta: json['meta'] as Map<String, dynamic>?,
    );
  }

  static Uint8List _ttdToBytes(TransferableTypedData ttd) {
    final materialized = ttd.materialize();
    return materialized.asUint8List();
  }

  static String _encodeBytes(Object source) {
    if (source is TransferableTypedData) {
      return base64Encode(_ttdToBytes(source));
    }
    if (source is Uint8List) {
      return base64Encode(source);
    }
    if (source is List<int>) {
      return base64Encode(Uint8List.fromList(source));
    }
    if (source is Float32List) {
      return base64Encode(source.buffer.asUint8List());
    }
    throw ArgumentError('Unsupported channel type: ${source.runtimeType}');
  }

  static Uint8List _decodeBytes(Object source) {
    if (source is Uint8List) return source;
    if (source is List<int>) return Uint8List.fromList(source);
    if (source is String) return base64Decode(source);
    if (source is TransferableTypedData) return _ttdToBytes(source);
    throw ArgumentError('Unsupported encoded type: ${source.runtimeType}');
  }
}
