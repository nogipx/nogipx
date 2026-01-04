import 'dart:io';

import 'package:jaspr/server.dart';
import 'package:personal/resume_data.dart';
import 'package:personal/site.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_router/shelf_router.dart';

final _router = Router()..get('/echo/<message>', _echoHandler);

Response _echoHandler(Request request) {
  final message = request.params['message'];
  return Response.ok('$message\n');
}

void main(List<String> args) async {
  Jaspr.initializeApp();

  final resumeEnv = await bootstrapResumeData();

  final jasprHandler = serveApp((request, render) {
    return render(PersonalSite(resumeClient: resumeEnv.client));
  });

  final handler = Pipeline()
      .addMiddleware(logRequests())
      .addHandler(Cascade().add(_router.call).add(jasprHandler).handler);

  final port = int.parse(Platform.environment['PORT'] ?? '9080');
  final server = await serve(handler, InternetAddress.anyIPv4, port);
  print('Server listening on port ${server.port}');
}
