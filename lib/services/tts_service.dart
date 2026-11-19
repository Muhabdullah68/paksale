import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'language_provider.dart';
import 'web_speech.dart' if (dart.library.html) 'web_speech_web.dart' as web;

/// TTS (Text-to-Speech) service with proper language handling.
///
/// Web note: iOS Safari only starts speech that is triggered from inside a tap.
/// Going through `flutter_tts` hops over a platform channel (async) and loses
/// that gesture, so on the web we call the browser's `speechSynthesis` directly
/// (`web_speech.dart`) on the same call stack as the tap. Mobile keeps using
/// `flutter_tts`.
class TtsService with ChangeNotifier {
  // flutter_tts is only constructed on mobile. Web speaks through the browser
  // directly so the call stays inside the user's tap (required by iOS Safari).
  FlutterTts? _tts;
  FlutterTts get tts => _tts ??= FlutterTts();
  final LanguageProvider _languageProvider;

  // State
  bool _isSpeaking = false;
  bool _isLoadingLanguage = false;
  String? _lastError;
  String? _currentLanguageCode;
  double _volume = 1.0;
  double _rate = 0.5;
  double _pitch = 1.0;

  // Callbacks
  VoidCallback? onLanguageSelected;
  VoidCallback? onSpeakComplete;

  TtsService(this._languageProvider) {
    _initTts();
  }

  // Getters
  bool get isSpeaking => _isSpeaking;
  bool get isLoadingLanguage => _isLoadingLanguage;
  String? get lastError => _lastError;
  double get volume => _volume;
  double get rate => _rate;
  double get pitch => _pitch;

  /// Called by the language picker so callers can show a loading indicator
  /// while the engine language is being prepared.
  void setLoadingLanguage(bool value) {
    if (_isLoadingLanguage == value) return;
    _isLoadingLanguage = value;
    notifyListeners();
  }

  /// Initialize the platform engine and apply the starting language/parameters.
  Future<void> _initTts() async {
    _isLoadingLanguage = true;
    notifyListeners();

    try {
      if (kIsWeb) {
        // The browser engine needs no setup; language travels with each
        // utterance so no registration delay is possible.
        _currentLanguageCode = _languageProvider.languageCode;
      } else {
        await tts.awaitSpeakCompletion(true);
        await tts.setVolume(_volume);
        await tts.setSpeechRate(_rate);
        await tts.setPitch(_pitch);
        _setupListeners();
        await _setLanguage(_languageProvider.languageCode);
      }
    } catch (e) {
      _lastError = 'TTS initialization failed: $e';
      debugPrint('TTS init error: $e');
    } finally {
      _isLoadingLanguage = false;
      notifyListeners();
    }
  }

  /// Completion / error / language listeners (mobile engines only).
  void _setupListeners() {
    tts.setCompletionHandler(() {
      _isSpeaking = false;
      notifyListeners();
      onSpeakComplete?.call();
    });

    tts.setErrorHandler((dynamic message) {
      _isSpeaking = false;
      _lastError = 'TTS error: $message';
      notifyListeners();
      debugPrint('TTS error: $message');
    });

    tts.setCancelHandler(() {
      _isSpeaking = false;
      notifyListeners();
    });
  }

  /// Map our internal language code to the TTS locale format.
  String _mapLanguageCode(String code) {
    switch (code) {
      case 'en':
        return 'en_US';
      case 'ar':
        return 'ar_AE';
      case 'ur':
        return 'ur_PK';
      default:
        return code;
    }
  }

  /// Sets the engine language. No-op on web (language is sent per utterance).
  Future<void> setLanguage(String languageCode) => _setLanguage(languageCode);

