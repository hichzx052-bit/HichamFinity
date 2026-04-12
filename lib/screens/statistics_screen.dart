import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/theme.dart';
import '../services/tiktok_live_service.dart';

class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final live = context.watch<TikTokLiveService>();

    // أكثر المشاهدين تفاعل
    final topViewers = live.viewers.values.toList()
      ..sort((a, b) => (b.totalLikes + b.totalGiftValue + b.totalComments)
          .compareTo(a.totalLikes + a.totalGiftValue + a.totalComments));

    return Scaffold(
      appBar: AppBar(title: const Text('📊 الإحصائيات')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // بطاقات الأرقام
          Row(
            children: [
              _StatCard(
                icon: Icons.visibility_rounded,
                label: 'المشاهدين',
                value: '${live.viewerCount}',
                color: AppTheme.viewer,
              ),
              const SizedBox(width: 12),
              _StatCard(
                icon: Icons.favorite_rounded,
                label: 'اللايكات',
                value: _formatNumber(live.totalLikes),
                color: AppTheme.like,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _StatCard(
                icon: Icons.card_giftcard_rounded,
                label: 'الهدايا',
                value: '${live.totalGifts}',
                color: AppTheme.gift,
              ),
              const SizedBox(width: 12),
              _StatCard(
                icon: Icons.chat_rounded,
                label: 'التعليقات',
                value: '${live.totalComments}',
                color: AppTheme.comment,
              ),
            ],
          ),
          const SizedBox(height: 12),
          // قيمة الهدايا
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                AppTheme.gift.withOpacity(0.2),
                AppTheme.accent.withOpacity(0.1),
              ]),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.monetization_on_rounded, color: AppTheme.gift, size: 40),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('قيمة الهدايا', style: TextStyle(color: AppTheme.textSecondary)),
                    Text(
                      '${_formatNumber(live.totalGiftValue)} كوين',
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppTheme.gift),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
          const Text('🏆 أكثر المشاهدين تفاعل', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),

          if (topViewers.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text('ما فيه مشاهدين بعد', style: TextStyle(color: AppTheme.textSecondary)),
              ),
            )
          else
            ...topViewers.take(10).toList().asMap().entries.map((entry) {
              final i = entry.key;
              final viewer = entry.value;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: i < 3
                      ? Border.all(color: [AppTheme.gift, AppTheme.textSecondary, AppTheme.warning][i].withOpacity(0.4))
                      : null,
                ),
                child: Row(
                  children: [
                    // الترتيب
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: i < 3
                            ? [AppTheme.gift, AppTheme.textSecondary, AppTheme.warning][i].withOpacity(0.2)
                            : AppTheme.surfaceLight,
                      ),
                      child: Center(
                        child: Text(
                          '${i + 1}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: i < 3 ? [AppTheme.gift, AppTheme.textSecondary, AppTheme.warning][i] : AppTheme.textPrimary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(viewer.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                          Row(
                            children: [
                              Text('❤️ ${viewer.totalLikes}', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                              const SizedBox(width: 10),
                              Text('🎁 ${viewer.totalGifts}', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                              const SizedBox(width: 10),
                              Text('💬 ${viewer.totalComments}', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  String _formatNumber(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({required this.icon, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
            Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
