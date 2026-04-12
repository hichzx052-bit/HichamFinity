import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/theme.dart';
import '../services/tiktok_live_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _serverController = TextEditingController(text: 'ws://localhost:3000');
  bool _isTesting = false;
  bool? _serverOk;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('⚙️ الإعدادات')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // إعدادات السيرفر
          const Text('🖥️ السيرفر', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                TextField(
                  controller: _serverController,
                  textDirection: TextDirection.ltr,
                  decoration: InputDecoration(
                    labelText: 'عنوان السيرفر',
                    hintText: 'ws://your-server.com:3000',
                    suffixIcon: _serverOk == null
                        ? null
                        : Icon(
                            _serverOk! ? Icons.check_circle : Icons.error,
                            color: _serverOk! ? AppTheme.success : AppTheme.error,
                          ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: _isTesting
                            ? const SizedBox(
                                width: 16, height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primary),
                              )
                            : const Icon(Icons.wifi_find),
                        label: const Text('فحص الاتصال'),
                        onPressed: _isTesting ? null : _testServer,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.save),
                        label: const Text('حفظ'),
                        onPressed: () {
                          context.read<TikTokLiveService>().setServerUrl(_serverController.text);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('تم حفظ عنوان السيرفر ✅')),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // معلومات
          const Text('ℹ️ عن السيرفر', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Text(
              'التطبيق يحتاج سيرفر وسيط (Node.js) يتصل بتيك توك ويرسل الأحداث.\n\n'
              '1. شغّل السيرفر على جهازك أو استضافة مجانية\n'
              '2. أدخل عنوان السيرفر هنا\n'
              '3. اتصل بالبث من الشاشة الرئيسية\n\n'
              'السيرفر موجود في مجلد server/ بالريبو على GitHub.',
              style: TextStyle(color: AppTheme.textSecondary, height: 1.6),
            ),
          ),

          const SizedBox(height: 24),
          const Text('👨‍💻 المطور', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Column(
              children: [
                ListTile(
                  leading: Icon(Icons.code, color: AppTheme.primary),
                  title: Text('Hichamdzz'),
                  subtitle: Text('المطور'),
                ),
                ListTile(
                  leading: Icon(Icons.info_outline, color: AppTheme.textSecondary),
                  title: Text('HichamFinity v1.0.0'),
                  subtitle: Text('أداة البث المباشر لتيك توك'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _testServer() async {
    setState(() {
      _isTesting = true;
      _serverOk = null;
    });

    final ok = await context.read<TikTokLiveService>().testServer(_serverController.text);

    setState(() {
      _isTesting = false;
      _serverOk = ok;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(ok ? 'السيرفر شغال ✅' : 'السيرفر مو شغال ❌'),
        backgroundColor: ok ? AppTheme.success : AppTheme.error,
      ));
    }
  }
}
