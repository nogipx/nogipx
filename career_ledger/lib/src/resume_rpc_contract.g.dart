// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'resume_rpc_contract.dart';

// **************************************************************************
// RpcDartGenerator
// **************************************************************************

// ignore_for_file: type=lint, unused_element

class ResumeContractNames {
  const ResumeContractNames._();
  static const service = 'ResumeService';
  static String instance(String suffix) => '\$service\_$suffix';
  static const generateResume = 'generateResume';
}

final class ResumeContractCaller extends RpcCallerContract
    implements IResumeContract {
  ResumeContractCaller(
    RpcCallerEndpoint endpoint, {
    String? serviceNameOverride,
    RpcDataTransferMode dataTransferMode = RpcDataTransferMode.codec,
  }) : super(
         serviceNameOverride ?? ResumeContractNames.service,
         endpoint,
         dataTransferMode: dataTransferMode,
       );

  @override
  Future<GenerateResumeResponse> generateResume(
    GenerateResumeRequest request, {
    RpcContext? context,
  }) {
    return callUnary<GenerateResumeRequest, GenerateResumeResponse>(
      methodName: ResumeContractNames.generateResume,
      requestCodec: const RpcCodec<GenerateResumeRequest>.withDecoder(
        GenerateResumeRequest.fromJson,
      ),
      responseCodec: const RpcCodec<GenerateResumeResponse>.withDecoder(
        GenerateResumeResponse.fromJson,
      ),
      request: request,
      context: context,
    );
  }
}

abstract class ResumeContractResponder extends RpcResponderContract
    implements IResumeContract {
  ResumeContractResponder({
    String? serviceNameOverride,
    RpcDataTransferMode dataTransferMode = RpcDataTransferMode.codec,
  }) : super(
         serviceNameOverride ?? ResumeContractNames.service,
         dataTransferMode: dataTransferMode,
       );

  @override
  void setup() {
    addUnaryMethod<GenerateResumeRequest, GenerateResumeResponse>(
      methodName: ResumeContractNames.generateResume,
      handler: generateResume,
      description: 'Generate resume for variant',
      requestCodec: const RpcCodec<GenerateResumeRequest>.withDecoder(
        GenerateResumeRequest.fromJson,
      ),
      responseCodec: const RpcCodec<GenerateResumeResponse>.withDecoder(
        GenerateResumeResponse.fromJson,
      ),
    );
  }
}
