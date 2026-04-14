import 'package:flutter/material.dart';
import '../models/live_event.dart';
import '../utils/theme.dart';

class EventCard extends StatelessWidget {
  final LiveEvent event;

  const EventCard({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 3, horizontal: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: _getEventColor().withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _getEventColor().withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Text(event.icon, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              event.description,
              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            '${event.timestamp.hour.toString().padLeft(2, '0')}:${event.timestamp.minute.toString().padLeft(2, '0')}',
            style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Color _getEventColor() {
    switch (event.type) {
      case 'gift':
        return AppTheme.accentGold;
      case 'like':
        return AppTheme.primaryColor;
      case 'follow':
        return AppTheme.successColor;
      case 'comment':
        return AppTheme.secondaryColor;
      case 'share':
        return Colors.orangeAccent;
      default:
        return AppTheme.textMuted;
    }
  }
}
