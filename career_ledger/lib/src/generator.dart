import 'models.dart';
import 'repository.dart';

class ResumeGenerator {
  ResumeGenerator(this.repository);

  final ResumeRepository repository;

  ResumeDocument generate(String variantId) {
    final variant = repository.variantById(variantId);
    final sections = <ResumeSection>[];

    for (final rule in variant.sections) {
      final items = _buildSection(rule, variant);
      if (items.isEmpty) continue;
      sections.add(ResumeSection(type: rule.type, items: items));
    }

    return ResumeDocument(
      variantId: variant.id,
      lang: variant.lang,
      sections: sections,
    );
  }

  List<Map<String, Object?>> _buildSection(SectionRule rule, ResumeVariant variant) {
    switch (rule.type) {
      case SectionType.profile:
        return _buildProfiles(rule, variant);
      case SectionType.experience:
        return _buildExperiences(rule, variant);
      case SectionType.projects:
        return _buildProjects(rule, variant);
      case SectionType.skills:
        return _buildSkills(rule, variant);
      case SectionType.education:
        return _buildEducation(rule, variant);
      case SectionType.bullets:
        return _buildBullets(rule, variant);
    }
  }

  List<Map<String, Object?>> _buildProfiles(SectionRule rule, ResumeVariant variant) {
    final records = repository.profiles.where((profile) {
      return _isVisible(profile, rule, variant) &&
          profile.fullName.has(variant.lang) &&
          profile.title.has(variant.lang);
    }).toList();

    final sorted = _applySort(records, rule, variant.lang);
    final limited = _applyLimit(sorted, rule.limit);

    return limited
        .map((profile) => _removeNulls({
              'id': profile.id,
              'fullName': profile.fullName.forLang(variant.lang),
              'title': profile.title.forLang(variant.lang),
              'summary': profile.summary?.forLang(variant.lang),
              'location': profile.location?.forLang(variant.lang),
              'tags': profile.tags,
              'avatar': _resolveMedia(profile.avatarImageId, variant),
            }))
        .toList();
  }

  List<Map<String, Object?>> _buildExperiences(SectionRule rule, ResumeVariant variant) {
    final records = repository.experiences.where((exp) {
      return _isVisible(exp, rule, variant) &&
          exp.company.has(variant.lang) &&
          exp.position.has(variant.lang);
    }).toList();

    final sorted = _applySort(records, rule, variant.lang);
    final limited = _applyLimit(sorted, rule.limit);

    return limited
        .map((exp) => _removeNulls({
              'id': exp.id,
              'company': exp.company.forLang(variant.lang),
              'position': exp.position.forLang(variant.lang),
              'description': exp.description?.forLang(variant.lang),
              'city': exp.city?.forLang(variant.lang),
              'startedAt': exp.startedAt,
              'endedAt': exp.endedAt,
              'period': _formatPeriod(exp.startedAt, exp.endedAt, variant.lang),
              'tags': exp.tags,
              'logo': _resolveMedia(exp.logoImageId, variant),
            }))
        .toList();
  }

  List<Map<String, Object?>> _buildProjects(SectionRule rule, ResumeVariant variant) {
    final records = repository.projects.where((project) {
      return _isVisible(project, rule, variant) && project.name.has(variant.lang);
    }).toList();

    final sorted = _applySort(records, rule, variant.lang);
    final limited = _applyLimit(sorted, rule.limit);

    return limited
        .map((project) => _removeNulls({
              'id': project.id,
              'name': project.name.forLang(variant.lang),
              'summary': project.summary?.forLang(variant.lang),
              'link': project.link,
              'startedAt': project.startedAt,
              'endedAt': project.endedAt,
              'period': _formatPeriod(project.startedAt, project.endedAt, variant.lang),
              'tags': project.tags,
              'logo': _resolveMedia(project.logoImageId, variant),
            }))
        .toList();
  }

