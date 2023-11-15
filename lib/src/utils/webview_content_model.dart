
import 'package:flutter/foundation.dart';
import 'enums.dart';

/// Model class for webview's content
///
/// This is the result of calling [await crossViewController.getContent()]
class WebViewContent {
  /// Source
  final String source;

  /// Source type
  final SourceType sourceType;

  /// Headers
  final Map<String, String> headers;

  /// POST request body, on WEB only
  final Uint8List? body;

  /// Constructor
  const WebViewContent({
    required this.source,
    required this.sourceType,
    this.headers = const {},
    this.body,
  });

  WebViewContent copyWith({
    String? source,
    SourceType? sourceType,
    Map<String, String>? headers,
    Uint8List? body,
  }) =>
      WebViewContent(
        source: source ?? this.source,
        sourceType: sourceType ?? this.sourceType,
        headers: headers ?? this.headers,
        body: body ?? this.body,
      );

  @override
  String toString() {
    return 'WebViewContent:\n'
        'Source: $source\n'
        'SourceType: ${describeEnum(sourceType)}\n'
        'Last request Headers: $headers\n'
        'Last request Body: ${body ?? 'none'}\n';
  }

  @override
  bool operator ==(Object other) =>
      identical(other, this) ||
      (other is WebViewContent &&
          other.source == source &&
          other.sourceType == sourceType &&
          other.headers == headers &&
          other.body == body);

  @override
  int get hashCode =>
      source.hashCode ^
      sourceType.hashCode ^
      headers.hashCode ^
      body.hashCode;
}
