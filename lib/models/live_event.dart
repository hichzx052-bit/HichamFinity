enum LiveEventType {
  join,      // مشاهد دخل البث
  gift,      // هدية
  like,      // لايك
  comment,   // تعليق
  follow,    // متابعة جديدة
  share,     // مشاركة
  subscribe, // اشتراك
}

class LiveEvent {
  final String id;
  final LiveEventType type;
  final String username;
  final String? displayName;
  final String? profilePicUrl;
  final String? message;      // للتعليقات
  final String? giftName;     // اسم الهدية
  final int? giftCount;       // عدد الهدايا
  final int? giftValue;       // قيمة الهدية (coins)
  final int? likeCount;       // عدد اللايكات
  final DateTime timestamp;

  LiveEvent({
    required this.id,
    required this.type,
    required this.username,
    this.displayName,
    this.profilePicUrl,
    this.message,
    this.giftName,
    this.giftCount,
    this.giftValue,
    this.likeCount,
    required this.timestamp,
  });

  factory LiveEvent.fromJson(Map<String, dynamic> json) {
    return LiveEvent(
      id: json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      type: LiveEventType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => LiveEventType.comment,
      ),
      username: json['username'] ?? 'unknown',
      displayName: json['displayName'],
      profilePicUrl: json['profilePicUrl'],
      message: json['message'],
      giftName: json['giftName'],
      giftCount: json['giftCount'],
      giftValue: json['giftValue'],
      likeCount: json['likeCount'],
      timestamp: json['timestamp'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['timestamp'])
          : DateTime.now(),
    );
  }

  String get typeLabel {
    switch (type) {
      case LiveEventType.join:
        return '👁️ دخول';
      case LiveEventType.gift:
        return '🎁 هدية';
      case LiveEventType.like:
        return '❤️ لايك';
      case LiveEventType.comment:
        return '💬 تعليق';
      case LiveEventType.follow:
        return '➕ متابعة';
      case LiveEventType.share:
        return '🔗 مشاركة';
      case LiveEventType.subscribe:
        return '⭐ اشتراك';
    }
  }

  String get description {
    switch (type) {
      case LiveEventType.join:
        return '${displayName ?? username} دخل البث';
      case LiveEventType.gift:
        return '${displayName ?? username} أرسل ${giftName ?? "هدية"} x${giftCount ?? 1}';
      case LiveEventType.like:
        return '${displayName ?? username} أعجب ${likeCount ?? 1} مرة';
      case LiveEventType.comment:
        return '${displayName ?? username}: ${message ?? ""}';
      case LiveEventType.follow:
        return '${displayName ?? username} تابعك!';
      case LiveEventType.share:
        return '${displayName ?? username} شارك البث';
      case LiveEventType.subscribe:
        return '${displayName ?? username} اشترك!';
    }
  }
}