  List<Map<String, Object?>> _buildSkills(SectionRule rule, ResumeVariant variant) {
    final records = repository.skills.where((skill) {
      return _isVisible(skill, rule, variant) && skill.name.has(variant.lang);
    }).toList();

    final sorted = _applySort(records, rule, variant.lang);
    final limited = _applyLimit(sorted, rule.limit);

    return limited
        .map((skill) => _removeNulls({
              'id': skill.id,
              'name': skill.name.forLang(variant.lang),
              'level': skill.level,
              'category': skill.category,
              'tags': skill.tags,
            }))
        .toList();
  }

  List<Map<String, Object?>> _buildEducation(SectionRule rule, ResumeVariant variant) {
    final records = repository.education.where((edu) {
      return _isVisible(edu, rule, variant) &&
          edu.institution.has(variant.lang) &&
          edu.degree.has(variant.lang);
    }).toList();

    final sorted = _applySort(records, rule, variant.lang);
    final limited = _applyLimit(sorted, rule.limit);

    return limited
        .map((edu) => _removeNulls({
              'id': edu.id,
              'institution': edu.institution.forLang(variant.lang),
              'degree': edu.degree.forLang(variant.lang),
              'description': edu.description?.forLang(variant.lang),
              'startedAt': edu.startedAt,
              'endedAt': edu.endedAt,
              'period': _formatPeriod(edu.startedAt, edu.endedAt, variant.lang),
              'tags': edu.tags,
            }))
        .toList();
  }

  List<Map<String, Object?>> _buildBullets(SectionRule rule, ResumeVariant variant) {
    final validExperienceIds = repository.experiences.where((exp) => exp.visible).map((e) => e.id).toSet();
    final validProjectIds = repository.projects.where((proj) => proj.visible).map((p) => p.id).toSet();

    final records = repository.bullets.where((bullet) {
      final hasTranslation = _isVisible(bullet, rule, variant) && bullet.text.has(variant.lang);
      final hasValidExperience =
          bullet.experienceId == null || (validExperienceIds.contains(bullet.experienceId));
      final hasValidProject = bullet.projectId == null || (validProjectIds.contains(bullet.projectId));
      return hasTranslation && hasValidExperience && hasValidProject;
    }).toList();

    final sorted = _applySort(records, rule, variant.lang);
    final limited = _applyLimit(sorted, rule.limit);

    return limited
        .map((bullet) => _removeNulls({
              'id': bullet.id,
              'text': bullet.text.forLang(variant.lang),
              'experienceId': bullet.experienceId,
              'projectId': bullet.projectId,
              'tags': bullet.tags,
            }))
        .toList();
  }

  List<T> _applyLimit<T>(List<T> list, int? limit) {
    if (limit == null || limit <= 0 || list.length <= limit) return list;
    return list.sublist(0, limit);
  }

  bool _isVisible(RecordBase record, SectionRule rule, ResumeVariant variant) {
    if (!record.visible) return false;

    if (variant.defaultExcludeTags.isNotEmpty &&
        record.tags.any((tag) => variant.defaultExcludeTags.contains(tag))) {
      return false;
    }

    if (rule.excludeTags.isNotEmpty && record.tags.any((tag) => rule.excludeTags.contains(tag))) {
      return false;
    }

    if (rule.includeTags.isNotEmpty) {
      final hasAll = rule.includeTags.every((tag) => record.tags.contains(tag));
      if (!hasAll) return false;
    }

    return true;
  }

  List<T> _applySort<T extends RecordBase>(List<T> records, SectionRule rule, Language lang) {
    if (rule.sort == null) return records;
    final comparator = _comparator<T>(rule.type, rule.sort!, lang);
    if (comparator == null) return records;
    records.sort(comparator);
    if (rule.sort!.descending) {
      return records.reversed.toList();
    }
    return records;
  }

