import 'package:career_ledger/career_ledger.dart';
import 'package:rpc_dart_data/rpc_dart_data.dart';
import 'package:test/test.dart';

void main() {
  group('DataServiceResumeLoader', () {
    test('loads from data service and generates resume', () async {
      final dataService = await _seedDataService();
      final dataRepo = DataServiceResumeRepository(dataService: dataService);
      final repo = await dataRepo.getSnapshot();
      final generator = ResumeGenerator(repo);

      final doc = generator.generate('variant1');
      final profile = _section(doc.toJson(), SectionType.profile).first;
      expect(profile['fullName'], 'Alex Doe');
      final exp = _section(doc.toJson(), SectionType.experience).first;
      expect(exp['company'], 'Contoso');
      expect(exp['logo'], isNotNull);
    });
  });

  group('ResumeGenerator', () {
    test('generates resume with media and language filtering', () {
      final repository = _buildRepository();
      final generator = ResumeGenerator(repository);

      final doc = generator.generate('variant_en_full');
      final json = doc.toJson();

      final profileSection = _section(json, SectionType.profile);
      expect(profileSection, isNotEmpty);
      final profile = profileSection.first;
      expect(profile['fullName'], 'Alex Doe');
      expect(
        (profile['avatar'] as Map)['data'],
        isNotEmpty,
        reason: 'avatar base64 included in full mode',
      );

      final experienceSection = _section(json, SectionType.experience);
      expect(experienceSection.length, 1, reason: 'limit applied');
      final exp = experienceSection.first;
      expect(exp['company'], 'Contoso');
      expect(exp['period'], contains('2020'));

      final bulletSection = _section(json, SectionType.bullets);
      expect(
        bulletSection.length,
        1,
        reason: 'bullets without translation are excluded',
      );

      final skillsSection = _section(json, SectionType.skills);
      expect(
        skillsSection.length,
        1,
        reason: 'skills without translation are excluded',
      );
    });

    test('media mode idsOnly strips base64 payload', () {
      final repository = _buildRepository(
        mediaMode: MediaMode.idsOnly,
        variantId: 'variant_en_ids',
      );
      final generator = ResumeGenerator(repository);

      final doc = generator.generate('variant_en_ids');
      final profile = _section(doc.toJson(), SectionType.profile).first;
      final avatar = profile['avatar'] as Map<String, Object?>;
      expect(avatar.containsKey('data'), isFalse);
      expect(avatar['id'], 'avatar1');
      expect(avatar['mime'], 'image/png');
    });
  });
}

List<Map<String, Object?>> _section(
  Map<String, Object?> json,
  SectionType type,
) {
  final sections = (json['sections'] as List).cast<Map<String, Object?>>();
  for (final section in sections) {
    if (section['type'] == type.name) {
      return (section['items'] as List).cast<Map<String, Object?>>();
    }
  }
  return [];
}

