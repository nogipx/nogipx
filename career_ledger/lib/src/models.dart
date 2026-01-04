enum Language { en, ru }

enum MediaMode { none, idsOnly, full }

enum SectionType { profile, experience, projects, skills, education, bullets }

class LocalizedText {
  const LocalizedText({this.en, this.ru});

  final String? en;
  final String? ru;

  String? forLang(Language lang) => switch (lang) { Language.en => en, Language.ru => ru };

  bool has(Language lang) {
    final value = forLang(lang);
    return value != null && value.trim().isNotEmpty;
  }

  factory LocalizedText.fromPrefix(Map<String, dynamic> data, String prefix) {
    return LocalizedText(
      en: _string(data['${prefix}_en']),
      ru: _string(data['${prefix}_ru']),
    );
  }
}

abstract class RecordBase {
  RecordBase({
    required this.id,
    this.version = 0,
    this.visible = true,
    List<String>? tags,
    this.terms,
  }) : tags = tags ?? const [];

  final String id;
  final int version;
  final bool visible;
  final List<String> tags;
  final String? terms;
}

class MediaAsset extends RecordBase {
  MediaAsset({
    required super.id,
    required this.dataBase64,
    this.mime,
    this.alt,
    super.version,
    super.visible,
    super.tags,
    super.terms,
  });

  final String dataBase64;
  final String? mime;
  final LocalizedText? alt;

  factory MediaAsset.fromJson(Map<String, dynamic> data) {
    return MediaAsset(
      id: _string(data['id']) ?? '',
      version: _int(data['version']) ?? 0,
      visible: _visible(data['visibility']),
      tags: _tags(data['tags']),
      terms: _string(data['terms']),
      dataBase64: _string(data['data_base64']) ?? '',
      mime: _string(data['mime']),
      alt: LocalizedText.fromPrefix(data, 'alt'),
    );
  }
}

class Profile extends RecordBase {
  Profile({
    required super.id,
    required this.fullName,
    required this.title,
    this.summary,
    this.location,
    this.avatarImageId,
    super.version,
    super.visible,
    super.tags,
    super.terms,
  });

  final LocalizedText fullName;
  final LocalizedText title;
  final LocalizedText? summary;
  final LocalizedText? location;
  final String? avatarImageId;

  factory Profile.fromJson(Map<String, dynamic> data) {
    return Profile(
      id: _string(data['id']) ?? '',
      version: _int(data['version']) ?? 0,
      visible: _visible(data['visibility']),
      tags: _tags(data['tags']),
      terms: _string(data['terms']),
      fullName: LocalizedText.fromPrefix(data, 'full_name'),
      title: LocalizedText.fromPrefix(data, 'title'),
      summary: LocalizedText.fromPrefix(data, 'summary'),
      location: LocalizedText.fromPrefix(data, 'location'),
      avatarImageId: _string(data['avatar_image_id']),
    );
  }
}

class Experience extends RecordBase {
  Experience({
    required super.id,
    required this.company,
    required this.position,
    required this.startedAt,
    this.endedAt,
    this.description,
    this.city,
    this.logoImageId,
    super.version,
    super.visible,
    super.tags,
    super.terms,
  });

  final LocalizedText company;
  final LocalizedText position;
  final int startedAt;
  final int? endedAt;
  final LocalizedText? description;
  final LocalizedText? city;
  final String? logoImageId;

  factory Experience.fromJson(Map<String, dynamic> data) {
    return Experience(
      id: _string(data['id']) ?? '',
      version: _int(data['version']) ?? 0,
      visible: _visible(data['visibility']),
      tags: _tags(data['tags']),
      terms: _string(data['terms']),
      company: LocalizedText.fromPrefix(data, 'company'),
      position: LocalizedText.fromPrefix(data, 'position'),
      startedAt: _int(data['started_at']) ?? 0,
      endedAt: _int(data['ended_at']),
      description: LocalizedText.fromPrefix(data, 'description'),
      city: LocalizedText.fromPrefix(data, 'city'),
      logoImageId: _string(data['logo_image_id']),
    );
  }
}

