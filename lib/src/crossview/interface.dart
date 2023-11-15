
import 'package:crossview/src/utils/utils.dart';
import 'package:crossview/src/controller/interface.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Interface for widget
abstract class CrossView {
  
  /// Initial content
  final String initialContent;

  /// Initial source type. Must match [initialContent]'s type.
  ///
  /// Example:
  /// If you set [initialContent] to '<p>hi</p>', then you should
  /// also set the [initialSourceType] accordingly, that is [SourceType.html].
  final SourceType initialSourceType;

  /// User-agent
  /// On web, this is only used when using [SourceType.urlBypass]
  final String? userAgent;


  /// Callback which returns a referrence to the [IWebViewXController]
  /// being created.
  final Function(CrossViewController controller)? onViewCreated;

  
  /// A set of [EmbeddedJsContent].
  ///
  /// You can define JS functions, which will be embedded into
  /// the HTML source (won't do anything on URL) and you can later call them
  /// using the controller.
  ///
  /// For more info, see [EmbeddedJsContent].
  final Set<EmbeddedJsContent> jsContent;


  /// Boolean value to specify if should ignore all gestures that touch the webview.
  ///
  /// You can change this later from the controller.
  final bool ignoreAllGestures;
  
  
  /// Callback for when the page starts loading.
  final NavigationDelegate? navigationDelegate;


  /// This defines if Javascript execution should be allowed inside the webview
  final JavaScriptMode javascriptMode;


  /// Parameters specific to the web version.
  /// This may eventually be merged with [mobileSpecificParams],
  /// if all features become cross platform.
  final WebSpecificParams webSpecificParams;

  /// Parameters specific to the web version.
  /// This may eventually be merged with [webSpecificParams],
  /// if all features become cross platform.
  final MobileSpecificParams mobileSpecificParams;

  
  /// Constructor
  const CrossView({
    this.initialContent = 'about:blank',
    this.initialSourceType = SourceType.url,
    this.javascriptMode = JavaScriptMode.unrestricted,
    this.userAgent,
    this.onViewCreated,
    this.navigationDelegate,
    this.jsContent = const {},
    this.ignoreAllGestures = false,
    this.webSpecificParams = const WebSpecificParams(),
    this.mobileSpecificParams = const MobileSpecificParams(),
  });
  
}
