

/// Specifies where to embed ("burn") the javascript inside the HTML source
enum EmbedPosition {
  belowBodyOpenTag,
  aboveBodyCloseTag,
  belowHeadOpenTag,
  aboveHeadCloseTag,
}


enum SourceType {
  html,
  url,
  urlBypass,
  assets,
}