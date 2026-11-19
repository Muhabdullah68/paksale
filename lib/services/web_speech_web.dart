/// Browser speech synthesis bridge (web only).
///
/// iOS Safari refuses to start speech that is triggered after an `await` or a
/// timer — the call has to happen inside the user's tap. `flutter_tts` reaches
/// the browser through a platform channel, which is asynchronous, so on iOS the
/// gesture is often already gone by the time the plugin speaks. Calling
/// `speechSynthesis` directly keeps the call inside the tap and works on both
/// iOS Safari and every other browser.
library;

// ignore: deprecated_member_use, avoid_web_libraries_in_flutter
import 'dart:html' as html;

/// Whether the platform can speak through the browser's speech engine.
bool get webSpeechSupported => html.window.speechSynthesis != null;

/// Starts speaking immediately, on the current call stack.
bool webSpeak(
  String text, {
  String? language,
  double? rate,
  double? pitch,
  double? volume,
}) {
  final synth = html.window.speechSynthesis;
  if (synth == null) return false;
  try {
    // iOS Safari leaves the engine paused until resumed, and a stuck utterance
    // (page was backgrounded, or a previous one was never cancelled) blocks new
    // speech, so always resume + cancel before speaking.
    synth.resume();
    synth.cancel();
    final utterance = html.SpeechSynthesisUtterance(text);
    if (language != null && language.isNotEmpty) utterance.lang = language;
    if (rate != null) utterance.rate = rate;
    if (pitch != null) utterance.pitch = pitch;
    if (volume != null) utterance.volume = volume;
    synth.speak(utterance);
    return true;
  } catch (_) {
    return false;
  }
}

/// Cancels any in-flight browser speech.
void webStopSpeaking() {
  html.window.speechSynthesis?.cancel();
}
