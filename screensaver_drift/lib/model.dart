import 'dart:typed_data';

import 'package:equatable/equatable.dart';
import 'package:screensaver_drift/dto.dart';
import 'package:screensaver_drift/worker.dart';

/// Данные, которые реально нужны painter'у (уже materialize'нутые).
class DriftFrameData with EquatableMixin {
  final int w;
  final int h;
  final double t;
  final String kind;
  final Map<String, Float32List> channels;
  final Map<String, dynamic>? meta;

  const DriftFrameData({
    required this.w,
    required this.h,
    required this.t,
    required this.kind,
    required this.channels,
    required this.meta,
  });

  @override
  List<Object?> get props => [w, h, t, kind, channels];

  factory DriftFrameData.empty() {
    return DriftFrameData(
      w: 0,
      h: 0,
      t: 0,
      kind: 'standard',
      channels: const <String, Float32List>{},
      meta: const <String, dynamic>{},
    );
  }
  factory DriftFrameData.fromRawFrame(DriftFieldFrame frame) {
    final decoded = <String, Float32List>{
      for (final entry in frame.channels.entries)
        entry.key: DriftWorkerClient.materializeF32(entry.value),
    };
    return DriftFrameData(
      w: frame.w,
      h: frame.h,
      t: frame.t,
      kind: frame.kind,
      channels: decoded,
      meta: frame.meta,
    );
  }

  Float32List? channel(String name) => channels[name];
}

/// Ресайклер для materialize без постоянных выделений: копирует входные каналы
/// во внутренние буферы, переиспользуя их между кадрами.
class FrameRecycler {
  final Map<String, Float32List> _buffers = {};

  DriftFrameData materialize(DriftFieldFrame frame) {
    final channels = <String, Float32List>{};
    frame.channels.forEach((key, value) {
      final src = DriftWorkerClient.materializeF32(value);
      final len = src.length;
      final existing = _buffers[key];
      final dst = (existing != null && existing.length == len)
          ? existing
          : (_buffers[key] = Float32List(len));
      dst.setAll(0, src);
      channels[key] = dst;
    });
    return DriftFrameData(
      w: frame.w,
      h: frame.h,
      t: frame.t,
      kind: frame.kind,
      channels: channels,
      meta: frame.meta,
    );
  }
}
