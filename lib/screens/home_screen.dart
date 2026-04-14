import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/tiktok_live_service.dart';
import '../services/tts_service.dart';
import '../services/trigger_service.dart';
import '../utils/theme.dart';
import '../utils/constants.dart';
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
  bool _ttsInitialized = false;

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
    _initServices();
  }

  Future<void> _initServices() async {
    final tts = context.read<TtsService>();
    await tts.init();
    final triggers = context.read<TriggerService>();
    await triggers.loadTriggers();
    _ttsInitialized = true;
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _connect() {
    final username = _usernameController.text.trim();
    if (username.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('اكتب اسم المستخدم أولاً'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    final service = context.read<TikTokLiveService>();
    service.connect(username);

    // ربط الأحداث بـ TTS و Triggers
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

    // إعادة تعيين الـ triggers
    triggers.resetFiredTriggers();

    // الأحداث
    service.eventStream.listen((event) {
      // TTS
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

      // فحص المشاهدين
      triggers.checkViewerTrigger(service.viewerCount);
    });

    // أحداث "الأوائل"
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
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppTheme.backgroundColor, Color(0xFF0D0D1A)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const SizedBox(height: 20),
                // لوجو
                _buildLogo(),
                const SizedBox(height: 30),
                // حقل اليوزرنيم
                _buildUsernameField(),
                const SizedBox(height: 20),
                // زر الاتصال
                _buildConnectButton(),
                const SizedBox(height: 40),
                // القائمة
                _buildMenuGrid(),
                const SizedBox(height: 30),
                // معلومات المطور
                _buildFooter(),
              ],
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
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppTheme.primaryGradient,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withValues(alpha: 0.5),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: const Icon(
              Icons.live_tv_rounded,
              size: 50,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
            ).createShader(bounds),
            child: const Text(
              'HichamFinity',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'أداة البث الاحترافية',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsernameField() {
    return Container(
      decoration: AppDecorations.glassCard(borderColor: AppTheme.primaryColor.withValues(alpha: 0.3)),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🎬 اتصل بالبث',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _usernameController,
            textDirection: TextDirection.ltr,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              hintText: 'اكتب اسم المستخدم بتيك توك',
              hintStyle: TextStyle(color: AppTheme.textMuted),
              prefixIcon: const Icon(Icons.alternate_email, color: AppTheme.primaryColor),
              filled: true,
              fillColor: AppTheme.backgroundColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectButton() {
    return Consumer<TikTokLiveService>(
      builder: (context, service, _) {
        final isConnecting = service.state == ConnectionState.connecting;
        return SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: isConnecting ? null : _connect,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 8,
              shadowColor: AppTheme.primaryColor.withValues(alpha: 0.5),
            ),
            child: isConnecting
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.play_circle_fill, size: 28),
                      SizedBox(width: 8),
                      Text(
                        'اتصل بالبث',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
          ),
        );
      },
    );
  }

  Widget _buildMenuGrid() {
    final items = [
      _MenuItem(
        icon: Icons.monitor_heart_rounded,
        label: 'مراقبة البث',
        color: AppTheme.primaryColor,
        screen: const LiveMonitorScreen(),
      ),
      _MenuItem(
        icon: Icons.record_voice_over_rounded,
        label: 'إعدادات الصوت',
        color: AppTheme.secondaryColor,
        screen: const TtsSettingsScreen(),
      ),
      _MenuItem(
        icon: Icons.videocam_rounded,
        label: 'الفيديوهات',
        color: AppTheme.accentPurple,
        screen: const VideoTriggersScreen(),
      ),
      _MenuItem(
        icon: Icons.notifications_active_rounded,
        label: 'التنبيهات',
        color: AppTheme.warningColor,
        screen: const AlertsScreen(),
      ),
      _MenuItem(
        icon: Icons.bar_chart_rounded,
        label: 'الإحصائيات',
        color: AppTheme.successColor,
        screen: const StatisticsScreen(),
      ),
      _MenuItem(
        icon: Icons.settings_rounded,
        label: 'الإعدادات',
        color: AppTheme.textSecondary,
        screen: const SettingsScreen(),
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.95,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return _buildMenuItem(item);
      },
    );
  }

  Widget _buildMenuItem(_MenuItem item) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => item.screen),
      ),
      child: Container(
        decoration: AppDecorations.glassCard(
          borderColor: item.color.withValues(alpha: 0.2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: item.color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(item.icon, color: item.color, size: 28),
            ),
            const SizedBox(height: 8),
            Text(
              item.label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Column(
      children: [
        Text(
          '${AppConstants.appName} v${AppConstants.appVersion}',
          style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
        ),
        const SizedBox(height: 4),
        const Text(
          'بواسطة Hicham ❤️',
          style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
        ),
      ],
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String label;
  final Color color;
  final Widget screen;

  _MenuItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.screen,
  });
}