ResumeRepository _buildRepository({
  MediaMode mediaMode = MediaMode.full,
  String variantId = 'variant_en_full',
}) {
  final avatar = MediaAsset(
    id: 'avatar1',
    dataBase64: 'ZGF0YQ==', // "data" in base64
    mime: 'image/png',
    alt: const LocalizedText(en: 'Profile photo', ru: 'Фото'),
  );

  final logo = MediaAsset(
    id: 'logo1',
    dataBase64: 'bG9nbw==',
    mime: 'image/png',
    alt: const LocalizedText(en: 'Logo', ru: 'Логотип'),
  );

  final profile = Profile(
    id: 'profile1',
    fullName: const LocalizedText(en: 'Alex Doe', ru: 'Алекс Доу'),
    title: const LocalizedText(en: 'Senior Engineer', ru: 'Старший инженер'),
    summary: const LocalizedText(en: 'Builds things.', ru: 'Строит вещи.'),
    location: const LocalizedText(en: 'Remote', ru: 'Удаленно'),
    avatarImageId: 'avatar1',
  );

  final experience = Experience(
    id: 'exp1',
    company: const LocalizedText(en: 'Contoso', ru: 'Контосо'),
    position: const LocalizedText(en: 'Team Lead', ru: 'Тимлид'),
    startedAt: DateTime.utc(2020, 1, 1).millisecondsSinceEpoch,
    endedAt: DateTime.utc(2021, 6, 1).millisecondsSinceEpoch,
    description: const LocalizedText(
      en: 'Led a team.',
      ru: 'Руководил командой.',
    ),
    city: const LocalizedText(en: 'Berlin', ru: 'Берлин'),
    logoImageId: 'logo1',
    tags: const ['relevant'],
  );

  final hiddenExperience = Experience(
    id: 'exp_hidden',
    company: const LocalizedText(en: 'Hidden', ru: 'Скрытая'),
    position: const LocalizedText(en: 'Ghost', ru: 'Призрак'),
    startedAt: DateTime.utc(2010, 1, 1).millisecondsSinceEpoch,
    tags: const ['hidden'],
  );

  final bulletEn = Bullet(
    id: 'b1',
    text: const LocalizedText(en: 'Delivered X.', ru: 'Сделал X.'),
    experienceId: 'exp1',
  );

  final bulletOnlyRu = Bullet(
    id: 'b2',
    text: const LocalizedText(ru: 'Нет EN.'),
    experienceId: 'exp1',
  );

  final skill = Skill(
    id: 'skill1',
    name: const LocalizedText(en: 'Dart', ru: 'Дарт'),
    level: 5,
    category: 'Backend',
  );

  final skillMissingEn = Skill(
    id: 'skill2',
    name: const LocalizedText(ru: 'Нет перевода'),
  );

  final project = Project(
    id: 'proj1',
    name: const LocalizedText(en: 'Resume Generator', ru: 'Генератор резюме'),
    summary: const LocalizedText(en: 'Build resumes.', ru: 'Собирает резюме.'),
    startedAt: DateTime.utc(2022, 2, 1).millisecondsSinceEpoch,
    logoImageId: 'logo1',
    tags: const ['relevant'],
  );

  final education = Education(
    id: 'edu1',
    institution: const LocalizedText(en: 'MIT', ru: 'МИТ'),
    degree: const LocalizedText(en: 'MSc CS', ru: 'Магистр КН'),
    startedAt: DateTime.utc(2015, 9, 1).millisecondsSinceEpoch,
    endedAt: DateTime.utc(2017, 6, 1).millisecondsSinceEpoch,
  );

  final variant = ResumeVariant(
    id: variantId,
    name: 'English Full',
    lang: Language.en,
    mediaMode: mediaMode,
    defaultExcludeTags: const ['hidden'],
    sections: const [
      SectionRule(type: SectionType.profile),
      SectionRule(
        type: SectionType.experience,
        sort: SortRule(field: 'startedAt', descending: true),
        limit: 1,
      ),
      SectionRule(type: SectionType.projects),
      SectionRule(type: SectionType.skills),
      SectionRule(type: SectionType.education),
      SectionRule(type: SectionType.bullets),
    ],
  );

  return ResumeRepository(
    mediaAssets: [avatar, logo],
    profiles: [profile],
    experiences: [experience, hiddenExperience],
    bullets: [bulletEn, bulletOnlyRu],
    skills: [skill, skillMissingEn],
    projects: [project],
    education: [education],
    variants: [variant],
  );
}

Future<IDataService> _seedDataService() async {
  final env = await DataServiceFactory.inMemory();
  final dataService = env.client;
  final seed = _seedData();
  for (final entry in seed.entries) {
    final collection = entry.key;
    for (final record in entry.value) {
      await dataService.create(collection: collection, payload: record);
    }
  }
  return dataService;
}

Map<String, List<Map<String, Object?>>> _seedData() {
  final now = DateTime.utc(2020, 1, 1).millisecondsSinceEpoch;
  return {
    'media_assets': [
      {
        'id': 'avatar1',
        'data_base64': 'ZGF0YQ==',
        'mime': 'image/png',
        'alt_en': 'Avatar',
      },
      {
        'id': 'logo1',
        'data_base64': 'bG9nbw==',
        'mime': 'image/png',
        'alt_en': 'Logo',
      },
    ],
    'profiles': [
      {
        'id': 'profile1',
        'full_name_en': 'Alex Doe',
        'title_en': 'Engineer',
        'avatar_image_id': 'avatar1',
      },
    ],
    'experiences': [
      {
        'id': 'exp1',
        'company_en': 'Contoso',
        'position_en': 'Lead',
        'started_at': now,
        'logo_image_id': 'logo1',
      },
    ],
    'projects': [],
    'skills': [],
    'education': [],
    'bullets': [],
    'resume_variants': [
      {
        'id': 'variant1',
        'lang': 'en',
        'media_mode': 'full',
        'sections': [
          {'type': 'profile'},
          {'type': 'experience'},
        ],
      },
    ],
  };
}
