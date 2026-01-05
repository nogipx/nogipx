import 'dart:convert';

import 'package:career_ledger/career_ledger.dart';
import 'package:flutter/material.dart';
import 'package:postgres/postgres.dart';
import 'package:rpc_dart/rpc_dart.dart';
import 'package:rpc_dart_data/rpc_dart_data.dart';
import 'package:uuid/uuid.dart';

void main() {
  runApp(const CareerLedgerApp());
}

class CareerLedgerApp extends StatelessWidget {
  const CareerLedgerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Career Ledger',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const CareerLedgerHome(),
    );
  }
}

class CareerLedgerHome extends StatefulWidget {
  const CareerLedgerHome({super.key});

  @override
  State<CareerLedgerHome> createState() => _CareerLedgerHomeState();
}

class _CareerLedgerHomeState extends State<CareerLedgerHome> {
  final _connection = ConnectionFormState();
  final _uuid = const Uuid();

  bool _connecting = false;
  String? _connectionError;
  String? _status;
  int _selectedIndex = 0;

  RpcResponderEndpoint? _responderEndpoint;
  RpcCallerEndpoint? _callerEndpoint;
  DataServiceResponder? _dataResponder;
  ResumeServiceResponder? _resumeResponder;
  DataServiceClient? _dataClient;
  ResumeContractCaller? _resumeCaller;
  PostgresDataRepository? _repository;

  DataServiceCollection<Profile>? _profiles;
  DataServiceCollection<Experience>? _experiences;
  DataServiceCollection<Project>? _projects;
  DataServiceCollection<Skill>? _skills;
  DataServiceCollection<Education>? _education;
  DataServiceCollection<Bullet>? _bullets;
  DataServiceCollection<MediaAsset>? _mediaAssets;
  DataServiceCollection<ResumeVariant>? _variants;

  @override
  void dispose() {
    _disposeServices();
    _connection.dispose();
    super.dispose();
  }

  Future<void> _disposeServices() async {
    await _responderEndpoint?.close();
    await _dataResponder?.dispose();
    await _callerEndpoint?.close();
    _resumeResponder = null;
    _dataResponder = null;
    _responderEndpoint = null;
    _callerEndpoint = null;
    _dataClient = null;
    _resumeCaller = null;
    _repository = null;
    _profiles = null;
    _experiences = null;
    _projects = null;
    _skills = null;
    _education = null;
    _bullets = null;
    _mediaAssets = null;
    _variants = null;
  }

  void _buildCollections() {
    final dataService = _dataClient;
    if (dataService == null) return;

    _profiles = DataServiceCollection(
      collection: 'profiles',
      dataService: dataService,
      fromJson: Profile.fromJson,
      toJson: (model) => model.toJson(),
      idSelector: (model) => model.id,
    );
    _experiences = DataServiceCollection(
      collection: 'experiences',
      dataService: dataService,
      fromJson: Experience.fromJson,
      toJson: (model) => model.toJson(),
      idSelector: (model) => model.id,
    );
    _projects = DataServiceCollection(
      collection: 'projects',
      dataService: dataService,
      fromJson: Project.fromJson,
      toJson: (model) => model.toJson(),
      idSelector: (model) => model.id,
    );
    _skills = DataServiceCollection(
      collection: 'skills',
      dataService: dataService,
      fromJson: Skill.fromJson,
      toJson: (model) => model.toJson(),
      idSelector: (model) => model.id,
    );
    _education = DataServiceCollection(
      collection: 'education',
      dataService: dataService,
      fromJson: Education.fromJson,
      toJson: (model) => model.toJson(),
      idSelector: (model) => model.id,
    );
    _bullets = DataServiceCollection(
      collection: 'bullets',
      dataService: dataService,
      fromJson: Bullet.fromJson,
      toJson: (model) => model.toJson(),
      idSelector: (model) => model.id,
    );
    _mediaAssets = DataServiceCollection(
      collection: 'media_assets',
      dataService: dataService,
      fromJson: MediaAsset.fromJson,
      toJson: (model) => model.toJson(),
      idSelector: (model) => model.id,
    );
    _variants = DataServiceCollection(
      collection: 'resume_variants',
      dataService: dataService,
      fromJson: ResumeVariant.fromJson,
      toJson: (model) => model.toJson(),
      idSelector: (model) => model.id,
    );
  }

  Future<void> _connect() async {
    setState(() {
      _connecting = true;
      _connectionError = null;
      _status = 'Подключение к Postgres...';
    });

    await _disposeServices();

    try {
      final endpoint = Endpoint(
        host: _connection.host,
        port: _connection.port,
        database: _connection.database,
        username: _connection.username,
        password: _connection.password,
      );
      final settings = ConnectionSettings(
        sslMode: _connection.useSsl ? SslMode.require : SslMode.disable,
        connectTimeout: Duration(seconds: _connection.connectTimeoutSeconds),
        queryTimeout: Duration(seconds: _connection.queryTimeoutSeconds),
      );
      final adapter = await PostgresDataStorageAdapter.connect(
        endpoint: endpoint,
        settings: settings,
        schema: _connection.schema,
        tablePrefix: _connection.tablePrefix,
      );
      final repository = PostgresDataRepository(storage: adapter);
      final (clientTransport, serverTransport) = RpcInMemoryTransport.pair();
      final responderEndpoint = RpcResponderEndpoint(
        transport: serverTransport,
        debugLabel: 'CareerLedgerServer',
      );
      final callerEndpoint = RpcCallerEndpoint(
        transport: clientTransport,
        debugLabel: 'CareerLedgerClient',
      );
      final dataResponder = DataServiceResponder(
        repository: repository,
        transferMode: RpcDataTransferMode.codec,
      );
      responderEndpoint.registerServiceContract(dataResponder);

      final dataCaller = DataServiceCaller(
        endpoint: callerEndpoint,
        transferMode: RpcDataTransferMode.codec,
      );
      final dataClient = DataServiceClient(callerEndpoint, dataCaller);
      final resumeResponder = ResumeServiceResponder(
        dataRepository: DataServiceResumeRepository(dataService: dataClient),
      );
      responderEndpoint.registerServiceContract(resumeResponder);
      responderEndpoint.start();

      setState(() {
        _repository = repository;
        _dataResponder = dataResponder;
        _resumeResponder = resumeResponder;
        _responderEndpoint = responderEndpoint;
        _callerEndpoint = callerEndpoint;
        _dataClient = dataClient;
        _resumeCaller = ResumeContractCaller(callerEndpoint);
        _status =
            'Соединение установлено: ${_connection.host}:${_connection.port}/${_connection.database}';
      });
      _buildCollections();
    } catch (error, stackTrace) {
      debugPrint('Connection error: $error\n$stackTrace');
      setState(() {
        _connectionError = error.toString();
        _status = 'Не удалось подключиться';
      });
    } finally {
      setState(() {
        _connecting = false;
      });
    }
  }

