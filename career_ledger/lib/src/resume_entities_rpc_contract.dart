import 'package:rpc_dart/rpc_dart.dart';
import 'package:rpc_dart_data/rpc_dart_data.dart';

import 'models.dart';

part 'resume_entities_rpc_contract.g.dart';

enum ResumeEntity {
  profile('profiles'),
  experience('experiences'),
  project('projects'),
  skill('skills'),
  education('education'),
  bullet('bullets'),
  mediaAsset('media_assets'),
  variant('resume_variants');

  const ResumeEntity(this.collection);
  final String collection;
}

@RpcService(
  name: 'ResumeEntitiesService',
  transferMode: RpcDataTransferMode.codec,
  description:
      'Typed CRUD for resume entities (profiles, experience, projects, etc.)',
)
abstract class IResumeEntitiesContract {
  @RpcMethod(name: 'createProfile', kind: RpcMethodKind.unary)
  Future<Profile> createProfile(Profile request, {RpcContext? context});

  @RpcMethod(name: 'updateProfile', kind: RpcMethodKind.unary)
  Future<Profile> updateProfile(Profile request, {RpcContext? context});

  @RpcMethod(name: 'patchProfile', kind: RpcMethodKind.unary)
  Future<Profile> patchProfile(
    PatchProfileRequest request, {
    RpcContext? context,
  });

  @RpcMethod(name: 'deleteProfile', kind: RpcMethodKind.unary)
  Future<DeleteRecordResponse> deleteProfile(
    DeleteEntityRequest request, {
    RpcContext? context,
  });

  @RpcMethod(name: 'createExperience', kind: RpcMethodKind.unary)
  Future<Experience> createExperience(
    Experience request, {
    RpcContext? context,
  });

  @RpcMethod(name: 'updateExperience', kind: RpcMethodKind.unary)
  Future<Experience> updateExperience(
    Experience request, {
    RpcContext? context,
  });

  @RpcMethod(name: 'patchExperience', kind: RpcMethodKind.unary)
  Future<Experience> patchExperience(
    PatchExperienceRequest request, {
    RpcContext? context,
  });

  @RpcMethod(name: 'deleteExperience', kind: RpcMethodKind.unary)
  Future<DeleteRecordResponse> deleteExperience(
    DeleteEntityRequest request, {
    RpcContext? context,
  });

  @RpcMethod(name: 'createProject', kind: RpcMethodKind.unary)
  Future<Project> createProject(Project request, {RpcContext? context});

  @RpcMethod(name: 'updateProject', kind: RpcMethodKind.unary)
  Future<Project> updateProject(Project request, {RpcContext? context});

  @RpcMethod(name: 'patchProject', kind: RpcMethodKind.unary)
  Future<Project> patchProject(
    PatchProjectRequest request, {
    RpcContext? context,
  });

  @RpcMethod(name: 'deleteProject', kind: RpcMethodKind.unary)
  Future<DeleteRecordResponse> deleteProject(
    DeleteEntityRequest request, {
    RpcContext? context,
  });

  @RpcMethod(name: 'createSkill', kind: RpcMethodKind.unary)
  Future<Skill> createSkill(Skill request, {RpcContext? context});

  @RpcMethod(name: 'updateSkill', kind: RpcMethodKind.unary)
  Future<Skill> updateSkill(Skill request, {RpcContext? context});

  @RpcMethod(name: 'patchSkill', kind: RpcMethodKind.unary)
  Future<Skill> patchSkill(PatchSkillRequest request, {RpcContext? context});

  @RpcMethod(name: 'deleteSkill', kind: RpcMethodKind.unary)
  Future<DeleteRecordResponse> deleteSkill(
    DeleteEntityRequest request, {
    RpcContext? context,
  });

  @RpcMethod(name: 'createEducation', kind: RpcMethodKind.unary)
  Future<Education> createEducation(Education request, {RpcContext? context});

  @RpcMethod(name: 'updateEducation', kind: RpcMethodKind.unary)
  Future<Education> updateEducation(Education request, {RpcContext? context});

  @RpcMethod(name: 'patchEducation', kind: RpcMethodKind.unary)
  Future<Education> patchEducation(
    PatchEducationRequest request, {
    RpcContext? context,
  });

  @RpcMethod(name: 'deleteEducation', kind: RpcMethodKind.unary)
  Future<DeleteRecordResponse> deleteEducation(
    DeleteEntityRequest request, {
    RpcContext? context,
  });

