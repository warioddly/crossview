import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import 'dart:js' as js;
import 'package:webview_flutter/webview_flutter.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import 'package:crossview/src/utils/constants.dart';
import 'package:crossview/src/utils/logger.dart';
import 'package:crossview/src/utils/utils.dart';
import 'package:crossview/src/controller/implements/web.dart';
import 'package:http/http.dart' as http;
import 'package:crossview/src/utils/dart_ui_fix.dart' as ui;
import 'package:crossview/src/controller/interface.dart' as ctrl_interface;
import 'package:crossview/src/crossview/interface.dart' as view_interface;

/// Web implementation
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
  final Function(ctrl_interface.CrossViewController controller)? onViewCreated;

  /// A set of [EmbeddedJsContent].
  ///
  /// You can define JS functions, which will be embedded into
  /// the HTML source (won't do anything on URL) and you can later call them
  /// using the controller.
  ///
  /// For more info, see [EmbeddedJsContent].
  @override
  final Set<EmbeddedJsContent> jsContent;

  /// Boolean value to specify if should ignore all gestures that touch the webview.
  ///
  /// You can change this later from the controller.
  @override
  final bool ignoreAllGestures;


  /// Callback to decide whether to allow navigation to the incoming url
  @override
  final NavigationDelegate? navigationDelegate;


  /// This defines if Javascript execution should be allowed inside the webview
  @override
  final JavaScriptMode javascriptMode;


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
    this.javascriptMode = JavaScriptMode.unrestricted,
    this.userAgent,
    this.onViewCreated,
    this.jsContent = const {},
    this.ignoreAllGestures = false,
    this.navigationDelegate,
    this.webSpecificParams = const WebSpecificParams(),
    this.mobileSpecificParams = const MobileSpecificParams(),
  }) : super(key: key);

  @override
  State<CrossView> createState() => _WebViewXState();
}

class _WebViewXState extends State<CrossView> {

  late html.IFrameElement iframe;
  late String iframeViewType;
  late StreamSubscription iframeOnLoadSubscription;
  late js.JsObject jsWindowObject;

  late CrossViewController crossViewController;

  late bool _didLoadInitialContent;
  late bool _ignoreAllGestures;

  @override
  void initState() {
    super.initState();
    _init();
  }


  @override
  Widget build(BuildContext context) {
    return _iframeIgnorePointer(
      ignoring: _ignoreAllGestures,
      child: SizedBox(
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.width,
        child: AbsorbPointer(
          child: RepaintBoundary(
            child: HtmlElementView(
              key: widget.key,
              viewType: iframeViewType,
            ),
          ),
        ),
      ),
    );
  }


  void _init() {

    _didLoadInitialContent = false;
    _ignoreAllGestures = widget.ignoreAllGestures;

    iframeViewType = _createViewType();
    iframe = _createIFrame();
    _registerView(iframeViewType);

    crossViewController = _createCrossViewController();

    if (widget.initialSourceType == SourceType.html || widget.initialSourceType == SourceType.urlBypass ||
        (widget.initialSourceType == SourceType.url && widget.initialContent == 'about:blank')
    ) {
      _connectJsToFlutter(then: _callOnWebViewCreatedCallback);
    } else {
      _callOnWebViewCreatedCallback();
    }

    _registerIframeOnLoadCallback();

    // Allow the iframe to initialize.
    // Otherwise it will fail loading the initial content.
    Future.delayed(Duration.zero, () => _updateSource(crossViewController.value));
  }


