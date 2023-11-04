import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:crossview/src/utils/utils.dart';
import 'package:webview_flutter/webview_flutter.dart' as wf;

import 'package:crossview/src/view/interface.dart' as view_interface;
import 'package:crossview/src/controller/interface.dart' as ctrl_interface;
import 'package:crossview/src/controller/impl/mobile.dart';

/// Mobile implementation
class CrossView extends StatefulWidget implements view_interface.CrossView {
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

  /// Callback for when the page starts loading.
  @override
  final void Function(String src)? onPageStarted;

  /// Callback for when the page has finished loading (i.e. is shown on screen).
  @override
  final void Function(String src)? onPageFinished;





  /// Callback to decide whether to allow navigation to the incoming url
  @override
  final NavigationDelegate? navigationDelegate;

  /// Callback for when something goes wrong in while page or resources load.
  @override
  final void Function(WebResourceError error)? onWebResourceError;

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
    this.onPageStarted,
    this.onPageFinished,
    this.navigationDelegate,
    this.onWebResourceError,
    this.webSpecificParams = const WebSpecificParams(),
    this.mobileSpecificParams = const MobileSpecificParams(),
  }) : super(key: key);

  @override
  _CrossViewState createState() => _CrossViewState();
}

class _CrossViewState extends State<CrossView> {


  late wf.WebViewController originalWebViewController = wf.WebViewController();
  late CrossViewController crossViewController;

  late bool _ignoreAllGestures;

  @override
  void initState() {
    super.initState();

    _ignoreAllGestures = widget.ignoreAllGestures;

    _init();

    if (Platform.isAndroid && widget.mobileSpecificParams.androidEnableHybridComposition) {
      // wf.WebView.platform = wf.SurfaceAndroidWebView();
    }


  }


  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        height: MediaQuery.of(context).size.width,
        width: MediaQuery.of(context).size.width,
        child: IgnorePointer(
          ignoring: _ignoreAllGestures,
          child: wf.WebViewWidget(
            key: widget.key,
            controller: originalWebViewController,
            gestureRecognizers: widget.mobileSpecificParams.mobileGestureRecognizers ?? {},
          ),
        ),
      ),
    );
  }


  void _init() {


    originalWebViewController
      ..setUserAgent(widget.userAgent)
      ..setOnConsoleMessage((message) {
        print(message.message);
      })
      ..setNavigationDelegate(_createNavigationDelegate())
      ..setJavaScriptMode(widget.javascriptMode);

    crossViewController = _createCrossViewController()
      ..connector = originalWebViewController;

    widget.onCreated?.call(crossViewController);


    _handleChange();

  }


  wf.NavigationDelegate _createNavigationDelegate() {
    return wf.NavigationDelegate(
      onProgress: (int progress) {
        print("progress $progress");
      },
      onPageStarted: (String url) => widget.onPageStarted?.call(url),
      onPageFinished: (String url) => widget.onPageFinished?.call(url),
      onWebResourceError: (wf.WebResourceError err) {
        return widget.onWebResourceError!(
          WebResourceError(
            description: err.description,
            errorCode: err.errorCode,
            domain: err.url,
            errorType: WebResourceErrorType.values.singleWhere((value) => value.toString() == err.errorType.toString()),
            failingUrl: err.url,
          ),
        );
      },
      onNavigationRequest: (wf.NavigationRequest request) async {

        if (widget.navigationDelegate == null) {
          crossViewController.value = crossViewController.value.copyWith(source: request.url);
          return wf.NavigationDecision.navigate;
        }

        final delegate = await widget.navigationDelegate?.call(NavigationRequest(
          content: NavigationContent(request.url, crossViewController.value.sourceType),
          isMainFrame: request.isMainFrame,
        ));

        switch (delegate!) {
          case NavigationDecision.navigate:
          // When clicking on an URL, the sourceType stays the same.
          // That's because you cannot move from URL to HTML just by clicking.
          // Also we don't take URL_BYPASS into consideration because it has no effect here in mobile
            crossViewController.value = crossViewController.value.copyWith(source: request.url);
            return wf.NavigationDecision.navigate;
        case NavigationDecision.prevent:
          return wf.NavigationDecision.prevent;
        //   default:
        //     return wf.NavigationDecision.prevent;
        }


      }
    );

  }


  CrossViewController _createCrossViewController() {
    return CrossViewController(
        initialContent: widget.initialContent,
        initialSourceType: widget.initialSourceType,
        ignoreAllGestures: _ignoreAllGestures,
      )
      ..addListener(_handleChange)
      ..addIgnoreGesturesListener(_handleIgnoreGesturesChange);
  }
  

  void _handleChange() {
    
    final data = crossViewController.value;

    switch (data.sourceType) {
      case SourceType.html:
        originalWebViewController.loadHtmlString(HtmlUtils.preprocessSource(
            data.source,
            jsContent: widget.jsContent,
            encodeHtml: false,
          ),
        );
        break;
      case SourceType.url:
        originalWebViewController.loadRequest(
          Uri.parse(data.source),
          headers: data.headers,
          body: data.body
        );
        break;
      case SourceType.assets:
        originalWebViewController.loadFlutterAsset(data.source);
        break;
      default:
        originalWebViewController.loadHtmlString(data.source);
        break;
    }

  }

  void _handleIgnoreGesturesChange() {
    setState(() => _ignoreAllGestures = crossViewController.ignoresAllGestures);
  }

  @override
  void dispose() {
    crossViewController.removeListener(_handleChange);
    crossViewController.removeIgnoreGesturesListener(
      _handleIgnoreGesturesChange,
    );
    super.dispose();
  }
}
