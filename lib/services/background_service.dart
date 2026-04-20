import 'package:flutter/material.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

/// خدمة الخلفية — تبقي التطبيق شغال
class BackgroundServiceHelper {
  static bool _isActive = false;

  /// تفعيل — يبقي الشاشة والاتصال شغالين
  static Future<void> startKeepAlive() async {
    if (_isActive) return;
    
    try {
      // منع الشاشة من النوم
      await WakelockPlus.enable();
      _isActive = true;
      debugPrint('✅ Keep-alive مفعّل — التطبيق يشتغل بالخلفية');
    } catch (e) {
      debugPrint('❌ خطأ في تفعيل keep-alive: $e');
    }
  }

  /// إيقاف
  static Future<void> stopKeepAlive() async {
    if (!_isActive) return;
    
    try {
      await WakelockPlus.disable();
      _isActive = false;
      debugPrint('📴 Keep-alive متوقف');
    } catch (e) {
      debugPrint('❌ خطأ في إيقاف keep-alive: $e');
    }
  }

  static bool get isActive => _isActive;
}
