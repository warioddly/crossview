import 'package:flutter_test/flutter_test.dart';
import 'package:crossview/crossview.dart';
import 'package:crossview/crossview_platform_interface.dart';
import 'package:crossview/crossview_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockCrossviewPlatform
    with MockPlatformInterfaceMixin
    implements CrossviewPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final CrossviewPlatform initialPlatform = CrossviewPlatform.instance;

  test('$MethodChannelCrossview is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelCrossview>());
  });

  test('getPlatformVersion', () async {
    CrossView crossviewPlugin = CrossView();
    MockCrossviewPlatform fakePlatform = MockCrossviewPlatform();
    CrossviewPlatform.instance = fakePlatform;

    expect(await crossviewPlugin.getPlatformVersion(), '42');
  });
}
