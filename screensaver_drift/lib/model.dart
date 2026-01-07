import 'dart:typed_data';

import 'package:equatable/equatable.dart';
import 'package:screensaver_drift/dto.dart';
import 'package:screensaver_drift/worker.dart';

/// Данные, которые реально нужны painter'у (уже materialize'нутые).
class DriftFrameData with EquatableMixin {
  final int w;
  final int h;
  final double t;
  final Float32List flowX;
  final Float32List flowY;
  final Float32List height;

  const DriftFrameData({
    required this.w,
    required this.h,
    required this.t,
    required this.flowX,
    required this.flowY,
    required this.height,
  });

  @override
  List<Object?> get props => [w, h, t, flowX, flowY, height];

  factory DriftFrameData.empty() {
    return DriftFrameData(
      w: 0,
      h: 0,
      t: 0,
      flowX: Float32List(0),
      flowY: Float32List(0),
      height: Float32List(0),
    );
  }
  factory DriftFrameData.fromRawFrame(DriftFieldFrame frame) {
    return DriftFrameData(
      w: frame.w,
      h: frame.h,
      t: frame.t,
      flowX: DriftWorkerClient.materializeF32(frame.flowX),
      flowY: DriftWorkerClient.materializeF32(frame.flowY),
      height: DriftWorkerClient.materializeF32(frame.height),
    );
  }
}
