/// إعدادات المحفزات — مثلاً عند X لايك يظهر فيديو
enum TriggerType {
  likeCount,    // عدد لايكات معين
  giftReceived, // هدية معينة
  followerJoin, // متابع يدخل
  viewerCount,  // عدد مشاهدين يوصل رقم معين
}

class TriggerConfig {
  final String id;
  final TriggerType type;
  final String label;          // اسم المحفز (يظهر بالواجهة)
  final int threshold;         // الحد — مثلاً 100 لايك
  final String? videoPath;     // مسار الفيديو المحلي
  final String? soundPath;     // مسار الصوت
  final bool showViewerName;   // يظهر اسم المشاهد فوق الفيديو
  final bool enabled;
  int currentCount;            // العدد الحالي

  TriggerConfig({
    required this.id,
    required this.type,
    required this.label,
    required this.threshold,
    this.videoPath,
    this.soundPath,
    this.showViewerName = true,
    this.enabled = true,
    this.currentCount = 0,
  });

  bool get isTriggered => currentCount >= threshold;

  double get progress => threshold > 0 ? (currentCount / threshold).clamp(0.0, 1.0) : 0.0;

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'label': label,
    'threshold': threshold,
    'videoPath': videoPath,
    'soundPath': soundPath,
    'showViewerName': showViewerName,
    'enabled': enabled,
  };

  factory TriggerConfig.fromJson(Map<String, dynamic> json) {
    return TriggerConfig(
      id: json['id'],
      type: TriggerType.values.firstWhere((e) => e.name == json['type']),
      label: json['label'] ?? '',
      threshold: json['threshold'] ?? 100,
      videoPath: json['videoPath'],
      soundPath: json['soundPath'],
      showViewerName: json['showViewerName'] ?? true,
      enabled: json['enabled'] ?? true,
    );
  }
}