class Bullet extends RecordBase {
  Bullet({
    required super.id,
    required this.text,
    this.experienceId,
    this.projectId,
    super.version,
    super.visible,
    super.tags,
    super.terms,
  });

  final LocalizedText text;
  final String? experienceId;
  final String? projectId;

  factory Bullet.fromJson(Map<String, dynamic> data) {
    return Bullet(
      id: _string(data['id']) ?? '',
      version: _int(data['version']) ?? 0,
      visible: _visible(data['visibility']),
      tags: _tags(data['tags']),
      terms: _string(data['terms']),
      text: LocalizedText.fromPrefix(data, 'text'),
      experienceId: _string(data['experience_id']),
      projectId: _string(data['project_id']),
    );
  }
}

class Skill extends RecordBase {
  Skill({
    required super.id,
    required this.name,
    this.level,
    this.category,
    super.version,
    super.visible,
    super.tags,
    super.terms,
  });

  final LocalizedText name;
  final int? level;
  final String? category;

  factory Skill.fromJson(Map<String, dynamic> data) {
    return Skill(
      id: _string(data['id']) ?? '',
      version: _int(data['version']) ?? 0,
      visible: _visible(data['visibility']),
      tags: _tags(data['tags']),
      terms: _string(data['terms']),
      name: LocalizedText.fromPrefix(data, 'name'),
      level: _int(data['level']),
      category: _string(data['category']),
    );
  }
}

class Project extends RecordBase {
  Project({
    required super.id,
    required this.name,
    this.summary,
    this.startedAt,
    this.endedAt,
    this.logoImageId,
    this.link,
    super.version,
    super.visible,
    super.tags,
    super.terms,
  });

  final LocalizedText name;
  final LocalizedText? summary;
  final int? startedAt;
  final int? endedAt;
  final String? logoImageId;
  final String? link;

  factory Project.fromJson(Map<String, dynamic> data) {
    return Project(
      id: _string(data['id']) ?? '',
      version: _int(data['version']) ?? 0,
      visible: _visible(data['visibility']),
      tags: _tags(data['tags']),
      terms: _string(data['terms']),
      name: LocalizedText.fromPrefix(data, 'name'),
      summary: LocalizedText.fromPrefix(data, 'summary'),
      startedAt: _int(data['started_at']),
      endedAt: _int(data['ended_at']),
      logoImageId: _string(data['logo_image_id']),
      link: _string(data['link']),
    );
  }
}

class Education extends RecordBase {
  Education({
    required super.id,
    required this.institution,
    required this.degree,
    required this.startedAt,
    this.endedAt,
    this.description,
    super.version,
    super.visible,
    super.tags,
    super.terms,
  });

  final LocalizedText institution;
  final LocalizedText degree;
  final int startedAt;
  final int? endedAt;
  final LocalizedText? description;

  factory Education.fromJson(Map<String, dynamic> data) {
    return Education(
      id: _string(data['id']) ?? '',
      version: _int(data['version']) ?? 0,
      visible: _visible(data['visibility']),
      tags: _tags(data['tags']),
      terms: _string(data['terms']),
      institution: LocalizedText.fromPrefix(data, 'institution'),
      degree: LocalizedText.fromPrefix(data, 'degree'),
      startedAt: _int(data['started_at']) ?? 0,
      endedAt: _int(data['ended_at']),
      description: LocalizedText.fromPrefix(data, 'description'),
    );
  }
}

class SortRule {
  const SortRule({required this.field, this.descending = false});

  final String field;
  final bool descending;

  factory SortRule.fromJson(Map<String, dynamic> data) {
    return SortRule(
      field: _string(data['sort_field']) ?? '',
      descending: _bool(data['sort_desc']) ?? false,
    );
  }
}

