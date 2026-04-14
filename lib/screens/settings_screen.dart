import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/tiktok_live_service.dart';
import '../utils/theme.dart';
import '../utils/constants.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _serverUrlController = TextEditingController();
  bool _autoReply = false;
  final _autoReplyMsgController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _serverUrlController.text = prefs.getString(AppConstants.prefServerUrl) ?? AppConstants.defaultServerUrl;
      _autoReply = prefs.getBool(AppConstants.prefAutoReply) ?? false;
      _autoReplyMsgController.text = prefs.getString(AppConstants.prefAutoReplyMessage) ?? 'أهلاً وسهلاً! 👋';
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.prefServerUrl, _serverUrlController.text);
    await prefs.setBool(AppConstants.prefAutoReply, _autoReply);
    await prefs.setString(AppConstants.prefAutoReplyMessage, _autoReplyMsgController.text);

    final service = context.read<TikTokLiveService>();
    service.setServerUrl(_serverUrlController.text);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ تم حفظ الإعدادات'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    }
  }

  @override
  void dispose() {
    _serverUrlController.dispose();
    _autoReplyMsgController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('⚙️ الإعدادات')),
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
            // عنوان السيرفر
            _buildSection(
              title: '🔗 عنوان السيرفر',
              child: TextField(
                controller: _serverUrlController,
                textDirection: TextDirection.ltr,
                style: const TextStyle(color: AppTheme.textPrimary),
                decoration: const InputDecoration(
                  hintText: 'ws://localhost:3000',
                ),
              ),
            ),
            const SizedBox(height: 16),

            // الرد التلقائي
            _buildSection(
              title: '🤖 الرد التلقائي',
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('تفعيل الرد التلقائي', style: TextStyle(color: AppTheme.textPrimary)),
                    subtitle: const Text('رسالة ترحيب لكل زائر جديد', style: TextStyle(color: AppTheme.textMuted)),
                    value: _autoReply,
                    activeColor: AppTheme.primaryColor,
                    onChanged: (v) => setState(() => _autoReply = v),
                  ),
                  if (_autoReply)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: TextField(
                        controller: _autoReplyMsgController,
                        style: const TextStyle(color: AppTheme.textPrimary),
                        decoration: const InputDecoration(
                          hintText: 'أهلاً وسهلاً! 👋',
                        ),
                        maxLines: 2,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // معلومات التطبيق
            _buildSection(
              title: 'ℹ️ عن التطبيق',
              child: Column(
                children: [
                  _buildInfoRow('الاسم', AppConstants.appName),
                  _buildInfoRow('الإصدار', AppConstants.appVersion),
                  _buildInfoRow('المطور', AppConstants.developer),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // زر الحفظ
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _saveSettings,
                icon: const Icon(Icons.save_rounded),
                label: const Text('حفظ الإعدادات', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required Widget child}) {
    return Container(
      decoration: AppDecorations.glassCard(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppTheme.textSecondary)),
          Text(value, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