  @RpcMethod(name: 'createBullet', kind: RpcMethodKind.unary)
  Future<Bullet> createBullet(Bullet request, {RpcContext? context});

  @RpcMethod(name: 'updateBullet', kind: RpcMethodKind.unary)
  Future<Bullet> updateBullet(Bullet request, {RpcContext? context});

  @RpcMethod(name: 'patchBullet', kind: RpcMethodKind.unary)
  Future<Bullet> patchBullet(PatchBulletRequest request, {RpcContext? context});

  @RpcMethod(name: 'deleteBullet', kind: RpcMethodKind.unary)
  Future<DeleteRecordResponse> deleteBullet(
    DeleteEntityRequest request, {
    RpcContext? context,
  });

  @RpcMethod(name: 'createMediaAsset', kind: RpcMethodKind.unary)
  Future<MediaAsset> createMediaAsset(
    MediaAsset request, {
    RpcContext? context,
  });

  @RpcMethod(name: 'updateMediaAsset', kind: RpcMethodKind.unary)
  Future<MediaAsset> updateMediaAsset(
    MediaAsset request, {
    RpcContext? context,
  });

  @RpcMethod(name: 'patchMediaAsset', kind: RpcMethodKind.unary)
  Future<MediaAsset> patchMediaAsset(
    PatchMediaAssetRequest request, {
    RpcContext? context,
  });

  @RpcMethod(name: 'deleteMediaAsset', kind: RpcMethodKind.unary)
  Future<DeleteRecordResponse> deleteMediaAsset(
    DeleteEntityRequest request, {
    RpcContext? context,
  });

  @RpcMethod(name: 'createVariant', kind: RpcMethodKind.unary)
  Future<ResumeVariant> createVariant(
    ResumeVariant request, {
    RpcContext? context,
  });

  @RpcMethod(name: 'updateVariant', kind: RpcMethodKind.unary)
  Future<ResumeVariant> updateVariant(
    ResumeVariant request, {
    RpcContext? context,
  });

  @RpcMethod(name: 'patchVariant', kind: RpcMethodKind.unary)
  Future<ResumeVariant> patchVariant(
    PatchVariantRequest request, {
    RpcContext? context,
  });

  @RpcMethod(name: 'deleteVariant', kind: RpcMethodKind.unary)
  Future<DeleteRecordResponse> deleteVariant(
    DeleteEntityRequest request, {
    RpcContext? context,
  });
}

class PatchProfileRequest implements IRpcSerializable {
  PatchProfileRequest({
    required this.id,
    required this.expectedVersion,
    required this.patch,
  });
  final String id;
  final int expectedVersion;
  final RecordPatch patch;

  factory PatchProfileRequest.fromJson(Map<String, dynamic> json) =>
      PatchProfileRequest(
        id: json['id'] as String? ?? '',
        expectedVersion: json['expectedVersion'] as int? ?? 0,
        patch: RecordPatch.fromJson(
          Map<String, dynamic>.from(json['patch'] as Map? ?? const {}),
        ),
      );

  @override
  Map<String, dynamic> toJson() => {
    'id': id,
    'expectedVersion': expectedVersion,
    'patch': patch.toJson(),
  };
}

class PatchExperienceRequest implements IRpcSerializable {
  PatchExperienceRequest({
    required this.id,
    required this.expectedVersion,
    required this.patch,
  });
  final String id;
  final int expectedVersion;
  final RecordPatch patch;

  factory PatchExperienceRequest.fromJson(Map<String, dynamic> json) =>
      PatchExperienceRequest(
        id: json['id'] as String? ?? '',
        expectedVersion: json['expectedVersion'] as int? ?? 0,
        patch: RecordPatch.fromJson(
          Map<String, dynamic>.from(json['patch'] as Map? ?? const {}),
        ),
      );

  @override
  Map<String, dynamic> toJson() => {
    'id': id,
    'expectedVersion': expectedVersion,
    'patch': patch.toJson(),
  };
}

class PatchProjectRequest implements IRpcSerializable {
  PatchProjectRequest({
    required this.id,
    required this.expectedVersion,
    required this.patch,
  });
  final String id;
  final int expectedVersion;
  final RecordPatch patch;

