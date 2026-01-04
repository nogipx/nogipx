import 'models.dart';
import 'repository.dart';

class DataCollection<T> {
  const DataCollection({required this.name, required this.fromJson});

  final String name;
  final T Function(Map<String, dynamic>) fromJson;
}

/// Base class for repositories backed by IDataService.
abstract class DataServiceRepositoryBase<T> {
  DataServiceRepositoryBase(this.dataService, {required this.collection});

  final Object dataService;
  final DataCollection<T> collection;

  Future<List<T>> all() async {
    final ds = dataService as dynamic;
    final records = await ds.listAllRecords(collection: collection.name);
    if (records is! List) {
      throw StateError(
        'Expected list from IDataService.listAllRecords for ${collection.name}',
      );
    }
    return records.map(_unwrapRecord).map(collection.fromJson).toList();
  }

  Map<String, dynamic> _unwrapRecord(dynamic record) {
    if (record is Map) return Map<String, dynamic>.from(record as Map);
    final payload = (record as dynamic).payload;
    if (payload is Map) {
      final map = Map<String, dynamic>.from(payload);
      map.putIfAbsent('id', () => (record as dynamic).id);
      map.putIfAbsent('version', () => (record as dynamic).version);
      return map;
    }
    throw StateError('Unsupported record type: ${record.runtimeType}');
  }
}

class MediaAssetsRepository extends DataServiceRepositoryBase<MediaAsset> {
  MediaAssetsRepository(super.dataService)
    : super(
        collection: DataCollection(
          name: 'media_assets',
          fromJson: MediaAsset.fromJson,
        ),
      );
}

class ProfilesRepository extends DataServiceRepositoryBase<Profile> {
  ProfilesRepository(super.dataService)
    : super(
        collection: DataCollection(
          name: 'profiles',
          fromJson: Profile.fromJson,
        ),
      );
}

class ExperiencesRepository extends DataServiceRepositoryBase<Experience> {
  ExperiencesRepository(super.dataService)
    : super(
        collection: DataCollection(
          name: 'experiences',
          fromJson: Experience.fromJson,
        ),
      );
}

class BulletsRepository extends DataServiceRepositoryBase<Bullet> {
  BulletsRepository(super.dataService)
    : super(
        collection: DataCollection(name: 'bullets', fromJson: Bullet.fromJson),
      );
}

class SkillsRepository extends DataServiceRepositoryBase<Skill> {
  SkillsRepository(super.dataService)
    : super(
        collection: DataCollection(name: 'skills', fromJson: Skill.fromJson),
      );
}

class ProjectsRepository extends DataServiceRepositoryBase<Project> {
  ProjectsRepository(super.dataService)
    : super(
        collection: DataCollection(
          name: 'projects',
          fromJson: Project.fromJson,
        ),
      );
}

class EducationRepository extends DataServiceRepositoryBase<Education> {
  EducationRepository(super.dataService)
    : super(
        collection: DataCollection(
          name: 'education',
          fromJson: Education.fromJson,
        ),
      );
}

class ResumeVariantsRepository
    extends DataServiceRepositoryBase<ResumeVariant> {
  ResumeVariantsRepository(super.dataService)
    : super(
        collection: DataCollection(
          name: 'resume_variants',
          fromJson: ResumeVariant.fromJson,
        ),
      );
}

/// Aggregates all data-service-backed repositories to load an in-memory snapshot
/// used by the ResumeGenerator.
class DataServiceResumeRepository {
  DataServiceResumeRepository({required Object dataService})
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

  Future<ResumeRepository> loadAll() async {
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
