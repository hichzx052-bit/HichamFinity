import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/theme.dart';
import '../services/tiktok_live_service.dart';
import '../models/live_event.dart';
import '../widgets/event_card.dart';
import '../widgets/stats_dashboard.dart';

class LiveMonitorScreen extends StatelessWidget {
  const LiveMonitorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final liveService = context.watch<TikTokLiveService>();

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: liveService.isConnected ? AppTheme.error : AppTheme.textSecondary,
                boxShadow: liveService.isConnected
                    ? [BoxShadow(color: AppTheme.error.withOpacity(0.5), blurRadius: 8)]
                    : null,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              liveService.isConnected
                  ? 'LIVE — @${liveService.currentUsername}'
                  : 'غير متصل',
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
        actions: [
          if (liveService.isConnected)
            IconButton(
              icon: const Icon(Icons.stop_circle_outlined, color: AppTheme.error),
              onPressed: () {
                liveService.disconnect();
                Navigator.pop(context);
              },
            ),
        ],
      ),
      body: Column(
        children: [
          // إحصائيات سريعة
          const StatsDashboard(),

          // فاصل
          const Divider(height: 1, color: AppTheme.surfaceLight),

          // قائمة الأحداث
          Expanded(
            child: liveService.events.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.live_tv_rounded,
                          size: 60,
                          color: AppTheme.textSecondary.withOpacity(0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          liveService.isConnected
                              ? 'بانتظار الأحداث...'
                              : 'غير متصل بالبث',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: liveService.events.length,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    itemBuilder: (context, index) {
                      return EventCard(event: liveService.events[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
