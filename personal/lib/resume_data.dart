import 'package:rpc_dart_data/rpc_dart_data.dart';

class ResumeDataEnv {
  ResumeDataEnv({required this.env});

  final InMemoryDataServiceEnvironment env;

  DataServiceClient get client => env.client;
}

class ResumeProfile {
  ResumeProfile({
    required this.name,
    required this.role,
    required this.location,
    required this.citizenship,
    required this.salary,
    required this.contacts,
    required this.formats,
    required this.specializations,
    required this.publisher,
  });

  final String name;
  final String role;
  final String location;
  final String citizenship;
  final String salary;
  final ResumeContacts contacts;
  final List<String> formats;
  final List<String> specializations;
  final String publisher;
}

class ResumeContacts {
  const ResumeContacts({
    required this.phone,
    required this.email,
    required this.telegram,
  });

  final String phone;
  final String email;
  final String telegram;
}

class ResumeExperience {
  ResumeExperience({
    required this.company,
    required this.city,
    required this.role,
    required this.period,
    required this.duration,
    required this.points,
    required this.order,
  });

  final String company;
  final String city;
  final String role;
  final String period;
  final String duration;
  final List<String> points;
  final int order;
}

class ResumeSkills {
  const ResumeSkills({
    required this.core,
    required this.tools,
    required this.languages,
    required this.formats,
    required this.specializations,
  });

  final List<String> core;
  final List<String> tools;
  final List<String> languages;
  final List<String> formats;
  final List<String> specializations;
}

class ResumeLibrary {
  const ResumeLibrary({
    required this.name,
    required this.description,
    required this.order,
  });

  final String name;
  final String description;
  final int order;
}

class ResumeExtras {
  const ResumeExtras({required this.notes});

  final List<String> notes;
}

class ResumeRepository {
  const ResumeRepository(this.client);

  final DataServiceClient client;

  Future<ResumeProfile> loadProfile() async {
    final record = await client.get(collection: 'profile', id: 'me');
    if (record == null) {
      throw StateError('resume profile is missing');
    }
    final payload = record.payload;
    final contacts = payload['contacts'] as Map<String, dynamic>;
    return ResumeProfile(
      name: payload['name'] as String,
      role: payload['role'] as String,
      location: payload['location'] as String,
      citizenship: payload['citizenship'] as String,
      salary: payload['salary'] as String,
      formats: List<String>.from(payload['formats'] as List<dynamic>),
      specializations: List<String>.from(
        payload['specializations'] as List<dynamic>,
      ),
      publisher: payload['publisher'] as String,
      contacts: ResumeContacts(
        phone: contacts['phone'] as String,
        email: contacts['email'] as String,
        telegram: contacts['telegram'] as String,
      ),
    );
  }

  Future<List<ResumeExperience>> loadExperience() async {
    final records = await client.listAllRecords(
      collection: 'experience',
      sort: const SortOrder(field: 'order'),
    );
    return records
        .map(
          (rec) => ResumeExperience(
            company: rec.payload['company'] as String,
            city: rec.payload['city'] as String,
            role: rec.payload['role'] as String,
            period: rec.payload['period'] as String,
            duration: rec.payload['duration'] as String,
            points: List<String>.from(rec.payload['points'] as List<dynamic>),
            order: rec.payload['order'] as int,
          ),
        )
        .toList();
  }

  Future<ResumeSkills> loadSkills() async {
    final record = await client.get(collection: 'skills', id: 'skills');
    if (record == null) {
      throw StateError('skills are missing');
    }
    final payload = record.payload;
    return ResumeSkills(
      core: List<String>.from(payload['core'] as List<dynamic>),
      tools: List<String>.from(payload['tools'] as List<dynamic>),
      languages: List<String>.from(payload['languages'] as List<dynamic>),
      formats: List<String>.from(payload['formats'] as List<dynamic>),
      specializations: List<String>.from(
        payload['specializations'] as List<dynamic>,
      ),
    );
  }

  Future<List<ResumeLibrary>> loadLibraries() async {
    final records = await client.listAllRecords(
      collection: 'libraries',
      sort: const SortOrder(field: 'order'),
    );
    return records
        .map(
          (rec) => ResumeLibrary(
            name: rec.payload['name'] as String,
            description: rec.payload['description'] as String,
            order: rec.payload['order'] as int,
          ),
        )
        .toList();
  }

  Future<ResumeExtras> loadExtras() async {
    final record = await client.get(collection: 'extras', id: 'extras');
    if (record == null) {
      throw StateError('extras are missing');
    }
    return ResumeExtras(
      notes: List<String>.from(record.payload['notes'] as List<dynamic>),
    );
  }
}

Future<ResumeDataEnv> bootstrapResumeData() async {
  final env = await DataServiceFactory.inMemory(
    serverLabel: 'resume-data-server',
    clientLabel: 'resume-data-client',
  );
  await _seed(env.client);
  return ResumeDataEnv(env: env);
}

