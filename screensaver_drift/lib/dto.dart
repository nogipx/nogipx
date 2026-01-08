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

  /// Случайный набор параметров для генерации разнообразных паттернов.
  factory DriftFieldRequest.random(Random rng) {
    double lerp(double a, double b) => a + (b - a) * rng.nextDouble();
    int lerpInt(int a, int b) => a + (rng.nextDouble() * (b - a)).round();

    final w = lerpInt(150, 250);
    final h = (w * 9 / 16 / 1.5).round();

    return DriftFieldRequest(
      w: w,
      h: h,
      fps: 60,
      seed: rng.nextInt(0x7fffffff),
      baseFreq: lerp(0.024, 0.052),
      warpFreq: lerp(0.12, 0.16),
      warpAmp: lerp(8.0, 18.0),
      speedX: lerp(0, 3),
      speedY: lerp(0, 3),
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
  };

  factory DriftFieldRequest.fromJson(Map<String, dynamic> json) {
    double d(String k) => (json[k] as num).toDouble();
    int i(String k) => (json[k] as num).toInt();
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
    );
  }
}

/// Один “кадр” полей. Все большие массивы — только TransferableTypedData.
class DriftFieldFrame implements IRpcSerializable {
  final int w;
  final int h;
  final double t; // время симуляции в секундах

  /// Float32 (w*h) — divergence-free flow, компоненты.
  /// Тип зависит от RpcDataTransferMode:
  /// - zeroCopy: TransferableTypedData
  /// - codec: Uint8List / List<int>
  final Object flowX; // dpsi/dy
  final Object flowY; // -dpsi/dx

  /// Float32 (w*h) — “высота/длина” волосков (h-field).
  /// Тип зависит от RpcDataTransferMode:
  /// - zeroCopy: TransferableTypedData
  /// - codec: Uint8List / List<int>
  final Object height;

  /// Float32 (w*h) — дополнительное поле “bulge” для вариации длины.
  /// Тип зависит от RpcDataTransferMode:
  /// - zeroCopy: TransferableTypedData
  /// - codec: Uint8List / List<int>
  final Object bulge;

  const DriftFieldFrame({
    required this.w,
    required this.h,
    required this.t,
    required this.flowX,
    required this.flowY,
    required this.height,
    required this.bulge,
  });

  @override
  Map<String, dynamic> toJson() => {
        'w': w,
        'h': h,
        't': t,
        'flowX': _encodeBytes(flowX),
        'flowY': _encodeBytes(flowY),
        'height': _encodeBytes(height),
        'bulge': _encodeBytes(bulge),
      };

  factory DriftFieldFrame.fromJson(Map<String, dynamic> json) {
    Uint8List b64(String key) => _decodeBytes(json[key]!);
    return DriftFieldFrame(
      w: (json['w'] as num).toInt(),
      h: (json['h'] as num).toInt(),
      t: (json['t'] as num).toDouble(),
      flowX: b64('flowX'),
      flowY: b64('flowY'),
      height: b64('height'),
      bulge: b64('bulge'),
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
    throw ArgumentError('Unsupported flow type: ${source.runtimeType}');
  }

  static Uint8List _decodeBytes(Object source) {
    if (source is Uint8List) return source;
    if (source is List<int>) return Uint8List.fromList(source);
    if (source is String) return base64Decode(source);
    throw ArgumentError('Unsupported encoded type: ${source.runtimeType}');
  }
}
