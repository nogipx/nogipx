import 'package:rpc_dart/rpc_dart.dart';

import 'data_service_repositories.dart';
import 'generator.dart';
import 'models.dart';

part 'resume_rpc_contract.g.dart';

@RpcService(
  name: 'ResumeService',
  transferMode: RpcDataTransferMode.codec,
  description: 'Resume generation service',
)
abstract class IResumeContract {
  @RpcMethod(
    name: 'generateResume',
    kind: RpcMethodKind.unary,
    description: 'Generate resume for variant',
  )
  Future<GenerateResumeResponse> generateResume(
    GenerateResumeRequest request, {
    RpcContext? context,
  });
}

class GenerateResumeRequest implements IRpcSerializable {
  GenerateResumeRequest({required this.variantId});

  final String variantId;

  factory GenerateResumeRequest.fromJson(Map<String, dynamic> json) {
    return GenerateResumeRequest(variantId: json['variantId'] as String? ?? '');
  }

  @override
  Map<String, dynamic> toJson() => {'variantId': variantId};
}

class GenerateResumeResponse implements IRpcSerializable {
  GenerateResumeResponse({required this.resume});

  final ResumeDocument resume;

  factory GenerateResumeResponse.fromJson(Map<String, dynamic> json) {
    return GenerateResumeResponse(
      resume: ResumeDocument.fromJson(
        Map<String, dynamic>.from(json['resume'] as Map),
      ),
    );
  }

  @override
  Map<String, dynamic> toJson() => {'resume': resume.toJson()};
}

/// Concrete responder that delegates to the business-layer generator.
class ResumeServiceResponder extends ResumeContractResponder {
  ResumeServiceResponder({
    this.generator,
    this.dataRepository,
    String? serviceNameOverride,
    RpcDataTransferMode dataTransferMode = RpcDataTransferMode.codec,
  }) : assert(
         generator != null || dataRepository != null,
         'Provide either generator or dataRepository',
       ),
       super(
         serviceNameOverride: serviceNameOverride,
         dataTransferMode: dataTransferMode,
       );

  final ResumeGenerator? generator;
  final DataServiceResumeRepository? dataRepository;

  @override
  Future<GenerateResumeResponse> generateResume(
    GenerateResumeRequest request, {
    RpcContext? context,
  }) async {
    final effectiveGenerator = await _resolveGenerator();
    final doc = effectiveGenerator.generate(request.variantId);
    return GenerateResumeResponse(resume: doc);
  }

  Future<ResumeGenerator> _resolveGenerator() async {
    if (generator != null) return generator!;
    final dataRepo = dataRepository;
    if (dataRepo == null) {
      throw StateError('No generator or dataRepository provided');
    }
    final snapshot = await dataRepo.getSnapshot();
    return ResumeGenerator(snapshot);
  }
}
