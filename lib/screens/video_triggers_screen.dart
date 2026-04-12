import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../utils/theme.dart';
import '../services/trigger_service.dart';
import '../models/trigger_config.dart';

class VideoTriggersScreen extends StatelessWidget {
  const VideoTriggersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final triggerService = context.watch<TriggerService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('🎬 فيديو مخصص'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddTriggerDialog(context),
        backgroundColor: AppTheme.primary,
        icon: const Icon(Icons.add),
        label: const Text('إضافة محفز'),
      ),
      body: triggerService.triggers.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.videocam_off_rounded, size: 60, color: AppTheme.textSecondary.withOpacity(0.3)),
                  const SizedBox(height: 16),
                  const Text('ما فيه محفزات', style: TextStyle(color: AppTheme.textSecondary, fontSize: 16)),
                  const SizedBox(height: 8),
                  const Text(
                    'أضف محفز عشان يظهر فيديو\nلما مشاهد يوصل عدد لايكات معين',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: triggerService.triggers.length,
              itemBuilder: (context, index) {
                return _TriggerCard(trigger: triggerService.triggers[index]);
              },
            ),
    );
  }

  void _showAddTriggerDialog(BuildContext context) {
    final labelController = TextEditingController();
    final thresholdController = TextEditingController(text: '100');
    TriggerType selectedType = TriggerType.likeCount;
    String? selectedVideoPath;
    bool showName = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20, right: 20, top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    '➕ محفز جديد',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),

                  // نوع المحفز
                  DropdownButtonFormField<TriggerType>(
                    value: selectedType,
                    decoration: const InputDecoration(labelText: 'نوع المحفز'),
                    items: const [
                      DropdownMenuItem(value: TriggerType.likeCount, child: Text('❤️ عدد لايكات من مشاهد')),
                      DropdownMenuItem(value: TriggerType.giftReceived, child: Text('🎁 قيمة هدايا')),
                      DropdownMenuItem(value: TriggerType.followerJoin, child: Text('➕ عدد متابعين جدد')),
                      DropdownMenuItem(value: TriggerType.viewerCount, child: Text('👁️ عدد مشاهدين')),
                    ],
                    onChanged: (v) => setState(() => selectedType = v!),
                  ),
                  const SizedBox(height: 12),

                  // اسم المحفز
                  TextField(
                    controller: labelController,
                    decoration: const InputDecoration(
                      labelText: 'اسم المحفز',
                      hintText: 'مثال: فيديو 100 لايك',
                    ),
                  ),
                  const SizedBox(height: 12),

                  // الحد
                  TextField(
                    controller: thresholdController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'العدد المطلوب',
                      hintText: _getThresholdHint(selectedType),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // اختيار فيديو
                  OutlinedButton.icon(
                    icon: Icon(
                      selectedVideoPath != null ? Icons.check_circle : Icons.video_library,
                      color: selectedVideoPath != null ? AppTheme.success : AppTheme.textSecondary,
                    ),
                    label: Text(
                      selectedVideoPath != null ? 'فيديو محدد ✅' : 'اختر فيديو من الجهاز',
                    ),
                    onPressed: () async {
                      final result = await FilePicker.platform.pickFiles(type: FileType.video);
                      if (result != null) {
                        setState(() => selectedVideoPath = result.files.single.path);
                      }
                    },
                  ),
                  const SizedBox(height: 8),

                  // عرض اسم المشاهد
                  SwitchListTile(
                    title: const Text('عرض اسم المشاهد فوق الفيديو'),
                    value: showName,
                    activeColor: AppTheme.primary,
                    onChanged: (v) => setState(() => showName = v),
                    contentPadding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: 16),

                  // زر الإضافة
                  ElevatedButton(
                    onPressed: () {
                      final label = labelController.text.trim();
                      final threshold = int.tryParse(thresholdController.text) ?? 100;
                      if (label.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('أدخل اسم المحفز')),
                        );
                        return;
                      }
                      context.read<TriggerService>().addTrigger(
                        type: selectedType,
                        label: label,
                        threshold: threshold,
                        videoPath: selectedVideoPath,
                        showViewerName: showName,
                      );
                      Navigator.pop(context);
                    },
                    child: const Text('✅ إضافة', style: TextStyle(fontSize: 18)),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _getThresholdHint(TriggerType type) {
    switch (type) {
      case TriggerType.likeCount: return 'مثال: 100 (100 لايك من مشاهد واحد)';
      case TriggerType.giftReceived: return 'مثال: 500 (500 كوين هدايا)';
      case TriggerType.followerJoin: return 'مثال: 10 (10 متابعين جدد)';
      case TriggerType.viewerCount: return 'مثال: 50 (50 مشاهد)';
    }
  }
}

class _TriggerCard extends StatelessWidget {
  final TriggerConfig trigger;

  const _TriggerCard({required this.trigger});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: trigger.enabled ? AppTheme.primary.withOpacity(0.3) : AppTheme.surfaceLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_getTypeIcon(trigger.type), color: AppTheme.accent),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  trigger.label,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              Switch(
                value: trigger.enabled,
                activeColor: AppTheme.primary,
                onChanged: (v) {
                  context.read<TriggerService>().updateTrigger(trigger.id, enabled: v);
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          // شريط التقدم
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: trigger.progress,
              backgroundColor: AppTheme.surfaceLight,
              valueColor: AlwaysStoppedAnimation(
                trigger.isTriggered ? AppTheme.success : AppTheme.primary,
              ),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${trigger.currentCount} / ${trigger.threshold}',
                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
              ),
              Row(
                children: [
                  if (trigger.videoPath != null)
                    const Icon(Icons.videocam, size: 16, color: AppTheme.success),
                  if (trigger.showViewerName)
                    const Padding(
                      padding: EdgeInsets.only(right: 4),
                      child: Icon(Icons.person, size: 16, color: AppTheme.viewer),
                    ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: AppTheme.error, size: 20),
                    onPressed: () {
                      context.read<TriggerService>().removeTrigger(trigger.id);
                    },
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _getTypeIcon(TriggerType type) {
    switch (type) {
      case TriggerType.likeCount: return Icons.favorite_rounded;
      case TriggerType.giftReceived: return Icons.card_giftcard_rounded;
      case TriggerType.followerJoin: return Icons.person_add_rounded;
      case TriggerType.viewerCount: return Icons.groups_rounded;
    }
  }
}
