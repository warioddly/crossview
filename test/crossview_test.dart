import 'package:flutter_test/flutter_test.dart';
import 'package:crossview/crossview.dart';
import 'package:crossview/crossview_platform_interface.dart';
import 'package:crossview/crossview_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockCrossViewPlatform
    with MockPlatformInterfaceMixin
    implements CrossViewPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final CrossViewPlatform initialPlatform = CrossViewPlatform.instance;

  test('$MethodChannelCrossView is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelCrossView>());
  });

  test('getPlatformVersion', () async {
    CrossView crossviewPlugin = CrossView();
    MockCrossViewPlatform fakePlatform = MockCrossViewPlatform();
    CrossViewPlatform.instance = fakePlatform;

    expect(await crossviewPlugin.getPlatformVersion(), '42');
  });
}