  factory PatchProjectRequest.fromJson(Map<String, dynamic> json) =>
      PatchProjectRequest(
        id: json['id'] as String? ?? '',
        expectedVersion: json['expectedVersion'] as int? ?? 0,
        patch: RecordPatch.fromJson(
          Map<String, dynamic>.from(json['patch'] as Map? ?? const {}),
        ),
      );

  @override
  Map<String, dynamic> toJson() => {
    'id': id,
    'expectedVersion': expectedVersion,
    'patch': patch.toJson(),
  };
}

class PatchSkillRequest implements IRpcSerializable {
  PatchSkillRequest({
    required this.id,
    required this.expectedVersion,
    required this.patch,
  });
  final String id;
  final int expectedVersion;
  final RecordPatch patch;

  factory PatchSkillRequest.fromJson(Map<String, dynamic> json) =>
      PatchSkillRequest(
        id: json['id'] as String? ?? '',
        expectedVersion: json['expectedVersion'] as int? ?? 0,
        patch: RecordPatch.fromJson(
          Map<String, dynamic>.from(json['patch'] as Map? ?? const {}),
        ),
      );

  @override
  Map<String, dynamic> toJson() => {
    'id': id,
    'expectedVersion': expectedVersion,
    'patch': patch.toJson(),
  };
}

class PatchEducationRequest implements IRpcSerializable {
  PatchEducationRequest({
    required this.id,
    required this.expectedVersion,
    required this.patch,
  });
  final String id;
  final int expectedVersion;
  final RecordPatch patch;

  factory PatchEducationRequest.fromJson(Map<String, dynamic> json) =>
      PatchEducationRequest(
        id: json['id'] as String? ?? '',
        expectedVersion: json['expectedVersion'] as int? ?? 0,
        patch: RecordPatch.fromJson(
          Map<String, dynamic>.from(json['patch'] as Map? ?? const {}),
        ),
      );

  @override
  Map<String, dynamic> toJson() => {
    'id': id,
    'expectedVersion': expectedVersion,
    'patch': patch.toJson(),
  };
}

class PatchBulletRequest implements IRpcSerializable {
  PatchBulletRequest({
    required this.id,
    required this.expectedVersion,
    required this.patch,
  });
  final String id;
  final int expectedVersion;
  final RecordPatch patch;

  factory PatchBulletRequest.fromJson(Map<String, dynamic> json) =>
      PatchBulletRequest(
        id: json['id'] as String? ?? '',
        expectedVersion: json['expectedVersion'] as int? ?? 0,
        patch: RecordPatch.fromJson(
          Map<String, dynamic>.from(json['patch'] as Map? ?? const {}),
        ),
      );

  @override
  Map<String, dynamic> toJson() => {
    'id': id,
    'expectedVersion': expectedVersion,
    'patch': patch.toJson(),
  };
}

class PatchMediaAssetRequest implements IRpcSerializable {
  PatchMediaAssetRequest({
    required this.id,
    required this.expectedVersion,
    required this.patch,
  });
  final String id;
  final int expectedVersion;
  final RecordPatch patch;

  factory PatchMediaAssetRequest.fromJson(Map<String, dynamic> json) =>
      PatchMediaAssetRequest(
        id: json['id'] as String? ?? '',
        expectedVersion: json['expectedVersion'] as int? ?? 0,
        patch: RecordPatch.fromJson(
          Map<String, dynamic>.from(json['patch'] as Map? ?? const {}),
        ),
      );

  @override
  Map<String, dynamic> toJson() => {
    'id': id,
    'expectedVersion': expectedVersion,
    'patch': patch.toJson(),
  };
}

class PatchVariantRequest implements IRpcSerializable {
  PatchVariantRequest({
    required this.id,
    required this.expectedVersion,
    required this.patch,
  });
  final String id;
  final int expectedVersion;
  final RecordPatch patch;

  factory PatchVariantRequest.fromJson(Map<String, dynamic> json) =>
      PatchVariantRequest(
        id: json['id'] as String? ?? '',
        expectedVersion: json['expectedVersion'] as int? ?? 0,
        patch: RecordPatch.fromJson(
          Map<String, dynamic>.from(json['patch'] as Map? ?? const {}),
        ),
      );

  @override
  Map<String, dynamic> toJson() => {
    'id': id,
    'expectedVersion': expectedVersion,
    'patch': patch.toJson(),
  };
}

