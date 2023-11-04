import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'crossview_method_channel.dart';

abstract class CrossviewPlatform extends PlatformInterface {
  /// Constructs a CrossviewPlatform.
  CrossviewPlatform() : super(token: _token);

  static final Object _token = Object();

  static CrossviewPlatform _instance = MethodChannelCrossview();

  /// The default instance of [CrossviewPlatform] to use.
  ///
  /// Defaults to [MethodChannelCrossview].
  static CrossviewPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [CrossviewPlatform] when
  /// they register themselves.
  static set instance(CrossviewPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
