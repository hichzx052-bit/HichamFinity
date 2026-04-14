import 'package:flutter/material.dart';
import '../utils/theme.dart';

class AlertsScreen extends StatelessWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('🔔 التنبيهات')),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppTheme.backgroundColor, Color(0xFF0D0D1A)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildAlertSection(
              title: '🎁 تنبيهات الهدايا',
              description: 'صوت وأنيميشن لكل هدية',
              icon: Icons.card_giftcard,
              color: AppTheme.accentGold,
            ),
            const SizedBox(height: 12),
            _buildAlertSection(
              title: '➕ تنبيه المتابعة',
              description: 'إشعار لما أحد يتابعك',
              icon: Icons.person_add,
              color: AppTheme.secondaryColor,
            ),
            const SizedBox(height: 12),
            _buildAlertSection(
              title: '🏅 الأوائل',
              description: 'تأثير خاص لأول متابع/معلق/مهدي',
              icon: Icons.emoji_events,
              color: AppTheme.accentPurple,
            ),
            const SizedBox(height: 12),
            _buildAlertSection(
              title: '🔢 عدادات',
              description: 'إشعار عند وصول عدد معين من اللايكات',
              icon: Icons.numbers,
              color: AppTheme.primaryColor,
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: AppDecorations.accentCard(AppTheme.warningColor),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: AppTheme.warningColor),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'التنبيهات تشتغل تلقائياً مع البث. خصص الفيديوهات والأصوات من صفحاتها.',
                      style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertSection({
    required String title,
    required String description,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      decoration: AppDecorations.glassCard(borderColor: color.withValues(alpha: 0.2)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 45,
          height: 45,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
        subtitle: Text(description, style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
        trailing: Switch(
          value: true,
          activeColor: color,
          onChanged: (_) {},
        ),
      ),
    );
  }
}
