import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/tiktok_live_service.dart';
import '../services/tts_service.dart';
import '../services/trigger_service.dart';
import '../utils/theme.dart';
import '../utils/constants.dart';
import '../widgets/video_overlay.dart';
import '../services/background_service.dart';
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
  late AnimationController _rotateController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _rotateController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    )..repeat();

    _initServices();
  }

  Future<void> _initServices() async {
    final tts = context.read<TtsService>();
    await tts.init();
    tts.resetLikeCounter();
    final triggers = context.read<TriggerService>();
    await triggers.loadTriggers();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _pulseController.dispose();
    _rotateController.dispose();
    super.dispose();
  }

  void _connect() {
    final username = _usernameController.text.trim();
    if (username.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('✏️ اكتب اسم المستخدم أولاً'),
          backgroundColor: AppTheme.errorColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }

    final service = context.read<TikTokLiveService>();
    service.connect(username);
    _setupEventListeners();
    
    // تفعيل الخلفية — يبقى شغال
    BackgroundServiceHelper.startKeepAlive();

    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const LiveMonitorScreen(),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  void _setupEventListeners() {
    final service = context.read<TikTokLiveService>();
    final tts = context.read<TtsService>();
    final triggers = context.read<TriggerService>();

    triggers.resetFiredTriggers();
    tts.resetLikeCounter();

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
          tts.speakLikeAtThreshold(service.totalLikes);
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
        case 'follow': label = 'متابع'; break;
        case 'comment': label = 'معلق'; break;
        case 'gift': label = 'مهدي'; break;
        default: label = type;
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
        body: Stack(
          children: [
            // خلفية متحركة
            _buildAnimatedBackground(),
            // المحتوى
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    const SizedBox(height: 25),
                    _buildLogo(),
                    const SizedBox(height: 30),
                    _buildConnectCard(),
                    const SizedBox(height: 28),
                    _buildMenuGrid(),
                    const SizedBox(height: 20),
                    _buildFooter(),
                    const SizedBox(height: 15),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedBackground() {
    return AnimatedBuilder(
      animation: _rotateController,
      builder: (context, child) {
        return Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF05050F), Color(0xFF0A0520), Color(0xFF050510)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: CustomPaint(
            painter: _BackgroundPainter(_rotateController.value),
            size: Size.infinite,
          ),
        );
      },
    );
  }

  Widget _buildLogo() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final scale = 1.0 + (_pulseController.value * 0.05);
        final glowOpacity = 0.3 + (_pulseController.value * 0.4);
        return Transform.scale(
          scale: scale,
          child: Column(
            children: [
              // لوجو دائري متوهج
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF0050), Color(0xFFFF3070), Color(0xFFFF0050)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF0050).withValues(alpha: glowOpacity),
                      blurRadius: 50,
                      spreadRadius: 10,
                    ),
                    BoxShadow(
                      color: const Color(0xFF00F2EA).withValues(alpha: glowOpacity * 0.4),
                      blurRadius: 80,
                      spreadRadius: 20,
                    ),
                  ],
                ),
                child: const Center(
                  child: Text('🎬', style: TextStyle(fontSize: 55)),
                ),
              ),
              const SizedBox(height: 20),
              // اسم التطبيق
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [Color(0xFFFF0050), Color(0xFF00F2EA), Color(0xFF9B59B6)],
                ).createShader(bounds),
                child: const Text(
                  'HichamFinity',
                  style: TextStyle(
                    fontSize: 38,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 2,
                    shadows: [
                      Shadow(color: Color(0xFFFF0050), blurRadius: 20),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // وصف
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFFFF0050).withValues(alpha: 0.2),
                      const Color(0xFF00F2EA).withValues(alpha: 0.2),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(
                    color: const Color(0xFFFF0050).withValues(alpha: 0.3),
                  ),
                ),
                child: const Text(
                  '⚡ أداة البث الاحترافية ⚡',
                  style: TextStyle(
                    color: Color(0xFF00F2EA),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildConnectCard() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF15152D), Color(0xFF0E0E22)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          width: 1.5,
          color: const Color(0xFFFF0050).withValues(alpha: 0.25),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF0050).withValues(alpha: 0.08),
            blurRadius: 25,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // عنوان
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFFFF0050).withValues(alpha: 0.2),
                      const Color(0xFFFF0050).withValues(alpha: 0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFF0050).withValues(alpha: 0.3)),
                ),
                child: const Text('🔴', style: TextStyle(fontSize: 20)),
              ),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'اتصل بالبث المباشر',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  Text(
                    'اكتب اسم المستخدم وابدأ',
                    style: TextStyle(fontSize: 12, color: Color(0xFF666680)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 18),
          // حقل الإدخال
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF08081A),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: TextField(
              controller: _usernameController,
              textDirection: TextDirection.ltr,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
              ),
              decoration: InputDecoration(
                hintText: '@username',
                hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.15), fontSize: 20),
                prefixIcon: const Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: Text('🎯', style: TextStyle(fontSize: 22)),
                ),
                prefixIconConstraints: const BoxConstraints(minWidth: 50),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              ),
            ),
          ),
          const SizedBox(height: 18),
          // زر الاتصال
          Consumer<TikTokLiveService>(
            builder: (context, service, _) {
              final isConnecting = service.state == LiveConnectionState.connecting;
              return GestureDetector(
                onTap: isConnecting ? null : _connect,
                child: Container(
                  width: double.infinity,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: isConnecting
                        ? const LinearGradient(colors: [Color(0xFF333333), Color(0xFF444444)])
                        : const LinearGradient(
                            colors: [Color(0xFFFF0050), Color(0xFFFF3366), Color(0xFFFF0050)],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: isConnecting ? [] : [
                      BoxShadow(
                        color: const Color(0xFFFF0050).withValues(alpha: 0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Center(
                    child: isConnecting
                        ? const SizedBox(
                            width: 26, height: 26,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('⚡', style: TextStyle(fontSize: 24)),
                              SizedBox(width: 8),
                              Text(
                                'اتصل الآن',
                                style: TextStyle(
                                  fontSize: 19,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
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
      _MenuItem('📡', 'مراقبة\nالبث', [const Color(0xFFFF0050), const Color(0xFFFF3366)], const LiveMonitorScreen()),
      _MenuItem('🎤', 'إعدادات\nالصوت', [const Color(0xFF00F2EA), const Color(0xFF00C4BD)], const TtsSettingsScreen()),
      _MenuItem('🎬', 'الفيديوهات', [const Color(0xFF9B59B6), const Color(0xFF8E44AD)], const VideoTriggersScreen()),
      _MenuItem('🔔', 'التنبيهات', [const Color(0xFFFFAB00), const Color(0xFFFF8F00)], const AlertsScreen()),
      _MenuItem('📊', 'الإحصائيات', [const Color(0xFF00E676), const Color(0xFF00C853)], const StatisticsScreen()),
      _MenuItem('⚙️', 'الإعدادات', [const Color(0xFF78909C), const Color(0xFF546E7A)], const SettingsScreen()),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.85,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) => _buildMenuItem(items[index]),
    );
  }

  Widget _buildMenuItem(_MenuItem item) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => item.screen,
          transitionsBuilder: (_, animation, __, child) {
            return SlideTransition(
              position: Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
                  .animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
              child: FadeTransition(opacity: animation, child: child),
            );
          },
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              item.colors[0].withValues(alpha: 0.15),
              item.colors[1].withValues(alpha: 0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: item.colors[0].withValues(alpha: 0.25),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: item.colors[0].withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // إيموجي كبير
            Container(
              width: 55,
              height: 55,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    item.colors[0].withValues(alpha: 0.2),
                    item.colors[1].withValues(alpha: 0.08),
                  ],
                ),
                shape: BoxShape.circle,
                border: Border.all(color: item.colors[0].withValues(alpha: 0.3)),
                boxShadow: [
                  BoxShadow(
                    color: item.colors[0].withValues(alpha: 0.15),
                    blurRadius: 15,
                  ),
                ],
              ),
              child: Center(
                child: Text(item.emoji, style: const TextStyle(fontSize: 26)),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              item.label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: item.colors[0],
                fontSize: 11,
                fontWeight: FontWeight.w700,
                height: 1.3,
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
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Color(0xFFFF0050), Color(0xFF00F2EA)],
          ).createShader(bounds),
          child: Text(
            '${AppConstants.appName} v${AppConstants.appVersion}',
            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(height: 3),
        const Text(
          'صنع بـ ❤️ بواسطة Hicham',
          style: TextStyle(color: Color(0xFF555555), fontSize: 11),
        ),
      ],
    );
  }
}

class _MenuItem {
  final String emoji;
  final String label;
  final List<Color> colors;
  final Widget screen;
  _MenuItem(this.emoji, this.label, this.colors, this.screen);
}

/// رسام الخلفية المتحركة — نقاط متوهجة
class _BackgroundPainter extends CustomPainter {
  final double progress;
  _BackgroundPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // نقاط حمراء متوهجة
    final dots = [
      Offset(size.width * 0.2, size.height * 0.15),
      Offset(size.width * 0.8, size.height * 0.25),
      Offset(size.width * 0.5, size.height * 0.5),
      Offset(size.width * 0.15, size.height * 0.7),
      Offset(size.width * 0.85, size.height * 0.8),
    ];

    for (var i = 0; i < dots.length; i++) {
      final offset = progress * 2 * 3.14159;
      final dx = dots[i].dx + sin(offset + i) * 20;
      final dy = dots[i].dy + cos(offset + i * 0.7) * 15;

      paint.shader = RadialGradient(
        colors: [
          const Color(0xFFFF0050).withValues(alpha: 0.06),
          const Color(0xFFFF0050).withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromCircle(center: Offset(dx, dy), radius: 80));

      canvas.drawCircle(Offset(dx, dy), 80, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _BackgroundPainter oldDelegate) => true;
}
