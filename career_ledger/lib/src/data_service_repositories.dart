import 'package:rpc_dart_data/rpc_dart_data.dart';

import 'models.dart';
import 'repository.dart';

/// Base class for repositories backed by IDataService.
abstract class DataServiceRepositoryBase<T> {
  DataServiceRepositoryBase(this.dataService, {required this.collection});

  final IDataService dataService;
  final DataServiceCollection<T> collection;

  Future<List<T>> all() async {
    final records = await _fetchRecords();
    return records.map(_unwrapRecord).map(collection.fromJson).toList();
  }

  Map<String, dynamic> _unwrapRecord(dynamic record) {
    if (record is Map) return Map<String, dynamic>.from(record);
    final payload = (record as dynamic).payload;
    if (payload is Map) {
      final map = Map<String, dynamic>.from(payload);
      map.putIfAbsent('id', () => (record as dynamic).id);
      map.putIfAbsent('version', () => (record as dynamic).version);
      return map;
    }
    throw StateError('Unsupported record type: ${record.runtimeType}');
  }

  Future<List<dynamic>> _fetchRecords() async {
    final ds = dataService;
    final all = await ds.listAllRecords(collection: collection.collection);
    return all;
  }
}

class MediaAssetsRepository extends DataServiceRepositoryBase<MediaAsset> {
  MediaAssetsRepository(super.dataService)
    : super(
        collection: DataServiceCollection(
          collection: 'media_assets',
          fromJson: MediaAsset.fromJson,
          dataService: dataService,
          toJson: (MediaAsset model) => model.toJson(),
          idSelector: (MediaAsset model) => model.id,
        ),
      );
}

class ProfilesRepository extends DataServiceRepositoryBase<Profile> {
  ProfilesRepository(super.dataService)
    : super(
        collection: DataServiceCollection(
          collection: 'profiles',
          fromJson: Profile.fromJson,
          dataService: dataService,
          toJson: (Profile model) => model.toJson(),
          idSelector: (Profile model) => model.id,
        ),
      );
}

class ExperiencesRepository extends DataServiceRepositoryBase<Experience> {
  ExperiencesRepository(super.dataService)
    : super(
        collection: DataServiceCollection(
          collection: 'experiences',
          fromJson: Experience.fromJson,
          dataService: dataService,
          toJson: (Experience model) => model.toJson(),
          idSelector: (Experience model) => model.id,
        ),
      );
}

class BulletsRepository extends DataServiceRepositoryBase<Bullet> {
  BulletsRepository(super.dataService)
    : super(
        collection: DataServiceCollection(
          collection: 'bullets',
          fromJson: Bullet.fromJson,
          dataService: dataService,
          toJson: (Bullet model) => model.toJson(),
          idSelector: (Bullet model) => model.id,
        ),
      );
}

class SkillsRepository extends DataServiceRepositoryBase<Skill> {
  SkillsRepository(super.dataService)
    : super(
        collection: DataServiceCollection(
          collection: 'skills',
          fromJson: Skill.fromJson,
          dataService: dataService,
          toJson: (Skill model) => model.toJson(),
          idSelector: (Skill model) => model.id,
        ),
      );
}

class ProjectsRepository extends DataServiceRepositoryBase<Project> {
  ProjectsRepository(super.dataService)
    : super(
        collection: DataServiceCollection(
          collection: 'projects',
          fromJson: Project.fromJson,
          dataService: dataService,
          toJson: (Project model) => model.toJson(),
          idSelector: (Project model) => model.id,
        ),
      );
}

class EducationRepository extends DataServiceRepositoryBase<Education> {
  EducationRepository(super.dataService)
    : super(
        collection: DataServiceCollection(
          collection: 'education',
          fromJson: Education.fromJson,
          dataService: dataService,
          toJson: (Education model) => model.toJson(),
          idSelector: (Education model) => model.id,
        ),
      );
}

class ResumeVariantsRepository
    extends DataServiceRepositoryBase<ResumeVariant> {
  ResumeVariantsRepository(super.dataService)
    : super(
        collection: DataServiceCollection(
          collection: 'resume_variants',
          fromJson: ResumeVariant.fromJson,
          dataService: dataService,
          toJson: (ResumeVariant model) => model.toJson(),
          idSelector: (ResumeVariant model) => model.id,
        ),
      );
}

/// Aggregates all data-service-backed repositories to load an in-memory snapshot
/// used by the ResumeGenerator.
class DataServiceResumeRepository {
  DataServiceResumeRepository({required IDataService dataService})
    : mediaAssets = MediaAssetsRepository(dataService),
      profiles = ProfilesRepository(dataService),
      experiences = ExperiencesRepository(dataService),
      bullets = BulletsRepository(dataService),
      skills = SkillsRepository(dataService),
      projects = ProjectsRepository(dataService),
      education = EducationRepository(dataService),
      variants = ResumeVariantsRepository(dataService);

  final MediaAssetsRepository mediaAssets;
  final ProfilesRepository profiles;
  final ExperiencesRepository experiences;
  final BulletsRepository bullets;
  final SkillsRepository skills;
  final ProjectsRepository projects;
  final EducationRepository education;
  final ResumeVariantsRepository variants;

  Future<ResumeRepository> getSnapshot() async {
    final media = await mediaAssets.all();
    final profileList = await profiles.all();
    final experienceList = await experiences.all();
    final bulletList = await bullets.all();
    final skillList = await skills.all();
    final projectList = await projects.all();
    final educationList = await education.all();
    final variantList = await variants.all();

    return ResumeRepository(
      mediaAssets: media,
      profiles: profileList,
      experiences: experienceList,
      bullets: bulletList,
      skills: skillList,
      projects: projectList,
      education: educationList,
      variants: variantList,
    );
  }
}
