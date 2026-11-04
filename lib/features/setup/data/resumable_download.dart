import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';

/// Streams directly to a partial file so cancellation retains received bytes.
Future<void> downloadResumable({
  required Dio dio,
  required String url,
  required File partial,
  required CancelToken? cancelToken,
  required int expectedSize,
  required void Function(int received, int total) onProgress,
}) async {
  final offset = await partial.exists() ? await partial.length() : 0;
  final response = await dio.get<ResponseBody>(url,
    cancelToken: cancelToken,
    options: Options(responseType: ResponseType.stream,
      headers: {if (offset > 0) 'Range': 'bytes=$offset-', 'Accept-Encoding': 'identity'},
    ),
  );
  final body = response.data!;
  var received = 0;
  var total = int.tryParse(response.headers.value('content-length') ?? '') ?? expectedSize;
  if (response.statusCode == 206) {
    final range = RegExp(r'^bytes (\d+)-(\d+)/(\d+)$').firstMatch(response.headers.value('content-range') ?? '');
    if (range == null || int.parse(range[1]!) != offset || int.parse(range[2]!) < offset || int.parse(range[3]!) <= int.parse(range[2]!)) {
      await body.stream.listen(null).cancel();
      throw DioException(requestOptions: response.requestOptions, type: DioExceptionType.badResponse, message: 'Invalid download range response');
    }
    received = offset;
    total = int.parse(range[3]!);
  } else if (response.statusCode != 200) {
    await body.stream.listen(null).cancel();
    throw DioException(requestOptions: response.requestOptions, type: DioExceptionType.badResponse, message: 'Unexpected download response');
  }
  // A server ignoring Range returns 200: replace, never append a full response.
  final file = await partial.open(mode: response.statusCode == 206 ? FileMode.append : FileMode.write);
  try {
    onProgress(received, total);
    await for (final chunk in body.stream.timeout(const Duration(seconds: 45))) {
      if (cancelToken?.isCancelled ?? false) throw cancelToken!.cancelError!;
      await file.writeFrom(chunk);
      received += chunk.length;
      onProgress(received, total);
    }
    if (received != total) {
      throw DioException(requestOptions: response.requestOptions, type: DioExceptionType.connectionError, message: 'Incomplete download');
    }
  } on TimeoutException {
    throw DioException(requestOptions: response.requestOptions, type: DioExceptionType.receiveTimeout, message: 'Download stalled');
  } finally {
    await file.close();
  }
}
