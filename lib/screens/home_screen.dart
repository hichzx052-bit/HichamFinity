import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/tiktok_live_service.dart';
import '../services/tts_service.dart';
import '../services/trigger_service.dart';
import '../utils/theme.dart';
import '../utils/constants.dart';
import '../widgets/video_overlay.dart';
import 'live_monitor_screen.dart';
import 'settings_screen.dart';
import 'tts_settings_screen.dart';
import 'video_triggers_screen.dart';
import 'statistics_screen.dart';
import 'alerts_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final _usernameController = TextEditingController();
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _glowController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);
    _glowAnimation = Tween<double>(begin: 0.3, end: 0.8).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    _initServices();
  }

  Future<void> _initServices() async {
    final tts = context.read<TtsService>();
    await tts.init();
    final triggers = context.read<TriggerService>();
    await triggers.loadTriggers();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _pulseController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  void _connect() {
    final username = _usernameController.text.trim();
    if (username.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('اكتب اسم المستخدم أولاً'),
          backgroundColor: AppTheme.errorColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    final service = context.read<TikTokLiveService>();
    service.connect(username);
    _setupEventListeners();

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LiveMonitorScreen()),
    );
  }

  void _setupEventListeners() {
    final service = context.read<TikTokLiveService>();
    final tts = context.read<TtsService>();
    final triggers = context.read<TriggerService>();

    triggers.resetFiredTriggers();

    service.eventStream.listen((event) {
      switch (event.type) {
        case 'join':
          tts.speakJoin(event.displayName);
          break;
        case 'comment':
          tts.speakComment(event.displayName, event.message ?? '');
          break;
        case 'gift':
          tts.speakGift(event.displayName, event.giftName ?? '', event.giftCount ?? 1);
          triggers.checkGiftTrigger(event.giftName ?? '');
          break;
        case 'like':
          tts.speakLike(event.displayName, event.likeCount ?? 1);
          triggers.checkLikeTrigger(service.totalLikes);
          break;
        case 'follow':
          tts.speakFollow(event.displayName);
          break;
      }
      triggers.checkViewerTrigger(service.viewerCount);
    });

    service.firstEventStream.listen((data) {
      final type = data['type']!;
      final name = data['name']!;
      String label;
      switch (type) {
        case 'follow':
          label = 'متابع';
          break;
        case 'comment':
          label = 'معلق';
          break;
        case 'gift':
          label = 'مهدي';
          break;
        default:
          label = type;
      }
      tts.speakFirst(label, name);
    });
  }

  @override
  Widget build(BuildContext context) {
    final triggers = context.read<TriggerService>();
    return VideoOverlay(
      triggerService: triggers,
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0A0A1A), Color(0xFF0D0520), Color(0xFF0A0A1A)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  const SizedBox(height: 30),
                  _buildLogo(),
                  const SizedBox(height: 35),
                  _buildConnectCard(),
                  const SizedBox(height: 30),
                  _buildMenuGrid(),
                  const SizedBox(height: 25),
                  _buildFooter(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return ScaleTransition(
      scale: _pulseAnimation,
      child: Column(
        children: [
          // اللوجو مع توهج
          AnimatedBuilder(
            animation: _glowController,
            builder: (context, child) {
              return Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppTheme.primaryGradient,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withValues(alpha: _glowAnimation.value),
                      blurRadius: 40,
                      spreadRadius: 8,
                    ),
                    BoxShadow(
                      color: AppTheme.secondaryColor.withValues(alpha: _glowAnimation.value * 0.5),
                      blurRadius: 60,
                      spreadRadius: 12,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.live_tv_rounded,
                  size: 55,
                  color: Colors.white,
                ),
              );
            },
          ),
          const SizedBox(height: 18),
          // اسم التطبيق
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [AppTheme.primaryColor, AppTheme.secondaryColor, AppTheme.accentPurple],
            ).createShader(bounds),
            child: const Text(
              'HichamFinity',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.3)),
            ),
            child: const Text(
              '⚡ أداة البث الاحترافية',
              style: TextStyle(color: AppTheme.secondaryColor, fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectCard() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A1A35), Color(0xFF12122A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(22),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.live_tv, color: AppTheme.primaryColor, size: 22),
              ),
              const SizedBox(width: 10),
              const Text(
                'اتصل بالبث المباشر',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // حقل اليوزرنيم
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF0A0A1A),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: TextField(
              controller: _usernameController,
              textDirection: TextDirection.ltr,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
              decoration: InputDecoration(
                hintText: '@username',
                hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.2), fontSize: 18),
                prefixIcon: const Icon(Icons.alternate_email, color: AppTheme.secondaryColor),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // زر الاتصال
          Consumer<TikTokLiveService>(
            builder: (context, service, _) {
              final isConnecting = service.state == LiveConnectionState.connecting;
              return SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: isConnecting ? null : _connect,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Ink(
                    decoration: BoxDecoration(
                      gradient: isConnecting ? null : AppTheme.primaryGradient,
                      color: isConnecting ? AppTheme.textMuted : null,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: isConnecting ? null : [
                        BoxShadow(
                          color: AppTheme.primaryColor.withValues(alpha: 0.4),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Container(
                      alignment: Alignment.center,
                      child: isConnecting
                          ? const SizedBox(
                              width: 24, height: 24,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.bolt_rounded, size: 26, color: Colors.white),
                                SizedBox(width: 8),
                                Text(
                                  'اتصل الآن',
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMenuGrid() {
    final items = [
      _MenuItem(Icons.monitor_heart_rounded, 'مراقبة البث', AppTheme.primaryColor, '📡', const LiveMonitorScreen()),
      _MenuItem(Icons.record_voice_over_rounded, 'الأصوات', AppTheme.secondaryColor, '🎤', const TtsSettingsScreen()),
      _MenuItem(Icons.videocam_rounded, 'الفيديوهات', AppTheme.accentPurple, '🎬', const VideoTriggersScreen()),
      _MenuItem(Icons.notifications_active_rounded, 'التنبيهات', AppTheme.warningColor, '🔔', const AlertsScreen()),
      _MenuItem(Icons.bar_chart_rounded, 'الإحصائيات', AppTheme.successColor, '📊', const StatisticsScreen()),
      _MenuItem(Icons.settings_rounded, 'الإعدادات', AppTheme.textSecondary, '⚙️', const SettingsScreen()),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.9,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) => _buildMenuItem(items[index]),
    );
  }

  Widget _buildMenuItem(_MenuItem item) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => item.screen)),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              item.color.withValues(alpha: 0.12),
              item.color.withValues(alpha: 0.04),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: item.color.withValues(alpha: 0.2)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(item.emoji, style: const TextStyle(fontSize: 30)),
            const SizedBox(height: 8),
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: item.color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(item.icon, color: item.color, size: 24),
            ),
            const SizedBox(height: 6),
            Text(
              item.label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: item.color,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        children: [
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
            ).createShader(bounds),
            child: Text(
              '${AppConstants.appName} v${AppConstants.appVersion}',
              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'صنع بـ ❤️ بواسطة Hicham',
            style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String label;
  final Color color;
  final String emoji;
  final Widget screen;
  _MenuItem(this.icon, this.label, this.color, this.emoji, this.screen);
}