  Comparator<T>? _comparator<T extends RecordBase>(SectionType type, SortRule sort, Language lang) {
    switch (type) {
      case SectionType.profile:
        if (sort.field == 'name') {
          return (a, b) => _compareStrings(
                (a as Profile).fullName.forLang(lang),
                (b as Profile).fullName.forLang(lang),
              );
        }
        return null;
      case SectionType.experience:
        if (sort.field == 'startedAt') {
          return (a, b) => _compareInts((a as Experience).startedAt, (b as Experience).startedAt);
        }
        if (sort.field == 'endedAt') {
          return (a, b) => _compareInts((a as Experience).endedAt, (b as Experience).endedAt);
        }
        return null;
      case SectionType.projects:
        if (sort.field == 'startedAt') {
          return (a, b) => _compareInts((a as Project).startedAt, (b as Project).startedAt);
        }
        if (sort.field == 'endedAt') {
          return (a, b) => _compareInts((a as Project).endedAt, (b as Project).endedAt);
        }
        if (sort.field == 'name') {
          return (a, b) =>
              _compareStrings((a as Project).name.forLang(lang), (b as Project).name.forLang(lang));
        }
        return null;
      case SectionType.skills:
        if (sort.field == 'level') {
          return (a, b) => _compareInts((a as Skill).level, (b as Skill).level);
        }
        if (sort.field == 'name') {
          return (a, b) => _compareStrings((a as Skill).name.forLang(lang), (b as Skill).name.forLang(lang));
        }
        return null;
      case SectionType.education:
        if (sort.field == 'startedAt') {
          return (a, b) => _compareInts((a as Education).startedAt, (b as Education).startedAt);
        }
        if (sort.field == 'endedAt') {
          return (a, b) => _compareInts((a as Education).endedAt, (b as Education).endedAt);
        }
        return null;
      case SectionType.bullets:
        if (sort.field == 'text') {
          return (a, b) => _compareStrings((a as Bullet).text.forLang(lang), (b as Bullet).text.forLang(lang));
        }
        return null;
    }
  }

  int _compareInts(int? a, int? b) {
    final left = a ?? -0x7fffffff;
    final right = b ?? -0x7fffffff;
    return left.compareTo(right);
  }

  int _compareStrings(String? a, String? b) {
    final left = a ?? '';
    final right = b ?? '';
    return left.compareTo(right);
  }

  Map<String, Object?>? _resolveMedia(String? mediaId, ResumeVariant variant) {
    if (mediaId == null || variant.mediaMode == MediaMode.none) return null;
    final asset = repository.mediaById(mediaId);
    if (asset == null) return null;
    if (variant.mediaMode == MediaMode.idsOnly) {
      return _removeNulls({
        'id': asset.id,
        'mime': asset.mime,
      });
    }

    return _removeNulls({
      'id': asset.id,
      'mime': asset.mime,
      'data': asset.dataBase64,
      'alt': asset.alt?.forLang(variant.lang),
      'tags': asset.tags,
    });
  }

  String? _formatPeriod(int? start, int? end, Language lang) {
    if (start == null) return null;
    final startText = _formatMonthYear(start, lang);
    final endText = end != null ? _formatMonthYear(end, lang) : (lang == Language.en ? 'Present' : 'Сейчас');
    return '$startText — $endText';
  }

  String _formatMonthYear(int timestampMs, Language lang) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestampMs, isUtc: true);
    final monthNames = lang == Language.en ? _monthsEn : _monthsRu;
    final month = monthNames[date.month - 1];
    return '$month ${date.year}';
  }

  Map<String, Object?> _removeNulls(Map<String, Object?> source) {
    final copy = <String, Object?>{};
    source.forEach((key, value) {
      if (value == null) return;
      copy[key] = value;
    });
    return copy;
  }
}

const _monthsEn = <String>[
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

const _monthsRu = <String>[
  'Янв',
  'Фев',
  'Мар',
  'Апр',
  'Май',
  'Июн',
  'Июл',
  'Авг',
  'Сен',
  'Окт',
  'Ноя',
  'Дек',
];
