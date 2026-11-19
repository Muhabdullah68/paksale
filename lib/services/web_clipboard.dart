/// Non-web stub for `web_clipboard_web.dart`.
///
/// Kept so callers can import `web_clipboard.dart` on every platform without
/// pulling `dart:html` into mobile builds.
library;

/// Off the web we never use the browser clipboard path.
Future<bool> copyToClipboard(String text) async => false;
