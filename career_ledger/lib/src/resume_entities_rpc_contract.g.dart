// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'resume_entities_rpc_contract.dart';

// **************************************************************************
// RpcDartGenerator
// **************************************************************************

// ignore_for_file: type=lint, unused_element

class ResumeEntitiesContractNames {
  const ResumeEntitiesContractNames._();
  static const service = 'ResumeEntitiesService';
  static String instance(String suffix) => '\$service\_$suffix';
  static const createProfile = 'createProfile';
  static const updateProfile = 'updateProfile';
  static const patchProfile = 'patchProfile';
  static const deleteProfile = 'deleteProfile';
  static const createExperience = 'createExperience';
  static const updateExperience = 'updateExperience';
  static const patchExperience = 'patchExperience';
  static const deleteExperience = 'deleteExperience';
  static const createProject = 'createProject';
  static const updateProject = 'updateProject';
  static const patchProject = 'patchProject';
  static const deleteProject = 'deleteProject';
  static const createSkill = 'createSkill';
  static const updateSkill = 'updateSkill';
  static const patchSkill = 'patchSkill';
  static const deleteSkill = 'deleteSkill';
  static const createEducation = 'createEducation';
  static const updateEducation = 'updateEducation';
  static const patchEducation = 'patchEducation';
  static const deleteEducation = 'deleteEducation';
  static const createBullet = 'createBullet';
  static const updateBullet = 'updateBullet';
  static const patchBullet = 'patchBullet';
  static const deleteBullet = 'deleteBullet';
  static const createMediaAsset = 'createMediaAsset';
  static const updateMediaAsset = 'updateMediaAsset';
  static const patchMediaAsset = 'patchMediaAsset';
  static const deleteMediaAsset = 'deleteMediaAsset';
  static const createVariant = 'createVariant';
  static const updateVariant = 'updateVariant';
  static const patchVariant = 'patchVariant';
  static const deleteVariant = 'deleteVariant';
}