  String _newId(String prefix) => '$prefix-${_uuid.v4().split('-').first}';

  @override
  Widget build(BuildContext context) {
    final tabs = _tabs();
    final selected = tabs[_selectedIndex];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Career Ledger (macOS desktop)'),
        actions: [
          if (_status != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Center(
                child: Text(
                  _status!,
                  style: const TextStyle(fontSize: 14),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          if (_connectionError != null)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Chip(
                label: Text(
                  _connectionError!,
                  style: const TextStyle(color: Colors.white),
                ),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth > 1000) {
            return Row(
              children: [
                NavigationRail(
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: (index) {
                    setState(() {
                      _selectedIndex = index;
                    });
                  },
                  labelType: NavigationRailLabelType.all,
                  destinations: [
                    for (final tab in tabs)
                      NavigationRailDestination(
                        icon: Icon(tab.icon),
                        label: Text(tab.title),
                      ),
                  ],
                ),
                const VerticalDivider(width: 1),
                Expanded(
                  child: IndexedStack(
                    index: _selectedIndex,
                    children: [for (final tab in tabs) tab.builder(context)],
                  ),
                ),
              ],
            );
          }
          return Column(
            children: [
              Expanded(child: selected.builder(context)),
              SafeArea(
                child: NavigationBar(
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: (index) {
                    setState(() {
                      _selectedIndex = index;
                    });
                  },
                  destinations: [
                    for (final tab in tabs)
                      NavigationDestination(
                        icon: Icon(tab.icon),
                        label: tab.title,
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  List<_TabConfig> _tabs() => [
        _TabConfig(
          title: 'Подключение',
          icon: Icons.storage,
          builder: (_) => _buildConnectionTab(),
        ),
        _TabConfig(
          title: 'Профиль',
          icon: Icons.person,
          builder: (_) => _buildProfilesTab(),
        ),
        _TabConfig(
          title: 'Опыт',
          icon: Icons.work_history,
          builder: (_) => _buildExperienceTab(),
        ),
        _TabConfig(
          title: 'Проекты',
          icon: Icons.account_tree,
          builder: (_) => _buildProjectsTab(),
        ),
        _TabConfig(
          title: 'Навыки',
          icon: Icons.lightbulb,
          builder: (_) => _buildSkillsTab(),
        ),
        _TabConfig(
          title: 'Образование',
          icon: Icons.school,
          builder: (_) => _buildEducationTab(),
        ),
        _TabConfig(
          title: 'Буллеты',
          icon: Icons.list_alt,
          builder: (_) => _buildBulletsTab(),
        ),
        _TabConfig(
          title: 'Медиа',
          icon: Icons.photo_library,
          builder: (_) => _buildMediaTab(),
        ),
        _TabConfig(
          title: 'Варианты резюме',
          icon: Icons.dashboard_customize,
          builder: (_) => _buildVariantsTab(),
        ),
        _TabConfig(
          title: 'Сборка резюме',
          icon: Icons.description,
          builder: (_) => _buildResumeBuilder(),
        ),
      ];

  Widget _buildConnectionTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Postgres + rpc_dart_data',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              'Клиент использует PostgresDataStorageAdapter через rpc_dart_data и поднимает '
              'in-memory RPC endpoint (DataService + ResumeService) внутри приложения.',
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 16,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: 280,
                  child: TextField(
                    controller: _connection.hostController,
                    decoration: const InputDecoration(
                      labelText: 'Host',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                SizedBox(
                  width: 140,
                  child: TextField(
                    controller: _connection.portController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Port',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                SizedBox(
                  width: 240,
                  child: TextField(
                    controller: _connection.databaseController,
                    decoration: const InputDecoration(
                      labelText: 'Database',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                SizedBox(
                  width: 220,
                  child: TextField(
                    controller: _connection.usernameController,
                    decoration: const InputDecoration(
                      labelText: 'Username',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                SizedBox(
                  width: 240,
                  child: TextField(
                    controller: _connection.passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                SizedBox(
                  width: 200,
                  child: TextField(
                    controller: _connection.schemaController,
                    decoration: const InputDecoration(
                      labelText: 'Schema',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                SizedBox(
                  width: 220,
                  child: TextField(
                    controller: _connection.prefixController,
                    decoration: const InputDecoration(
                      labelText: 'Table prefix',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SizedBox(
                  width: 220,
                  child: TextField(
                    controller: _connection.connectTimeoutController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Connect timeout (сек)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                SizedBox(
                  width: 220,
                  child: TextField(
                    controller: _connection.queryTimeoutController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Query timeout (сек)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                FilterChip(
                  selected: _connection.useSsl,
                  label: const Text('Использовать SSL'),
                  onSelected: (v) {
                    setState(() => _connection.useSsl = v);
                  },
                ),
                ElevatedButton.icon(
                  onPressed: _connecting ? null : _connect,
                  icon: _connecting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.play_arrow),
                  label: const Text('Подключиться'),
                ),
                if (_dataClient != null)
                  OutlinedButton.icon(
                    onPressed: _connecting ? null : _disposeServices,
                    icon: const Icon(Icons.stop),
                    label: const Text('Отключиться'),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            Card(
              margin: const EdgeInsets.only(top: 8),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Что происходит после подключения?',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '• Создается PostgresDataStorageAdapter и PostgresDataRepository.\n'
                      '• Поднимается in-memory RPC transport (RpcInMemoryTransport.pair).\n'
                      '• На сервер регистрируются DataServiceResponder и ResumeServiceResponder.\n'
                      '• Клиентские коллекции и генератор резюме используют DataServiceClient.',
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _status ?? 'Нет активного соединения.',
                      style: TextStyle(
                        color: _dataClient != null
                            ? Colors.green.shade700
                            : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfilesTab() {
    final collection = _profiles;
    if (collection == null) return _needsConnection();
    return _CollectionList<Profile>(
      title: 'Профиль',
      collection: collection,
      idSelector: (p) => p.id,
      titleBuilder: (p) => p.fullName.en ?? p.fullName.ru ?? p.id,
      subtitleBuilder: (p) => p.title.en ?? p.title.ru ?? '',
      editor: (existing) => _showProfileDialog(existing),
    );
  }

  Widget _buildExperienceTab() {
    final collection = _experiences;
    if (collection == null) return _needsConnection();
    return _CollectionList<Experience>(
      title: 'Опыт работы',
      collection: collection,
      idSelector: (e) => e.id,
      titleBuilder: (e) => '${e.company.en ?? e.company.ru ?? e.id} — '
          '${e.position.en ?? e.position.ru ?? ''}',
      subtitleBuilder: (e) =>
          'С ${e.startedAt}${e.endedAt != null ? ' по ${e.endedAt}' : ''}',
      editor: (existing) => _showExperienceDialog(existing),
    );
  }

  Widget _buildProjectsTab() {
    final collection = _projects;
    if (collection == null) return _needsConnection();
    return _CollectionList<Project>(
      title: 'Проекты',
      collection: collection,
      idSelector: (p) => p.id,
      titleBuilder: (p) => p.name.en ?? p.name.ru ?? p.id,
      subtitleBuilder: (p) =>
          [p.summary?.en ?? p.summary?.ru, p.link].whereType<String>().join(' • '),
      editor: (existing) => _showProjectDialog(existing),
    );
  }

  Widget _buildSkillsTab() {
    final collection = _skills;
    if (collection == null) return _needsConnection();
    return _CollectionList<Skill>(
      title: 'Навыки',
      collection: collection,
      idSelector: (s) => s.id,
      titleBuilder: (s) => s.name.en ?? s.name.ru ?? s.id,
      subtitleBuilder: (s) => [
        if (s.category != null) s.category!,
        if (s.level != null) 'Уровень: ${s.level}',
      ].join(' • '),
      editor: (existing) => _showSkillDialog(existing),
    );
  }

  Widget _buildEducationTab() {
    final collection = _education;
    if (collection == null) return _needsConnection();
    return _CollectionList<Education>(
      title: 'Образование',
      collection: collection,
      idSelector: (e) => e.id,
      titleBuilder: (e) => e.institution.en ?? e.institution.ru ?? e.id,
      subtitleBuilder: (e) =>
          '${e.degree.en ?? e.degree.ru ?? ''} • ${e.startedAt}-${e.endedAt ?? '...'}',
      editor: (existing) => _showEducationDialog(existing),
    );
  }

  Widget _buildBulletsTab() {
    final collection = _bullets;
    if (collection == null) return _needsConnection();
    return _CollectionList<Bullet>(
      title: 'Буллеты/достижения',
      collection: collection,
      idSelector: (b) => b.id,
      titleBuilder: (b) => b.text.en ?? b.text.ru ?? b.id,
      subtitleBuilder: (b) => [
        if (b.experienceId != null) 'Опыт: ${b.experienceId}',
        if (b.projectId != null) 'Проект: ${b.projectId}',
      ].join(' • '),
      editor: (existing) => _showBulletDialog(existing),
    );
  }

  Widget _buildMediaTab() {
    final collection = _mediaAssets;
    if (collection == null) return _needsConnection();
    return _CollectionList<MediaAsset>(
      title: 'Медиа-активы',
      collection: collection,
      idSelector: (m) => m.id,
      titleBuilder: (m) => m.mime ?? 'Медиа ${m.id}',
      subtitleBuilder: (m) =>
          'Размер base64: ${m.dataBase64.length} • Alt: ${m.alt?.en ?? m.alt?.ru ?? ''}',
      editor: (existing) => _showMediaDialog(existing),
    );
  }

  Widget _buildVariantsTab() {
    final collection = _variants;
    if (collection == null) return _needsConnection();
    return _CollectionList<ResumeVariant>(
      title: 'Варианты резюме',
      collection: collection,
      idSelector: (v) => v.id,
      titleBuilder: (v) => v.name ?? v.id,
      subtitleBuilder: (v) =>
          'Язык: ${v.lang.name} • Секций: ${v.sections.length} • Медиа: ${v.mediaMode.name}',
      editor: (existing) => _showVariantDialog(existing),
    );
  }

  Widget _buildResumeBuilder() {
    final caller = _resumeCaller;
    final variants = _variants;
    if (caller == null || variants == null) return _needsConnection();
    return _ResumeBuilder(
      variantsCollection: variants,
      caller: caller,
    );
  }

  Widget _needsConnection() {
    return const Center(
      child: Text('Подключите Postgres, чтобы редактировать данные.'),
    );
  }

  Future<Profile?> _showProfileDialog(Versioned<Profile>? existing) {
    final base = RecordFormControllers(
      id: existing?.data.id ?? _newId('profile'),
      visible: existing?.data.visible ?? true,
      tags: existing?.data.tags,
      terms: existing?.data.terms,
    );
    final fullName = LocalizedTextControllers(value: existing?.data.fullName);
    final title = LocalizedTextControllers(value: existing?.data.title);
    final summary = LocalizedTextControllers(value: existing?.data.summary);
    final location = LocalizedTextControllers(value: existing?.data.location);
    final avatar = TextEditingController(
      text: existing?.data.avatarImageId ?? '',
    );
    String? error;

    return showDialog<Profile>(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setModalState) {
          return AlertDialog(
            title: Text(
              existing == null ? 'Новый профиль' : 'Редактировать профиль',
            ),
            content: SizedBox(
              width: 600,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RecordBaseFields(
                      controllers: base,
                      onChanged: () => setModalState(() {}),
                    ),
                    const SizedBox(height: 12),
                    LocalizedFields(
                      label: 'Полное имя',
                      controllers: fullName,
                    ),
                    const SizedBox(height: 12),
                    LocalizedFields(
                      label: 'Должность',
                      controllers: title,
                    ),
                    const SizedBox(height: 12),
                    LocalizedFields(
                      label: 'Резюме (summary)',
                      controllers: summary,
                    ),
                    const SizedBox(height: 12),
                    LocalizedFields(
                      label: 'Локация',
                      controllers: location,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: avatar,
                      decoration: const InputDecoration(
                        labelText: 'Avatar image id',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    if (error != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        error!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Отмена'),
              ),
              ElevatedButton(
                onPressed: () {
                  final full = fullName.build();
                  final role = title.build();
                  if (!_hasContent(full) || !_hasContent(role)) {
                    setModalState(
                      () => error = 'Имя и должность должны быть заполнены.',
                    );
                    return;
                  }
                  final profile = Profile(
                    id: base.id.text.trim(),
                    visible: base.visible,
                    tags: _parseTags(base.tags.text),
                    terms: base.terms.text.trim().isEmpty
                        ? null
                        : base.terms.text.trim(),
                    fullName: full,
                    title: role,
                    summary: summary.build(),
                    location: location.build(),
                    avatarImageId: avatar.text.trim().isEmpty
                        ? null
                        : avatar.text.trim(),
                    version: existing?.version ?? 0,
                  );
                  Navigator.pop(context, profile);
                },
                child: const Text('Сохранить'),
              ),
            ],
          );
        });
      },
    );
  }

  Future<Experience?> _showExperienceDialog(
    Versioned<Experience>? existing,
  ) {
    final base = RecordFormControllers(
      id: existing?.data.id ?? _newId('exp'),
      visible: existing?.data.visible ?? true,
      tags: existing?.data.tags,
      terms: existing?.data.terms,
    );
    final company = LocalizedTextControllers(value: existing?.data.company);
    final position = LocalizedTextControllers(value: existing?.data.position);
    final description =
        LocalizedTextControllers(value: existing?.data.description);
    final city = LocalizedTextControllers(value: existing?.data.city);
    final started = TextEditingController(
      text: existing?.data.startedAt.toString() ?? '',
    );
    final ended = TextEditingController(
      text: existing?.data.endedAt?.toString() ?? '',
    );
    final logo = TextEditingController(
      text: existing?.data.logoImageId ?? '',
    );
    String? error;

    return showDialog<Experience>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              title: Text(
                existing == null ? 'Новый опыт' : 'Редактировать опыт',
              ),
              content: SizedBox(
                width: 700,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RecordBaseFields(
                        controllers: base,
                        onChanged: () => setModalState(() {}),
                      ),
                      const SizedBox(height: 12),
                      LocalizedFields(
                        label: 'Компания',
                        controllers: company,
                      ),
                      const SizedBox(height: 12),
                      LocalizedFields(
                        label: 'Позиция',
                        controllers: position,
                      ),
                      const SizedBox(height: 12),
                      LocalizedFields(
                        label: 'Описание',
                        controllers: description,
                      ),
                      const SizedBox(height: 12),
                      LocalizedFields(
                        label: 'Город',
                        controllers: city,
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          SizedBox(
                            width: 220,
                            child: TextField(
                              controller: started,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Дата начала (ms epoch)',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 220,
                            child: TextField(
                              controller: ended,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Дата окончания (ms epoch)',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 220,
                            child: TextField(
                              controller: logo,
                              decoration: const InputDecoration(
                                labelText: 'Logo image id',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (error != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          error!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Отмена'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final companyText = company.build();
                    final positionText = position.build();
                    if (!_hasContent(companyText) || !_hasContent(positionText)) {
                      setModalState(
                        () => error = 'Компания и позиция обязательны.',
                      );
                      return;
                    }
                    final start = _parseInt(started.text);
                    if (start == null) {
                      setModalState(
                        () => error = 'Укажите дату начала в мс epoch.',
                      );
                      return;
                    }
                    final experience = Experience(
                      id: base.id.text.trim(),
                      visible: base.visible,
                      tags: _parseTags(base.tags.text),
                      terms: base.terms.text.trim().isEmpty
                          ? null
                          : base.terms.text.trim(),
                      company: companyText,
                      position: positionText,
                      startedAt: start,
                      endedAt: _parseInt(ended.text),
                      description: description.build(),
                      city: city.build(),
                      logoImageId:
                          logo.text.trim().isEmpty ? null : logo.text.trim(),
                      version: existing?.version ?? 0,
                    );
                    Navigator.pop(context, experience);
                  },
                  child: const Text('Сохранить'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<Project?> _showProjectDialog(Versioned<Project>? existing) {
    final base = RecordFormControllers(
      id: existing?.data.id ?? _newId('proj'),
      visible: existing?.data.visible ?? true,
      tags: existing?.data.tags,
      terms: existing?.data.terms,
    );
    final name = LocalizedTextControllers(value: existing?.data.name);
    final summary = LocalizedTextControllers(value: existing?.data.summary);
    final started = TextEditingController(
      text: existing?.data.startedAt?.toString() ?? '',
    );
    final ended = TextEditingController(
      text: existing?.data.endedAt?.toString() ?? '',
    );
    final logo = TextEditingController(
      text: existing?.data.logoImageId ?? '',
    );
    final link = TextEditingController(text: existing?.data.link ?? '');
    String? error;

    return showDialog<Project>(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setModalState) {
          return AlertDialog(
            title: Text(
              existing == null ? 'Новый проект' : 'Редактировать проект',
            ),
            content: SizedBox(
              width: 650,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RecordBaseFields(
                      controllers: base,
                      onChanged: () => setModalState(() {}),
                    ),
                    const SizedBox(height: 12),
                    LocalizedFields(label: 'Название', controllers: name),
                    const SizedBox(height: 12),
                    LocalizedFields(label: 'Описание', controllers: summary),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        SizedBox(
                          width: 200,
                          child: TextField(
                            controller: started,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Начало (ms epoch)',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 200,
                          child: TextField(
                            controller: ended,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Конец (ms epoch)',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 220,
                          child: TextField(
                            controller: logo,
                            decoration: const InputDecoration(
                              labelText: 'Logo image id',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 260,
                          child: TextField(
                            controller: link,
                            decoration: const InputDecoration(
                              labelText: 'Ссылка',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (error != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        error!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Отмена'),
              ),
              ElevatedButton(
                onPressed: () {
                  final nameText = name.build();
                  if (!_hasContent(nameText)) {
                    setModalState(
                      () => error = 'Название проекта обязательно.',
                    );
                    return;
                  }
                  final project = Project(
                    id: base.id.text.trim(),
                    visible: base.visible,
                    tags: _parseTags(base.tags.text),
                    terms: base.terms.text.trim().isEmpty
                        ? null
                        : base.terms.text.trim(),
                    name: nameText,
                    summary: summary.build(),
                    startedAt: _parseInt(started.text),
                    endedAt: _parseInt(ended.text),
                    logoImageId:
                        logo.text.trim().isEmpty ? null : logo.text.trim(),
                    link: link.text.trim().isEmpty ? null : link.text.trim(),
                    version: existing?.version ?? 0,
                  );
                  Navigator.pop(context, project);
                },
                child: const Text('Сохранить'),
              ),
            ],
          );
        });
      },
    );
  }

  Future<Skill?> _showSkillDialog(Versioned<Skill>? existing) {
    final base = RecordFormControllers(
      id: existing?.data.id ?? _newId('skill'),
      visible: existing?.data.visible ?? true,
      tags: existing?.data.tags,
      terms: existing?.data.terms,
    );
    final name = LocalizedTextControllers(value: existing?.data.name);
    final level = TextEditingController(
      text: existing?.data.level?.toString() ?? '',
    );
    final category = TextEditingController(
      text: existing?.data.category ?? '',
    );
    String? error;

    return showDialog<Skill>(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setModalState) {
          return AlertDialog(
            title: Text(
              existing == null ? 'Новый навык' : 'Редактировать навык',
            ),
            content: SizedBox(
              width: 520,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RecordBaseFields(
                      controllers: base,
                      onChanged: () => setModalState(() {}),
                    ),
                    const SizedBox(height: 12),
                    LocalizedFields(label: 'Название', controllers: name),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        SizedBox(
                          width: 180,
                          child: TextField(
                            controller: level,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Уровень (число)',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 240,
                          child: TextField(
                            controller: category,
                            decoration: const InputDecoration(
                              labelText: 'Категория',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (error != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        error!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Отмена'),
              ),
              ElevatedButton(
                onPressed: () {
                  final nameText = name.build();
                  if (!_hasContent(nameText)) {
                    setModalState(() => error = 'Название навыка обязательно.');
                    return;
                  }
                  final skill = Skill(
                    id: base.id.text.trim(),
                    visible: base.visible,
                    tags: _parseTags(base.tags.text),
                    terms: base.terms.text.trim().isEmpty
                        ? null
                        : base.terms.text.trim(),
                    name: nameText,
                    level: _parseInt(level.text),
                    category: category.text.trim().isEmpty
                        ? null
                        : category.text.trim(),
                    version: existing?.version ?? 0,
                  );
                  Navigator.pop(context, skill);
                },
                child: const Text('Сохранить'),
              ),
            ],
          );
        });
      },
    );
  }

  Future<Education?> _showEducationDialog(Versioned<Education>? existing) {
    final base = RecordFormControllers(
      id: existing?.data.id ?? _newId('edu'),
      visible: existing?.data.visible ?? true,
      tags: existing?.data.tags,
      terms: existing?.data.terms,
    );
    final institution =
        LocalizedTextControllers(value: existing?.data.institution);
    final degree = LocalizedTextControllers(value: existing?.data.degree);
    final description =
        LocalizedTextControllers(value: existing?.data.description);
    final started = TextEditingController(
      text: existing?.data.startedAt.toString() ?? '',
    );
    final ended = TextEditingController(
      text: existing?.data.endedAt?.toString() ?? '',
    );
    String? error;

    return showDialog<Education>(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setModalState) {
          return AlertDialog(
            title: Text(
              existing == null ? 'Новое образование' : 'Редактировать запись',
            ),
            content: SizedBox(
              width: 620,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RecordBaseFields(
                      controllers: base,
                      onChanged: () => setModalState(() {}),
                    ),
                    const SizedBox(height: 12),
                    LocalizedFields(
                      label: 'Учреждение',
                      controllers: institution,
                    ),
                    const SizedBox(height: 12),
                    LocalizedFields(label: 'Степень', controllers: degree),
                    const SizedBox(height: 12),
                    LocalizedFields(
                      label: 'Описание',
                      controllers: description,
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        SizedBox(
                          width: 200,
                          child: TextField(
                            controller: started,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Начало (ms epoch)',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 200,
                          child: TextField(
                            controller: ended,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Конец (ms epoch)',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (error != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        error!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Отмена'),
              ),
              ElevatedButton(
                onPressed: () {
                  final institutionText = institution.build();
                  final degreeText = degree.build();
                  if (!_hasContent(institutionText) ||
                      !_hasContent(degreeText)) {
                    setModalState(
                      () =>
                          error = 'Учреждение и степень должны быть заполнены.',
                    );
                    return;
                  }
                  final start = _parseInt(started.text);
                  if (start == null) {
                    setModalState(
                      () => error = 'Дата начала обязательна (ms epoch).',
                    );
                    return;
                  }
                  final education = Education(
                    id: base.id.text.trim(),
                    visible: base.visible,
                    tags: _parseTags(base.tags.text),
                    terms: base.terms.text.trim().isEmpty
                        ? null
                        : base.terms.text.trim(),
                    institution: institutionText,
                    degree: degreeText,
                    startedAt: start,
                    endedAt: _parseInt(ended.text),
                    description: description.build(),
                    version: existing?.version ?? 0,
                  );
                  Navigator.pop(context, education);
                },
                child: const Text('Сохранить'),
              ),
            ],
          );
        });
      },
    );
  }

  Future<Bullet?> _showBulletDialog(Versioned<Bullet>? existing) {
    final base = RecordFormControllers(
      id: existing?.data.id ?? _newId('bullet'),
      visible: existing?.data.visible ?? true,
      tags: existing?.data.tags,
      terms: existing?.data.terms,
    );
    final text = LocalizedTextControllers(value: existing?.data.text);
    final experienceId = TextEditingController(
      text: existing?.data.experienceId ?? '',
    );
    final projectId = TextEditingController(
      text: existing?.data.projectId ?? '',
    );
    String? error;

    return showDialog<Bullet>(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setModalState) {
          return AlertDialog(
            title: Text(
              existing == null ? 'Новый буллет' : 'Редактировать буллет',
            ),
            content: SizedBox(
              width: 520,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RecordBaseFields(
                      controllers: base,
                      onChanged: () => setModalState(() {}),
                    ),
                    const SizedBox(height: 12),
                    LocalizedFields(label: 'Текст', controllers: text),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        SizedBox(
                          width: 220,
                          child: TextField(
                            controller: experienceId,
                            decoration: const InputDecoration(
                              labelText: 'experience_id',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 220,
                          child: TextField(
                            controller: projectId,
                            decoration: const InputDecoration(
                              labelText: 'project_id',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (error != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        error!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Отмена'),
              ),
              ElevatedButton(
                onPressed: () {
                  final bulletText = text.build();
                  if (!_hasContent(bulletText)) {
                    setModalState(
                      () => error = 'Текст буллета обязателен.',
                    );
                    return;
                  }
                  final bullet = Bullet(
                    id: base.id.text.trim(),
                    visible: base.visible,
                    tags: _parseTags(base.tags.text),
                    terms: base.terms.text.trim().isEmpty
                        ? null
                        : base.terms.text.trim(),
                    text: bulletText,
                    experienceId: experienceId.text.trim().isEmpty
                        ? null
                        : experienceId.text.trim(),
                    projectId: projectId.text.trim().isEmpty
                        ? null
                        : projectId.text.trim(),
                    version: existing?.version ?? 0,
                  );
                  Navigator.pop(context, bullet);
                },
                child: const Text('Сохранить'),
              ),
            ],
          );
        });
      },
    );
  }

  Future<MediaAsset?> _showMediaDialog(Versioned<MediaAsset>? existing) {
    final base = RecordFormControllers(
      id: existing?.data.id ?? _newId('media'),
      visible: existing?.data.visible ?? true,
      tags: existing?.data.tags,
      terms: existing?.data.terms,
    );
    final data = TextEditingController(
      text: existing?.data.dataBase64 ?? '',
    );
    final mime = TextEditingController(text: existing?.data.mime ?? '');
    final alt = LocalizedTextControllers(value: existing?.data.alt);
    String? error;

    return showDialog<MediaAsset>(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setModalState) {
          return AlertDialog(
            title: Text(
              existing == null ? 'Новый медиа-актив' : 'Редактировать медиа',
            ),
            content: SizedBox(
              width: 620,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RecordBaseFields(
                      controllers: base,
                      onChanged: () => setModalState(() {}),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: data,
                      maxLines: 6,
                      decoration: const InputDecoration(
                        labelText: 'Base64 данные',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: mime,
                      decoration: const InputDecoration(
                        labelText: 'MIME',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    LocalizedFields(label: 'Alt', controllers: alt),
                    if (error != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        error!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Отмена'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (data.text.trim().isEmpty) {
                    setModalState(
                      () => error = 'Base64 данные обязательны.',
                    );
                    return;
                  }
                  final asset = MediaAsset(
                    id: base.id.text.trim(),
                    visible: base.visible,
                    tags: _parseTags(base.tags.text),
                    terms: base.terms.text.trim().isEmpty
                        ? null
                        : base.terms.text.trim(),
                    dataBase64: data.text.trim(),
                    mime: mime.text.trim().isEmpty ? null : mime.text.trim(),
                    alt: alt.build(),
                    version: existing?.version ?? 0,
                  );
                  Navigator.pop(context, asset);
                },
                child: const Text('Сохранить'),
              ),
            ],
          );
        });
      },
    );
  }

  Future<ResumeVariant?> _showVariantDialog(
    Versioned<ResumeVariant>? existing,
  ) {
    final idCtrl = TextEditingController(
      text: existing?.data.id ?? _newId('variant'),
    );
    final nameCtrl =
        TextEditingController(text: existing?.data.name ?? 'Новый вариант');
    Language lang = existing?.data.lang ?? Language.en;
    MediaMode mediaMode = existing?.data.mediaMode ?? MediaMode.full;
    final defaultExclude =
        TextEditingController(text: existing?.data.defaultExcludeTags.join(', '));
    final sectionForms = <SectionRuleForm>[
      for (final rule in existing?.data.sections ?? [const SectionRule(type: SectionType.profile)])
        SectionRuleForm(rule),
    ];
    return showDialog<ResumeVariant>(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setModalState) {
          return AlertDialog(
            title: Text(
              existing == null
                  ? 'Новый вариант резюме'
                  : 'Редактировать вариант',
            ),
            content: SizedBox(
              width: 760,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: idCtrl,
                      decoration: const InputDecoration(
                        labelText: 'ID варианта',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Название',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        DropdownButton<Language>(
                          value: lang,
                          onChanged: (value) =>
                              setModalState(() => lang = value ?? Language.en),
                          items: Language.values
                              .map(
                                (v) => DropdownMenuItem(
                                  value: v,
                                  child: Text('Язык: ${v.name}'),
                                ),
                              )
                              .toList(),
                        ),
                        DropdownButton<MediaMode>(
                          value: mediaMode,
                          onChanged: (value) => setModalState(
                            () => mediaMode = value ?? MediaMode.full,
                          ),
                          items: MediaMode.values
                              .map(
                                (v) => DropdownMenuItem(
                                  value: v,
                                  child: Text('Медиа: ${v.name}'),
                                ),
                              )
                              .toList(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: defaultExclude,
                      decoration: const InputDecoration(
                        labelText: 'Исключить теги по умолчанию',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Секции',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    for (var i = 0; i < sectionForms.length; i++)
                      _SectionRuleCard(
                        form: sectionForms[i],
                        onChanged: () => setModalState(() {}),
                        onRemove: sectionForms.length > 1
                            ? () {
                                setModalState(
                                  () => sectionForms.removeAt(i),
                                );
                              }
                            : null,
                      ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: () {
                        setModalState(
                          () => sectionForms.add(
                            SectionRuleForm(
                              const SectionRule(type: SectionType.profile),
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Добавить секцию'),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Отмена'),
              ),
              ElevatedButton(
                onPressed: () {
                  final sections = sectionForms.map((form) => form.toRule()).toList();
                  final variant = ResumeVariant(
                    id: idCtrl.text.trim().isEmpty
                        ? _newId('variant')
                        : idCtrl.text.trim(),
                    name: nameCtrl.text.trim().isEmpty
                        ? null
                        : nameCtrl.text.trim(),
                    lang: lang,
                    mediaMode: mediaMode,
                    defaultExcludeTags: _parseTags(defaultExclude.text),
                    sections: sections,
                  );
                  Navigator.pop(context, variant);
                },
                child: const Text('Сохранить'),
              ),
            ],
          );
        });
      },
    );
  }
}

class _TabConfig {
  const _TabConfig({
    required this.title,
    required this.icon,
    required this.builder,
  });

  final String title;
  final IconData icon;
  final WidgetBuilder builder;
}

class RecordFormControllers {
  RecordFormControllers({
    required String id,
    bool visible = true,
    List<String>? tags,
    String? terms,
  })  : id = TextEditingController(text: id),
        visible = visible,
        tags = TextEditingController(tags?.join(', ') ?? ''),
        terms = TextEditingController(terms ?? '');

  final TextEditingController id;
  final TextEditingController tags;
  final TextEditingController terms;
  bool visible;
}

class RecordBaseFields extends StatelessWidget {
  const RecordBaseFields({
    super.key,
    required this.controllers,
    required this.onChanged,
  });

  final RecordFormControllers controllers;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controllers.id,
          decoration: const InputDecoration(
            labelText: 'ID',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: 360,
              child: TextField(
                controller: controllers.tags,
                decoration: const InputDecoration(
                  labelText: 'Теги (через запятую)',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            SizedBox(
              width: 280,
              child: TextField(
                controller: controllers.terms,
                decoration: const InputDecoration(
                  labelText: 'Terms/лицензия',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            FilterChip(
              selected: controllers.visible,
              label: const Text('Видимость'),
              onSelected: (v) {
                controllers.visible = v;
                onChanged();
              },
            ),
          ],
        ),
      ],
    );
  }
}

class LocalizedTextControllers {
  LocalizedTextControllers({LocalizedText? value})
      : en = TextEditingController(text: value?.en ?? ''),
        ru = TextEditingController(text: value?.ru ?? '');

  final TextEditingController en;
  final TextEditingController ru;

  LocalizedText build() => LocalizedText(
        en: en.text.trim().isEmpty ? null : en.text.trim(),
        ru: ru.text.trim().isEmpty ? null : ru.text.trim(),
      );
}

class LocalizedFields extends StatelessWidget {
  const LocalizedFields({
    super.key,
    required this.label,
    required this.controllers,
  });

  final String label;
  final LocalizedTextControllers controllers;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SizedBox(
              width: 260,
              child: TextField(
                controller: controllers.en,
                decoration: const InputDecoration(
                  labelText: 'EN',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            SizedBox(
              width: 260,
              child: TextField(
                controller: controllers.ru,
                decoration: const InputDecoration(
                  labelText: 'RU',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _CollectionList<T> extends StatefulWidget {
  const _CollectionList({
    required this.title,
    required this.collection,
    required this.idSelector,
    required this.titleBuilder,
    required this.editor,
    this.subtitleBuilder,
  });

  final String title;
  final DataServiceCollection<T> collection;
  final String Function(T model) idSelector;
  final String Function(T model) titleBuilder;
  final String Function(T model)? subtitleBuilder;
  final Future<T?> Function(Versioned<T>? existing) editor;

  @override
  State<_CollectionList<T>> createState() => _CollectionListState<T>();
}

class _CollectionListState<T> extends State<_CollectionList<T>> {
  late Future<List<Versioned<T>>> _future;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    setState(() {
      _future = widget.collection.list();
    });
  }

  Future<void> _upsertModel(T model) async {
    try {
      await widget.collection.upsert(model);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Сохранено')),
        );
      }
      _refresh();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка сохранения: $error')),
        );
      }
    }
  }

  Future<void> _delete(Versioned<T> item) async {
    try {
      await widget.collection.delete(widget.idSelector(item.data));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Удалено')),
        );
      }
      _refresh();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка удаления: $error')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                widget.title,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              IconButton(
                tooltip: 'Обновить',
                onPressed: _refresh,
                icon: const Icon(Icons.refresh),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () async {
                  final created = await widget.editor(null);
                  if (created != null) {
                    await _upsertModel(created);
                  }
                },
                icon: const Icon(Icons.add),
                label: const Text('Добавить'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: FutureBuilder<List<Versioned<T>>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Ошибка загрузки: ${snapshot.error}'),
                  );
                }
                final items = snapshot.data ?? [];
                if (items.isEmpty) {
                  return const Center(child: Text('Нет данных'));
                }
                return ListView.separated(
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final title = widget.titleBuilder(item.data);
                    final subtitle = widget.subtitleBuilder?.call(item.data);
                    return Card(
                      child: ListTile(
                        title: Text(title),
                        subtitle:
                            subtitle == null || subtitle.isEmpty ? null : Text(subtitle),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () async {
                                final updated = await widget.editor(item);
                                if (updated != null) {
                                  await _upsertModel(updated);
                                }
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () => _delete(item),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemCount: items.length,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ResumeBuilder extends StatefulWidget {
  const _ResumeBuilder({
    required this.variantsCollection,
    required this.caller,
  });

  final DataServiceCollection<ResumeVariant> variantsCollection;
  final ResumeContractCaller caller;

  @override
  State<_ResumeBuilder> createState() => _ResumeBuilderState();
}

class _ResumeBuilderState extends State<_ResumeBuilder> {
  String? _selectedVariant;
  String? _result;
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Сборка резюме',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: _loading ? null : _generate,
                icon: _loading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.description),
                label: const Text('Собрать'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          FutureBuilder<List<Versioned<ResumeVariant>>>(
            future: widget.variantsCollection.list(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final variants = snapshot.data ?? [];
              if (variants.isEmpty) {
                return const Text('Создайте вариант резюме в соседней вкладке.');
              }
              _selectedVariant ??= variants.first.data.id;
              return DropdownButton<String>(
                value: _selectedVariant,
                items: variants
                    .map(
                      (v) => DropdownMenuItem(
                        value: v.data.id,
                        child: Text(v.data.name ?? v.data.id),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedVariant = value;
                  });
                },
              );
            },
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
              ),
              child: SingleChildScrollView(
                child: SelectableText(
                  _result ?? 'Результат появится после генерации.',
                  style: const TextStyle(fontFamily: 'monospace'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _generate() async {
    final variantId = _selectedVariant;
    if (variantId == null) return;
    setState(() {
      _loading = true;
    });
    try {
      final response = await widget.caller.generateResume(
        GenerateResumeRequest(variantId: variantId),
      );
      final jsonText = const JsonEncoder.withIndent('  ')
          .convert(response.resume.toJson());
      setState(() => _result = jsonText);
    } catch (error) {
      if (mounted) {
        setState(() => _result = 'Ошибка: $error');
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }
}

class SectionRuleForm {
  SectionRuleForm(SectionRule rule)
      : type = rule.type,
        includeTags = TextEditingController(rule.includeTags.join(', ')),
        excludeTags = TextEditingController(rule.excludeTags.join(', ')),
        limit = TextEditingController(rule.limit?.toString() ?? ''),
        sortField = TextEditingController(rule.sort?.field ?? ''),
        descending = rule.sort?.descending ?? false;

  SectionType type;
  final TextEditingController includeTags;
  final TextEditingController excludeTags;
  final TextEditingController limit;
  final TextEditingController sortField;
  bool descending;

  SectionRule toRule() {
    final limitValue = _parseInt(limit.text);
    final sortValue = sortField.text.trim().isEmpty
        ? null
        : SortRule(field: sortField.text.trim(), descending: descending);
    return SectionRule(
      type: type,
      includeTags: _parseTags(includeTags.text),
      excludeTags: _parseTags(excludeTags.text),
      limit: limitValue,
      sort: sortValue,
    );
  }
}

class _SectionRuleCard extends StatelessWidget {
  const _SectionRuleCard({
    required this.form,
    required this.onChanged,
    this.onRemove,
  });

  final SectionRuleForm form;
  final VoidCallback onChanged;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                DropdownButton<SectionType>(
                  value: form.type,
                  onChanged: (value) {
                    if (value != null) {
                      form.type = value;
                      onChanged();
                    }
                  },
                  items: SectionType.values
                      .map(
                        (v) => DropdownMenuItem(
                          value: v,
                          child: Text(v.name),
                        ),
                      )
                      .toList(),
                ),
                const Spacer(),
                if (onRemove != null)
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: onRemove,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: 240,
                  child: TextField(
                    controller: form.includeTags,
                    decoration: const InputDecoration(
                      labelText: 'Включать теги',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                SizedBox(
                  width: 240,
                  child: TextField(
                    controller: form.excludeTags,
                    decoration: const InputDecoration(
                      labelText: 'Исключать теги',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                SizedBox(
                  width: 180,
                  child: TextField(
                    controller: form.limit,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Лимит',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                SizedBox(
                  width: 220,
                  child: TextField(
                    controller: form.sortField,
                    decoration: const InputDecoration(
                      labelText: 'Поле сортировки',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                FilterChip(
                  selected: form.descending,
                  label: const Text('Сортировка по убыванию'),
                  onSelected: (v) {
                    form.descending = v;
                    onChanged();
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ConnectionFormState {
  ConnectionFormState() {
    hostController = TextEditingController(text: 'localhost');
    portController = TextEditingController(text: '5432');
    databaseController = TextEditingController(text: 'career_ledger');
    usernameController = TextEditingController(text: 'postgres');
    passwordController = TextEditingController(text: '');
    schemaController = TextEditingController(text: 'public');
    prefixController = TextEditingController(text: '');
    connectTimeoutController = TextEditingController(text: '10');
    queryTimeoutController = TextEditingController(text: '30');
  }

  late final TextEditingController hostController;
  late final TextEditingController portController;
  late final TextEditingController databaseController;
  late final TextEditingController usernameController;
  late final TextEditingController passwordController;
  late final TextEditingController schemaController;
  late final TextEditingController prefixController;
  late final TextEditingController connectTimeoutController;
  late final TextEditingController queryTimeoutController;
  bool useSsl = false;

  String get host => hostController.text.trim();
  int get port => int.tryParse(portController.text) ?? 5432;
  String get database => databaseController.text.trim();
  String get username => usernameController.text.trim();
  String get password => passwordController.text;
  String get schema => schemaController.text.trim().isEmpty
      ? 'public'
      : schemaController.text.trim();
  String get tablePrefix => prefixController.text.trim();
  int get connectTimeoutSeconds =>
      int.tryParse(connectTimeoutController.text) ?? 10;
  int get queryTimeoutSeconds =>
      int.tryParse(queryTimeoutController.text) ?? 30;

  void dispose() {
    hostController.dispose();
    portController.dispose();
    databaseController.dispose();
    usernameController.dispose();
    passwordController.dispose();
    schemaController.dispose();
    prefixController.dispose();
    connectTimeoutController.dispose();
    queryTimeoutController.dispose();
  }
}

bool _hasContent(LocalizedText text) =>
    (text.en?.trim().isNotEmpty ?? false) ||
    (text.ru?.trim().isNotEmpty ?? false);

int? _parseInt(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return null;
  return int.tryParse(trimmed);
}

List<String> _parseTags(String raw) => raw
    .split(RegExp(r'[;,\s]+'))
    .map((e) => e.trim())
    .where((e) => e.isNotEmpty)
    .toList();
