import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../services/trigger_service.dart';
import '../utils/theme.dart';

class VideoTriggersScreen extends StatelessWidget {
  const VideoTriggersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('🎬 الفيديوهات')),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.primaryColor,
        onPressed: () => _showAddDialog(context),
        child: const Icon(Icons.add),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppTheme.backgroundColor, Color(0xFF0D0D1A)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Consumer<TriggerService>(
          builder: (context, service, _) {
            if (service.triggers.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.videocam_off, color: AppTheme.textMuted, size: 60),
                    SizedBox(height: 16),
                    Text('ما فيه فيديوهات', style: TextStyle(color: AppTheme.textMuted, fontSize: 16)),
                    SizedBox(height: 8),
                    Text('اضغط + لإضافة فيديو', style: TextStyle(color: AppTheme.textMuted, fontSize: 14)),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: service.triggers.length,
              itemBuilder: (context, index) {
                final trigger = service.triggers[index];
                return _buildTriggerCard(context, trigger, service);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildTriggerCard(BuildContext context, TriggerConfig trigger, TriggerService service) {
    final typeInfo = _getTriggerTypeInfo(trigger.type);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: AppDecorations.glassCard(
        borderColor: trigger.enabled ? typeInfo.color.withValues(alpha: 0.3) : AppTheme.textMuted.withValues(alpha: 0.2),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 45,
          height: 45,
          decoration: BoxDecoration(
            color: typeInfo.color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(typeInfo.icon, color: typeInfo.color),
        ),
        title: Text(
          '${typeInfo.label} — ${trigger.threshold}',
          style: TextStyle(
            color: trigger.enabled ? AppTheme.textPrimary : AppTheme.textMuted,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          trigger.videoPath?.split('/').last ?? 'بدون فيديو',
          style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // تشغيل يدوي
            IconButton(
              icon: const Icon(Icons.play_circle, color: AppTheme.successColor),
              onPressed: () => service.fireManualTrigger(trigger.id),
            ),
            // تفعيل/تعطيل
            Switch(
              value: trigger.enabled,
              activeColor: AppTheme.primaryColor,
              onChanged: (_) => service.toggleTrigger(trigger.id),
            ),
            // حذف
            IconButton(
              icon: const Icon(Icons.delete, color: AppTheme.errorColor, size: 20),
              onPressed: () => service.removeTrigger(trigger.id),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddDialog(BuildContext context) {
    TriggerType selectedType = TriggerType.likes;
    final thresholdController = TextEditingController(text: '100');
    final giftNameController = TextEditingController();
    String? videoPath;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Center(
                    child: Text(
                      '➕ إضافة فيديو',
                      style: TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // نوع الحدث
                  const Text('نوع الحدث:', style: TextStyle(color: AppTheme.textSecondary)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: TriggerType.values.map((type) {
                      final info = _getTriggerTypeInfo(type);
                      final isSelected = selectedType == type;
                      return ChoiceChip(
                        label: Text(info.label),
                        selected: isSelected,
                        selectedColor: info.color.withValues(alpha: 0.3),
                        labelStyle: TextStyle(color: isSelected ? info.color : AppTheme.textMuted),
                        onSelected: (_) => setSheetState(() => selectedType = type),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  // العدد
                  if (selectedType != TriggerType.manual) ...[
                    Text(
                      selectedType == TriggerType.gifts ? 'اسم الهدية (اختياري):' : 'العدد المطلوب:',
                      style: const TextStyle(color: AppTheme.textSecondary),
                    ),
                    const SizedBox(height: 8),
                    if (selectedType == TriggerType.gifts)
                      TextField(
                        controller: giftNameController,
                        style: const TextStyle(color: AppTheme.textPrimary),
                        decoration: const InputDecoration(hintText: 'أي هدية'),
                      ),
                    if (selectedType != TriggerType.gifts)
                      TextField(
                        controller: thresholdController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: AppTheme.textPrimary),
                        decoration: const InputDecoration(hintText: '100'),
                      ),
                    const SizedBox(height: 16),
                  ],

                  // اختيار فيديو
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final result = await FilePicker.platform.pickFiles(type: FileType.video);
                        if (result != null) {
                          setSheetState(() => videoPath = result.files.single.path);
                        }
                      },
                      icon: const Icon(Icons.video_library),
                      label: Text(
                        videoPath != null ? videoPath!.split('/').last : 'اختر فيديو',
                        overflow: TextOverflow.ellipsis,
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.secondaryColor,
                        side: const BorderSide(color: AppTheme.secondaryColor),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // زر الإضافة
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        final trigger = TriggerConfig(
                          id: DateTime.now().millisecondsSinceEpoch.toString(),
                          type: selectedType,
                          threshold: int.tryParse(thresholdController.text) ?? 100,
                          videoPath: videoPath,
                          giftName: giftNameController.text.isNotEmpty ? giftNameController.text : null,
                        );
                        context.read<TriggerService>().addTrigger(trigger);
                        Navigator.pop(context);
                      },
                      child: const Text('✅ إضافة', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  _TriggerTypeInfo _getTriggerTypeInfo(TriggerType type) {
    switch (type) {
      case TriggerType.likes:
        return _TriggerTypeInfo('❤️ لايكات', Icons.favorite, AppTheme.primaryColor);
      case TriggerType.viewers:
        return _TriggerTypeInfo('👁 مشاهدين', Icons.visibility, AppTheme.secondaryColor);
      case TriggerType.gifts:
        return _TriggerTypeInfo('🎁 هدايا', Icons.card_giftcard, AppTheme.accentGold);
      case TriggerType.manual:
        return _TriggerTypeInfo('🎮 يدوي', Icons.touch_app, AppTheme.accentPurple);
    }
  }
}

class _TriggerTypeInfo {
  final String label;
  final IconData icon;
  final Color color;
  _TriggerTypeInfo(this.label, this.icon, this.color);
}
