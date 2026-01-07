import 'dart:isolate';

import 'package:flutter/foundation.dart';
import 'package:rpc_dart/rpc_dart.dart';
import 'package:rpc_dart_transports/rpc_dart_transports.dart';
import 'package:screensaver_drift/server.dart';

import 'dto.dart';
import 'isolate_worker.dart';

final class DriftWorkerClient {
  DriftWorkerClient._(this._kill, this._endpoint, this._api);

  final void Function() _kill;
  final RpcCallerEndpoint _endpoint;
  final ScreensaverComputeCaller _api;

  void cancelStream() {
    _api.cancelMethod(ScreensaverComputeNames.framesStream);
  }

  static Future<DriftWorkerClient> spawn() async {
    final isZeroCopy = !kIsWasm && !kIsWeb;

    final spawned = await RpcIsolateTransport.spawn(
      entrypoint: driftWorkerEntrypoint,
      isolateId: 'drift',
      debugName: 'drift_worker',
      customParams: {'isZeroCopy': isZeroCopy},
    );

    final endpoint = RpcCallerEndpoint(transport: spawned.transport);
    final api = ScreensaverComputeCaller(
      endpoint,
      dataTransferMode: isZeroCopy
          ? RpcDataTransferMode.zeroCopy
          : RpcDataTransferMode.codec,
    );
    return DriftWorkerClient._(spawned.kill, endpoint, api);
  }

  Stream<DriftFieldFrame> stream(DriftFieldRequest req) =>
      _api.framesStream(req);

  Future<void> dispose() async {
    await _endpoint.close();
    _kill();
  }

  static Float32List materializeF32(Object source) {
    if (source is List<int>) {
      final u8 = Uint8List.fromList(source);
      return u8.buffer.asFloat32List(0, u8.lengthInBytes ~/ 4);
    }

    if (source is Uint8List) {
      return source.buffer.asFloat32List(
        source.offsetInBytes,
        source.lengthInBytes ~/ 4,
      );
    }
    if (source is TransferableTypedData) {
      final Object m = source.materialize();

      if (m is ByteBuffer) {
        // Dart SDK, где materialize() -> ByteBuffer
        return m.asFloat32List();
      }

      if (m is ByteData) {
        // Dart SDK, где materialize() -> ByteData
        final u8 = m.buffer.asUint8List(m.offsetInBytes, m.lengthInBytes);
        return u8.buffer.asFloat32List(u8.offsetInBytes, u8.lengthInBytes ~/ 4);
      }
    }

    if (source is ByteBuffer) {
      return source.asFloat32List();
    }

    if (source is ByteData) {
      final u8 = source.buffer.asUint8List(
        source.offsetInBytes,
        source.lengthInBytes,
      );
      return u8.buffer.asFloat32List(u8.offsetInBytes, u8.lengthInBytes ~/ 4);
    }

    throw StateError('Unexpected flow type: ${source.runtimeType}');
  }
}