class DeleteEntityRequest implements IRpcSerializable {
  DeleteEntityRequest({required this.id, this.expectedVersion});

  final String id;
  final int? expectedVersion;

  factory DeleteEntityRequest.fromJson(Map<String, dynamic> json) =>
      DeleteEntityRequest(
        id: json['id'] as String? ?? '',
        expectedVersion: json['expectedVersion'] as int?,
      );

  @override
  Map<String, dynamic> toJson() => {
    'id': id,
    if (expectedVersion != null) 'expectedVersion': expectedVersion,
  };
}

/// Responder that proxies typed CRUD to IDataService with hardcoded collections.
class ResumeEntitiesResponder extends ResumeEntitiesContractResponder {
  ResumeEntitiesResponder({
    required this.dataService,
    super.serviceNameOverride,
    super.dataTransferMode,
  });

  final IDataService dataService;

  @override
  Future<Profile> createProfile(Profile request, {RpcContext? context}) =>
      _create(request, ResumeEntity.profile, Profile.fromJson, context);

  @override
  Future<Profile> updateProfile(Profile request, {RpcContext? context}) =>
      _update(request, ResumeEntity.profile, Profile.fromJson, context);

  @override
  Future<Profile> patchProfile(
    PatchProfileRequest request, {
    RpcContext? context,
  }) => _patch(request, ResumeEntity.profile, Profile.fromJson, context);

  @override
  Future<DeleteRecordResponse> deleteProfile(
    DeleteEntityRequest request, {
    RpcContext? context,
  }) => _delete(request, ResumeEntity.profile, context);

  @override
  Future<Experience> createExperience(
    Experience request, {
    RpcContext? context,
  }) => _create(request, ResumeEntity.experience, Experience.fromJson, context);

  @override
  Future<Experience> updateExperience(
    Experience request, {
    RpcContext? context,
  }) => _update(request, ResumeEntity.experience, Experience.fromJson, context);

  @override
  Future<Experience> patchExperience(
    PatchExperienceRequest request, {
    RpcContext? context,
  }) => _patch(request, ResumeEntity.experience, Experience.fromJson, context);

  @override
  Future<DeleteRecordResponse> deleteExperience(
    DeleteEntityRequest request, {
    RpcContext? context,
  }) => _delete(request, ResumeEntity.experience, context);

  @override
  Future<Project> createProject(Project request, {RpcContext? context}) =>
      _create(request, ResumeEntity.project, Project.fromJson, context);

  @override
  Future<Project> updateProject(Project request, {RpcContext? context}) =>
      _update(request, ResumeEntity.project, Project.fromJson, context);

  @override
  Future<Project> patchProject(
    PatchProjectRequest request, {
    RpcContext? context,
  }) => _patch(request, ResumeEntity.project, Project.fromJson, context);

  @override
  Future<DeleteRecordResponse> deleteProject(
    DeleteEntityRequest request, {
    RpcContext? context,
  }) => _delete(request, ResumeEntity.project, context);

  @override
  Future<Skill> createSkill(Skill request, {RpcContext? context}) =>
      _create(request, ResumeEntity.skill, Skill.fromJson, context);

  @override
  Future<Skill> updateSkill(Skill request, {RpcContext? context}) =>
      _update(request, ResumeEntity.skill, Skill.fromJson, context);

  @override
  Future<Skill> patchSkill(PatchSkillRequest request, {RpcContext? context}) =>
      _patch(request, ResumeEntity.skill, Skill.fromJson, context);

  @override
  Future<DeleteRecordResponse> deleteSkill(
    DeleteEntityRequest request, {
    RpcContext? context,
  }) => _delete(request, ResumeEntity.skill, context);

  @override
  Future<Education> createEducation(Education request, {RpcContext? context}) =>
      _create(request, ResumeEntity.education, Education.fromJson, context);

  @override
  Future<Education> updateEducation(Education request, {RpcContext? context}) =>
      _update(request, ResumeEntity.education, Education.fromJson, context);

  @override
  Future<Education> patchEducation(
    PatchEducationRequest request, {
    RpcContext? context,
  }) => _patch(request, ResumeEntity.education, Education.fromJson, context);

  @override
  Future<DeleteRecordResponse> deleteEducation(
    DeleteEntityRequest request, {
    RpcContext? context,
  }) => _delete(request, ResumeEntity.education, context);

