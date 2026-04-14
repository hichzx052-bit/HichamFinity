import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

enum TriggerType { likes, viewers, gifts, manual }

class TriggerConfig {
  final String id;
  final TriggerType type;
  final int threshold; // عدد اللايكات/المشاهدين/الخ
  final String? videoPath; // مسار الفيديو
  final String? giftName; // اسم الهدية (لو نوع هدية)
  bool enabled;

  TriggerConfig({
    required this.id,
    required this.type,
    required this.threshold,
    this.videoPath,
    this.giftName,
    this.enabled = true,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.index,
        'threshold': threshold,
        'videoPath': videoPath,
        'giftName': giftName,
        'enabled': enabled,
      };

  factory TriggerConfig.fromJson(Map<String, dynamic> json) => TriggerConfig(
        id: json['id'] as String,
        type: TriggerType.values[json['type'] as int],
        threshold: json['threshold'] as int,
        videoPath: json['videoPath'] as String?,
        giftName: json['giftName'] as String?,
        enabled: json['enabled'] as bool? ?? true,
      );
}

class TriggerService extends ChangeNotifier {
  final List<TriggerConfig> _triggers = [];
  final Set<String> _firedTriggers = {}; // اللي اشتغلت خلاص
  
  // Stream للفيديوهات اللي لازم تنعرض
  final _videoController = StreamController<TriggerConfig>.broadcast();
  Stream<TriggerConfig> get videoStream => _videoController.stream;

  List<TriggerConfig> get triggers => List.unmodifiable(_triggers);

  /// تحميل الـ triggers المحفوظة
  Future<void> loadTriggers() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('triggers');
    if (data != null) {
      final list = jsonDecode(data) as List;
      _triggers.clear();
      _triggers.addAll(list.map((e) => TriggerConfig.fromJson(e as Map<String, dynamic>)));
      notifyListeners();
    }
  }

  /// حفظ الـ triggers
  Future<void> _saveTriggers() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('triggers', jsonEncode(_triggers.map((e) => e.toJson()).toList()));
  }

  /// إضافة trigger جديد
  void addTrigger(TriggerConfig trigger) {
    _triggers.add(trigger);
    _saveTriggers();
    notifyListeners();
  }

  /// حذف trigger
  void removeTrigger(String id) {
    _triggers.removeWhere((t) => t.id == id);
    _saveTriggers();
    notifyListeners();
  }

  /// تفعيل/تعطيل trigger
  void toggleTrigger(String id) {
    final trigger = _triggers.firstWhere((t) => t.id == id);
    trigger.enabled = !trigger.enabled;
    _saveTriggers();
    notifyListeners();
  }

  /// تحديث trigger
  void updateTrigger(TriggerConfig updated) {
    final index = _triggers.indexWhere((t) => t.id == updated.id);
    if (index != -1) {
      _triggers[index] = updated;
      _saveTriggers();
      notifyListeners();
    }
  }

  /// فحص الأحداث — هل لازم نشغل فيديو؟
  void checkLikeTrigger(int totalLikes) {
    for (final trigger in _triggers) {
      if (!trigger.enabled) continue;
      if (trigger.type != TriggerType.likes) continue;
      if (_firedTriggers.contains(trigger.id)) continue;

      if (totalLikes >= trigger.threshold) {
        _fireTrigger(trigger);
      }
    }
  }

  void checkViewerTrigger(int viewerCount) {
    for (final trigger in _triggers) {
      if (!trigger.enabled) continue;
      if (trigger.type != TriggerType.viewers) continue;
      if (_firedTriggers.contains(trigger.id)) continue;

      if (viewerCount >= trigger.threshold) {
        _fireTrigger(trigger);
      }
    }
  }

  void checkGiftTrigger(String giftName) {
    for (final trigger in _triggers) {
      if (!trigger.enabled) continue;
      if (trigger.type != TriggerType.gifts) continue;

      if (trigger.giftName == giftName || trigger.giftName == null || trigger.giftName!.isEmpty) {
        _fireTrigger(trigger);
      }
    }
  }

  /// تشغيل يدوي
  void fireManualTrigger(String id) {
    final trigger = _triggers.firstWhere((t) => t.id == id, orElse: () => throw Exception('Trigger not found'));
    _fireTrigger(trigger);
  }

  void _fireTrigger(TriggerConfig trigger) {
    if (trigger.videoPath == null || trigger.videoPath!.isEmpty) return;
    
    _firedTriggers.add(trigger.id);
    _videoController.add(trigger);
    debugPrint('🎬 Trigger fired: ${trigger.id} — ${trigger.videoPath}');
  }

  /// إعادة تعيين (بداية بث جديد)
  void resetFiredTriggers() {
    _firedTriggers.clear();
  }

  void dispose() {
    _videoController.close();
    super.dispose();
  }
}
