/// Non-web stub for `web_speech_web.dart`.
///
/// Used on every platform that is not compiled to JavaScript, so the app can
/// keep importing `web_speech.dart` without pulling in `dart:html`.
library;

/// Whether the platform can speak through the browser's speech engine.
bool get webSpeechSupported => false;

/// Starts speaking synchronously. Always false off the web.
bool webSpeak(
  String text, {
  String? language,
  double? rate,
  double? pitch,
  double? volume,
}) =>
    false;

/// Cancels any in-flight browser speech.
void webStopSpeaking() {}