final class ResumeEntitiesContractCaller extends RpcCallerContract
    implements IResumeEntitiesContract {
  ResumeEntitiesContractCaller(
    RpcCallerEndpoint endpoint, {
    String? serviceNameOverride,
    RpcDataTransferMode dataTransferMode = RpcDataTransferMode.codec,
  }) : super(
         serviceNameOverride ?? ResumeEntitiesContractNames.service,
         endpoint,
         dataTransferMode: dataTransferMode,
       );

  @override
  Future<Profile> createProfile(Profile request, {RpcContext? context}) {
    return callUnary<Profile, Profile>(
      methodName: ResumeEntitiesContractNames.createProfile,
      requestCodec: const RpcCodec<Profile>.withDecoder(Profile.fromJson),
      responseCodec: const RpcCodec<Profile>.withDecoder(Profile.fromJson),
      request: request,
      context: context,
    );
  }

  @override
  Future<Profile> updateProfile(Profile request, {RpcContext? context}) {
    return callUnary<Profile, Profile>(
      methodName: ResumeEntitiesContractNames.updateProfile,
      requestCodec: const RpcCodec<Profile>.withDecoder(Profile.fromJson),
      responseCodec: const RpcCodec<Profile>.withDecoder(Profile.fromJson),
      request: request,
      context: context,
    );
  }

  @override
  Future<Profile> patchProfile(
    PatchProfileRequest request, {
    RpcContext? context,
  }) {
    return callUnary<PatchProfileRequest, Profile>(
      methodName: ResumeEntitiesContractNames.patchProfile,
      requestCodec: const RpcCodec<PatchProfileRequest>.withDecoder(
        PatchProfileRequest.fromJson,
      ),
      responseCodec: const RpcCodec<Profile>.withDecoder(Profile.fromJson),
      request: request,
      context: context,
    );
  }

  @override
  Future<DeleteRecordResponse> deleteProfile(
    DeleteEntityRequest request, {
    RpcContext? context,
  }) {
    return callUnary<DeleteEntityRequest, DeleteRecordResponse>(
      methodName: ResumeEntitiesContractNames.deleteProfile,
      requestCodec: const RpcCodec<DeleteEntityRequest>.withDecoder(
        DeleteEntityRequest.fromJson,
      ),
      responseCodec: const RpcCodec<DeleteRecordResponse>.withDecoder(
        DeleteRecordResponse.fromJson,
      ),
      request: request,
      context: context,
    );
  }

  @override
  Future<Experience> createExperience(
    Experience request, {
    RpcContext? context,
  }) {
    return callUnary<Experience, Experience>(
      methodName: ResumeEntitiesContractNames.createExperience,
      requestCodec: const RpcCodec<Experience>.withDecoder(Experience.fromJson),
      responseCodec: const RpcCodec<Experience>.withDecoder(
        Experience.fromJson,
      ),
      request: request,
      context: context,
    );
  }

  @override
  Future<Experience> updateExperience(
    Experience request, {
    RpcContext? context,
  }) {
    return callUnary<Experience, Experience>(
      methodName: ResumeEntitiesContractNames.updateExperience,
      requestCodec: const RpcCodec<Experience>.withDecoder(Experience.fromJson),
      responseCodec: const RpcCodec<Experience>.withDecoder(
        Experience.fromJson,
      ),
      request: request,
      context: context,
    );
  }

  @override
  Future<Experience> patchExperience(
    PatchExperienceRequest request, {
    RpcContext? context,
  }) {
    return callUnary<PatchExperienceRequest, Experience>(
      methodName: ResumeEntitiesContractNames.patchExperience,
      requestCodec: const RpcCodec<PatchExperienceRequest>.withDecoder(
        PatchExperienceRequest.fromJson,
      ),
      responseCodec: const RpcCodec<Experience>.withDecoder(
        Experience.fromJson,
      ),
      request: request,
      context: context,
    );
  }

  @override
  Future<DeleteRecordResponse> deleteExperience(
    DeleteEntityRequest request, {
    RpcContext? context,
  }) {
    return callUnary<DeleteEntityRequest, DeleteRecordResponse>(
      methodName: ResumeEntitiesContractNames.deleteExperience,
      requestCodec: const RpcCodec<DeleteEntityRequest>.withDecoder(
        DeleteEntityRequest.fromJson,
      ),
      responseCodec: const RpcCodec<DeleteRecordResponse>.withDecoder(
        DeleteRecordResponse.fromJson,
      ),
      request: request,
      context: context,
    );
  }

  @override
  Future<Project> createProject(Project request, {RpcContext? context}) {
    return callUnary<Project, Project>(
      methodName: ResumeEntitiesContractNames.createProject,
      requestCodec: const RpcCodec<Project>.withDecoder(Project.fromJson),
      responseCodec: const RpcCodec<Project>.withDecoder(Project.fromJson),
      request: request,
      context: context,
    );
  }

  @override
  Future<Project> updateProject(Project request, {RpcContext? context}) {
    return callUnary<Project, Project>(
      methodName: ResumeEntitiesContractNames.updateProject,
      requestCodec: const RpcCodec<Project>.withDecoder(Project.fromJson),
      responseCodec: const RpcCodec<Project>.withDecoder(Project.fromJson),
      request: request,
      context: context,
    );
  }

  @override
  Future<Project> patchProject(
    PatchProjectRequest request, {
    RpcContext? context,
  }) {
    return callUnary<PatchProjectRequest, Project>(
      methodName: ResumeEntitiesContractNames.patchProject,
      requestCodec: const RpcCodec<PatchProjectRequest>.withDecoder(
        PatchProjectRequest.fromJson,
      ),
      responseCodec: const RpcCodec<Project>.withDecoder(Project.fromJson),
      request: request,
      context: context,
    );
  }

  @override
  Future<DeleteRecordResponse> deleteProject(
    DeleteEntityRequest request, {
    RpcContext? context,
  }) {
    return callUnary<DeleteEntityRequest, DeleteRecordResponse>(
      methodName: ResumeEntitiesContractNames.deleteProject,
      requestCodec: const RpcCodec<DeleteEntityRequest>.withDecoder(
        DeleteEntityRequest.fromJson,
      ),
      responseCodec: const RpcCodec<DeleteRecordResponse>.withDecoder(
        DeleteRecordResponse.fromJson,
      ),
      request: request,
      context: context,
    );
  }

  @override
  Future<Skill> createSkill(Skill request, {RpcContext? context}) {
    return callUnary<Skill, Skill>(
      methodName: ResumeEntitiesContractNames.createSkill,
      requestCodec: const RpcCodec<Skill>.withDecoder(Skill.fromJson),
      responseCodec: const RpcCodec<Skill>.withDecoder(Skill.fromJson),
      request: request,
      context: context,
    );
  }

  @override
  Future<Skill> updateSkill(Skill request, {RpcContext? context}) {
    return callUnary<Skill, Skill>(
      methodName: ResumeEntitiesContractNames.updateSkill,
      requestCodec: const RpcCodec<Skill>.withDecoder(Skill.fromJson),
      responseCodec: const RpcCodec<Skill>.withDecoder(Skill.fromJson),
      request: request,
      context: context,
    );
  }

  @override
  Future<Skill> patchSkill(PatchSkillRequest request, {RpcContext? context}) {
    return callUnary<PatchSkillRequest, Skill>(
      methodName: ResumeEntitiesContractNames.patchSkill,
      requestCodec: const RpcCodec<PatchSkillRequest>.withDecoder(
        PatchSkillRequest.fromJson,
      ),
      responseCodec: const RpcCodec<Skill>.withDecoder(Skill.fromJson),
      request: request,
      context: context,
    );
  }

  @override
  Future<DeleteRecordResponse> deleteSkill(
    DeleteEntityRequest request, {
    RpcContext? context,
  }) {
    return callUnary<DeleteEntityRequest, DeleteRecordResponse>(
      methodName: ResumeEntitiesContractNames.deleteSkill,
      requestCodec: const RpcCodec<DeleteEntityRequest>.withDecoder(
        DeleteEntityRequest.fromJson,
      ),
      responseCodec: const RpcCodec<DeleteRecordResponse>.withDecoder(
        DeleteRecordResponse.fromJson,
      ),
      request: request,
      context: context,
    );
  }

  @override
  Future<Education> createEducation(Education request, {RpcContext? context}) {
    return callUnary<Education, Education>(
      methodName: ResumeEntitiesContractNames.createEducation,
      requestCodec: const RpcCodec<Education>.withDecoder(Education.fromJson),
      responseCodec: const RpcCodec<Education>.withDecoder(Education.fromJson),
      request: request,
      context: context,
    );
  }

  @override
  Future<Education> updateEducation(Education request, {RpcContext? context}) {
    return callUnary<Education, Education>(
      methodName: ResumeEntitiesContractNames.updateEducation,
      requestCodec: const RpcCodec<Education>.withDecoder(Education.fromJson),
      responseCodec: const RpcCodec<Education>.withDecoder(Education.fromJson),
      request: request,
      context: context,
    );
  }

  @override
  Future<Education> patchEducation(
    PatchEducationRequest request, {
    RpcContext? context,
  }) {
    return callUnary<PatchEducationRequest, Education>(
      methodName: ResumeEntitiesContractNames.patchEducation,
      requestCodec: const RpcCodec<PatchEducationRequest>.withDecoder(
        PatchEducationRequest.fromJson,
      ),
      responseCodec: const RpcCodec<Education>.withDecoder(Education.fromJson),
      request: request,
      context: context,
    );
  }

  @override
  Future<DeleteRecordResponse> deleteEducation(
    DeleteEntityRequest request, {
    RpcContext? context,
  }) {
    return callUnary<DeleteEntityRequest, DeleteRecordResponse>(
      methodName: ResumeEntitiesContractNames.deleteEducation,
      requestCodec: const RpcCodec<DeleteEntityRequest>.withDecoder(
        DeleteEntityRequest.fromJson,
      ),
      responseCodec: const RpcCodec<DeleteRecordResponse>.withDecoder(
        DeleteRecordResponse.fromJson,
      ),
      request: request,
      context: context,
    );
  }

  @override
  Future<Bullet> createBullet(Bullet request, {RpcContext? context}) {
    return callUnary<Bullet, Bullet>(
      methodName: ResumeEntitiesContractNames.createBullet,
      requestCodec: const RpcCodec<Bullet>.withDecoder(Bullet.fromJson),
      responseCodec: const RpcCodec<Bullet>.withDecoder(Bullet.fromJson),
      request: request,
      context: context,
    );
  }

  @override
  Future<Bullet> updateBullet(Bullet request, {RpcContext? context}) {
    return callUnary<Bullet, Bullet>(
      methodName: ResumeEntitiesContractNames.updateBullet,
      requestCodec: const RpcCodec<Bullet>.withDecoder(Bullet.fromJson),
      responseCodec: const RpcCodec<Bullet>.withDecoder(Bullet.fromJson),
      request: request,
      context: context,
    );
  }

  @override
  Future<Bullet> patchBullet(
    PatchBulletRequest request, {
    RpcContext? context,
  }) {
    return callUnary<PatchBulletRequest, Bullet>(
      methodName: ResumeEntitiesContractNames.patchBullet,
      requestCodec: const RpcCodec<PatchBulletRequest>.withDecoder(
        PatchBulletRequest.fromJson,
      ),
      responseCodec: const RpcCodec<Bullet>.withDecoder(Bullet.fromJson),
      request: request,
      context: context,
    );
  }

  @override
  Future<DeleteRecordResponse> deleteBullet(
    DeleteEntityRequest request, {
    RpcContext? context,
  }) {
    return callUnary<DeleteEntityRequest, DeleteRecordResponse>(
      methodName: ResumeEntitiesContractNames.deleteBullet,
      requestCodec: const RpcCodec<DeleteEntityRequest>.withDecoder(
        DeleteEntityRequest.fromJson,
      ),
      responseCodec: const RpcCodec<DeleteRecordResponse>.withDecoder(
        DeleteRecordResponse.fromJson,
      ),
      request: request,
      context: context,
    );
  }

  @override
  Future<MediaAsset> createMediaAsset(
    MediaAsset request, {
    RpcContext? context,
  }) {
    return callUnary<MediaAsset, MediaAsset>(
      methodName: ResumeEntitiesContractNames.createMediaAsset,
      requestCodec: const RpcCodec<MediaAsset>.withDecoder(MediaAsset.fromJson),
      responseCodec: const RpcCodec<MediaAsset>.withDecoder(
        MediaAsset.fromJson,
      ),
      request: request,
      context: context,
    );
  }

  @override
  Future<MediaAsset> updateMediaAsset(
    MediaAsset request, {
    RpcContext? context,
  }) {
    return callUnary<MediaAsset, MediaAsset>(
      methodName: ResumeEntitiesContractNames.updateMediaAsset,
      requestCodec: const RpcCodec<MediaAsset>.withDecoder(MediaAsset.fromJson),
      responseCodec: const RpcCodec<MediaAsset>.withDecoder(
        MediaAsset.fromJson,
      ),
      request: request,
      context: context,
    );
  }

  @override
  Future<MediaAsset> patchMediaAsset(
    PatchMediaAssetRequest request, {
    RpcContext? context,
  }) {
    return callUnary<PatchMediaAssetRequest, MediaAsset>(
      methodName: ResumeEntitiesContractNames.patchMediaAsset,
      requestCodec: const RpcCodec<PatchMediaAssetRequest>.withDecoder(
        PatchMediaAssetRequest.fromJson,
      ),
      responseCodec: const RpcCodec<MediaAsset>.withDecoder(
        MediaAsset.fromJson,
      ),
      request: request,
      context: context,
    );
  }

  @override
  Future<DeleteRecordResponse> deleteMediaAsset(
    DeleteEntityRequest request, {
    RpcContext? context,
  }) {
    return callUnary<DeleteEntityRequest, DeleteRecordResponse>(
      methodName: ResumeEntitiesContractNames.deleteMediaAsset,
      requestCodec: const RpcCodec<DeleteEntityRequest>.withDecoder(
        DeleteEntityRequest.fromJson,
      ),
      responseCodec: const RpcCodec<DeleteRecordResponse>.withDecoder(
        DeleteRecordResponse.fromJson,
      ),
      request: request,
      context: context,
    );
  }

  @override
  Future<ResumeVariant> createVariant(
    ResumeVariant request, {
    RpcContext? context,
  }) {
    return callUnary<ResumeVariant, ResumeVariant>(
      methodName: ResumeEntitiesContractNames.createVariant,
      requestCodec: const RpcCodec<ResumeVariant>.withDecoder(
        ResumeVariant.fromJson,
      ),
      responseCodec: const RpcCodec<ResumeVariant>.withDecoder(
        ResumeVariant.fromJson,
      ),
      request: request,
      context: context,
    );
  }

  @override
  Future<ResumeVariant> updateVariant(
    ResumeVariant request, {
    RpcContext? context,
  }) {
    return callUnary<ResumeVariant, ResumeVariant>(
      methodName: ResumeEntitiesContractNames.updateVariant,
      requestCodec: const RpcCodec<ResumeVariant>.withDecoder(
        ResumeVariant.fromJson,
      ),
      responseCodec: const RpcCodec<ResumeVariant>.withDecoder(
        ResumeVariant.fromJson,
      ),
      request: request,
      context: context,
    );
  }

  @override
  Future<ResumeVariant> patchVariant(
    PatchVariantRequest request, {
    RpcContext? context,
  }) {
    return callUnary<PatchVariantRequest, ResumeVariant>(
      methodName: ResumeEntitiesContractNames.patchVariant,
      requestCodec: const RpcCodec<PatchVariantRequest>.withDecoder(
        PatchVariantRequest.fromJson,
      ),
      responseCodec: const RpcCodec<ResumeVariant>.withDecoder(
        ResumeVariant.fromJson,
      ),
      request: request,
      context: context,
    );
  }

  @override
  Future<DeleteRecordResponse> deleteVariant(
    DeleteEntityRequest request, {
    RpcContext? context,
  }) {
    return callUnary<DeleteEntityRequest, DeleteRecordResponse>(
      methodName: ResumeEntitiesContractNames.deleteVariant,
      requestCodec: const RpcCodec<DeleteEntityRequest>.withDecoder(
        DeleteEntityRequest.fromJson,
      ),
      responseCodec: const RpcCodec<DeleteRecordResponse>.withDecoder(
        DeleteRecordResponse.fromJson,
      ),
      request: request,
      context: context,
    );
  }
}

