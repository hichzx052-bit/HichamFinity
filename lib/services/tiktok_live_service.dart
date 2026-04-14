import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/live_event.dart';
import '../models/viewer.dart';
import '../utils/constants.dart';

enum ConnectionState { disconnected, connecting, connected, error }

class TikTokLiveService extends ChangeNotifier {
  WebSocketChannel? _channel;
  ConnectionState _state = ConnectionState.disconnected;
  String? _errorMessage;
  String _serverUrl = AppConstants.defaultServerUrl;
  String? _username;

  // الإحصائيات
  int _viewerCount = 0;
  int _totalLikes = 0;
  int _totalComments = 0;
  int _totalGifts = 0;
  int _totalDiamonds = 0;
  int _totalFollows = 0;
  int _totalShares = 0;

  // "الأوائل"
  String? _firstFollower;
  String? _firstCommenter;
  String? _firstGifter;

  // أكثر واحد
  final Map<String, int> _topGifters = {};
  final Map<String, int> _topCommenters = {};

  // الأحداث والمشاهدين
  final List<LiveEvent> _events = [];
  final Map<String, Viewer> _viewers = {};

  // Stream controllers
  final _eventController = StreamController<LiveEvent>.broadcast();
  final _firstEventController = StreamController<Map<String, String>>.broadcast();

  // وقت بداية البث
  DateTime? _streamStartTime;

  // Getters
  ConnectionState get state => _state;
  String? get errorMessage => _errorMessage;
  String get serverUrl => _serverUrl;
  String? get username => _username;
  int get viewerCount => _viewerCount;
  int get totalLikes => _totalLikes;
  int get totalComments => _totalComments;
  int get totalGifts => _totalGifts;
  int get totalDiamonds => _totalDiamonds;
  int get totalFollows => _totalFollows;
  int get totalShares => _totalShares;
  String? get firstFollower => _firstFollower;
  String? get firstCommenter => _firstCommenter;
  String? get firstGifter => _firstGifter;
  List<LiveEvent> get events => List.unmodifiable(_events);
  Map<String, Viewer> get viewers => Map.unmodifiable(_viewers);
  Stream<LiveEvent> get eventStream => _eventController.stream;
  Stream<Map<String, String>> get firstEventStream => _firstEventController.stream;
  DateTime? get streamStartTime => _streamStartTime;
  Map<String, int> get topGifters => Map.unmodifiable(_topGifters);
  Map<String, int> get topCommenters => Map.unmodifiable(_topCommenters);

  String get streamDuration {
    if (_streamStartTime == null) return '00:00:00';
    final diff = DateTime.now().difference(_streamStartTime!);
    return '${diff.inHours.toString().padLeft(2, '0')}:'
        '${(diff.inMinutes % 60).toString().padLeft(2, '0')}:'
        '${(diff.inSeconds % 60).toString().padLeft(2, '0')}';
  }

  void setServerUrl(String url) {
    _serverUrl = url;
    notifyListeners();
  }

  Future<void> connect(String username) async {
    if (_state == ConnectionState.connecting) return;

    _username = username;
    _state = ConnectionState.connecting;
    _errorMessage = null;
    notifyListeners();

    try {
      final wsUrl = '$_serverUrl${AppConstants.wsLivePath}?username=$username';
      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));

