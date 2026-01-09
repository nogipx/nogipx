import 'dart:async';

import 'package:rpc_dart/rpc_dart.dart';
import 'package:rpc_dart_transports/rpc_dart_transports.dart';
import 'package:screensaver_drift/server.dart';

@pragma('vm:entry-point')
@isolateManagerCustomWorker
FutureOr<void> rpcIsolateWorker(dynamic _) async {
  runRpcIsolateManagerWorker(driftWorkerEntrypoint);
}

void driftWorkerEntrypoint(
  IRpcTransport transport,
  Map<String, dynamic> customParams,
) {
  final responder = RpcResponderEndpoint(transport: transport);
  final isZeroCopy = customParams['isZeroCopy'] == true;
  responder.registerServiceContract(
    ScreensaverCompute(
      // randomTuning: true,
      dataTransferMode: isZeroCopy
          ? RpcDataTransferMode.zeroCopy
          : RpcDataTransferMode.codec,
    ),
  );
  responder.start();
}
