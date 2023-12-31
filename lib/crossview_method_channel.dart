import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'crossview_platform_interface.dart';

/// An implementation of [CrossViewPlatform] that uses method channels.
class MethodChannelCrossView extends CrossViewPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('crossview');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
