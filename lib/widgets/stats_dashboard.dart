import 'package:flutter/material.dart';
import '../utils/theme.dart';

class StatsDashboard extends StatelessWidget {
  final int viewers;
  final int likes;
  final int comments;
  final int gifts;
  final int diamonds;

  const StatsDashboard({
    super.key,
    required this.viewers,
    required this.likes,
    required this.comments,
    required this.gifts,
    required this.diamonds,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          _buildStat('👁', '$viewers', AppTheme.secondaryColor),
          _buildStat('❤️', '$likes', AppTheme.primaryColor),
          _buildStat('💬', '$comments', AppTheme.accentPurple),
          _buildStat('🎁', '$gifts', AppTheme.accentGold),
          _buildStat('💎', '$diamonds', Colors.cyanAccent),
        ],
      ),
    );
  }

  Widget _buildStat(String emoji, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(color: color, fontSize: 15, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
