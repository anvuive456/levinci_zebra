import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:levinci_zebra/levinci_zebra_method_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  MethodChannelLevinciZebra platform = MethodChannelLevinciZebra();
  const MethodChannel channel = MethodChannel('levinci_zebra');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      (MethodCall methodCall) async {
        return '42';
      },
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
  });

  test('getPlatformVersion', () async {
    expect(await platform.getPlatformVersion(), '42');
  });
}
