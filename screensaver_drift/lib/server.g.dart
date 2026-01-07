// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'server.dart';

// **************************************************************************
// RpcDartGenerator
// **************************************************************************

// ignore_for_file: type=lint, unused_element

class ScreensaverComputeNames {
  const ScreensaverComputeNames._();
  static const service = 'ScreensaverCompute';
  static String instance(String suffix) => '\$service\_$suffix';
  static const framesStream = 'framesStream';
}

final class ScreensaverComputeCaller extends RpcCallerContract
    implements IScreensaverCompute {
  ScreensaverComputeCaller(
    RpcCallerEndpoint endpoint, {
    String? serviceNameOverride,
    RpcDataTransferMode dataTransferMode = RpcDataTransferMode.auto,
  }) : super(
         serviceNameOverride ?? ScreensaverComputeNames.service,
         endpoint,
         dataTransferMode: dataTransferMode,
       );

  @override
  Stream<DriftFieldFrame> framesStream(
    DriftFieldRequest request, {
    RpcContext? context,
  }) {
    return callServerStream<DriftFieldRequest, DriftFieldFrame>(
      methodName: ScreensaverComputeNames.framesStream,
      requestCodec: const RpcCodec<DriftFieldRequest>.withDecoder(
        DriftFieldRequest.fromJson,
      ),
      responseCodec: const RpcCodec<DriftFieldFrame>.withDecoder(
        DriftFieldFrame.fromJson,
      ),
      request: request,
      context: context,
    );
  }
}

abstract class ScreensaverComputeResponder extends RpcResponderContract
    implements IScreensaverCompute {
  ScreensaverComputeResponder({
    String? serviceNameOverride,
    RpcDataTransferMode dataTransferMode = RpcDataTransferMode.auto,
  }) : super(
         serviceNameOverride ?? ScreensaverComputeNames.service,
         dataTransferMode: dataTransferMode,
       );

  @override
  void setup() {
    addServerStreamMethod<DriftFieldRequest, DriftFieldFrame>(
      methodName: ScreensaverComputeNames.framesStream,
      handler: framesStream,
      requestCodec: const RpcCodec<DriftFieldRequest>.withDecoder(
        DriftFieldRequest.fromJson,
      ),
      responseCodec: const RpcCodec<DriftFieldFrame>.withDecoder(
        DriftFieldFrame.fromJson,
      ),
    );
  }
}
