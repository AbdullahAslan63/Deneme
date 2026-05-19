import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_sizes.dart';
import '../../../../l10n/strings.g.dart';
import '../../../../shared/widgets/toast_overlay.dart';
import '../../../buildings/data/buildings_store.dart';
import '../providers/notifications_provider.dart';

class SendAnnouncementScreen extends ConsumerStatefulWidget {
  const SendAnnouncementScreen({super.key});

  @override
  ConsumerState<SendAnnouncementScreen> createState() =>
      _SendAnnouncementScreenState();
}

class _SendAnnouncementScreenState extends ConsumerState<SendAnnouncementScreen> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  String? _buildingId;
  bool _submitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final buildings = ref.watch(buildingsStoreProvider).value ?? [];
    final t = context.t.features.notifications;

    if (_buildingId == null && buildings.isNotEmpty) {
      _buildingId = buildings.first.id;
    }

    return Scaffold(
      appBar: AppBar(title: Text(t.sendTitle), centerTitle: true),
      body: ListView(
        padding: AppSizes.screenBodyScrollPadding,
        children: [
          if (buildings.isNotEmpty)
            DropdownButtonFormField<String>(
              value: _buildingId,
              decoration: InputDecoration(
                labelText: context.t.common.buildingName,
                border: const OutlineInputBorder(),
              ),
              items: buildings
                  .map((b) => DropdownMenuItem(value: b.id, child: Text(b.name)))
                  .toList(),
              onChanged: (id) => setState(() => _buildingId = id),
            ),
          const SizedBox(height: AppSizes.spacingM),
          TextField(
            controller: _titleController,
            decoration: InputDecoration(labelText: t.fieldTitle),
          ),
          const SizedBox(height: AppSizes.spacingM),
          TextField(
            controller: _bodyController,
            maxLines: 5,
            decoration: InputDecoration(labelText: t.fieldBody),
          ),
          const SizedBox(height: AppSizes.spacingXL),
          FilledButton(
            onPressed: _submitting ? null : _submit,
            child: _submitting
                ? const CircularProgressIndicator()
                : Text(t.sendButton),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    final id = _buildingId;
    final title = _titleController.text.trim();
    final body = _bodyController.text.trim();
    if (id == null || title.isEmpty || body.isEmpty) return;
    setState(() => _submitting = true);
    final result = await ref
        .read(notificationsNotifierProvider.notifier)
        .sendAnnouncement(id, title: title, body: body);
    if (!mounted) return;
    setState(() => _submitting = false);
    if (result != null) {
      ref.read(toastProvider.notifier).show(
            context.t.features.notifications.sendSuccess,
            type: ToastType.success,
          );
      context.pop();
    }
  }
}
