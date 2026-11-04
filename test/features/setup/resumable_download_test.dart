import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:citecoach/features/setup/data/resumable_download.dart';

void main() {
  for (final mode in ['range', 'ignored', 'invalid']) {
    test('partial transfer handles $mode range response safely', () async {
      final directory = await Directory.systemTemp.createTemp('citecoach-download-');
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      final dio = Dio();
      addTearDown(() async { dio.close(force: true); await server.close(force: true); await directory.delete(recursive: true); });
      final file = File('${directory.path}/model.tmp');
      await file.writeAsBytes([1, 2, 3]);
      String? range;
      server.listen((request) async {
        range = request.headers.value('range');
        request.response.statusCode = mode == 'ignored' ? 200 : 206;
        if (mode != 'ignored') request.response.headers.set('content-range', mode == 'invalid' ? 'bytes 2-5/6' : 'bytes 3-5/6');
        final bytes = mode == 'ignored' ? [1, 2, 3, 4, 5, 6] : [4, 5, 6];
        request.response.contentLength = bytes.length;
        request.response.add(bytes);
        await request.response.close();
      });
      final transfer = downloadResumable(dio: dio, url: 'http://127.0.0.1:${server.port}/model', partial: file, cancelToken: CancelToken(), expectedSize: 6, onProgress: (_, __) {});
      if (mode == 'invalid') {
        await expectLater(transfer, throwsA(isA<DioException>()));
        expect(await file.readAsBytes(), [1, 2, 3]);
      } else {
        await transfer;
        expect(await file.readAsBytes(), [1, 2, 3, 4, 5, 6]);
      }
      expect(range, 'bytes=3-');
    });
  }
}
