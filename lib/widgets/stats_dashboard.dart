import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/theme.dart';
import '../services/tiktok_live_service.dart';

class StatsDashboard extends StatelessWidget {
  const StatsDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final live = context.watch<TikTokLiveService>();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: AppTheme.surface,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _MiniStat(icon: Icons.visibility, value: '${live.viewerCount}', color: AppTheme.viewer),
          _MiniStat(icon: Icons.favorite, value: _fmt(live.totalLikes), color: AppTheme.like),
          _MiniStat(icon: Icons.card_giftcard, value: '${live.totalGifts}', color: AppTheme.gift),
          _MiniStat(icon: Icons.chat_bubble, value: '${live.totalComments}', color: AppTheme.comment),
        ],
      ),
    );
  }

  String _fmt(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }
}

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final Color color;

  const _MiniStat({required this.icon, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16)),
      ],
    );
  }
}