class SectionRule {
  const SectionRule({
    required this.type,
    this.includeTags = const [],
    this.excludeTags = const [],
    this.limit,
    this.sort,
  });

  final SectionType type;
  final List<String> includeTags;
  final List<String> excludeTags;
  final int? limit;
  final SortRule? sort;

  factory SectionRule.fromJson(Map<String, dynamic> data) {
    return SectionRule(
      type: _parseSectionType(data['type']),
      includeTags: _tags(data['include_tags']),
      excludeTags: _tags(data['exclude_tags']),
      limit: _int(data['limit']),
      sort: _string(data['sort_field']) != null ? SortRule.fromJson(data) : null,
    );
  }
}

class ResumeVariant {
  ResumeVariant({
    required this.id,
    required this.lang,
    required this.sections,
    this.name,
    this.mediaMode = MediaMode.full,
    this.defaultExcludeTags = const [],
  });

  final String id;
  final String? name;
  final Language lang;
  final List<SectionRule> sections;
  final MediaMode mediaMode;
  final List<String> defaultExcludeTags;

  factory ResumeVariant.fromJson(Map<String, dynamic> data) {
    final sectionsRaw = data['sections'];
    final sections = <SectionRule>[];
    if (sectionsRaw is List) {
      for (final raw in sectionsRaw) {
        if (raw is Map) {
          sections.add(SectionRule.fromJson(Map<String, dynamic>.from(raw)));
        }
      }
    }

    return ResumeVariant(
      id: _string(data['id']) ?? '',
      name: _string(data['name']),
      lang: _parseLang(data['lang']),
      mediaMode: _parseMediaMode(data['media_mode']),
      defaultExcludeTags: _tags(data['default_exclude_tags']),
      sections: sections,
    );
  }
}

class ResumeDocument {
  ResumeDocument({
    required this.variantId,
    required this.lang,
    required this.sections,
  });

  final String variantId;
  final Language lang;
  final List<ResumeSection> sections;

  Map<String, Object?> toJson() => {
        'variantId': variantId,
        'lang': lang.name,
        'sections': sections.map((section) => section.toJson()).toList(),
      };
}

class ResumeSection {
  ResumeSection({required this.type, required this.items});

  final SectionType type;
  final List<Map<String, Object?>> items;

  Map<String, Object?> toJson() => {
        'type': type.name,
        'items': items,
      };
}

Language _parseLang(dynamic value) {
  final raw = _string(value)?.toLowerCase();
  switch (raw) {
    case 'ru':
      return Language.ru;
    case 'en':
    default:
      return Language.en;
  }
}

MediaMode _parseMediaMode(dynamic value) {
  final raw = _string(value)?.toLowerCase();
  switch (raw) {
    case 'none':
      return MediaMode.none;
    case 'idsonly':
    case 'ids_only':
    case 'ids-only':
      return MediaMode.idsOnly;
    default:
      return MediaMode.full;
  }
}

SectionType _parseSectionType(dynamic value) {
  final raw = _string(value)?.toLowerCase();
  switch (raw) {
    case 'profile':
      return SectionType.profile;
    case 'experience':
      return SectionType.experience;
    case 'projects':
      return SectionType.projects;
    case 'skills':
      return SectionType.skills;
    case 'education':
      return SectionType.education;
    case 'bullets':
    default:
      return SectionType.bullets;
  }
}

List<String> _tags(dynamic value) {
  if (value == null) return const [];
  if (value is List) {
    return value.where((e) => e != null).map((e) => e.toString()).toList();
  }
  if (value is String) {
    return value
        .split(RegExp(r'[ ,]+'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }
  return const [];
}

String? _string(dynamic value) {
  if (value == null) return null;
  return value.toString();
}

int? _int(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}

bool? _bool(dynamic value) {
  if (value == null) return null;
  if (value is bool) return value;
  if (value is num) return value != 0;
  final text = value.toString().toLowerCase();
  return text == 'true' || text == '1';
}

bool _visible(dynamic value) => _bool(value) ?? true;
