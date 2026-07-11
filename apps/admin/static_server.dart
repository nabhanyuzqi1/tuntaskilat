import 'dart:io';
Future<void> main() async {
  final root = Directory('build/web').absolute.path;
  final server = await HttpServer.bind('127.0.0.1', 8091);
  stdout.writeln('READY http://127.0.0.1:8091');
  await for (final req in server) {
    var path = req.uri.path;
    if (path == '/' || path.isEmpty) path = '/index.html';
    var file = File('$root$path');
    if (!await file.exists()) file = File('$root/index.html');
    try {
      final ext = file.path.split('.').last.toLowerCase();
      final ct = {
        'html':'text/html','js':'application/javascript','json':'application/json',
        'css':'text/css','wasm':'application/wasm','otf':'font/otf','ttf':'font/ttf',
        'png':'image/png','webp':'image/webp','jpg':'image/jpeg','svg':'image/svg+xml',
        'bin':'application/octet-stream','map':'application/json',
      }[ext] ?? 'application/octet-stream';
      req.response.headers.contentType = ContentType.parse(ct);
      await req.response.addStream(file.openRead());
    } catch (_) { req.response.statusCode = 404; }
    await req.response.close();
  }
}
