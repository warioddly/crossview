import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'crossview_method_channel.dart';

abstract class CrossViewPlatform extends PlatformInterface {
  /// Constructs a CrossViewPlatform.
  CrossViewPlatform() : super(token: _token);

  static final Object _token = Object();

  static CrossViewPlatform _instance = MethodChannelCrossView();

  /// The default instance of [CrossViewPlatform] to use.
  ///
  /// Defaults to [MethodChannelCrossView].
  static CrossViewPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [CrossViewPlatform] when
  /// they register themselves.
  static set instance(CrossViewPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
