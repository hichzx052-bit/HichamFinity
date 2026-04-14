import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/tiktok_live_service.dart';
import '../utils/theme.dart';

class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('📊 الإحصائيات')),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppTheme.backgroundColor, Color(0xFF0D0D1A)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Consumer<TikTokLiveService>(
          builder: (context, service, _) {
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // الإحصائيات الرئيسية
                _buildMainStats(service),
                const SizedBox(height: 20),
                // الأوائل
                _buildFirstsCard(service),
                const SizedBox(height: 20),
                // أكثر المهدين
                _buildTopList('👑 أكثر المهدين', service.topGifters, AppTheme.accentGold),
                const SizedBox(height: 16),
                // أكثر المعلقين
                _buildTopList('💬 أكثر المعلقين', service.topCommenters, AppTheme.secondaryColor),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildMainStats(TikTokLiveService service) {
    return Container(
      decoration: AppDecorations.glassCard(),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const Text(
            '📈 إحصائيات البث',
            style: TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildStatBox('👁', '${service.viewerCount}', 'مشاهد', AppTheme.secondaryColor),
              const SizedBox(width: 12),
              _buildStatBox('❤️', '${service.totalLikes}', 'لايك', AppTheme.primaryColor),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildStatBox('💬', '${service.totalComments}', 'تعليق', AppTheme.accentPurple),
              const SizedBox(width: 12),
              _buildStatBox('🎁', '${service.totalGifts}', 'هدية', AppTheme.accentGold),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildStatBox('💎', '${service.totalDiamonds}', 'ماسة', Colors.cyanAccent),
              const SizedBox(width: 12),
              _buildStatBox('➕', '${service.totalFollows}', 'متابع', AppTheme.successColor),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildStatBox('🔗', '${service.totalShares}', 'مشاركة', Colors.orangeAccent),
              const SizedBox(width: 12),
              _buildStatBox('⏱', service.streamDuration, 'مدة البث', AppTheme.textSecondary),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatBox(String emoji, String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: AppDecorations.accentCard(color),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.bold),
            ),
            Text(label, style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildFirstsCard(TikTokLiveService service) {
    if (service.firstFollower == null &&
        service.firstCommenter == null &&
        service.firstGifter == null) {
      return const SizedBox.shrink();
    }

    return Container(
      decoration: AppDecorations.glassCard(borderColor: AppTheme.accentGold.withValues(alpha: 0.3)),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🏅 الأوائل',
            style: TextStyle(color: AppTheme.accentGold, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          if (service.firstFollower != null)
            _buildFirstRow('أول متابع', service.firstFollower!, '➕'),
          if (service.firstCommenter != null)
            _buildFirstRow('أول معلق', service.firstCommenter!, '💬'),
          if (service.firstGifter != null)
            _buildFirstRow('أول مهدي', service.firstGifter!, '🎁'),
        ],
      ),
    );
  }

  Widget _buildFirstRow(String label, String name, String emoji) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 8),
          Text('$label: ', style: const TextStyle(color: AppTheme.textMuted)),
          Text(name, style: const TextStyle(color: AppTheme.accentGold, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildTopList(String title, Map<String, int> data, Color color) {
    if (data.isEmpty) return const SizedBox.shrink();

    final sorted = data.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final top = sorted.take(10).toList();

    return Container(
      decoration: AppDecorations.glassCard(borderColor: color.withValues(alpha: 0.2)),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ...top.asMap().entries.map((entry) {
            final rank = entry.key + 1;
            final item = entry.value;
            final medal = rank == 1 ? '🥇' : rank == 2 ? '🥈' : rank == 3 ? '🥉' : '$rank.';
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  SizedBox(width: 30, child: Text(medal, style: const TextStyle(fontSize: 16))),
                  Expanded(child: Text(item.key, style: const TextStyle(color: AppTheme.textPrimary))),
                  Text('${item.value}', style: TextStyle(color: color, fontWeight: FontWeight.bold)),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
