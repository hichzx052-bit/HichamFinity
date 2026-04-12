import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/theme.dart';
import '../services/tiktok_live_service.dart';
import '../services/tts_service.dart';
import '../services/trigger_service.dart';
import 'live_monitor_screen.dart';
import 'settings_screen.dart';
import 'alerts_screen.dart';
import 'tts_settings_screen.dart';
import 'video_triggers_screen.dart';
import 'statistics_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final _usernameController = TextEditingController();
  bool _isConnecting = false;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _connect() async {
    final username = _usernameController.text.trim();
    if (username.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('أدخل يوزرنيم البث')),
      );
      return;
    }

    setState(() => _isConnecting = true);
    final service = context.read<TikTokLiveService>();
    final success = await service.connect(username);

    setState(() => _isConnecting = false);

    if (success && mounted) {
      // بدء الاستماع للأحداث
      _setupEventListeners();
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const LiveMonitorScreen()),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('فشل الاتصال — تأكد من السيرفر واليوزرنيم'),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  void _setupEventListeners() {
    final liveService = context.read<TikTokLiveService>();
    final ttsService = context.read<TtsService>();
    final triggerService = context.read<TriggerService>();

    liveService.eventStream.listen((event) {
      ttsService.processEvent(event);
      triggerService.processEvent(event);
    });
  }

  @override
  Widget build(BuildContext context) {
    final liveService = context.watch<TikTokLiveService>();

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.background,
              AppTheme.primary.withOpacity(0.1),
              AppTheme.background,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const SizedBox(height: 20),
                // Logo
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: 1.0 + (_pulseController.value * 0.05),
                      child: child,
                    );
                  },
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(colors: AppTheme.gradientPrimary),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primary.withOpacity(0.4),
                          blurRadius: 30,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.live_tv_rounded,
                      size: 60,
                      color: Colors.white,
                    ),
                  ),
                ),

                const SizedBox(height: 20),
                // App name
                ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: AppTheme.gradientPrimary,
                  ).createShader(bounds),
                  child: const Text(
                    'HichamFinity',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const Text(
                  'أداة البث المباشر لتيك توك 🎬',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 16,
                  ),
                ),

                const SizedBox(height: 40),

                // Connection card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: liveService.isConnected
                          ? AppTheme.success.withOpacity(0.5)
                          : AppTheme.primary.withOpacity(0.2),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(
                            liveService.isConnected
                                ? Icons.wifi_rounded
                                : Icons.wifi_off_rounded,
                            color: liveService.isConnected
                                ? AppTheme.success
                                : AppTheme.textSecondary,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            liveService.isConnected ? 'متصل بالبث' : 'غير متصل',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: liveService.isConnected
                                  ? AppTheme.success
                                  : AppTheme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _usernameController,
                        textDirection: TextDirection.ltr,
                        decoration: InputDecoration(
                          hintText: 'يوزرنيم تيك توك (بدون @)',
                          prefixIcon: const Icon(Icons.person_outline),
                          suffixIcon: liveService.isConnected
                              ? IconButton(
                                  icon: const Icon(Icons.close, color: AppTheme.error),
                                  onPressed: () => liveService.disconnect(),
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isConnecting
                              ? null
                              : liveService.isConnected
                                  ? () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => const LiveMonitorScreen(),
                                        ),
                                      )
                                  : _connect,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: liveService.isConnected
                                ? AppTheme.success
                                : AppTheme.primary,
                          ),
                          child: _isConnecting
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  liveService.isConnected
                                      ? '📺 فتح شاشة البث'
                                      : '🔗 اتصال بالبث',
                                  style: const TextStyle(fontSize: 18),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // Feature grid
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.3,
                  children: [
                    _FeatureCard(
                      icon: Icons.record_voice_over_rounded,
                      label: 'قراءة الأسماء',
                      subtitle: 'TTS للداخلين',
                      color: AppTheme.viewer,
                      onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const TtsSettingsScreen())),
                    ),
                    _FeatureCard(
                      icon: Icons.videocam_rounded,
                      label: 'فيديو مخصص',
                      subtitle: 'عند عدد لايكات',
                      color: AppTheme.accent,
                      onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const VideoTriggersScreen())),
                    ),
                    _FeatureCard(
                      icon: Icons.notifications_active_rounded,
                      label: 'التنبيهات',
                      subtitle: 'هدايا وتعليقات',
                      color: AppTheme.gift,
                      onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const AlertsScreen())),
                    ),
                    _FeatureCard(
                      icon: Icons.bar_chart_rounded,
                      label: 'الإحصائيات',
                      subtitle: 'بيانات البث',
                      color: AppTheme.success,
                      onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const StatisticsScreen())),
                    ),
                    _FeatureCard(
                      icon: Icons.settings_rounded,
                      label: 'الإعدادات',
                      subtitle: 'السيرفر والتطبيق',
                      color: AppTheme.textSecondary,
                      onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const SettingsScreen())),
                    ),
                    _FeatureCard(
                      icon: Icons.code_rounded,
                      label: 'المطور',
                      subtitle: 'Hichamdzz',
                      color: AppTheme.primary,
                      onTap: () => _showDeveloperDialog(),
                    ),
                  ],
                ),

                const SizedBox(height: 30),
                Text(
                  'v1.0.0 — صنع بـ ❤️ بواسطة Hichamdzz',
                  style: TextStyle(
                    color: AppTheme.textSecondary.withOpacity(0.5),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDeveloperDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('👨‍💻 المطور', textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(colors: AppTheme.gradientPrimary),
              ),
              child: const Icon(Icons.developer_mode, size: 40, color: Colors.white),
            ),
            const SizedBox(height: 16),
            const Text(
              'Hichamdzz',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'HichamFinity v1.0.0\nأداة البث المباشر لتيك توك',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _FeatureCard({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 10),
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
