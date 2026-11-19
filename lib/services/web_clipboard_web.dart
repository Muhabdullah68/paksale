/// Browser clipboard bridge (web only).
///
/// iOS Safari only allows clipboard writes while the user's tap is still on
/// the call stack. Flutter's `Clipboard.setData` crosses a platform channel
/// (async), so Safari drops the gesture and nothing is copied even though the
/// app reports success. Calling `navigator.clipboard.writeText` directly keeps
/// the write in the tap. A hidden-textarea fallback covers browsers without
/// the async Clipboard API.
library;

// ignore: deprecated_member_use, avoid_web_libraries_in_flutter
import 'dart:html' as html;

/// Copies [text] to the system clipboard from the current user gesture.
/// Returns whether the browser reported success.
Future<bool> copyToClipboard(String text) async {
  // Important: start writeText BEFORE any await so the gesture is preserved.
  try {
    final clipboard = html.window.navigator.clipboard;
    if (clipboard != null) {
      await clipboard.writeText(text);
      return true;
    }
  } catch (_) {
    // Older browsers / denied permission — try the legacy path below.
  }
  return _legacyCopy(text);
}

bool _legacyCopy(String text) {
  html.TextAreaElement? area;
  try {
    area = html.TextAreaElement()
      ..value = text
      ..style.position = 'fixed'
      ..style.top = '-1000px'
      ..style.opacity = '0';
    html.document.body?.append(area);
    area.focus();
    area.select();
    // ignore: deprecated_member_use
    return html.document.execCommand('copy');
  } catch (_) {
    return false;
  } finally {
    area?.remove();
  }
}
