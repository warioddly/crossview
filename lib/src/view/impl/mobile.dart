import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:crossview/src/utils/utils.dart';

import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart' as ww;
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

  /// Widget width
  @override
  final double width;

  /// Widget height
  @override
  final double height;

  /// Callback which returns a referrence to the [crossViewController]
  /// being created.
  @override
  final Function(ctrl_interface.crossViewController controller)? onWebViewCreated;

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
  final JavascriptMode javascriptMode;

  /// This defines if media content(audio - video) should
  /// auto play when entering the page.
  @override
  final AutoMediaPlaybackPolicy initialMediaPlaybackPolicy;

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
    required this.width,
    required this.height,
    this.onWebViewCreated,
    this.jsContent = const {},
    this.dartCallBacks = const {},
    this.ignoreAllGestures = false,
    this.javascriptMode = JavascriptMode.unrestricted,
    this.initialMediaPlaybackPolicy = AutoMediaPlaybackPolicy.requireUserActionForAllMediaTypes,
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

  final wf.WebViewController originalWebViewController = wf.WebViewController();
  late CrossViewController crossViewController;

  late bool _ignoreAllGestures;

  @override
  void initState() {
    super.initState();

    if (Platform.isAndroid && widget.mobileSpecificParams.androidEnableHybridComposition) {
      // wf.WebViewWidget.fromPlatform(platform: wf.PlatformWebViewWidgetCreationParams(
      //
      // ));
      // );
    }

    _ignoreAllGestures = widget.ignoreAllGestures;
    crossViewController = _createCrossViewController();
  }

  @override
  Widget build(BuildContext context) {

    final javaScriptMode = widget.javascriptMode == JavascriptMode.unrestricted
        ? wf.JavaScriptMode.unrestricted
        : wf.JavaScriptMode.disabled;


    void onWebResourceError(WebResourceError err) =>
        widget.onWebResourceError!(
          WebResourceError(
            description: err.description,
            errorCode: err.errorCode,
            domain: err.domain,
            errorType: WebResourceErrorType.values.singleWhere(
              (value) => value.toString() == err.errorType.toString(),
            ),
            failingUrl: err.failingUrl,
          ),
        );

    FutureOr<wf.NavigationDecision> navigationDelegate(
      wf.NavigationRequest request,
    ) async {
      if (widget.navigationDelegate == null) {
        crossViewController.value =
            crossViewController.value.copyWith(source: request.url);
        return wf.NavigationDecision.navigate;
      }

      final delegate = await widget.navigationDelegate!.call(
        NavigationRequest(
          content: NavigationContent(request.url, crossViewController.value.sourceType),
          isForMainFrame: request.isMainFrame,
        ),
      );

      switch (delegate) {
        case NavigationDecision.navigate:
          // When clicking on an URL, the sourceType stays the same.
          // That's because you cannot move from URL to HTML just by clicking.
          // Also we don't take URL_BYPASS into consideration because it has no effect here in mobile
          crossViewController.value = crossViewController.value.copyWith(
            source: request.url,
          );
          return wf.NavigationDecision.navigate;
        case NavigationDecision.prevent:
          return wf.NavigationDecision.prevent;
      }
    }

    void onWebViewCreated(wf.WebViewController webViewController) {
      crossViewController.connector = originalWebViewController;
      if (widget.onWebViewCreated != null) {
        widget.onWebViewCreated!(crossViewController);
      }
    }


    onWebViewCreated(originalWebViewController);

    // final javascriptChannels = widget.dartCallBacks
    //     .map(
    //       (cb) => wf.JavaScriptChannel(
    //         name: cb.name,
    //         onMessageReceived: (msg) => cb.callBack(msg.message),
    //       ),
    //     )
    //     .toSet();


    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: IgnorePointer(
        ignoring: _ignoreAllGestures,
        child: wf.WebViewWidget(
          key: widget.key,
          controller: originalWebViewController,
          // initialUrl: _initialContent(),
          // javascriptMode: javascriptMode,
          // onWebViewCreated: onWebViewCreated,
          // javascriptChannels: javascriptChannels,
          // gestureRecognizers:
          //     widget.mobileSpecificParams.mobileGestureRecognizers,
          // onPageStarted: widget.onPageStarted,
          // onPageFinished: widget.onPageFinished,
          // initialMediaPlaybackPolicy: initialMediaPlaybackPolicy,
          // onWebResourceError: onWebResourceError,
          // gestureNavigationEnabled:
          //     widget.mobileSpecificParams.gestureNavigationEnabled,
          // debuggingEnabled: widget.mobileSpecificParams.debuggingEnabled,
          // navigationDelegate: navigationDelegate,
          // userAgent: widget.userAgent,
        ),
      ),
    );
  }

  // Returns initial data
  String? _initialContent() {
    if (widget.initialSourceType == SourceType.html) {
      return HtmlUtils.preprocessSource(
        widget.initialContent,
        jsContent: widget.jsContent,
        encodeHtml: true,
      );
    }
    return widget.initialContent;
  }

  // Creates a crossViewController and adds the listener
  CrossViewController _createCrossViewController() {
    return crossViewController(
        initialContent: widget.initialContent,
        initialSourceType: widget.initialSourceType,
        ignoreAllGestures: _ignoreAllGestures,
      )
      ..addListener(_handleChange)
      ..addIgnoreGesturesListener(_handleIgnoreGesturesChange);
  }

  // Prepares the source depending if it is HTML or URL
  String _prepareContent(CrossViewContent content) {
    if (content.sourceType == SourceType.html) {
      return HtmlUtils.preprocessSource(
        content.source,
        jsContent: widget.jsContent,
        // Needed for mobile webview in order to URI-encode the HTML
        encodeHtml: true,
      );
    }
    return content.source;
  }

  // Called when crossViewController updates it's value
  void _handleChange() {
    
    final source = crossViewController.value;

    if (source.sourceType == SourceType.url) {
      originalWebViewController.loadRequest(
        Uri.parse(source.source),
        headers: source.headers ?? {},
        body: source.webPostRequestBody
      );
      return;
    }
    
    if (source.sourceType == SourceType.url) {
      originalWebViewController.loadFlutterAsset(source.source);
      return;
    }
    
    if (source.sourceType == SourceType.html) {
      originalWebViewController.loadHtmlString(source.source);
      return;
    }

    
  }

  // Called when the ValueNotifier inside crossViewController updates it's value
  void _handleIgnoreGesturesChange() {
    setState(() {
      _ignoreAllGestures = crossViewController.ignoresAllGestures;
    });
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
