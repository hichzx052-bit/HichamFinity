class LiveEvent {
  final String id;
  final String type;
  final String username;
  final String displayName;
  final String? profilePicUrl;
  final String? message;
  final String? giftName;
  final int? giftCount;
  final int? giftValue;
  final int? likeCount;
  final DateTime timestamp;

  LiveEvent({
    required this.id,
    required this.type,
    required this.username,
    required this.displayName,
    this.profilePicUrl,
    this.message,
    this.giftName,
    this.giftCount,
    this.giftValue,
    this.likeCount,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  factory LiveEvent.fromJson(Map<String, dynamic> json) {
    return LiveEvent(
      id: json['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
      type: json['type'] as String? ?? 'unknown',
      username: json['username'] as String? ?? '',
      displayName: json['displayName'] as String? ?? json['username'] as String? ?? '',
      profilePicUrl: json['profilePicUrl'] as String?,
      message: json['message'] as String?,
      giftName: json['giftName'] as String?,
      giftCount: json['giftCount'] as int?,
      giftValue: json['giftValue'] as int?,
      likeCount: json['likeCount'] as int?,
      timestamp: json['timestamp'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['timestamp'] as int)
          : DateTime.now(),
    );
  }

  String get icon {
    switch (type) {
      case 'join':
        return '👋';
      case 'comment':
        return '💬';
      case 'gift':
        return '🎁';
      case 'like':
        return '❤️';
      case 'follow':
        return '➕';
      case 'share':
        return '🔗';
      case 'subscribe':
        return '⭐';
      default:
        return '📌';
    }
  }

  String get description {
    switch (type) {
      case 'join':
        return '$displayName دخل البث';
      case 'comment':
        return '$displayName: $message';
      case 'gift':
        return '$displayName أرسل $giftName ${giftCount != null && giftCount! > 1 ? "x$giftCount" : ""}';
      case 'like':
        return '$displayName أعطى ${likeCount ?? 1} لايك';
      case 'follow':
        return '$displayName تابعك';
      case 'share':
        return '$displayName شارك البث';
      case 'subscribe':
        return '$displayName اشترك';
      default:
        return displayName;
    }
  }
}
