import 'dart:collection';
import 'package:flutter_tts/flutter_tts.dart';

/// خدمة TTS — تنطق الأسماء والأحداث مرة وحدة بس
class TtsService {
  final FlutterTts _tts = FlutterTts();
  final Queue<String> _queue = Queue<String>();
  final Set<String> _recentlySpoken = {}; // منع التكرار
  bool _isSpeaking = false;
  bool _isEnabled = true;
  
  // إعدادات
  double rate = 0.5;
  double pitch = 1.0;
  double volume = 1.0;
  String language = 'ar';

  // أنواع الأحداث المفعّلة
  bool speakJoins = true;
  bool speakComments = true;
  bool speakGifts = true;
  bool speakFollows = true;
  bool speakLikes = false; // اللايكات كثيرة — مقفل افتراضياً

  static const int _maxQueue = 10;
  static const Duration _duplicateWindow = Duration(seconds: 30);

  Future<void> init() async {
    await _tts.setLanguage(language);
    await _tts.setSpeechRate(rate);
    await _tts.setPitch(pitch);
    await _tts.setVolume(volume);

    _tts.setCompletionHandler(() {
      _isSpeaking = false;
      _processQueue();
    });

    _tts.setErrorHandler((msg) {
      _isSpeaking = false;
      _processQueue();
    });
  }

  void setEnabled(bool enabled) {
    _isEnabled = enabled;
    if (!enabled) {
      stop();
    }
  }

  Future<void> updateSettings({
    double? newRate,
    double? newPitch,
    double? newVolume,
    String? newLanguage,
  }) async {
    if (newRate != null) {
      rate = newRate;
      await _tts.setSpeechRate(rate);
    }
    if (newPitch != null) {
      pitch = newPitch;
      await _tts.setPitch(pitch);
    }
    if (newVolume != null) {
      volume = newVolume;
      await _tts.setVolume(volume);
    }
    if (newLanguage != null) {
      language = newLanguage;
      await _tts.setLanguage(language);
    }
  }

  /// نطق حدث دخول
  void speakJoin(String displayName) {
    if (!speakJoins) return;
    _enqueue('أهلاً $displayName');
  }

  /// نطق تعليق
  void speakComment(String displayName, String comment) {
    if (!speakComments) return;
    _enqueue('$displayName يقول: $comment');
  }

  /// نطق هدية
  void speakGift(String displayName, String giftName, int count) {
    if (!speakGifts) return;
    final text = count > 1
        ? '$displayName أرسل $giftName ضرب $count'
        : '$displayName أرسل $giftName';
    _enqueue(text);
  }

  /// نطق متابعة
  void speakFollow(String displayName) {
    if (!speakFollows) return;
    _enqueue('$displayName تابعك!');
  }

  /// نطق لايك
  void speakLike(String displayName, int count) {
    if (!speakLikes) return;
    _enqueue('$displayName أعطاك $count لايك');
  }

  /// نطق نص مخصص
  void speakCustom(String text) {
    _enqueue(text);
  }

  /// نطق حدث "الأول" (أول متابع/معلق/مهدي)
  void speakFirst(String type, String displayName) {
    _enqueue('🏅 $displayName هو أول $type في البث!', priority: true);
  }

  void _enqueue(String text, {bool priority = false}) {
    if (!_isEnabled) return;

    // منع التكرار — نفس النص خلال 30 ثانية
    if (_recentlySpoken.contains(text)) return;
    _recentlySpoken.add(text);
    Future.delayed(_duplicateWindow, () => _recentlySpoken.remove(text));

    // حد أقصى للقائمة
    if (_queue.length >= _maxQueue) {
      if (!priority) return; // ما نضيف لو القائمة ممتلئة
      _queue.removeFirst(); // نشيل الأقدم لو أولوية
    }

    if (priority) {
      // الأولوية — نحط بالأول
      final list = _queue.toList();
      list.insert(0, text);
      _queue.clear();
      list.forEach(_queue.add);
    } else {
      _queue.add(text);
    }

    _processQueue();
  }

  void _processQueue() {
    if (_isSpeaking || _queue.isEmpty || !_isEnabled) return;

    final text = _queue.removeFirst();
    _isSpeaking = true;
    _tts.speak(text);
  }

  Future<void> stop() async {
    _queue.clear();
    _isSpeaking = false;
    await _tts.stop();
  }

  Future<void> dispose() async {
    await stop();
  }

  Future<List<dynamic>> getAvailableLanguages() async {
    return await _tts.getLanguages;
  }

  bool get isEnabled => _isEnabled;
  int get queueLength => _queue.length;
}