      _channel!.stream.listen(
        _onMessage,
        onError: _onError,
        onDone: _onDone,
      );
    } catch (e) {
      _state = ConnectionState.error;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  void disconnect() {
    _channel?.sink.close();
    _channel = null;
    _state = ConnectionState.disconnected;
    notifyListeners();
  }

  void _resetStats() {
    _viewerCount = 0;
    _totalLikes = 0;
    _totalComments = 0;
    _totalGifts = 0;
    _totalDiamonds = 0;
    _totalFollows = 0;
    _totalShares = 0;
    _firstFollower = null;
    _firstCommenter = null;
    _firstGifter = null;
    _topGifters.clear();
    _topCommenters.clear();
    _events.clear();
    _viewers.clear();
    _streamStartTime = null;
  }

  void _onMessage(dynamic message) {
    try {
      final data = jsonDecode(message as String) as Map<String, dynamic>;
      final type = data['type'] as String?;

      switch (type) {
        case 'connected':
          _state = ConnectionState.connected;
          _resetStats();
          _streamStartTime = DateTime.now();
          notifyListeners();
          break;

        case 'join':
          _handleJoin(data);
          break;

        case 'comment':
          _handleComment(data);
          break;

        case 'gift':
          _handleGift(data);
          break;

        case 'like':
          _handleLike(data);
          break;

        case 'follow':
          _handleFollow(data);
          break;

        case 'share':
          _handleShare(data);
          break;

        case 'subscribe':
          _handleSubscribe(data);
          break;

        case 'roomInfo':
          _viewerCount = data['viewerCount'] as int? ?? 0;
          notifyListeners();
          break;

        case 'streamEnd':
          _state = ConnectionState.disconnected;
          notifyListeners();
          break;

        case 'error':
          _state = ConnectionState.error;
          _errorMessage = data['message'] as String? ?? 'خطأ غير معروف';
          notifyListeners();
          break;
      }
    } catch (e) {
      debugPrint('Error parsing message: $e');
    }
  }

  void _handleJoin(Map<String, dynamic> data) {
    final event = LiveEvent.fromJson(data);
    _addEvent(event);
    _addViewer(data);
    notifyListeners();
  }

  void _handleComment(Map<String, dynamic> data) {
    final event = LiveEvent.fromJson(data);
    _addEvent(event);
    _totalComments++;
    _addViewer(data);

    // أول معلق
    final name = data['displayName'] as String? ?? data['username'] as String? ?? '';
    if (_firstCommenter == null && name.isNotEmpty) {
      _firstCommenter = name;
      _firstEventController.add({'type': 'comment', 'name': name});
    }

    // أكثر واحد علّق
    _topCommenters[name] = (_topCommenters[name] ?? 0) + 1;

    notifyListeners();
  }

  void _handleGift(Map<String, dynamic> data) {
    final event = LiveEvent.fromJson(data);
    _addEvent(event);
    _totalGifts++;
    _totalDiamonds += (data['giftValue'] as int? ?? 0);
    _addViewer(data);

    // أول مهدي
    final name = data['displayName'] as String? ?? data['username'] as String? ?? '';
    if (_firstGifter == null && name.isNotEmpty) {
      _firstGifter = name;
      _firstEventController.add({'type': 'gift', 'name': name});
    }

    // أكثر واحد هدى
    final value = data['giftValue'] as int? ?? 0;
    _topGifters[name] = (_topGifters[name] ?? 0) + value;

    notifyListeners();
  }

  void _handleLike(Map<String, dynamic> data) {
    final event = LiveEvent.fromJson(data);
    _addEvent(event);
    _totalLikes += (data['likeCount'] as int? ?? 1);
    _addViewer(data);
    notifyListeners();
  }

  void _handleFollow(Map<String, dynamic> data) {
    final event = LiveEvent.fromJson(data);
    _addEvent(event);
    _totalFollows++;
    _addViewer(data);

    // أول متابع
    final name = data['displayName'] as String? ?? data['username'] as String? ?? '';
    if (_firstFollower == null && name.isNotEmpty) {
      _firstFollower = name;
      _firstEventController.add({'type': 'follow', 'name': name});
    }

    notifyListeners();
  }

  void _handleShare(Map<String, dynamic> data) {
    final event = LiveEvent.fromJson(data);
    _addEvent(event);
    _totalShares++;
    _addViewer(data);
    notifyListeners();
  }

  void _handleSubscribe(Map<String, dynamic> data) {
    final event = LiveEvent.fromJson(data);
    _addEvent(event);
    _addViewer(data);
    notifyListeners();
  }

  void _addEvent(LiveEvent event) {
    _events.insert(0, event);
    if (_events.length > AppConstants.maxEventsInList) {
      _events.removeLast();
    }
    _eventController.add(event);
  }

  void _addViewer(Map<String, dynamic> data) {
    final id = data['username'] as String? ?? '';
    if (id.isEmpty) return;

    _viewers[id] = Viewer(
      username: id,
      displayName: data['displayName'] as String? ?? id,
      profilePicUrl: data['profilePicUrl'] as String?,
      lastSeen: DateTime.now(),
    );
  }

  void _onError(dynamic error) {
    _state = ConnectionState.error;
    _errorMessage = error.toString();
    notifyListeners();
  }

  void _onDone() {
    if (_state != ConnectionState.disconnected) {
      _state = ConnectionState.disconnected;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    disconnect();
    _eventController.close();
    _firstEventController.close();
    super.dispose();
  }
}
