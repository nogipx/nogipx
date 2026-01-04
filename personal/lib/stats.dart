import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:jaspr/dom.dart';
import 'package:jaspr/server.dart';

class PackageInfo {
  PackageInfo({
    required this.name,
    required this.likes,
    required this.downloads,
  });

  final String name;
  final int likes;
  final int downloads;
}

class StatsService {
  const StatsService({required this.publisher});

  final String publisher;

  Future<List<PackageInfo>> load() async {
    final searchUri = Uri.parse(
      'https://pub.dev/api/search?q=publisher:$publisher',
    );
    final searchRes = await http.get(searchUri);
    if (searchRes.statusCode != 200) {
      throw Exception('pub.dev search failed (${searchRes.statusCode})');
    }
    final searchJson = jsonDecode(searchRes.body) as Map<String, dynamic>;
    final packages = (searchJson['packages'] as List<dynamic>? ?? [])
        .map((e) => (e as Map<String, dynamic>)['package'] as String)
        .toList();

    final results = <PackageInfo>[];
    for (final name in packages) {
      final pkgUri = Uri.parse('https://pub.dev/api/packages/$name/score');
      final pkgRes = await http.get(pkgUri);
      if (pkgRes.statusCode != 200) {
        continue;
      }
      final pkgJson = jsonDecode(pkgRes.body) as Map<String, dynamic>;
      final likes = pkgJson['likeCount'] as int? ?? 0;
      final downloads = pkgJson['downloadCount30Days'] as int? ?? 0;
      results.add(PackageInfo(name: name, likes: likes, downloads: downloads));
    }
    return results;
  }
}

class LiveStatsSection extends AsyncStatelessComponent {
  const LiveStatsSection({super.key});

  @override
  Future<Component> build(BuildContext context) async {
    try {
      const service = StatsService(publisher: 'dart.nogipx.dev');
      final packages = await service.load();
      return section([
        div([
          h2([Component.text('Pub.dev')]),
        ], classes: 'section-header'),
        ul([
          for (final pkg in packages)
            li([
              Component.text(pkg.name),
              span([
                Component.text('${pkg.likes} 👍'),
                Component.text('  '),
                Component.text('${pkg.downloads} ⬇️'),
              ], classes: 'muted'),
            ], classes: 'stat-row'),
        ], classes: 'stats-list'),
      ], classes: 'section');
    } catch (e) {
      return section([
        div([
          h2([Component.text('Статистика вживую')]),
          p([Component.text('Не удалось загрузить: $e')], classes: 'muted'),
        ]),
      ], classes: 'section');
    }
  }
}
