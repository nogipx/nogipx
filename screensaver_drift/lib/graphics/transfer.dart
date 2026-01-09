part of '_index.dart';

/// Режим передачи буферов между потоками/изолятами.
enum BufferTransferMode { zeroCopy, copy }

/// Универсальное представление кадра поля без привязки к RPC-слою.
///
/// * [kind]: тип кадра (например, `standard`).
/// * [channels]: произвольные каналы (обычно Float32 буферы).
/// * [meta]: дополнительная метаинформация (цвета, gamma и т.п.).
class FieldFrame {
  FieldFrame({
    required this.w,
    required this.h,
    required this.t,
    required this.kind,
    required this.channels,
    this.meta,
  });

  final int w;
  final int h;
  final double t;
  final String kind;
  final Map<String, Object> channels;
  final Map<String, dynamic>? meta;
}

/// Упаковывает буферы поля в переносимый [FieldFrame] с выбранным режимом.
///
/// Используйте для сборки результата после заполнения Float32List массивов
/// вне контекста конкретного RPC-протокола. [mode] задает zero-copy или копию;
/// [channels] — произвольные именованные каналы (обычно Float32List).
FieldFrame buildFieldFrame(
  BufferTransferMode mode,
  int w,
  int h,
  double t, {
  String kind = 'standard',
  required Map<String, Float32List> channels,
  Map<String, dynamic>? meta,
}) {
  Object pack(Float32List src) {
    if (mode == BufferTransferMode.zeroCopy) {
      return TransferableTypedData.fromList([src.buffer.asUint8List()]);
    }
    return Uint8List.fromList(src.buffer.asUint8List());
  }

  final packed = <String, Object>{
    for (final entry in channels.entries) entry.key: pack(entry.value),
  };

  return FieldFrame(
    w: w,
    h: h,
    t: t,
    kind: kind,
    channels: packed,
    meta: meta,
  );
}

/// Конвертирует универсальный [FieldFrame] в RPC DTO проекта.
DriftFieldFrame toDriftFieldFrame(FieldFrame frame) => DriftFieldFrame(
  w: frame.w,
  h: frame.h,
  t: frame.t,
  kind: frame.kind,
  channels: frame.channels,
  meta: frame.meta,
);
