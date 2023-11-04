import 'package:flutter/foundation.dart';
import 'package:crossview/src/utils/source_type.dart';

/// Model class for webview's content
///
/// This is the result of calling [await crossviewController.getContent()]
class CrossViewContent {
  /// Source
  final String source;

  /// Source type
  final SourceType sourceType;

  /// Headers
  final Map<String, String>? headers;

  /// POST request body, on WEB only
  final Uint8List? body;

  /// Constructor
  const CrossViewContent({
    required this.source,
    required this.sourceType,
    this.headers,
    this.body,
  });

  CrossViewContent copyWith({
    String? source,
    SourceType? sourceType,
    Map<String, String>? headers,
    Object? body,
  }) =>
      CrossViewContent(
        source: source ?? this.source,
        sourceType: sourceType ?? this.sourceType,
        headers: headers ?? this.headers,
        body: body ?? this.body,
      );

  @override
  String toString() {
    return 'CrossViewContent:\n'
        'Source: $source\n'
        'SourceType: ${describeEnum(sourceType)}\n'
        'Last request Headers: ${headers ?? 'none'}\n'
        'Last request Body: ${body ?? 'none'}\n';
  }

  @override
  bool operator ==(Object other) =>
      identical(other, this) ||
      (other is CrossViewContent &&
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
