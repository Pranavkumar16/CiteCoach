import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:citecoach/features/setup/data/android_download_session.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('com.citecoach/download');
  final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  final calls = <MethodCall>[];
  setUp(() {
    calls.clear();
    messenger.setMockMethodCallHandler(channel, (call) async { calls.add(call); return null; });
  });
  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  test('starts once, publishes progress and releases the service once', () async {
    final session = AndroidDownloadSession(android: true, channel: channel);
    await session.start();
    await session.start();
    await session.update(.42);
    await session.update(.43); // rate-limited notification refresh
    await session.stop();
    await session.stop();
    await session.update(.5);
    expect(calls.map((c) => c.method), ['start', 'update', 'stop']);
    expect(calls[1].arguments['percent'], 42);
  });
  test('resume starts a new service and non-Android platforms make no calls', () async {
    final session = AndroidDownloadSession(android: true, channel: channel);
    await session.start();
    await session.stop();
    await session.start();
    await session.stop();
    expect(calls.map((c) => c.method), ['start', 'stop', 'start', 'stop']);
    calls.clear();
    final ios = AndroidDownloadSession(android: false, channel: channel);
    await ios.start();
    await ios.update(.5);
    await ios.stop();
    expect(calls, isEmpty);
  });
  test('start failure is visible rather than claiming background support', () async {
    messenger.setMockMethodCallHandler(channel, (_) async =>
        throw PlatformException(code: 'DOWNLOAD_SERVICE'));
    final session = AndroidDownloadSession(android: true, channel: channel);
    await expectLater(session.start(), throwsA(isA<PlatformException>()));
  });
}
