import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/tiktok_live_service.dart';
import '../utils/theme.dart';
import 'dart:async';

class LiveMonitorScreen extends StatefulWidget {
  const LiveMonitorScreen({super.key});

  @override
  State<LiveMonitorScreen> createState() => _LiveMonitorScreenState();
}

class _LiveMonitorScreenState extends State<LiveMonitorScreen> {
  Timer? _durationTimer;

  @override
  void initState() {
    super.initState();
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _durationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('📡 مراقبة البث'),
        actions: [
          Consumer<TikTokLiveService>(
            builder: (_, service, __) {
              return _buildStatusBadge(service.state);
            },
          ),
        ],
      ),
      body: Consumer<TikTokLiveService>(
        builder: (context, service, _) {
          return Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.backgroundColor, Color(0xFF0D0D1A)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Column(
              children: [
                // الإحصائيات السريعة
                _buildQuickStats(service),
                const Divider(color: AppTheme.textMuted, height: 1),
                // "الأوائل"
                if (service.state == ConnectionState.connected)
                  _buildFirstEvents(service),
                // قائمة الأحداث
                Expanded(
                  child: service.events.isEmpty
                      ? _buildEmptyState(service)
                      : _buildEventList(service),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusBadge(ConnectionState state) {
    Color color;
    String text;
    IconData icon;

    switch (state) {
      case ConnectionState.connected:
        color = AppTheme.successColor;
        text = 'متصل';
        icon = Icons.circle;
        break;
      case ConnectionState.connecting:
        color = AppTheme.warningColor;
        text = 'جاري...';
        icon = Icons.sync;
        break;
      case ConnectionState.error:
        color = AppTheme.errorColor;
        text = 'خطأ';
        icon = Icons.error;
        break;
      default:
        color = AppTheme.textMuted;
        text = 'غير متصل';
        icon = Icons.circle_outlined;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 10),
          const SizedBox(width: 4),
          Text(text, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildQuickStats(TikTokLiveService service) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      child: Column(
        children: [
          // مدة البث
          if (service.streamStartTime != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.timer, color: AppTheme.secondaryColor, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    service.streamDuration,
                    style: const TextStyle(
                      color: AppTheme.secondaryColor,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
          Row(
            children: [
              _buildStatItem('👁', '${service.viewerCount}', 'مشاهد'),
              _buildStatItem('❤️', '${service.totalLikes}', 'لايك'),
              _buildStatItem('💬', '${service.totalComments}', 'تعليق'),
              _buildStatItem('🎁', '${service.totalGifts}', 'هدية'),
              _buildStatItem('💎', '${service.totalDiamonds}', 'ماسة'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String emoji, String value, String label) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 3),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: AppDecorations.glassCard(),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: const TextStyle(color: AppTheme.textMuted, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFirstEvents(TikTokLiveService service) {
    if (service.firstFollower == null &&
        service.firstCommenter == null &&
        service.firstGifter == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          if (service.firstFollower != null)
            _buildFirstBadge('🏅 أول متابع', service.firstFollower!, AppTheme.accentGold),
          if (service.firstCommenter != null)
            _buildFirstBadge('🏅 أول معلق', service.firstCommenter!, AppTheme.secondaryColor),
          if (service.firstGifter != null)
            _buildFirstBadge('🏅 أول مهدي', service.firstGifter!, AppTheme.accentPurple),
        ],
      ),
    );
  }

  Widget _buildFirstBadge(String title, String name, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 3),
        padding: const EdgeInsets.all(8),
        decoration: AppDecorations.accentCard(color),
        child: Column(
          children: [
            Text(title, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text(
              name,
              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 11),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(TikTokLiveService service) {
    if (service.state == ConnectionState.error) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: AppTheme.errorColor, size: 60),
            const SizedBox(height: 16),
            const Text('خطأ في الاتصال', style: TextStyle(color: AppTheme.errorColor, fontSize: 18)),
            const SizedBox(height: 8),
            Text(
              service.errorMessage ?? '',
              style: const TextStyle(color: AppTheme.textMuted, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.live_tv, color: AppTheme.textMuted, size: 60),
          SizedBox(height: 16),
          Text('في انتظار الأحداث...', style: TextStyle(color: AppTheme.textMuted, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildEventList(TikTokLiveService service) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      itemCount: service.events.length,
      itemBuilder: (context, index) {
        final event = service.events[index];
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 3),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              // الصورة
              CircleAvatar(
                radius: 18,
                backgroundColor: AppTheme.cardColor,
                backgroundImage: event.profilePicUrl != null
                    ? NetworkImage(event.profilePicUrl!)
                    : null,
                child: event.profilePicUrl == null
                    ? Text(event.icon, style: const TextStyle(fontSize: 16))
                    : null,
              ),
              const SizedBox(width: 10),
              // المحتوى
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.description,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 13,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // الوقت
              Text(
                '${event.timestamp.hour.toString().padLeft(2, '0')}:${event.timestamp.minute.toString().padLeft(2, '0')}',
                style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
              ),
            ],
          ),
        );
      },
    );
  }
}
