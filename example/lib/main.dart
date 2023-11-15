import 'package:flutter/material.dart';
import 'package:crossview/crossview.dart';
import 'package:flutter/cupertino.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CrossView Example App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true),
      home: const CrossViewExample()
    );
  }


}


class CrossViewExample extends StatefulWidget {
  const CrossViewExample({Key? key}) : super(key: key);

  @override
  State<CrossViewExample> createState() => _CrossViewExampleState();
}

class _CrossViewExampleState extends State<CrossViewExample> {

  late CrossViewController webviewController;

  final initialContent = '<h4> This is some hardcoded HTML code embedded inside the webview <h4> <h2> Hello world! <h2>';

  final executeJsErrorMessage =
      'Failed to execute this task because the current content is (probably) URL that allows iframe embedding, on Web.\n\n'
      'A short reason for this is that, when a normal URL is embedded in the iframe, you do not actually own that content so you cant call your custom functions\n'
      '(read the documentation to find out why).';

  Size get screenSize => MediaQuery.of(context).size;


  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('CrossView Page'),
          actions: [

            IconButton(
              onPressed: () => _showMenu(),
              icon: const Icon(Icons.info_outline),
            ),

          ],
        ),
        body: Center(
          child: Column(
            children: <Widget>[

              TextField(
                onSubmitted: (value) {

                  if (Uri.parse(value).isAbsolute) {
                    webviewController.loadContent(
                      value,
                      SourceType.urlBypass,
                    );
                  }
                  else {

                    webviewController.loadContent(
                      'https://www.google.com/search?q=$value',
                      SourceType.urlBypass,
                    );

                  }

                },
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Enter a URL',
                  hintStyle: TextStyle(color: Colors.white),
                  contentPadding: EdgeInsets.all(10),
                  prefixIcon: Icon(Icons.search),
                ),
              ),

              Expanded(child: _buildCrossView()),

              Container(
                width: screenSize.width,
                height: 50,
                color: Colors.white.withOpacity(0.5),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [

                    IconButton(
                      onPressed: _goBack,
                      icon: const Icon(Icons.arrow_back_ios),
                    ),

                    IconButton(
                      onPressed: _goForward,
                      icon: const Icon(Icons.arrow_forward_ios),
                    ),

                    IconButton(
                      onPressed: _reload,
                      icon: const Icon(Icons.refresh),
                    ),

                    IconButton(
                      onPressed: _toggleIgnore,
                      icon: const Icon(Icons.touch_app),
                    ),

                  ],
                ),
              ),

            ],
          ),
        ),
      ),
    );
  }


  Future<void> _showMenu() async {

    showCupertinoModalPopup(
        context: context,
        builder: (context) {
          return SizedBox(
              height: MediaQuery.of(context).size.height * 0.8,
              child: CupertinoActionSheet(
                title: const Text("Select Action"),
                actions: [

                  _buildAction(
                      "Change content to URL that allows iframes embedding\n(https://flutter.dev)",
                      _setUrl,
                      context
                  ),

                  _buildAction(
                      "Change content to URL that doesnt allow iframes embedding\n(https://google.com/)",
                      _setUrlBypass,
                      context
                  ),

                  _buildAction(
                      "Change content to HTML (hardcoded)",
                      _setHtml,
                      context
                  ),

                  _buildAction(
                      "Change content to HTML (from assets)",
                      _setHtmlFromAssets,
                      context
                  ),

                  _buildAction(
                      "Evaluate 2+2 in the global \"window\" (javascript side)",
                      _evalRawJsInGlobalContext,
                      context
                  ),


                  _buildAction(
                      "Call platform independent Js method (console.log)",
                      _callPlatformIndependentJsMethod,
                      context
                  ),

                  _buildAction(
                      "Call platform specific Js method, that calls back a Dart function",
                      _callPlatformSpecificJsMethod,
                      context
                  ),

                  _buildAction(
                      "Show current webview content",
                      _getWebviewContent,
                      context
                  ),

                ],
                cancelButton: CupertinoActionSheetAction(
                  onPressed: () {
                    Navigator.maybePop(context);
                  },
                  child: Text(
                    "Cancel",
                    textAlign: TextAlign.left,
                    maxLines: 2,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              )
          );
        }
    );

  }


  Widget _buildAction(String text, VoidCallback onTap, context) {
    return CrossViewAware(
      child: CupertinoActionSheetAction(
        onPressed: () {
          onTap();
          Navigator.of(context).pop();
        },
        child: Text(text),
      ),
    );
  }


  Widget _buildCrossView() {
    return CrossView(
      key: const ValueKey('CrossView'),
      initialContent: initialContent,
      initialSourceType: SourceType.html,
      onViewCreated: (controller) => webviewController = controller,
      webSpecificParams: const WebSpecificParams(printDebugInfo: true),
      mobileSpecificParams: const MobileSpecificParams(androidEnableHybridComposition: true),
      // jsContent: const {
      //   EmbeddedJsContent(
      //     js: "function testPlatformIndependentMethod() { console.log('Hi from JS') }",
      //   ),
      //   EmbeddedJsContent(
      //     webJs:
      //     "function testPlatformSpecificMethod(msg) { TestDartCallback('Web callback says: ' + msg) }",
      //     mobileJs:
      //     "function testPlatformSpecificMethod(msg) { TestDartCallback.postMessage('Mobile callback says: ' + msg) }",
      //   ),
      // },
    );
  }


  void _setUrl() {
    webviewController.loadContent(
      'https://flutter.dev',
      SourceType.url,
    );
  }

  void _setUrlBypass() {
    webviewController.loadContent(
      'https://google.com/',
      SourceType.urlBypass,
    );
  }

  void _setHtml() {
    webviewController.loadContent(
      initialContent,
      SourceType.html,
    );
  }

  void _setHtmlFromAssets() {
    webviewController.loadContent(
      'assets/test.html',
      SourceType.html,
      fromAssets: true,
    );
  }

  Future<void> _goForward() async {
    if (await webviewController.canGoForward()) {
      await webviewController.goForward();
      showSnackBar('Did go forward', context);
    } else {
      showSnackBar('Cannot go forward', context);
    }
  }

  Future<void> _goBack() async {
    if (await webviewController.canGoBack()) {
      await webviewController.goBack();
      showSnackBar('Did go back', context);
    } else {
      showSnackBar('Cannot go back', context);
    }
  }

  void _reload() {
    webviewController.reload();
  }

  void _toggleIgnore() {
    final ignoring = webviewController.ignoresAllGestures;
    webviewController.setIgnoreAllGestures(!ignoring);
    showSnackBar('Ignore events = ${!ignoring}', context);
  }

  Future<void> _evalRawJsInGlobalContext() async {
    try {
      final result = await webviewController.runJavaScript(
        '2+2',
        inGlobalContext: true,
      );
      showSnackBar('The result is $result', context);
    } catch (e) {
      showAlertDialog(
        executeJsErrorMessage,
        context,
      );
    }
  }

  Future<void> _callPlatformIndependentJsMethod() async {
    try {
      await webviewController.callJsMethod('testPlatformIndependentMethod', []);
    } catch (e) {
      showAlertDialog(
        executeJsErrorMessage,
        context,
      );
    }
  }

  Future<void> _callPlatformSpecificJsMethod() async {
    try {
      await webviewController.callJsMethod('testPlatformSpecificMethod', ['Hi']);
    } catch (e) {
      showAlertDialog(
        executeJsErrorMessage,
        context,
      );
    }
  }

  Future<void> _getWebviewContent() async {
    try {
      final content = await webviewController.getContent();
      showAlertDialog(content.source, context);
    } catch (e) {
      showAlertDialog('Failed to execute this task.', context);
    }
  }

  Widget buildSpace({ Axis direction = Axis.horizontal, double amount = 0.2,  bool flex = true }) {
    return flex
        ? Flexible(
      child: FractionallySizedBox(
        widthFactor: direction == Axis.horizontal ? amount : null,
        heightFactor: direction == Axis.vertical ? amount : null,
      ),
    )
        : SizedBox(
      width: direction == Axis.horizontal ? amount : null,
      height: direction == Axis.vertical ? amount : null,
    );
  }

  Widget createButton({ VoidCallback? onTap, required String text }) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      ),
      child: Text(text),
    );
  }


  void showAlertDialog(String content, BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => CrossViewAware(
        child: AlertDialog(
          content: Text(content),
          actions: [
            TextButton(
              onPressed: Navigator.of(context).pop,
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }

  void showSnackBar(String content, BuildContext context) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.only(bottom: 60.0, left: 10.0, right: 10.0),
          backgroundColor: Colors.black,
          content: Text(
            content,
            style: const TextStyle(
              color: Colors.white,
            ),
          ),
          duration: const Duration(seconds: 1),
        ),
      );
  }

  @override
  void dispose() {
    webviewController.dispose();
    super.dispose();
  }

}