  @override
  Future<Bullet> createBullet(Bullet request, {RpcContext? context}) =>
      _create(request, ResumeEntity.bullet, Bullet.fromJson, context);

  @override
  Future<Bullet> updateBullet(Bullet request, {RpcContext? context}) =>
      _update(request, ResumeEntity.bullet, Bullet.fromJson, context);

  @override
  Future<Bullet> patchBullet(
    PatchBulletRequest request, {
    RpcContext? context,
  }) => _patch(request, ResumeEntity.bullet, Bullet.fromJson, context);

  @override
  Future<DeleteRecordResponse> deleteBullet(
    DeleteEntityRequest request, {
    RpcContext? context,
  }) => _delete(request, ResumeEntity.bullet, context);

  @override
  Future<MediaAsset> createMediaAsset(
    MediaAsset request, {
    RpcContext? context,
  }) => _create(request, ResumeEntity.mediaAsset, MediaAsset.fromJson, context);

  @override
  Future<MediaAsset> updateMediaAsset(
    MediaAsset request, {
    RpcContext? context,
  }) => _update(request, ResumeEntity.mediaAsset, MediaAsset.fromJson, context);

  @override
  Future<MediaAsset> patchMediaAsset(
    PatchMediaAssetRequest request, {
    RpcContext? context,
  }) => _patch(request, ResumeEntity.mediaAsset, MediaAsset.fromJson, context);

  @override
  Future<DeleteRecordResponse> deleteMediaAsset(
    DeleteEntityRequest request, {
    RpcContext? context,
  }) => _delete(request, ResumeEntity.mediaAsset, context);

  @override
  Future<ResumeVariant> createVariant(
    ResumeVariant request, {
    RpcContext? context,
  }) => _create(request, ResumeEntity.variant, ResumeVariant.fromJson, context);

  @override
  Future<ResumeVariant> updateVariant(
    ResumeVariant request, {
    RpcContext? context,
  }) => _update(request, ResumeEntity.variant, ResumeVariant.fromJson, context);

  @override
  Future<ResumeVariant> patchVariant(
    PatchVariantRequest request, {
    RpcContext? context,
  }) => _patch(request, ResumeEntity.variant, ResumeVariant.fromJson, context);

  @override
  Future<DeleteRecordResponse> deleteVariant(
    DeleteEntityRequest request, {
    RpcContext? context,
  }) => _delete(request, ResumeEntity.variant, context);

  Future<T> _create<T extends IRpcSerializable>(
    T model,
    ResumeEntity entity,
    T Function(Map<String, dynamic>) fromJson,
    RpcContext? context,
  ) async {
    final record = await dataService.create(
      collection: entity.collection,
      payload: (model as dynamic).toJson() as Map<String, dynamic>,
      id: (model as dynamic).id as String?,
      context: context,
    );
    return _mapRecord(record, fromJson);
  }

  Future<T> _update<T extends IRpcSerializable>(
    T model,
    ResumeEntity entity,
    T Function(Map<String, dynamic>) fromJson,
    RpcContext? context,
  ) async {
    final record = await dataService.update(
      collection: entity.collection,
      id: (model as dynamic).id as String,
      expectedVersion: (model as dynamic).version as int,
      payload: (model as dynamic).toJson() as Map<String, dynamic>,
      context: context,
    );
    return _mapRecord(record, fromJson);
  }

  Future<T> _patch<T extends IRpcSerializable>(
    dynamic request,
    ResumeEntity entity,
    T Function(Map<String, dynamic>) fromJson,
    RpcContext? context,
  ) async {
    final record = await dataService.patch(
      collection: entity.collection,
      id: request.id as String,
      expectedVersion: request.expectedVersion as int,
      patch: (request as dynamic).patch as RecordPatch,
      context: context,
    );
    return _mapRecord(record, fromJson);
  }

  Future<DeleteRecordResponse> _delete(
    DeleteEntityRequest request,
    ResumeEntity entity,
    RpcContext? context,
  ) async {
    final deleted = await dataService.delete(
      collection: entity.collection,
      id: request.id,
      expectedVersion: request.expectedVersion,
      context: context,
    );
    return DeleteRecordResponse(deleted: deleted);
  }

  T _mapRecord<T>(
    DataRecord record,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    final map = Map<String, dynamic>.from(record.payload);
    map['id'] = record.id;
    map['version'] = record.version;
    return fromJson(map);
  }
}
