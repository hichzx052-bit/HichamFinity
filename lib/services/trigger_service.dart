import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/live_event.dart';
import '../models/trigger_config.dart';

/// خدمة المحفزات — تراقب الأحداث وتطلق الفيديوهات/الأصوات
class TriggerService extends ChangeNotifier {
  final List<TriggerConfig> _triggers = [];
  final _triggerFiredController = StreamController<TriggerFiredEvent>.broadcast();

  List<TriggerConfig> get triggers => List.unmodifiable(_triggers);
  Stream<TriggerFiredEvent> get onTriggerFired => _triggerFiredController.stream;

  // تتبع اللايكات لكل مشاهد
  final Map<String, int> _viewerLikes = {};

  TriggerService() {
    _loadTriggers();
  }

  /// إضافة محفز جديد
  void addTrigger({
    required TriggerType type,
    required String label,
    required int threshold,
    String? videoPath,
    String? soundPath,
    bool showViewerName = true,
  }) {
    _triggers.add(TriggerConfig(
      id: const Uuid().v4(),
      type: type,
      label: label,
      threshold: threshold,
      videoPath: videoPath,
      soundPath: soundPath,
      showViewerName: showViewerName,
    ));
    _saveTriggers();
    notifyListeners();
  }

  /// حذف محفز
  void removeTrigger(String id) {
    _triggers.removeWhere((t) => t.id == id);
    _saveTriggers();
    notifyListeners();
  }

  /// تحديث محفز
  void updateTrigger(String id, {
    String? label,
    int? threshold,
    String? videoPath,
    String? soundPath,
    bool? showViewerName,
    bool? enabled,
  }) {
    final index = _triggers.indexWhere((t) => t.id == id);
    if (index == -1) return;

    final old = _triggers[index];
    _triggers[index] = TriggerConfig(
      id: old.id,
      type: old.type,
      label: label ?? old.label,
      threshold: threshold ?? old.threshold,
      videoPath: videoPath ?? old.videoPath,
      soundPath: soundPath ?? old.soundPath,
      showViewerName: showViewerName ?? old.showViewerName,
      enabled: enabled ?? old.enabled,
      currentCount: old.currentCount,
    );
    _saveTriggers();
    notifyListeners();
  }

  /// معالجة حدث — يتحقق من كل المحفزات
  void processEvent(LiveEvent event) {
    for (final trigger in _triggers) {
      if (!trigger.enabled) continue;

      switch (trigger.type) {
        case TriggerType.likeCount:
          if (event.type == LiveEventType.like) {
            // تتبع لايكات المشاهد الواحد
            final username = event.username;
            _viewerLikes[username] = (_viewerLikes[username] ?? 0) + (event.likeCount ?? 1);

            if (_viewerLikes[username]! >= trigger.threshold) {
              _fireTrigger(trigger, event);
              _viewerLikes[username] = 0; // ريسيت
            }
            trigger.currentCount = _viewerLikes[username]!;
          }
          break;

        case TriggerType.giftReceived:
          if (event.type == LiveEventType.gift) {
            trigger.currentCount += event.giftValue ?? 0;
            if (trigger.currentCount >= trigger.threshold) {
              _fireTrigger(trigger, event);
              trigger.currentCount = 0;
            }
          }
          break;

        case TriggerType.followerJoin:
          if (event.type == LiveEventType.follow) {
            trigger.currentCount++;
            if (trigger.currentCount >= trigger.threshold) {
              _fireTrigger(trigger, event);
              trigger.currentCount = 0;
            }
          }
          break;

        case TriggerType.viewerCount:
          if (event.type == LiveEventType.join) {
            trigger.currentCount++;
            if (trigger.currentCount >= trigger.threshold) {
              _fireTrigger(trigger, event);
            }
          }
          break;
      }
    }
    notifyListeners();
  }

  void _fireTrigger(TriggerConfig trigger, LiveEvent event) {
    _triggerFiredController.add(TriggerFiredEvent(
      trigger: trigger,
      event: event,
      viewerName: event.displayName ?? event.username,
    ));
  }

  /// إعادة ضبط كل العدادات
  void resetAll() {
    for (final t in _triggers) {
      t.currentCount = 0;
    }
    _viewerLikes.clear();
    notifyListeners();
  }

  Future<void> _saveTriggers() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = _triggers.map((t) => t.toJson()).toList();
    await prefs.setString('triggers', jsonEncode(jsonList));
  }

  Future<void> _loadTriggers() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString('triggers');
    if (jsonStr != null) {
      final list = jsonDecode(jsonStr) as List;
      _triggers.clear();
      _triggers.addAll(list.map((j) => TriggerConfig.fromJson(j)));
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _triggerFiredController.close();
    super.dispose();
  }
}

/// حدث إطلاق محفز
class TriggerFiredEvent {
  final TriggerConfig trigger;
  final LiveEvent event;
  final String viewerName;

  TriggerFiredEvent({
    required this.trigger,
    required this.event,
    required this.viewerName,
  });
}