  Future<void> _setLanguage(String languageCode) async {
    _currentLanguageCode = languageCode;
    notifyListeners();

    if (kIsWeb) return;

    try {
      final ttsLanguage = _mapLanguageCode(languageCode);

      final available = await tts.isLanguageAvailable(ttsLanguage);
      // Some Android engines only accept the base tag (e.g. `ur`).
      final applied = available == true
          ? ttsLanguage
          : ttsLanguage.split('_').first;
      await tts.setLanguage(applied);

      if (languageCode == 'ar') {
        await tts.setSpeechRate(0.5);
        await tts.setPitch(0.8);
      } else if (languageCode == 'ur') {
        await tts.setSpeechRate(0.5);
        await tts.setPitch(0.9);
      } else {
        await tts.setSpeechRate(0.5);
        await tts.setPitch(1.0);
      }

      debugPrint('TTS language set to: $applied');
    } catch (e) {
      _lastError = 'Failed to set TTS language: $e';
      debugPrint('TTS setLanguage error: $e');
    }
  }

  /// Speak [text] with the current language.
  ///
  /// On web the browser call happens synchronously, so this must be invoked
  /// directly from the tap handler (do not await anything first).
  Future<void> speak(String text) => speakWithLanguage(text);

  /// Speak [text] with an explicit language.
  Future<void> speakWithLanguage(String text, {String? languageCode}) async {
    if (text.isEmpty) return;

    final code = languageCode ?? _languageProvider.languageCode;
    _isSpeaking = true;
    _lastError = null;
    notifyListeners();

    if (kIsWeb) {
      final started = web.webSpeak(
        text,
        language: _mapLanguageCode(code).replaceAll('_', '-'),
        rate: _rate,
        pitch: _pitch,
        volume: _volume,
      );
      if (!started) {
        _lastError = 'Speech is not available in this browser.';
      }
      _currentLanguageCode = code;
      _isSpeaking = false;
      notifyListeners();
      if (started) onSpeakComplete?.call();
      return;
    }

    try {
      if (_currentLanguageCode != code) {
        await _setLanguage(code);
      }
      // `awaitSpeakCompletion(true)` makes this resolve when speech finishes.
      await tts.speak(text);
    } catch (e) {
      _lastError = 'Speak failed: $e';
      debugPrint('TTS speak error: $e');
    } finally {
      _isSpeaking = false;
      notifyListeners();
    }
  }

  /// Stop any ongoing speech.
  Future<void> stop() async {
    try {
      if (kIsWeb) {
        web.webStopSpeaking();
      } else {
        await tts.stop();
      }
    } catch (e) {
      debugPrint('TTS stop error: $e');
    }
    _isSpeaking = false;
    notifyListeners();
  }

  /// Kept for callers that want to stop and clear the speech queue.
  Future<void> cancel() => stop();

  /// Set volume (0.0 to 1.0).
  Future<void> setVolume(double volume) async {
    _volume = volume.clamp(0.0, 1.0);
    if (!kIsWeb) {
      try {
        await tts.setVolume(_volume);
      } catch (e) {
        debugPrint('TTS setVolume error: $e');
      }
    }
    notifyListeners();
  }

  /// Set speech rate (0.5 to 2.0, where 0.5 is the platform default).
  Future<void> setRate(double rate) async {
    _rate = rate.clamp(0.5, 2.0);
    if (!kIsWeb) {
      try {
        await tts.setSpeechRate(_rate);
      } catch (e) {
        debugPrint('TTS setRate error: $e');
      }
    }
    notifyListeners();
  }

  /// Set pitch (0.5 to 2.0).
  Future<void> setPitch(double pitch) async {
    _pitch = pitch.clamp(0.5, 2.0);
    if (!kIsWeb) {
      try {
        await tts.setPitch(_pitch);
      } catch (e) {
        debugPrint('TTS setPitch error: $e');
      }
    }
    notifyListeners();
  }

  /// Whether speech synthesis is usable on this device/browser.
  Future<bool> isAvailable() async {
    if (kIsWeb) return web.webSpeechSupported;
    try {
      final languages = await tts.getLanguages;
      return languages is List && languages.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Supported language tags, empty when the platform cannot report them.
  Future<List<String>> getAvailableLanguages() async {
    if (kIsWeb) return const [];
    try {
      final languages = await tts.getLanguages;
      if (languages is List) {
        return languages.map((e) => e.toString()).toList();
      }
      return const [];
    } catch (_) {
      return const [];
    }
  }

  @override
  void dispose() {
    if (!kIsWeb) tts.stop();
    super.dispose();
  }
}
