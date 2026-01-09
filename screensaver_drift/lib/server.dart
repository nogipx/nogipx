// screensaver_compute.dart
//
// Drop-in replacement for your current responder file.
// Changes vs your current version:
// - _fillPsiAndHeight now uses 3D value-noise + fbm (time is a 3rd dimension)
//   -> looks more “alive” than just scrolling x/y.
// - domain warp is also 3D.
// - psi->flow uses size-scaled central differences (flow strength stable vs grid size).
// - keeps your old 2D noise helpers (optional / debug), but main path uses 3D.
//
// Requires: dto.dart contains DriftFieldRequest / DriftFieldFrame, and rpc_dart generator parts.

import 'dart:math';

import 'package:rpc_dart/rpc_dart.dart';
import 'package:uuid/uuid.dart';

import 'dto.dart';
import 'graphics/_index.dart';

part 'server.g.dart';

BufferTransferMode _bufferModeFromRpc(RpcDataTransferMode mode) {
  return mode == RpcDataTransferMode.zeroCopy
      ? BufferTransferMode.zeroCopy
      : BufferTransferMode.copy;
}

@RpcService(
  name: 'ScreensaverCompute',
  description: 'Контракт для вычислений анимации',
)
abstract interface class IScreensaverCompute {
  /// Генерирует поток кадров поля для клиента.
  ///
  /// Используйте этот метод, когда фронтенд хочет получать кадры непрерывно
  /// через RPC, сохраняя их в порядке и с учетом отмены через [RpcContext].
  @RpcMethod.serverStream(name: 'framesStream')
  Stream<DriftFieldFrame> framesStream(
    DriftFieldRequest request, {
    RpcContext? context,
  });
}

/// Реализация RPC-сервиса, которая рассчитывает кадровые поля в изоляте.
///
/// Создавайте экземпляр для каждой сессии расчета; удерживает ключ потока, чтобы
/// отменять устаревшие запросы и не смешивать кадры между подписками.
final class ScreensaverCompute extends ScreensaverComputeResponder {
  final int? seed;
  final bool randomTuning;

  ScreensaverCompute({
    super.dataTransferMode,
    this.seed,
    this.randomTuning = false,
  });

  String _framesStreamKey = '';

  @override
  /// Запускает расчет анимации и стримит кадры, пока подписка актуальна.
  ///
  /// Подписка завершается, если клиент отменил запрос в [context] или если
  /// появился новый подписчик и `_framesStreamKey` поменялся.
  Stream<DriftFieldFrame> framesStream(
    DriftFieldRequest request, {
    RpcContext? context,
  }) async* {
    final localStreamKey = const Uuid().v4();
    _framesStreamKey = localStreamKey;
    final w = request.w;
    final h = request.h;
    final n = w * h;

    final psi = Float32List(n);
    final flowX = Float32List(n);
    final flowY = Float32List(n);
    final height = Float32List(n);
    final rho = Float32List(n); // advected density (“breathing voids”)
    final rhoTmp = Float32List(n);
    final bulge = Float32List(n);
    final bulgeTmp = Float32List(n);

    final dt = 1.0 / max(1, request.fps);
    var t = 0.0;

    while (true) {
      if (context?.cancellationToken?.isCancelled == true) {
        return;
      }
      if (localStreamKey != _framesStreamKey) {
        return;
      }

      final tuning = randomTuning
          ? FieldTuning.random(seed: seed)
          : FieldTuning();
      final config = FieldConfig.fromRequest(request, tuning: tuning);
      final transferMode = _bufferModeFromRpc(dataTransferMode);
      fillFields(
        config,
        t,
        dt,
        psi,
        flowX,
        flowY,
        rho,
        rhoTmp,
        height,
        bulge,
        bulgeTmp,
      );

      final payload = buildFieldFrame(
        transferMode,
        w,
        h,
        t,
        flowX,
        flowY,
        height,
        bulge,
      );
      yield toDriftFieldFrame(payload);

      t += dt;
      await Future<void>.delayed(Duration(microseconds: (dt * 1e6).round()));
    }
  }
}