  void _registerView(String viewType) {
    ui.platformViewRegistry.registerViewFactory(viewType, (int viewId) => iframe);
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

  // Keep js "window" object referrence, so we can call functions on it later.
  // This happens only if we use HTML (because you can't alter the source code
  // of some other webpage that you pass in using the URL param)
  //
  // Iframe viewType is used as a disambiguator.
  // Check function [embedWebIframeJsConnector] from [HtmlUtils] for details.
  void _connectJsToFlutter({VoidCallback? then}) {

    js.context['$jsToDartConnectorFN$iframeViewType'] = (js.JsObject window) {
      jsWindowObject = window;

      // /// Register dart callbacks one by one.
      // for (final cb in widget.dartCallBacks) {
      //   jsWindowObject[cb.name] = cb.callBack;
      // }
      //

      // Register history callback
      jsWindowObject[webOnClickInsideIframeCallback] = (onClickCallbackObject) {
        _handleOnIframeClick(onClickCallbackObject as String);
      };

      crossViewController.connector = jsWindowObject;

      then?.call();

      /* 
      // Registering the same events as we already do inside
      // HtmlUtils.embedClickListenersInPageSource(), but in Dart.
      // So far it seems to be working, but needs more testing.

      jsWindowObject.callMethod('addEventListener', [
        "click",
        js.allowInterop((event) {
          final href = jsWindowObject["document"]["activeElement"]["href"].toString();
          print(href);
        })
      ]);

      jsWindowObject.callMethod('addEventListener', [
        "submit",
        js.allowInterop((event) {
          final form = jsWindowObject["document"]["activeElement"]["form"];

          final method = form["method"].toString();

          if (method == 'get') {
            final action = jsWindowObject.callMethod(
              'eval',
              [
                "document.activeElement.form.action + '?' + new URLSearchParams(new FormData(document.activeElement.form))"
              ],
            ).toString();
            print(action);
          } else {
            // post
            final action = form["action"].toString();

            final formData = jsWindowObject
                .callMethod(
                  'eval',
                  ["[...new FormData(document.activeElement.form)]"],
                )
                .toString()
                .split(',');

            final mappedFields = <String, dynamic>{};
            for (var i = 0; i < formData.length; i++) {
              if (i % 2 != 0) {
                mappedFields[formData[i - 1]] = formData[i];
              }
            }
            print(mappedFields);
          }
        })
      ]);
      */
    };
  }

  void _registerIframeOnLoadCallback() {
    iframeOnLoadSubscription = iframe.onLoad.listen((event) {
      _debugLog('IFrame $iframeViewType has been (re)loaded.');

      if (!_didLoadInitialContent) {
        _didLoadInitialContent = true;
        _callOnPageStartedCallback(crossViewController.value.source);
      } else {
        _callOnPageFinishedCallback(crossViewController.value.source);
      }
    });
  }

  void _callOnWebViewCreatedCallback() {
    widget.onViewCreated?.call(crossViewController);
  }


  void _callOnPageStartedCallback(String src) {
    widget.navigationDelegate?.onPageStarted?.call(src);
  }


  void _callOnPageFinishedCallback(String src) {
    widget.navigationDelegate?.onPageFinished?.call(src);
  }


  Widget _iframeIgnorePointer({ bool ignoring = false, required Widget child }) {
    return Stack(
      children: [
        child,
        if (ignoring)
          Positioned.fill(
            child: PointerInterceptor(
              child: const SizedBox(),
            ),
          )
        else const SizedBox.shrink(),
      ],
    );
  }

  // This creates a unique String to be used as the view type of the HtmlElementView
  String _createViewType() {
    return HtmlUtils.buildIframeViewType();
  }

  html.IFrameElement _createIFrame() {


    final iframeElement = html.IFrameElement()
      ..id = 'id_$iframeViewType'
      ..name = 'name_$iframeViewType'
      ..style.border = 'none'
      // ..width = '100%'
      // ..height = '100%'
      ..allowFullscreen = widget.webSpecificParams.webAllowFullscreenContent;


    widget.webSpecificParams.additionalSandboxOptions.forEach(iframeElement.sandbox!.add);

    iframeElement.sandbox!.add('allow-scripts');

    // if (widget.initialMediaPlaybackPolicy ==
    //     AutoMediaPlaybackPolicy.alwaysAllow) {
    //   allow.add('autoplay');
    // }

    iframeElement.allow = widget.webSpecificParams.additionalAllowOptions.reduce((curr, next) => '$curr; $next');

    return iframeElement;
  }

  // Called when CrossViewController updates it's value
  void _handleChange() {
    final model = crossViewController.value;
    final source = model.source;

    _callOnPageStartedCallback(source);
    _updateSource(model);
  }

  // Called when CrossViewController updates it's ignoreAllGesturesNotifier value
  void _handleIgnoreGesturesChange() {
    setState(() {
      _ignoreAllGestures = crossViewController.ignoresAllGestures;
    });
  }

  Future<bool> _checkNavigationAllowed(String pageSource, SourceType sourceType) async {

    if (widget.navigationDelegate == null) return true;

    final decision = await widget.navigationDelegate!.onNavigationRequest?.call(NavigationRequest(
      url: pageSource,
      isMainFrame: true,
    ));

    return decision == NavigationDecision.navigate;
  }

  // Updates the source depending if it is HTML or URL
  void _updateSource(WebViewContent model) {
    final source = model.source;

    if (source.isEmpty) {
      _debugLog('Cannot set empty source on webview.');
      return;
    }

    switch (model.sourceType) {
      case SourceType.html:
        iframe.srcdoc = HtmlUtils.preprocessSource(
          source,
          jsContent: widget.jsContent,
          windowDisambiguator: iframeViewType,
          forWeb: true,
        );
        break;
      case SourceType.url:
      case SourceType.assets:
      case SourceType.urlBypass:
        if (source == 'about:blank') {
          iframe.srcdoc = HtmlUtils.preprocessSource(
            '<br>',
            jsContent: widget.jsContent,
            windowDisambiguator: iframeViewType,
            forWeb: true,
          );
          break;
        }

        if (!source.startsWith(RegExp('http[s]?://', caseSensitive: false))) {
          _debugLog('Invalid URL supplied for webview: $source');
          return;
        }

        if (model.sourceType == SourceType.url) {
          iframe.contentWindow!.location.href = source;
        }
        else {
          _tryFetchRemoteSource(method: 'get', url: source, headers: model.headers);
        }

        break;
    }
  }


  Future<void> _handleOnIframeClick(String receivedObject) async {
    final dartObj = jsonDecode(receivedObject) as Map<String, dynamic>;
    final href = dartObj['href'] as String;
    _debugLog(dartObj.toString());

    if (!await _checkNavigationAllowed(
        href, crossViewController.value.sourceType)) {
      _debugLog('Navigation not allowed for source:\n$href\n');
      return;
    }

    // (ㆆ_ㆆ)
    if (href == 'javascript:history.back()') {
      crossViewController.goBack();
      return;
    } else if (href == 'javascript:history.forward()') {
      crossViewController.goForward();
      return;
    }

    final method = dartObj['method'] as String;
    final body = dartObj['body'];


    final uint8ListBody = body == null
        ? null
        : Uint8List.fromList((body as List<dynamic>).map( (e) => int.parse(e.toString())).toList());

    _tryFetchRemoteSource(
      method: method,
      url: href,
      headers: crossViewController.value.headers,
      body: uint8ListBody,
    );
  }


  void _tryFetchRemoteSource({ required String method, required String url, Map<String, String> headers = const {}, Uint8List? body }) {

    _fetchPageSourceBypass( method: method, url: url, headers: headers, body: body ).then((source) {

      _setPageSourceAfterBypass(url, source);

      crossViewController.webRegisterNewHistoryEntry(WebViewContent(
        source: url,
        sourceType: SourceType.urlBypass,
        headers: headers,
        body: body,
      ));

      _debugLog('Got a new history entry: $url\n');
    }).catchError((e) {

      widget.navigationDelegate?.onWebResourceError?.call(WebResourceError(
          description: 'Failed to fetch the page at $url\nError:\n$e\n',
          errorCode: WebResourceErrorType.connect.index,
          errorType: WebResourceErrorType.connect,
          url: url,
          isForMainFrame: true
        ));

      _debugLog('Failed to fetch the page at $url\nError:\n$e\n');

    });
  }


  Future<String> _fetchPageSourceBypass({ required String method, required String url, Map<String, String> headers = const {}, Uint8List? body }) async {
    final proxyList = widget.webSpecificParams.proxyList;

    if (widget.userAgent != null) {
      headers.putIfAbsent(userAgentHeadersKey, () => widget.userAgent!);
    }

    for (var i = 0; i < proxyList.length; i++) {
      final proxy = proxyList[i];
      _debugLog('Using proxy: ${proxy.runtimeType}');

      final proxiedUri = Uri.parse(proxy.buildProxyUrl(Uri.encodeFull(url)));

      Future<http.Response> request;

      if (method == 'get') {
        request = http.get(proxiedUri, headers: headers);
      } else {
        request = http.post(proxiedUri, headers: headers, body: body);
      }

      try {
        final response = await request;
        return proxy.extractPageSource(response.body);
      } catch (e) {
        _debugLog(
          'Failed to fetch the page at $url from proxy ${proxy.runtimeType}.',
        );

        if (i == proxyList.length - 1) {
          return Future.error('None of the provided proxies were able to fetch the given page.');
        }

        continue;
      }
    }

    return Future.error('Bad state');
  }

  void _setPageSourceAfterBypass(String pageUrl, String pageSource) {

    final replacedPageSource = HtmlUtils.embedClickListenersInPageSource(pageUrl, pageSource);

    iframe.srcdoc = HtmlUtils.preprocessSource(
      replacedPageSource,
      jsContent: widget.jsContent,
      windowDisambiguator: iframeViewType,
      forWeb: true,
    );
  }

  void _debugLog(String text) {
    if (widget.webSpecificParams.printDebugInfo) {
      log(text);
    }
  }

  @override
  void dispose() {
    iframeOnLoadSubscription.cancel();
    crossViewController
      ..removeListener(_handleChange)
      ..removeIgnoreGesturesListener(_handleIgnoreGesturesChange);
    super.dispose();
  }
}
