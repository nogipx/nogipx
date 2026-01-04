import 'models.dart';

class ResumeRepository {
  ResumeRepository({
    List<Profile>? profiles,
    List<Experience>? experiences,
    List<Bullet>? bullets,
    List<Skill>? skills,
    List<Project>? projects,
    List<Education>? education,
    List<ResumeVariant>? variants,
    List<MediaAsset>? mediaAssets,
  })  : profiles = profiles ?? [],
        experiences = experiences ?? [],
        bullets = bullets ?? [],
        skills = skills ?? [],
        projects = projects ?? [],
        education = education ?? [],
        variants = variants ?? [],
        mediaAssets = mediaAssets ?? [];

  final List<Profile> profiles;
  final List<Experience> experiences;
  final List<Bullet> bullets;
  final List<Skill> skills;
  final List<Project> projects;
  final List<Education> education;
  final List<ResumeVariant> variants;
  final List<MediaAsset> mediaAssets;

  ResumeVariant variantById(String id) =>
      variants.firstWhere((v) => v.id == id, orElse: () => throw StateError('Variant $id not found'));

  MediaAsset? mediaById(String? id) {
    if (id == null) return null;
    for (final asset in mediaAssets) {
      if (asset.id == id && asset.visible) {
        return asset;
      }
    }
    return null;
  }
}
