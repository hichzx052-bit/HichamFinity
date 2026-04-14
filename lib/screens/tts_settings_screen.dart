import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/tts_service.dart';
import '../utils/theme.dart';

class TtsSettingsScreen extends StatefulWidget {
  const TtsSettingsScreen({super.key});

  @override
  State<TtsSettingsScreen> createState() => _TtsSettingsScreenState();
}

class _TtsSettingsScreenState extends State<TtsSettingsScreen> {
  late TtsService _tts;
  List<dynamic> _languages = [];

  @override
  void initState() {
    super.initState();
    _tts = context.read<TtsService>();
    _loadLanguages();
  }

  Future<void> _loadLanguages() async {
    final langs = await _tts.getAvailableLanguages();
    setState(() => _languages = langs);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('🎤 إعدادات الصوت')),
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
            // تفعيل/تعطيل
            _buildSection(
              title: '🔊 التفعيل',
              child: SwitchListTile(
                title: const Text('تفعيل الأصوات', style: TextStyle(color: AppTheme.textPrimary)),
                value: _tts.isEnabled,
                activeColor: AppTheme.primaryColor,
                onChanged: (v) {
                  _tts.setEnabled(v);
                  setState(() {});
                },
              ),
            ),
            const SizedBox(height: 16),

            // السرعة والنبرة والصوت
            _buildSection(
              title: '🎛️ التحكم بالصوت',
              child: Column(
                children: [
                  _buildSlider('السرعة', _tts.rate, 0.1, 1.0, (v) {
                    _tts.updateSettings(newRate: v);
                    setState(() {});
                  }),
                  _buildSlider('النبرة', _tts.pitch, 0.5, 2.0, (v) {
                    _tts.updateSettings(newPitch: v);
                    setState(() {});
                  }),
                  _buildSlider('الصوت', _tts.volume, 0.0, 1.0, (v) {
                    _tts.updateSettings(newVolume: v);
                    setState(() {});
                  }),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // الأحداث
            _buildSection(
              title: '📋 أحداث النطق',
              child: Column(
                children: [
                  _buildEventToggle('👋 دخول زائر', _tts.speakJoins, (v) {
                    _tts.speakJoins = v;
                    setState(() {});
                  }),
                  _buildEventToggle('💬 تعليق', _tts.speakComments, (v) {
                    _tts.speakComments = v;
                    setState(() {});
                  }),
                  _buildEventToggle('🎁 هدية', _tts.speakGifts, (v) {
                    _tts.speakGifts = v;
                    setState(() {});
                  }),
                  _buildEventToggle('➕ متابعة', _tts.speakFollows, (v) {
                    _tts.speakFollows = v;
                    setState(() {});
                  }),
                  _buildEventToggle('❤️ لايك', _tts.speakLikes, (v) {
                    _tts.speakLikes = v;
                    setState(() {});
                  }),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // تجربة
            _buildSection(
              title: '🧪 تجربة',
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    _tts.speakCustom('مرحباً! هذا اختبار صوت HichamFinity');
                  },
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('جرب الصوت'),
                ),
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
          Text(title, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildSlider(String label, double value, double min, double max, ValueChanged<double> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 60,
            child: Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
          ),
          Expanded(
            child: Slider(
              value: value,
              min: min,
              max: max,
              activeColor: AppTheme.primaryColor,
              inactiveColor: AppTheme.textMuted,
              onChanged: onChanged,
            ),
          ),
          SizedBox(
            width: 40,
            child: Text(
              value.toStringAsFixed(1),
              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventToggle(String label, bool value, ValueChanged<bool> onChanged) {
    return SwitchListTile(
      title: Text(label, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14)),
      value: value,
      activeColor: AppTheme.primaryColor,
      dense: true,
      onChanged: onChanged,
    );
  }
}
