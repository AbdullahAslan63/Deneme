import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../l10n/strings.g.dart';
import '../../../../shared/widgets/toast_overlay.dart';
import '../../../buildings/data/buildings_store.dart';
import '../providers/notifications_provider.dart';

/// Yönetici duyuru formu → `POST /buildings/:id/announcements` (B5).
class AnnouncementFormSheet extends ConsumerStatefulWidget {
  const AnnouncementFormSheet({super.key});

  static Future<bool?> show(BuildContext context) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AnnouncementFormSheet(),
    );
  }

  @override
  ConsumerState<AnnouncementFormSheet> createState() =>
      _AnnouncementFormSheetState();
}

class _AnnouncementFormSheetState extends ConsumerState<AnnouncementFormSheet> {
  final _formKey = GlobalKey<FormState>();
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
    final bottom = MediaQuery.viewInsetsOf(context).bottom;

    if (_buildingId == null && buildings.isNotEmpty) {
      _buildingId = buildings.first.id;
    }

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppSizes.spacingM,
              AppSizes.spacingS,
              AppSizes.spacingM,
              AppSizes.spacingM,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: AppSizes.spacingM),
                      decoration: BoxDecoration(
                        color: AppColors.borderColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Text(
                    t.sendTitle,
                    style: AppTypography.h4.copyWith(
                      color: AppColors.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSizes.spacingM),
                  if (buildings.isEmpty)
                    Text(
                      t.noBuilding,
                      textAlign: TextAlign.center,
                      style: AppTypography.body2.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    )
                  else ...[
                    DropdownButtonFormField<String>(
                      initialValue: _buildingId,
                      decoration: InputDecoration(
                        labelText: context.t.common.buildingName,
                        border: const OutlineInputBorder(),
                      ),
                      items: buildings
                          .map(
                            (b) => DropdownMenuItem(
                              value: b.id,
                              child: Text(b.name),
                            ),
                          )
                          .toList(),
                      onChanged: (id) => setState(() => _buildingId = id),
                      validator: (v) =>
                          v == null || v.isEmpty ? t.fieldRequired : null,
                    ),
                    const SizedBox(height: AppSizes.spacingM),
                    TextFormField(
                      controller: _titleController,
                      maxLength: 120,
                      decoration: InputDecoration(labelText: t.fieldTitle),
                      validator: (v) {
                        final s = v?.trim() ?? '';
                        if (s.isEmpty) return t.fieldRequired;
                        if (s.length > 120) return t.titleTooLong;
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSizes.spacingM),
                    TextFormField(
                      controller: _bodyController,
                      maxLines: 5,
                      maxLength: 2000,
                      decoration: InputDecoration(labelText: t.fieldBody),
                      validator: (v) {
                        final s = v?.trim() ?? '';
                        if (s.isEmpty) return t.fieldRequired;
                        if (s.length > 2000) return t.bodyTooLong;
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSizes.spacingXL),
                    FilledButton(
                      onPressed: _submitting ? null : _submit,
                      child: _submitting
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(t.sendButton),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final id = _buildingId;
    if (id == null) return;

    setState(() => _submitting = true);
    final result = await ref
        .read(notificationsNotifierProvider.notifier)
        .sendAnnouncement(
          id,
          title: _titleController.text.trim(),
          body: _bodyController.text.trim(),
        );
    if (!mounted) return;
    setState(() => _submitting = false);

    if (result != null) {
      ref.read(toastProvider.notifier).show(
            context.t.features.notifications.sendSuccess,
            type: ToastType.success,
          );
      Navigator.of(context).pop(true);
    } else {
      final err = ref.read(notificationsNotifierProvider).error;
      ref.read(toastProvider.notifier).show(
            err ?? context.t.features.notifications.sendFailed,
            type: ToastType.error,
          );
    }
  }
}
