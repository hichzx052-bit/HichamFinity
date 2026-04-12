import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/theme.dart';
import '../services/tts_service.dart';

class TtsSettingsScreen extends StatelessWidget {
  const TtsSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tts = context.watch<TtsService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('🗣️ إعدادات القراءة الصوتية'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // تفعيل/تعطيل
          _buildCard(
            child: SwitchListTile(
              title: const Text('تفعيل القراءة الصوتية'),
              subtitle: const Text('قراءة الأحداث بصوت عالي'),
              value: tts.enabled,
              activeColor: AppTheme.primary,
              onChanged: (v) => tts.setEnabled(v),
              secondary: Icon(
                tts.enabled ? Icons.volume_up : Icons.volume_off,
                color: tts.enabled ? AppTheme.primary : AppTheme.textSecondary,
              ),
            ),
          ),

          const SizedBox(height: 16),
          const Text('📋 وش يقرأ؟', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),

          _buildCard(
            child: Column(
              children: [
                _buildSwitch(
                  title: 'أسماء الداخلين',
                  subtitle: 'يقرأ اسم كل شخص يدخل البث',
                  icon: Icons.person_add_rounded,
                  value: tts.readJoins,
                  onChanged: (v) {
                    tts.readJoins = v;
                    tts.notifyListeners();
                  },
                ),
                const Divider(height: 1),
                _buildSwitch(
                  title: 'الهدايا',
                  subtitle: 'يقرأ اسم المرسل ونوع الهدية',
                  icon: Icons.card_giftcard_rounded,
                  value: tts.readGifts,
                  onChanged: (v) {
                    tts.readGifts = v;
                    tts.notifyListeners();
                  },
                ),
                const Divider(height: 1),
                _buildSwitch(
                  title: 'التعليقات',
                  subtitle: 'يقرأ كل تعليق (ممكن يكون كثير)',
                  icon: Icons.chat_bubble_rounded,
                  value: tts.readComments,
                  onChanged: (v) {
                    tts.readComments = v;
                    tts.notifyListeners();
                  },
                ),
                const Divider(height: 1),
                _buildSwitch(
                  title: 'المتابعين الجدد',
                  subtitle: 'يقرأ اسم كل متابع جديد',
                  icon: Icons.favorite_rounded,
                  value: tts.readFollows,
                  onChanged: (v) {
                    tts.readFollows = v;
                    tts.notifyListeners();
                  },
                ),
                const Divider(height: 1),
                _buildSwitch(
                  title: 'اللايكات الكبيرة',
                  subtitle: 'يقرأ لما أحد يعطي 10+ لايك دفعة',
                  icon: Icons.thumb_up_rounded,
                  value: tts.readLikes,
                  onChanged: (v) {
                    tts.readLikes = v;
                    tts.notifyListeners();
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
          const Text('🎛️ إعدادات الصوت', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),

          _buildCard(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // سرعة الكلام
                  Row(
                    children: [
                      const Icon(Icons.speed, color: AppTheme.primary),
                      const SizedBox(width: 12),
                      const Text('السرعة'),
                      Expanded(
                        child: Slider(
                          value: tts.rate,
                          min: 0.1,
                          max: 1.0,
                          divisions: 9,
                          label: '${(tts.rate * 100).toInt()}%',
                          activeColor: AppTheme.primary,
                          onChanged: (v) => tts.updateSettings(newRate: v),
                        ),
                      ),
                    ],
                  ),
                  // حدة الصوت
                  Row(
                    children: [
                      const Icon(Icons.music_note, color: AppTheme.accent),
                      const SizedBox(width: 12),
                      const Text('الحدة'),
                      Expanded(
                        child: Slider(
                          value: tts.pitch,
                          min: 0.5,
                          max: 2.0,
                          divisions: 15,
                          label: tts.pitch.toStringAsFixed(1),
                          activeColor: AppTheme.accent,
                          onChanged: (v) => tts.updateSettings(newPitch: v),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // زر اختبار
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text('اختبار الصوت'),
              onPressed: () => tts.speak('مرحباً! هذا اختبار القراءة الصوتية من هشام فينيتي'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: child,
    );
  }

  Widget _buildSwitch({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      title: Text(title),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
      secondary: Icon(icon, color: value ? AppTheme.primary : AppTheme.textSecondary),
      value: value,
      activeColor: AppTheme.primary,
      onChanged: onChanged,
    );
  }
}
