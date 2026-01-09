part of '_index.dart';

/// Режим передачи буферов между потоками/изолятами.
enum BufferTransferMode { zeroCopy, copy }

/// Универсальное представление кадра поля без привязки к RPC-слою.
///
/// * [w]/[h]: размер сетки.
/// * [t]: время кадра.
/// * [flowX]/[flowY]: буферы скоростей.
/// * [height]: высота/интенсивность.
/// * [bulge]: буфер пузырей/длины волосков.
class FieldFrame {
  FieldFrame({
    required this.w,
    required this.h,
    required this.t,
    required this.flowX,
    required this.flowY,
    required this.height,
    required this.bulge,
  });

  final int w;
  final int h;
  final double t;
  final Object flowX;
  final Object flowY;
  final Object height;
  final Object bulge;
}

/// Упаковывает буферы поля в переносимый [FieldFrame] с выбранным режимом.
///
/// Используйте для сборки результата после заполнения Float32List массивов
/// вне контекста конкретного RPC-протокола. [mode] задает zero-copy или копию;
/// [w]/[h] — размер сетки; [t] — время кадра; остальные аргументы — буферы.
FieldFrame buildFieldFrame(
  BufferTransferMode mode,
  int w,
  int h,
  double t,
  Float32List flowX,
  Float32List flowY,
  Float32List height,
  Float32List bulge,
) {
  // Формирует переносимый объект поля, выбирая между zero-copy и копией.
  // Используйте zero-copy для локальных изолятов, иначе безопасную копию через
  // Uint8List, чтобы избежать проблем с владением буфера.
  Object pack(Float32List src) {
    if (mode == BufferTransferMode.zeroCopy) {
      return TransferableTypedData.fromList([src.buffer.asUint8List()]);
    }
    return Uint8List.fromList(src.buffer.asUint8List());
  }

  return FieldFrame(
    w: w,
    h: h,
    t: t,
    flowX: pack(flowX),
    flowY: pack(flowY),
    height: pack(height),
    bulge: pack(bulge),
  );
}

/// Конвертирует универсальный [FieldFrame] в RPC DTO проекта.
DriftFieldFrame toDriftFieldFrame(FieldFrame frame) => DriftFieldFrame(
  w: frame.w,
  h: frame.h,
  t: frame.t,
  flowX: frame.flowX,
  flowY: frame.flowY,
  height: frame.height,
  bulge: frame.bulge,
);
