class AppConstants {
  static const String appName = 'HichamFinity';
  static const String appVersion = '2.0.0';
  static const String developer = 'Hicham';
  
  // السيرفر
  static const String defaultServerUrl = 'ws://localhost:3000';
  static const String wsLivePath = '/live';
  
  // TTS
  static const int maxTtsQueue = 10;
  static const double defaultTtsRate = 0.5;
  static const double defaultTtsPitch = 1.0;
  static const double defaultTtsVolume = 1.0;
  
  // أحداث
  static const String eventJoin = 'join';
  static const String eventComment = 'comment';
  static const String eventGift = 'gift';
  static const String eventLike = 'like';
  static const String eventFollow = 'follow';
  static const String eventShare = 'share';
  static const String eventSubscribe = 'subscribe';
  
  // تخزين
  static const String prefServerUrl = 'server_url';
  static const String prefTtsEnabled = 'tts_enabled';
  static const String prefTtsRate = 'tts_rate';
  static const String prefTtsPitch = 'tts_pitch';
  static const String prefTtsVolume = 'tts_volume';
  static const String prefTtsLanguage = 'tts_language';
  static const String prefUsername = 'tiktok_username';
  static const String prefAutoReply = 'auto_reply_enabled';
  static const String prefAutoReplyMessage = 'auto_reply_message';
  
  // حدود
  static const int maxEventsInList = 200;
  static const int maxViewersInList = 100;
}
