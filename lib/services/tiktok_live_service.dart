import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:http/http.dart' as http;
import '../models/live_event.dart';
import '../models/viewer.dart';

/// خدمة الاتصال بـ TikTok LIVE
/// تتصل بسيرفر الوسيط (Node.js backend) اللي يتصل بتيك توك
class TikTokLiveService extends ChangeNotifier {
  WebSocketChannel? _channel;
  bool _isConnected = false;
  String? _currentUsername;
  String _serverUrl = 'ws://localhost:3000';

  // البيانات الحية
  final List<LiveEvent> _events = [];
  final Map<String, Viewer> _viewers = {};
  int _totalLikes = 0;
  int _totalGifts = 0;
  int _totalGiftValue = 0;
  int _viewerCount = 0;
  int _totalComments = 0;

  // Stream controllers
  final _eventController = StreamController<LiveEvent>.broadcast();
  final _connectionController = StreamController<bool>.broadcast();

  // Getters
  bool get isConnected => _isConnected;
  String? get currentUsername => _currentUsername;
  List<LiveEvent> get events => List.unmodifiable(_events);
  Map<String, Viewer> get viewers => Map.unmodifiable(_viewers);
  int get totalLikes => _totalLikes;
  int get totalGifts => _totalGifts;
  int get totalGiftValue => _totalGiftValue;
  int get viewerCount => _viewerCount;
  int get totalComments => _totalComments;
  Stream<LiveEvent> get eventStream => _eventController.stream;
  Stream<bool> get connectionStream => _connectionController.stream;

  void setServerUrl(String url) {
    _serverUrl = url;
  }

  /// الاتصال ببث تيك توك
  Future<bool> connect(String username) async {
    if (_isConnected) await disconnect();

    try {
      _currentUsername = username;
      final wsUrl = '$_serverUrl/live?username=$username';

      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));

      _channel!.stream.listen(
        (data) => _handleMessage(data),
        onError: (error) {
          debugPrint('WebSocket Error: $error');
          _setConnected(false);
        },
        onDone: () {
          debugPrint('WebSocket closed');
          _setConnected(false);
        },
      );

      _setConnected(true);
      _resetStats();
      return true;
    } catch (e) {
      debugPrint('Connection failed: $e');
      _setConnected(false);
      return false;
    }
  }

  /// قطع الاتصال
  Future<void> disconnect() async {
    await _channel?.sink.close();
    _channel = null;
    _setConnected(false);
  }

  void _setConnected(bool connected) {
    _isConnected = connected;
    _connectionController.add(connected);
    notifyListeners();
  }

  void _resetStats() {
    _events.clear();
    _viewers.clear();
    _totalLikes = 0;
    _totalGifts = 0;
    _totalGiftValue = 0;
    _viewerCount = 0;
    _totalComments = 0;
    notifyListeners();
  }

  void _handleMessage(dynamic data) {
    try {
      final json = jsonDecode(data as String);
      final eventType = json['type'] as String?;

      if (eventType == 'roomInfo') {
        _viewerCount = json['viewerCount'] ?? 0;
        notifyListeners();
        return;
      }

      if (eventType == 'connected') {
        debugPrint('Connected to TikTok LIVE: ${json['roomId']}');
        return;
      }

      final event = LiveEvent.fromJson(json);
      _events.insert(0, event);

      // تحديث المشاهدين
      _updateViewer(event);

      // تحديث الإحصائيات
      switch (event.type) {
        case LiveEventType.like:
          _totalLikes += event.likeCount ?? 1;
          break;
        case LiveEventType.gift:
          _totalGifts += event.giftCount ?? 1;
          _totalGiftValue += event.giftValue ?? 0;
          break;
        case LiveEventType.comment:
          _totalComments++;
          break;
        case LiveEventType.join:
          _viewerCount++;
          break;
        default:
          break;
      }

      // حد الأحداث
      if (_events.length > 500) {
        _events.removeRange(500, _events.length);
      }

      _eventController.add(event);
      notifyListeners();
    } catch (e) {
      debugPrint('Error parsing event: $e');
    }
  }

  void _updateViewer(LiveEvent event) {
    final viewer = _viewers[event.username];
    if (viewer != null) {
      viewer.lastActiveAt = DateTime.now();
      switch (event.type) {
        case LiveEventType.like:
          viewer.totalLikes += event.likeCount ?? 1;
          break;
        case LiveEventType.gift:
          viewer.totalGifts += event.giftCount ?? 1;
          viewer.totalGiftValue += event.giftValue ?? 0;
          break;
        case LiveEventType.comment:
          viewer.totalComments++;
          break;
        default:
          break;
      }
    } else {
      _viewers[event.username] = Viewer(
        username: event.username,
        displayName: event.displayName,
        profilePicUrl: event.profilePicUrl,
        joinedAt: DateTime.now(),
        lastActiveAt: DateTime.now(),
      );
    }
  }

  /// فحص الاتصال بالسيرفر
  Future<bool> testServer(String url) async {
    try {
      final httpUrl = url.replaceFirst('ws://', 'http://').replaceFirst('wss://', 'https://');
      final response = await http.get(Uri.parse('$httpUrl/health')).timeout(
        const Duration(seconds: 5),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  @override
  void dispose() {
    disconnect();
    _eventController.close();
    _connectionController.close();
    super.dispose();
  }
}
