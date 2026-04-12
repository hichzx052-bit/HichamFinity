import 'dart:async';
import 'dart:collection';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../models/live_event.dart';

/// خدمة Text-to-Speech — تقرأ الأحداث بصوت عالي
class TtsService extends ChangeNotifier {
  final FlutterTts _tts = FlutterTts();
  final Queue<String> _queue = Queue();
  bool _isSpeaking = false;
  bool _enabled = true;

  // إعدادات TTS
  bool readJoins = true;        // يقرأ أسماء الداخلين
  bool readGifts = true;        // يقرأ الهدايا
  bool readComments = false;    // يقرأ التعليقات
  bool readFollows = true;      // يقرأ المتابعين الجدد
  bool readLikes = false;       // يقرأ اللايكات (كثير عادةً)

  double rate = 0.5;            // سرعة الكلام
  double pitch = 1.0;           // حدة الصوت
  String language = 'ar';       // اللغة

  bool get enabled => _enabled;
  bool get isSpeaking => _isSpeaking;

  TtsService() {
    _initTts();
  }

  Future<void> _initTts() async {
    await _tts.setLanguage(language);
    await _tts.setSpeechRate(rate);
    await _tts.setPitch(pitch);

    _tts.setCompletionHandler(() {
      _isSpeaking = false;
      _processQueue();
    });
  }

  void setEnabled(bool value) {
    _enabled = value;
    if (!value) {
      _tts.stop();
      _queue.clear();
      _isSpeaking = false;
    }
    notifyListeners();
  }

  Future<void> updateSettings({
    double? newRate,
    double? newPitch,
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
    if (newLanguage != null) {
      language = newLanguage;
      await _tts.setLanguage(language);
    }
    notifyListeners();
  }

  /// معالجة حدث جديد — يقرر إذا يقرأه ولا لا
  void processEvent(LiveEvent event) {
    if (!_enabled) return;

    String? text;

    switch (event.type) {
      case LiveEventType.join:
        if (readJoins) {
          text = '${event.displayName ?? event.username} دخل البث';
        }
        break;
      case LiveEventType.gift:
        if (readGifts) {
          text = '${event.displayName ?? event.username} أرسل ${event.giftName ?? "هدية"}';
          if ((event.giftCount ?? 1) > 1) {
            text += ' ضرب ${event.giftCount}';
          }
        }
        break;
      case LiveEventType.comment:
        if (readComments) {
          text = '${event.displayName ?? event.username} قال: ${event.message}';
        }
        break;
      case LiveEventType.follow:
        if (readFollows) {
          text = '${event.displayName ?? event.username} تابعك! مرحباً فيه';
        }
        break;
      case LiveEventType.like:
        if (readLikes && (event.likeCount ?? 0) >= 10) {
          text = '${event.displayName ?? event.username} أعجب ${event.likeCount} مرة';
        }
        break;
      default:
        break;
    }

    if (text != null) {
      _addToQueue(text);
    }
  }

  /// إضافة نص للطابور
  void _addToQueue(String text) {
    _queue.add(text);
    // حد الطابور عشان ما يتراكم
    while (_queue.length > 10) {
      _queue.removeFirst();
    }
    if (!_isSpeaking) {
      _processQueue();
    }
  }

  void _processQueue() {
    if (_queue.isEmpty || !_enabled) return;

    final text = _queue.removeFirst();
    _isSpeaking = true;
    _tts.speak(text);
  }

  /// نطق نص مباشر
  Future<void> speak(String text) async {
    if (!_enabled) return;
    _addToQueue(text);
  }

  /// إيقاف الكلام
  Future<void> stop() async {
    await _tts.stop();
    _queue.clear();
    _isSpeaking = false;
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }
}