Future<void> _seed(DataServiceClient client) async {
  final existingProfile = await client.get(collection: 'profile', id: 'me');
  if (existingProfile != null) {
    return;
  }

  await client.create(
    collection: 'profile',
    id: 'me',
    payload: {
      'name': 'Маматказин Карим',
      'role': 'Flutter-разработчик',
      'location': 'Краснодар',
      'citizenship': 'Россия',
      'salary': '250 000 ₽ на руки',
      'publisher': 'dart.nogipx.dev',
      'formats': [
        'полная занятость',
        'частичная занятость',
        'проектная работа',
      ],
      'specializations': [
        'Программист, разработчик',
        'Руководитель группы разработки',
        'Системный инженер',
      ],
      'contacts': {
        'phone': '+7 (906) 187-43-65',
        'email': 'nogipx@gmail.com',
        'telegram': '@yegpx',
      },
    },
  );

  await client.create(
    collection: 'skills',
    id: 'skills',
    payload: {
      'core': [
        'Dart',
        'Flutter',
        'BLoC',
        'Git',
        'Java',
        'Kotlin',
        'Python',
        'SQLite',
        'Linux',
        'Android',
        'iOS',
      ],
      'tools': [
        'CI/CD (GitlabCI, Github Actions, Codemagic, Bitrise)',
        'Firebase',
        'Sentry',
        'gRPC/REST',
        'Фоновая работа и интеграция нативного кода',
      ],
      'languages': ['Русский — родной', 'Английский — B1'],
      'formats': [
        'полная занятость',
        'частичная занятость',
        'проектная работа',
      ],
      'specializations': [
        'Программист, разработчик',
        'Руководитель группы разработки',
        'Системный инженер',
      ],
    },
  );

  final experiences = [
    (
      id: 'bristol',
      order: 1,
      company: 'Бристоль Ритейл Логистикс',
      city: 'Москва',
      role: 'Flutter-разработчик',
      period: 'Апрель 2023 — настоящее время',
      duration: '2 года 10 месяцев',
      points: [
        'Рефакторинг архитектуры и рост экспертизы команды.',
        'Поддержка инфраструктуры CI.',
        'Проектирование и разработка нового функционала.',
        'Запуск и сопровождение сложных модулей приложения.',
        'Инструменты для повышения эффективности manual-QA.',
      ],
    ),
    (
      id: 'magnit',
      order: 2,
      company: 'МАГНИТ',
      city: 'Россия',
      role: 'Flutter-разработчик',
      period: 'Май 2022 — Апрель 2023',
      duration: '1 год',
      points: [
        'Динамическая фильтрация дерева товаров с 5 уровнями вложенности.',
        'Инструмент для упрощения конфигурации сборок в yaml, наподобие melos.',
        'Запуск и поддержка модуля печати ценников.',
      ],
    ),
    (
      id: 'croc',
      order: 3,
      company: 'Крок инкорпорейтед',
      city: 'Москва',
      role: 'Flutter-разработчик',
      period: 'Июль 2021 — Май 2022',
      duration: '11 месяцев',
      points: [
        'Руководство командной разработкой кроссплатформенного приложения.',
        'Создание нативных Flutter-плагинов.',
        'Интеграция пуш-уведомлений и специфичных кейсов.',
        'Публикации в AppStore и GooglePlay.',
      ],
    ),
    (
      id: 'itmo',
      order: 4,
      company:
          'Санкт-Петербургский национальный исследовательский университет ИТМО',
      city: 'Санкт-Петербург',
      role: 'Flutter-разработчик',
      period: 'Сентябрь 2020 — Июль 2021',
      duration: '11 месяцев',
      points: [
        'Сбор требований и разработка UI по макетам.',
        'Публикации приложений в AppStore и GooglePlay.',
        'Интеграция Firebase и Sentry.',
        'Участие в развитии концепции продукта.',
      ],
    ),
  ];

  for (final exp in experiences) {
    await client.create(
      collection: 'experience',
      id: exp.id,
      payload: {
        'company': exp.company,
        'city': exp.city,
        'role': exp.role,
        'period': exp.period,
        'duration': exp.duration,
        'points': exp.points,
        'order': exp.order,
      },
    );
  }

  final libraries = [
    (
      id: 'rpc_dart',
      order: 1,
      name: 'rpc_dart',
      description:
          'Удалённые вызовы процедур с transport-агностичной обвязкой.',
    ),
    (
      id: 'licensify',
      order: 2,
      name: 'licensify',
      description: 'Гибкое создание и управление криптолицензиями.',
    ),
    (
      id: 'paseto_dart',
      order: 3,
      name: 'paseto_dart',
      description: 'Реализация спецификации PASETO v4.',
    ),
  ];

  for (final lib in libraries) {
    await client.create(
      collection: 'libraries',
      id: lib.id,
      payload: {
        'name': lib.name,
        'description': lib.description,
        'order': lib.order,
      },
    );
  }

  await client.create(
    collection: 'extras',
    id: 'extras',
    payload: {
      'notes': [
        'Telegram: @yegpx',
        'Менторство и ввод в проекты, проведение технических собеседований.',
        'Координация выпусков новых версий приложений.',
        'CI/CD пайплайны: GitlabCI, Github Actions, Codemagic, Bitrise.',
        'Работа с фоновыми задачами и нативным кодом для iOS/Android.',
        'Знаком со всеми основными методологиями разработки.',
      ],
    },
  );
}