abstract class ResumeEntitiesContractResponder extends RpcResponderContract
    implements IResumeEntitiesContract {
  ResumeEntitiesContractResponder({
    String? serviceNameOverride,
    RpcDataTransferMode dataTransferMode = RpcDataTransferMode.codec,
  }) : super(
         serviceNameOverride ?? ResumeEntitiesContractNames.service,
         dataTransferMode: dataTransferMode,
       );

  @override
  void setup() {
    addUnaryMethod<Profile, Profile>(
      methodName: ResumeEntitiesContractNames.createProfile,
      handler: createProfile,
      requestCodec: const RpcCodec<Profile>.withDecoder(Profile.fromJson),
      responseCodec: const RpcCodec<Profile>.withDecoder(Profile.fromJson),
    );
    addUnaryMethod<Profile, Profile>(
      methodName: ResumeEntitiesContractNames.updateProfile,
      handler: updateProfile,
      requestCodec: const RpcCodec<Profile>.withDecoder(Profile.fromJson),
      responseCodec: const RpcCodec<Profile>.withDecoder(Profile.fromJson),
    );
    addUnaryMethod<PatchProfileRequest, Profile>(
      methodName: ResumeEntitiesContractNames.patchProfile,
      handler: patchProfile,
      requestCodec: const RpcCodec<PatchProfileRequest>.withDecoder(
        PatchProfileRequest.fromJson,
      ),
      responseCodec: const RpcCodec<Profile>.withDecoder(Profile.fromJson),
    );
    addUnaryMethod<DeleteEntityRequest, DeleteRecordResponse>(
      methodName: ResumeEntitiesContractNames.deleteProfile,
      handler: deleteProfile,
      requestCodec: const RpcCodec<DeleteEntityRequest>.withDecoder(
        DeleteEntityRequest.fromJson,
      ),
      responseCodec: const RpcCodec<DeleteRecordResponse>.withDecoder(
        DeleteRecordResponse.fromJson,
      ),
    );
    addUnaryMethod<Experience, Experience>(
      methodName: ResumeEntitiesContractNames.createExperience,
      handler: createExperience,
      requestCodec: const RpcCodec<Experience>.withDecoder(Experience.fromJson),
      responseCodec: const RpcCodec<Experience>.withDecoder(
        Experience.fromJson,
      ),
    );
    addUnaryMethod<Experience, Experience>(
      methodName: ResumeEntitiesContractNames.updateExperience,
      handler: updateExperience,
      requestCodec: const RpcCodec<Experience>.withDecoder(Experience.fromJson),
      responseCodec: const RpcCodec<Experience>.withDecoder(
        Experience.fromJson,
      ),
    );
    addUnaryMethod<PatchExperienceRequest, Experience>(
      methodName: ResumeEntitiesContractNames.patchExperience,
      handler: patchExperience,
      requestCodec: const RpcCodec<PatchExperienceRequest>.withDecoder(
        PatchExperienceRequest.fromJson,
      ),
      responseCodec: const RpcCodec<Experience>.withDecoder(
        Experience.fromJson,
      ),
    );
    addUnaryMethod<DeleteEntityRequest, DeleteRecordResponse>(
      methodName: ResumeEntitiesContractNames.deleteExperience,
      handler: deleteExperience,
      requestCodec: const RpcCodec<DeleteEntityRequest>.withDecoder(
        DeleteEntityRequest.fromJson,
      ),
      responseCodec: const RpcCodec<DeleteRecordResponse>.withDecoder(
        DeleteRecordResponse.fromJson,
      ),
    );
    addUnaryMethod<Project, Project>(
      methodName: ResumeEntitiesContractNames.createProject,
      handler: createProject,
      requestCodec: const RpcCodec<Project>.withDecoder(Project.fromJson),
      responseCodec: const RpcCodec<Project>.withDecoder(Project.fromJson),
    );
    addUnaryMethod<Project, Project>(
      methodName: ResumeEntitiesContractNames.updateProject,
      handler: updateProject,
      requestCodec: const RpcCodec<Project>.withDecoder(Project.fromJson),
      responseCodec: const RpcCodec<Project>.withDecoder(Project.fromJson),
    );
    addUnaryMethod<PatchProjectRequest, Project>(
      methodName: ResumeEntitiesContractNames.patchProject,
      handler: patchProject,
      requestCodec: const RpcCodec<PatchProjectRequest>.withDecoder(
        PatchProjectRequest.fromJson,
      ),
      responseCodec: const RpcCodec<Project>.withDecoder(Project.fromJson),
    );
    addUnaryMethod<DeleteEntityRequest, DeleteRecordResponse>(
      methodName: ResumeEntitiesContractNames.deleteProject,
      handler: deleteProject,
      requestCodec: const RpcCodec<DeleteEntityRequest>.withDecoder(
        DeleteEntityRequest.fromJson,
      ),
      responseCodec: const RpcCodec<DeleteRecordResponse>.withDecoder(
        DeleteRecordResponse.fromJson,
      ),
    );
    addUnaryMethod<Skill, Skill>(
      methodName: ResumeEntitiesContractNames.createSkill,
      handler: createSkill,
      requestCodec: const RpcCodec<Skill>.withDecoder(Skill.fromJson),
      responseCodec: const RpcCodec<Skill>.withDecoder(Skill.fromJson),
    );
    addUnaryMethod<Skill, Skill>(
      methodName: ResumeEntitiesContractNames.updateSkill,
      handler: updateSkill,
      requestCodec: const RpcCodec<Skill>.withDecoder(Skill.fromJson),
      responseCodec: const RpcCodec<Skill>.withDecoder(Skill.fromJson),
    );
    addUnaryMethod<PatchSkillRequest, Skill>(
      methodName: ResumeEntitiesContractNames.patchSkill,
      handler: patchSkill,
      requestCodec: const RpcCodec<PatchSkillRequest>.withDecoder(
        PatchSkillRequest.fromJson,
      ),
      responseCodec: const RpcCodec<Skill>.withDecoder(Skill.fromJson),
    );
    addUnaryMethod<DeleteEntityRequest, DeleteRecordResponse>(
      methodName: ResumeEntitiesContractNames.deleteSkill,
      handler: deleteSkill,
      requestCodec: const RpcCodec<DeleteEntityRequest>.withDecoder(
        DeleteEntityRequest.fromJson,
      ),
      responseCodec: const RpcCodec<DeleteRecordResponse>.withDecoder(
        DeleteRecordResponse.fromJson,
      ),
    );
    addUnaryMethod<Education, Education>(
      methodName: ResumeEntitiesContractNames.createEducation,
      handler: createEducation,
      requestCodec: const RpcCodec<Education>.withDecoder(Education.fromJson),
      responseCodec: const RpcCodec<Education>.withDecoder(Education.fromJson),
    );
    addUnaryMethod<Education, Education>(
      methodName: ResumeEntitiesContractNames.updateEducation,
      handler: updateEducation,
      requestCodec: const RpcCodec<Education>.withDecoder(Education.fromJson),
      responseCodec: const RpcCodec<Education>.withDecoder(Education.fromJson),
    );
    addUnaryMethod<PatchEducationRequest, Education>(
      methodName: ResumeEntitiesContractNames.patchEducation,
      handler: patchEducation,
      requestCodec: const RpcCodec<PatchEducationRequest>.withDecoder(
        PatchEducationRequest.fromJson,
      ),
      responseCodec: const RpcCodec<Education>.withDecoder(Education.fromJson),
    );
    addUnaryMethod<DeleteEntityRequest, DeleteRecordResponse>(
      methodName: ResumeEntitiesContractNames.deleteEducation,
      handler: deleteEducation,
      requestCodec: const RpcCodec<DeleteEntityRequest>.withDecoder(
        DeleteEntityRequest.fromJson,
      ),
      responseCodec: const RpcCodec<DeleteRecordResponse>.withDecoder(
        DeleteRecordResponse.fromJson,
      ),
    );
    addUnaryMethod<Bullet, Bullet>(
      methodName: ResumeEntitiesContractNames.createBullet,
      handler: createBullet,
      requestCodec: const RpcCodec<Bullet>.withDecoder(Bullet.fromJson),
      responseCodec: const RpcCodec<Bullet>.withDecoder(Bullet.fromJson),
    );
    addUnaryMethod<Bullet, Bullet>(
      methodName: ResumeEntitiesContractNames.updateBullet,
      handler: updateBullet,
      requestCodec: const RpcCodec<Bullet>.withDecoder(Bullet.fromJson),
      responseCodec: const RpcCodec<Bullet>.withDecoder(Bullet.fromJson),
    );
    addUnaryMethod<PatchBulletRequest, Bullet>(
      methodName: ResumeEntitiesContractNames.patchBullet,
      handler: patchBullet,
      requestCodec: const RpcCodec<PatchBulletRequest>.withDecoder(
        PatchBulletRequest.fromJson,
      ),
      responseCodec: const RpcCodec<Bullet>.withDecoder(Bullet.fromJson),
    );
    addUnaryMethod<DeleteEntityRequest, DeleteRecordResponse>(
      methodName: ResumeEntitiesContractNames.deleteBullet,
      handler: deleteBullet,
      requestCodec: const RpcCodec<DeleteEntityRequest>.withDecoder(
        DeleteEntityRequest.fromJson,
      ),
      responseCodec: const RpcCodec<DeleteRecordResponse>.withDecoder(
        DeleteRecordResponse.fromJson,
      ),
    );
    addUnaryMethod<MediaAsset, MediaAsset>(
      methodName: ResumeEntitiesContractNames.createMediaAsset,
      handler: createMediaAsset,
      requestCodec: const RpcCodec<MediaAsset>.withDecoder(MediaAsset.fromJson),
      responseCodec: const RpcCodec<MediaAsset>.withDecoder(
        MediaAsset.fromJson,
      ),
    );
    addUnaryMethod<MediaAsset, MediaAsset>(
      methodName: ResumeEntitiesContractNames.updateMediaAsset,
      handler: updateMediaAsset,
      requestCodec: const RpcCodec<MediaAsset>.withDecoder(MediaAsset.fromJson),
      responseCodec: const RpcCodec<MediaAsset>.withDecoder(
        MediaAsset.fromJson,
      ),
    );
    addUnaryMethod<PatchMediaAssetRequest, MediaAsset>(
      methodName: ResumeEntitiesContractNames.patchMediaAsset,
      handler: patchMediaAsset,
      requestCodec: const RpcCodec<PatchMediaAssetRequest>.withDecoder(
        PatchMediaAssetRequest.fromJson,
      ),
      responseCodec: const RpcCodec<MediaAsset>.withDecoder(
        MediaAsset.fromJson,
      ),
    );
    addUnaryMethod<DeleteEntityRequest, DeleteRecordResponse>(
      methodName: ResumeEntitiesContractNames.deleteMediaAsset,
      handler: deleteMediaAsset,
      requestCodec: const RpcCodec<DeleteEntityRequest>.withDecoder(
        DeleteEntityRequest.fromJson,
      ),
      responseCodec: const RpcCodec<DeleteRecordResponse>.withDecoder(
        DeleteRecordResponse.fromJson,
      ),
    );
    addUnaryMethod<ResumeVariant, ResumeVariant>(
      methodName: ResumeEntitiesContractNames.createVariant,
      handler: createVariant,
      requestCodec: const RpcCodec<ResumeVariant>.withDecoder(
        ResumeVariant.fromJson,
      ),
      responseCodec: const RpcCodec<ResumeVariant>.withDecoder(
        ResumeVariant.fromJson,
      ),
    );
    addUnaryMethod<ResumeVariant, ResumeVariant>(
      methodName: ResumeEntitiesContractNames.updateVariant,
      handler: updateVariant,
      requestCodec: const RpcCodec<ResumeVariant>.withDecoder(
        ResumeVariant.fromJson,
      ),
      responseCodec: const RpcCodec<ResumeVariant>.withDecoder(
        ResumeVariant.fromJson,
      ),
    );
    addUnaryMethod<PatchVariantRequest, ResumeVariant>(
      methodName: ResumeEntitiesContractNames.patchVariant,
      handler: patchVariant,
      requestCodec: const RpcCodec<PatchVariantRequest>.withDecoder(
        PatchVariantRequest.fromJson,
      ),
      responseCodec: const RpcCodec<ResumeVariant>.withDecoder(
        ResumeVariant.fromJson,
      ),
    );
    addUnaryMethod<DeleteEntityRequest, DeleteRecordResponse>(
      methodName: ResumeEntitiesContractNames.deleteVariant,
      handler: deleteVariant,
      requestCodec: const RpcCodec<DeleteEntityRequest>.withDecoder(
        DeleteEntityRequest.fromJson,
      ),
      responseCodec: const RpcCodec<DeleteRecordResponse>.withDecoder(
        DeleteRecordResponse.fromJson,
      ),
    );
  }
}
