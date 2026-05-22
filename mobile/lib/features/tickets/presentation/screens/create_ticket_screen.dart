import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../l10n/strings.g.dart';
import '../../../../shared/widgets/toast_overlay.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/ticket_entity.dart';
import '../providers/tickets_provider.dart';
import '../utils/ticket_labels.dart';

class CreateTicketScreen extends ConsumerStatefulWidget {
  const CreateTicketScreen({super.key});

  @override
  ConsumerState<CreateTicketScreen> createState() => _CreateTicketScreenState();
}

class _CreateTicketScreenState extends ConsumerState<CreateTicketScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  TicketCategory _category = TicketCategory.malfunction;
  bool _submitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t.features.tickets;

    return PopScope(
      canPop: !_submitting,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text(t.createTitle),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: _submitting ? null : () => context.pop(),
          ),
        ),
        body: SafeArea(
          child: AbsorbPointer(
            absorbing: _submitting,
            child: Form(
              key: _formKey,
              child: ListView(
                padding: AppSizes.screenBodyScrollPadding,
                children: [
                  _HeroHeader(title: t.createTitle),
                  const SizedBox(height: AppSizes.spacingL),
                  _SectionCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _ModernField(
                          controller: _titleController,
                          label: t.fieldTitle,
                          hint: t.fieldTitleHint,
                          icon: Icons.edit_note_rounded,
                          validator: (v) {
                            final raw = v?.trim() ?? '';
                            if (raw.isEmpty) {
                              return context.t.common.fieldRequired;
                            }
                            if (raw.length < 3) return t.titleTooShort;
                            return null;
                          },
                        ),
                        const SizedBox(height: AppSizes.spacingM),
                        _ModernField(
                          controller: _descriptionController,
                          label: t.fieldDescription,
                          hint: t.fieldDescriptionHint,
                          icon: Icons.subject_rounded,
                          maxLines: 5,
                          validator: (v) {
                            final raw = v?.trim() ?? '';
                            if (raw.isEmpty) {
                              return context.t.common.fieldRequired;
                            }
                            if (raw.length < 10) return t.descriptionTooShort;
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSizes.spacingL),
                  Text(
                    t.fieldCategory,
                    style: AppTypography.h4.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: AppSizes.spacingM),
                  _CategoryGrid(
                    selected: _category,
                    submitting: _submitting,
                    onSelected: (c) => setState(() => _category = c),
                  ),
                  const SizedBox(height: AppSizes.spacingXL),
                  SizedBox(
                    height: AppSizes.buttonHeightPrimary,
                    child: FilledButton.icon(
                      onPressed: _submitting ? null : _submit,
                      icon: _submitting
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.send_rounded),
                      label: Text(
                        t.submit,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
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
    final apartmentId = ref.read(authStateProvider).user?.apartmentId;
    if (apartmentId == null || apartmentId.isEmpty) {
      ref.read(toastProvider.notifier).show(
            context.t.features.tickets.apartmentRequired,
            type: ToastType.error,
          );
      return;
    }
    setState(() => _submitting = true);
    try {
      final ok = await ref.read(ticketsNotifierProvider.notifier).createTicket(
            apartmentId: apartmentId,
            title: _titleController.text,
            description: _descriptionController.text,
            category: _category,
          );
      if (!mounted) return;
      if (ok) {
        ref.read(toastProvider.notifier).show(
              context.t.features.tickets.createSuccess,
              type: ToastType.success,
            );
        context.pop(true);
      } else {
        final err = ref.read(ticketsNotifierProvider).error;
        ref.read(toastProvider.notifier).show(
              err ?? context.t.features.auth.errorOccurred,
              type: ToastType.error,
            );
      }
    } on ApiException catch (e) {
      if (mounted) {
        ref.read(toastProvider.notifier).show(e.message, type: ToastType.error);
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }
}

class _HeroHeader extends StatelessWidget {
  final String title;

  const _HeroHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.spacingM),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSizes.cardRadius),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.support_agent_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: AppSizes.spacingM),
          Expanded(
            child: Text(
              title,
              style: AppTypography.h3.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final Widget child;

  const _SectionCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.spacingM),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.cardRadius),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _ModernField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final int maxLines;
  final String? Function(String?)? validator;

  const _ModernField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.maxLines = 1,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      style: AppTypography.body1.copyWith(color: AppColors.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: AppColors.primary),
        filled: true,
        fillColor: AppColors.background,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.error),
        ),
      ),
      validator: validator,
    );
  }
}

class _CategoryGrid extends StatelessWidget {
  final TicketCategory selected;
  final bool submitting;
  final ValueChanged<TicketCategory> onSelected;

  const _CategoryGrid({
    required this.selected,
    required this.submitting,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSizes.spacingS,
      runSpacing: AppSizes.spacingS,
      children: TicketCategory.values.map((cat) {
        final isSelected = selected == cat;
        return SizedBox(
          width: (MediaQuery.sizeOf(context).width - 48) / 2,
          child: Material(
            color: isSelected
                ? AppColors.primary.withValues(alpha: 0.08)
                : AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              onTap: submitting ? null : () => onSelected(cat),
              borderRadius: BorderRadius.circular(14),
              child: Ink(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.border,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                padding: const EdgeInsets.symmetric(
                  vertical: AppSizes.spacingM,
                  horizontal: AppSizes.spacingS,
                ),
                child: Column(
                  children: [
                    Icon(
                      _iconFor(cat),
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textSecondary,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      cat.label(context),
                      textAlign: TextAlign.center,
                      style: AppTypography.caption.copyWith(
                        fontWeight:
                            isSelected ? FontWeight.w800 : FontWeight.w600,
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  IconData _iconFor(TicketCategory cat) {
    switch (cat) {
      case TicketCategory.complaint:
        return Icons.report_problem_outlined;
      case TicketCategory.request:
        return Icons.handyman_outlined;
      case TicketCategory.malfunction:
        return Icons.build_circle_outlined;
      case TicketCategory.other:
        return Icons.more_horiz_rounded;
    }
  }
}
