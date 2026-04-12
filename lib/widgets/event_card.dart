import 'package:flutter/material.dart';
import '../utils/theme.dart';
import '../models/live_event.dart';

class EventCard extends StatelessWidget {
  final LiveEvent event;

  const EventCard({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: _getBackgroundColor(),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Text(_getEmoji(), style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              event.description,
              style: const TextStyle(fontSize: 14),
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

  Color _getBackgroundColor() {
    switch (event.type) {
      case LiveEventType.gift:
        return AppTheme.gift.withOpacity(0.08);
      case LiveEventType.like:
        return AppTheme.like.withOpacity(0.06);
      case LiveEventType.follow:
        return AppTheme.success.withOpacity(0.08);
      default:
        return AppTheme.surface;
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
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')}';
  }
}
