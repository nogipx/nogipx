import 'dart:convert';

import 'package:career_ledger/career_ledger.dart';
import 'package:rpc_dart_data/rpc_dart_data.dart';

/// Minimal example: load data into an in-memory IDataService from rpc_dart_data
/// and generate a resume JSON.
Future<void> main() async {
  final env = await DataServiceFactory.inMemory();
  final dataService = env.client;

  await _seed(dataService);

  final dataRepos = DataServiceResumeRepository(dataService: dataService);
  final repo = await dataRepos.loadAll();
  final generator = ResumeGenerator(repo);
  final resume = generator.generate('variant_en');

  print(const JsonEncoder.withIndent('  ').convert(resume.toJson()));
}

Future<void> _seed(dynamic dataService) async {
  final seed = _seedData();
  for (final entry in seed.entries) {
    final collection = entry.key;
    for (final record in entry.value) {
      await dataService.create(collection: collection, payload: record);
    }
  }
}

Map<String, List<Map<String, Object?>>> _seedData() {
  final now = DateTime.utc(2020, 1, 1).millisecondsSinceEpoch;

  return {
    'media_assets': [
      {
        'id': 'avatar1',
        'data_base64': 'ZGF0YQ==', // "data" in base64
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
        'full_name_ru': 'Алекс Доу',
        'title_en': 'Engineer',
        'title_ru': 'Инженер',
        'summary_en': 'Builds things.',
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
        'tags': ['relevant'],
      },
    ],
    'projects': [
      {
        'id': 'proj1',
        'name_en': 'Resume Generator',
        'summary_en': 'Builds resumes.',
        'started_at': now,
        'logo_image_id': 'logo1',
        'link': 'https://example.com',
      },
    ],
    'skills': [
      {
        'id': 'skill1',
        'name_en': 'Dart',
        'level': 5,
        'category': 'Backend',
      },
    ],
    'education': [
      {
        'id': 'edu1',
        'institution_en': 'MIT',
        'degree_en': 'MSc CS',
        'started_at': now,
        'ended_at': now,
      },
    ],
    'bullets': [
      {
        'id': 'b1',
        'text_en': 'Delivered X.',
        'experience_id': 'exp1',
      },
    ],
    'resume_variants': [
      {
        'id': 'variant_en',
        'name': 'English Full',
        'lang': 'en',
        'media_mode': 'full',
        'sections': [
          {'type': 'profile'},
          {
            'type': 'experience',
            'sort_field': 'startedAt',
            'sort_desc': true,
          },
          {'type': 'projects'},
          {'type': 'skills'},
          {'type': 'education'},
          {'type': 'bullets'},
        ],
      },
    ],
  };
}
