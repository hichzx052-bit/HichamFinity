import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/tiktok_live_service.dart';
import '../services/trigger_service.dart';
import '../widgets/video_overlay.dart';
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
    final triggers = context.read<TriggerService>();
    return VideoOverlay(
      triggerService: triggers,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('📡 مراقبة البث'),
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1A1A35), Colors.transparent],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          actions: [
            Consumer<TikTokLiveService>(
              builder: (_, service, __) => _buildStatusBadge(service.state),
            ),
          ],
        ),
        body: Consumer<TikTokLiveService>(
          builder: (context, service, _) {
            return Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0A0A1A), Color(0xFF0D0520)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Column(
                children: [
                  _buildQuickStats(service),
                  if (service.state == LiveConnectionState.connected)
                    _buildFirstEvents(service),
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
      ),
    );
  }

  Widget _buildStatusBadge(LiveConnectionState state) {
    Color color;
    String text;
    IconData icon;

    switch (state) {
      case LiveConnectionState.connected:
        color = AppTheme.successColor;
        text = 'متصل';
        icon = Icons.circle;
        break;
      case LiveConnectionState.connecting:
        color = AppTheme.warningColor;
        text = 'جاري...';
        icon = Icons.sync;
        break;
      case LiveConnectionState.error:
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.2), blurRadius: 8),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 10),
          const SizedBox(width: 5),
          Text(text, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildQuickStats(TikTokLiveService service) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
      child: Column(
        children: [
          if (service.streamStartTime != null)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.secondaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: AppTheme.secondaryColor.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.timer_rounded, color: AppTheme.secondaryColor, size: 18),
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
              _buildStatItem('👁', '${service.viewerCount}', 'مشاهد', AppTheme.secondaryColor),
              _buildStatItem('❤️', '${service.totalLikes}', 'لايك', AppTheme.primaryColor),
              _buildStatItem('💬', '${service.totalComments}', 'تعليق', AppTheme.accentPurple),
              _buildStatItem('🎁', '${service.totalGifts}', 'هدية', AppTheme.accentGold),
              _buildStatItem('💎', '${service.totalDiamonds}', 'ماسة', Colors.cyanAccent),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String emoji, String value, String label, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 3),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withValues(alpha: 0.12), color.withValues(alpha: 0.04)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(label, style: const TextStyle(color: AppTheme.textMuted, fontSize: 9)),
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withValues(alpha: 0.2), color.withValues(alpha: 0.05)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Text(title, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
            const SizedBox(height: 3),
            Text(name, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 11), overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(TikTokLiveService service) {
    if (service.state == LiveConnectionState.error) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.errorColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.error_outline, color: AppTheme.errorColor, size: 50),
            ),
            const SizedBox(height: 16),
            const Text('خطأ في الاتصال', style: TextStyle(color: AppTheme.errorColor, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                service.errorMessage ?? '',
                style: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      );
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(25),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.live_tv_rounded, color: AppTheme.textMuted, size: 50),
          ),
          const SizedBox(height: 16),
          const Text('في انتظار الأحداث...', style: TextStyle(color: AppTheme.textMuted, fontSize: 16)),
          const SizedBox(height: 6),
          const Text('اتصل ببث لايف لبدء المراقبة', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildEventList(TikTokLiveService service) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      itemCount: service.events.length,
      itemBuilder: (context, index) {
        final event = service.events[index];
        final eventColor = _getEventColor(event.type);
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 3),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [eventColor.withValues(alpha: 0.08), Colors.transparent],
              begin: Alignment.centerRight,
              end: Alignment.centerLeft,
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: eventColor.withValues(alpha: 0.1)),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: eventColor.withValues(alpha: 0.15),
                backgroundImage: event.profilePicUrl != null ? NetworkImage(event.profilePicUrl!) : null,
                child: event.profilePicUrl == null
                    ? Text(event.icon, style: const TextStyle(fontSize: 16))
                    : null,
              ),
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
                style: const TextStyle(color: AppTheme.textMuted, fontSize: 10),
              ),
            ],
          ),
        );
      },
    );
  }

  Color _getEventColor(String type) {
    switch (type) {
      case 'gift': return AppTheme.accentGold;
      case 'like': return AppTheme.primaryColor;
      case 'follow': return AppTheme.successColor;
      case 'comment': return AppTheme.secondaryColor;
      case 'share': return Colors.orangeAccent;
      default: return AppTheme.textMuted;
    }
  }
}
