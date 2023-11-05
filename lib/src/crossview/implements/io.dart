import 'package:flutter/material.dart';
import 'package:crossview/src/utils/utils.dart';
import 'package:crossview/src/crossview/interface.dart' as view_interface;
import 'package:crossview/src/controller/interface.dart' as ctrl_interface;
import 'package:crossview/src/crossview/implements/mobile.dart' as mobile;
import 'package:webview_flutter/webview_flutter.dart' as wf;

/// IO implementation
///
/// Will build the coresponding widget for the current IO platform
class CrossView extends StatelessWidget implements view_interface.CrossView {
  /// Initial content
  @override
  final String initialContent;

  /// Initial source type. Must match [initialContent]'s type.
  ///
  /// Example:
  /// If you set [initialContent] to '<p>hi</p>', then you should
  /// also set the [initialSourceType] accordingly, that is [SourceType.html].
  @override
  final SourceType initialSourceType;

  /// User-agent
  /// On web, this is only used when using [SourceType.urlBypass]
  @override
  final String? userAgent;

  /// Callback which returns a referrence to the [CrossViewController]
  /// being created.
  @override
  final Function(ctrl_interface.CrossViewController controller)? onCreated;

  /// A set of [EmbeddedJsContent].
  ///
  /// You can define JS functions, which will be embedded into
  /// the HTML source (won't do anything on URL) and you can later call them
  /// using the controller.
  ///
  /// For more info, see [EmbeddedJsContent].
  @override
  final Set<EmbeddedJsContent> jsContent;

  /// A set of [DartCallback].
  ///
  /// You can define Dart functions, which can be called from the JS side.
  ///
  /// For more info, see [DartCallback].
  @override
  final Set<DartCallback> dartCallBacks;

  /// Boolean value to specify if should ignore all gestures that touch the webview.
  ///
  /// You can change this later from the controller.
  @override
  final bool ignoreAllGestures;

  /// Boolean value to specify if Javascript execution should be allowed inside the webview
  @override
  final wf.JavaScriptMode javascriptMode;


  /// Callback to decide whether to allow navigation to the incoming url
  @override
  final wf.NavigationDelegate? navigationDelegate;


  /// Parameters specific to the web version.
  /// This may eventually be merged with [mobileSpecificParams],
  /// if all features become cross platform.
  @override
  final WebSpecificParams webSpecificParams;

  /// Parameters specific to the web version.
  /// This may eventually be merged with [webSpecificParams],
  /// if all features become cross platform.
  @override
  final MobileSpecificParams mobileSpecificParams;

  /// Constructor
  const CrossView({
    Key? key,
    this.initialContent = 'about:blank',
    this.initialSourceType = SourceType.url,
    this.userAgent,
    this.onCreated,
    this.jsContent = const {},
    this.dartCallBacks = const {},
    this.ignoreAllGestures = false,
    this.javascriptMode = wf.JavaScriptMode.unrestricted,
    this.navigationDelegate,
    this.webSpecificParams = const WebSpecificParams(),
    this.mobileSpecificParams = const MobileSpecificParams(),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return mobile.CrossView(
      key: key,
      initialContent: initialContent,
      initialSourceType: initialSourceType,
      userAgent: userAgent,
      dartCallBacks: dartCallBacks,
      jsContent: jsContent,
      onCreated: onCreated,
      ignoreAllGestures: ignoreAllGestures,
      javascriptMode: javascriptMode,
      navigationDelegate: navigationDelegate,
      webSpecificParams: webSpecificParams,
      mobileSpecificParams: mobileSpecificParams,
    );
  }


}
