import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/theme.dart';
import '../services/tiktok_live_service.dart';
import '../models/live_event.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  LiveEventType? _filter;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(() {
      setState(() {
        switch (_tabController.index) {
          case 0: _filter = null; break;
          case 1: _filter = LiveEventType.join; break;
          case 2: _filter = LiveEventType.gift; break;
          case 3: _filter = LiveEventType.comment; break;
          case 4: _filter = LiveEventType.like; break;
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final liveService = context.watch<TikTokLiveService>();
    final events = _filter == null
        ? liveService.events
        : liveService.events.where((e) => e.type == _filter).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('🔔 التنبيهات'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: AppTheme.primary,
          tabs: const [
            Tab(text: '📋 الكل'),
            Tab(text: '👁️ دخول'),
            Tab(text: '🎁 هدايا'),
            Tab(text: '💬 تعليقات'),
            Tab(text: '❤️ لايكات'),
          ],
        ),
      ),
      body: events.isEmpty
          ? Center(
              child: Text(
                'ما فيه تنبيهات بعد',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
            )
          : ListView.builder(
              itemCount: events.length,
              padding: const EdgeInsets.all(12),
              itemBuilder: (context, index) {
                final event = events[index];
                return _AlertTile(event: event);
              },
            ),
    );
  }
}

class _AlertTile extends StatelessWidget {
  final LiveEvent event;
  const _AlertTile({required this.event});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border(
          right: BorderSide(color: _getColor(), width: 3),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _getColor().withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(_getEmoji(), style: const TextStyle(fontSize: 20)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.displayName ?? event.username,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  event.description,
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                ),
              ],
            ),
          ),
          Text(
            _formatTime(event.timestamp),
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Color _getColor() {
    switch (event.type) {
      case LiveEventType.join: return AppTheme.viewer;
      case LiveEventType.gift: return AppTheme.gift;
      case LiveEventType.like: return AppTheme.like;
      case LiveEventType.comment: return AppTheme.comment;
      case LiveEventType.follow: return AppTheme.success;
      case LiveEventType.share: return AppTheme.primary;
      case LiveEventType.subscribe: return AppTheme.accent;
    }
  }

  String _getEmoji() {
    switch (event.type) {
      case LiveEventType.join: return '👁️';
      case LiveEventType.gift: return '🎁';
      case LiveEventType.like: return '❤️';
      case LiveEventType.comment: return '💬';
      case LiveEventType.follow: return '➕';
      case LiveEventType.share: return '🔗';
      case LiveEventType.subscribe: return '⭐';
    }
  }

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
