import 'dart:math' show max, min;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../l10n/strings.g.dart';
import '../../../../shared/widgets/toast_overlay.dart';
import '../../../apartments/data/apartments_store.dart';
import '../../../apartments/domain/entities/apartment_entity.dart';
import '../../../apartments/presentation/widgets/delete_apartment_dialog.dart';
import '../../../apartments/presentation/widgets/edit_apartment_bottom_sheet.dart';
import '../../../apartments/presentation/widgets/remove_resident_dialog.dart';
import '../../domain/entities/building_entity.dart';

/// Alt sayfa kapatıldıktan sonra dialog / sheet açılması için.
void _afterApartmentSheetClosed(
  BuildContext pageContext,
  BuildContext sheetContext,
  VoidCallback action,
) {
  Navigator.of(sheetContext).pop();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (pageContext.mounted) action();
  });
}

class BuildingResidentsScreen extends ConsumerStatefulWidget {
  final BuildingEntity building;

  const BuildingResidentsScreen({super.key, required this.building});

  @override
  ConsumerState<BuildingResidentsScreen> createState() =>
      _BuildingResidentsScreenState();
}

class _BuildingResidentsScreenState
    extends ConsumerState<BuildingResidentsScreen> {
  bool _selectionMode = false;
  final Set<String> _selectedApartmentIds = <String>{};

  void _exitSelectionMode() {
    setState(() {
      _selectionMode = false;
      _selectedApartmentIds.clear();
    });
  }

  void _toggleApartmentSelection(ApartmentEntity apt) {
    if (!apt.isOccupied) return;
    setState(() {
      if (_selectedApartmentIds.contains(apt.id)) {
        _selectedApartmentIds.remove(apt.id);
      } else {
        _selectedApartmentIds.add(apt.id);
      }
    });
  }

  String _humanizeRemoveResident(ApiException e) {
    final raw = e.message.toLowerCase();
    if (raw.contains('forbidden') ||
        raw.contains('not the manager') ||
        raw.contains('yetk')) {
      return context.t.common.residentRemoveForbidden;
    }
    if (raw.contains('not found') ||
        raw.contains('no resident') ||
        raw.contains('bulunam')) {
      return context.t.common.residentRemoveNotFound;
    }
    return e.message.isNotEmpty
        ? e.message
        : context.t.common.residentRemoveFailed;
  }

  /// Çoklu çıkarma onayında gösterilecek sıra: kullanıcının seçim sırası.
  List<ApartmentEntity> _selectedApartmentsOrdered(List<String> ids) {
    final all = ref.read(apartmentsStoreProvider(widget.building.id)).value;
    if (all == null) return const [];
    final byId = {for (final a in all) a.id: a};
    return [
      for (final id in ids)
        if (byId[id] != null) byId[id]!,
    ];
  }

  Future<void> _confirmAndRemoveSelected() async {
    final ids = List<String>.from(_selectedApartmentIds);
    if (ids.isEmpty) {
      ref
          .read(toastProvider.notifier)
          .show(context.t.common.pickResidentsFirst, type: ToastType.info);
      return;
    }
    final apartmentsForDialog = _selectedApartmentsOrdered(ids);
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        final screenH = MediaQuery.sizeOf(dialogContext).height;
        final listMaxHeight = (screenH * 0.38).clamp(140.0, 320.0);

        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.cardRadius),
          ),
          title: Text(
            dialogContext.t.common.removeSelectedResidentsTitle,
            style: AppTypography.h3.copyWith(color: AppColors.textPrimary),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dialogContext.t.common.removeSelectedResidentsMessage,
                  style: AppTypography.body1.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSizes.spacingM),
                Text(
                  dialogContext
                      .t
                      .common
                      .removeSelectedResidentsAffectedListTitle,
                  style: AppTypography.body1.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSizes.spacingS),
                if (apartmentsForDialog.isEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dialogContext
                            .t
                            .common
                            .removeSelectedResidentsListUnavailable,
                        style: AppTypography.body1.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppSizes.spacingS),
                      Text(
                        '${ids.length}',
                        style: AppTypography.h3.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  )
                else
                  SizedBox(
                    height: min(
                      listMaxHeight,
                      max(100.0, 64.0 * apartmentsForDialog.length + 32),
                    ),
                    child: ListView.builder(
                      physics: const ClampingScrollPhysics(),
                      itemCount: apartmentsForDialog.length,
                      itemBuilder: (ctx, i) {
                        final apt = apartmentsForDialog[i];
                        final label = _formatApartmentLabel(
                          dialogContext,
                          apt.apartmentNumber,
                        );
                        final name = apt.resident?.name ?? apt.residentName;
                        return Padding(
                          padding: EdgeInsets.only(
                            bottom: i < apartmentsForDialog.length - 1
                                ? AppSizes.spacingM
                                : 0,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (i > 0) ...[
                                Divider(
                                  height: 1,
                                  color: AppColors.borderColor,
                                ),
                                const SizedBox(height: AppSizes.spacingM),
                              ],
                              Text(
                                label,
                                style: AppTypography.body1.copyWith(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                name,
                                style: AppTypography.body1.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            OutlinedButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textPrimary,
                side: const BorderSide(color: AppColors.borderColor, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                minimumSize: const Size(48, 48),
              ),
              child: Text(
                dialogContext.t.common.cancelBtn,
                style: AppTypography.button.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.warning,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                minimumSize: const Size(48, 48),
              ),
              child: Text(dialogContext.t.common.removeSelectedResidents),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !mounted) return;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (progressContext) {
        return PopScope(
          canPop: false,
          child: AlertDialog(
            content: Row(
              children: [
                const SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: AppSizes.spacingM),
                Expanded(
                  child: Text(
                    progressContext.t.common.removeSelectedProgress,
                    style: AppTypography.body1,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    try {
      final notifier = ref.read(
        apartmentsStoreProvider(widget.building.id).notifier,
      );
      for (final id in ids) {
        await notifier.removeResidentFromApartment(id);
      }
      if (mounted) {
        Navigator.of(context).pop();
        _exitSelectionMode();
        ref
            .read(toastProvider.notifier)
            .show(
              context.t.common.removeSelectedSuccess,
              type: ToastType.success,
            );
      }
    } on ApiException catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        ref
            .read(toastProvider.notifier)
            .show(
              _humanizeRemoveResident(e),
              type: ToastType.error,
              duration: const Duration(seconds: 6),
            );
      }
    } catch (_) {
      if (mounted) {
        Navigator.of(context).pop();
        ref
            .read(toastProvider.notifier)
            .show(context.t.common.removeSelectedFailed, type: ToastType.error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncApartments = ref.watch(
      apartmentsStoreProvider(widget.building.id),
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(context.t.common.buildingDetail),
        centerTitle: true,
      ),
      body: asyncApartments.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: AppSizes.spacingM),
              Text(
                e.toString(),
                style: AppTypography.body1.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSizes.spacingM),
              ElevatedButton(
                onPressed: () => ref
                    .read(apartmentsStoreProvider(widget.building.id).notifier)
                    .loadApartments(),
                child: Text(context.t.features.buildings.tekrarDene),
              ),
            ],
          ),
        ),
        data: (residents) => SingleChildScrollView(
          padding: AppSizes.screenBodyScrollPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(widget.building),
              const SizedBox(height: AppSizes.spacingL),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    context.t.common.residents,
                    style: AppTypography.h3.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.spacingS,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.18),
                      ),
                    ),
                    child: Text(
                      '${residents.length} ${context.t.common.apartmentsBadge}',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              if (residents.any((a) => a.isOccupied)) ...[
                const SizedBox(height: AppSizes.spacingS),
                if (!_selectionMode)
                  SizedBox(
                    width: double.infinity,
                    height: AppSizes.minTouchTarget,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => setState(() {
                          _selectionMode = true;
                          _selectedApartmentIds.clear();
                        }),
                        borderRadius: BorderRadius.circular(
                          AppSizes.buttonRadius,
                        ),
                        child: Ink(
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(
                              AppSizes.buttonRadius,
                            ),
                            border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.22),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.checklist_rtl,
                                size: 22,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                context.t.common.multiSelectResidents,
                                style: AppTypography.body1.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  )
                else ...[
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: AppSizes.minTouchTarget,
                          child: OutlinedButton(
                            onPressed: _exitSelectionMode,
                            child: Text(context.t.common.cancelBtn),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSizes.spacingM),
                      Expanded(
                        flex: 2,
                        child: SizedBox(
                          height: AppSizes.minTouchTarget,
                          child: FilledButton(
                            onPressed: _selectedApartmentIds.isEmpty
                                ? null
                                : _confirmAndRemoveSelected,
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.error,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: AppColors.error
                                  .withValues(alpha: 0.38),
                              disabledForegroundColor: Colors.white
                                  .withValues(alpha: 0.62),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: Text(
                              '${context.t.common.removeSelectedResidents}'
                              '${_selectedApartmentIds.isEmpty ? '' : ' (${_selectedApartmentIds.length})'}',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
              const SizedBox(height: AppSizes.spacingM),
              if (residents.isEmpty)
                _buildEmptyState(context)
              else
                ...residents.asMap().entries.map(
                  (entry) =>
                      _buildResidentCard(context, entry.key + 1, entry.value),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildingEntity building) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.spacingM),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.cardRadius),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primary.withValues(alpha: 0.18),
                  AppColors.primaryLight.withValues(alpha: 0.12),
                ],
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.18),
              ),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.apartment_rounded,
              color: AppColors.primary,
              size: 28,
            ),
          ),
          const SizedBox(width: AppSizes.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  building.name,
                  style: AppTypography.h3.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        building.displayAddress,
                        style: AppTypography.body2.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResidentCard(
    BuildContext context,
    int index,
    ApartmentEntity apt,
  ) {
    // ApartmentEntity.isOccupied: backend'den dönen `resident` objesinin
    // null olup olmadığına bakar. Telefon paylaşmamış sakinler de "boş"
    // görünmesin diye `apt.phone != null` yerine bunu kullanıyoruz.
    final isOccupied = apt.isOccupied;
    final statusInfo = _getStatusInfo(context, apt.paymentStatus);
    final showSelection = _selectionMode && isOccupied;
    final selected = _selectedApartmentIds.contains(apt.id);

    // Boş daire kartı için soluk bir görünüm: yönetici tarafında "burada
    // henüz sakin yok" mesajının ilk bakışta okunabilmesi için arka plan
    // ve kenarlık tonu hafifçe değiştiriliyor.
    final cardColor = isOccupied
        ? AppColors.surface
        : AppColors.background.withValues(alpha: 0.6);
    final borderColor = isOccupied
        ? AppColors.borderColor
        : AppColors.borderColor.withValues(alpha: 0.5);
    final effectiveBorderColor = showSelection && selected
        ? AppColors.primary
        : borderColor;

    final card = Container(
      margin: const EdgeInsets.only(bottom: AppSizes.spacingM),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(AppSizes.cardRadius),
        border: Border.all(
          color: effectiveBorderColor,
          width: showSelection && selected ? 2 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.spacingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (showSelection) ...[
                  SizedBox(
                    width: AppSizes.minTouchTarget,
                    height: AppSizes.minTouchTarget,
                    child: Icon(
                      selected
                          ? Icons.check_box
                          : Icons.check_box_outline_blank,
                      color: selected
                          ? AppColors.primary
                          : AppColors.textSecondary,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: AppSizes.spacingS),
                ],
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isOccupied
                        ? AppColors.primaryLight.withValues(alpha: 0.15)
                        : AppColors.borderColor.withValues(alpha: 0.4),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: isOccupied
                      ? Text(
                          '$index',
                          style: AppTypography.body1.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        )
                      : Icon(
                          Icons.person_off_outlined,
                          size: 22,
                          color: AppColors.textSecondary,
                        ),
                ),
                const SizedBox(width: AppSizes.spacingM),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _formatApartmentLabel(context, apt.apartmentNumber),
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isOccupied
                            ? apt.residentName
                            : context.t.common.emptyApartmentText,
                        style: AppTypography.body1.copyWith(
                          color: isOccupied
                              ? AppColors.textPrimary
                              : AppColors.textSecondary,
                          fontWeight: FontWeight.w700,
                          fontStyle: isOccupied
                              ? FontStyle.normal
                              : FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isOccupied)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusInfo.bgColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      statusInfo.label,
                      style: AppTypography.caption.copyWith(
                        color: statusInfo.color,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.borderColor.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      context.t.common.vacantBadge,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
            // Alt satır: "Detaylar.." → daire / sakin bilgisi ve işlemler alt sayfası.
            const SizedBox(height: AppSizes.spacingM),
            Container(height: 1, color: borderColor),
            const SizedBox(height: AppSizes.spacingM),
            if (showSelection)
              Row(
                children: [
                  Expanded(
                    child: Text(
                      context.t.common.multiSelectTapHint,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.body2.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  Text(
                    '₺${apt.monthlyDues.toStringAsFixed(0)}${context.t.common.perMonth}',
                    style: AppTypography.body2.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              )
            else
              Row(
                children: [
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: isOccupied
                          ? () =>
                              _showApartmentDetailsBottomSheet(context, apt)
                          : null,
                      borderRadius: BorderRadius.circular(
                        AppSizes.buttonRadius,
                      ),
                      child: Ink(
                        decoration: BoxDecoration(
                          color: isOccupied
                              ? AppColors.surface
                              : AppColors.borderColor.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(
                            AppSizes.buttonRadius,
                          ),
                          border: Border.all(
                            color: isOccupied
                                ? AppColors.primary.withValues(alpha: 0.22)
                                : AppColors.borderColor.withValues(alpha: 0.6),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSizes.spacingM,
                            vertical: AppSizes.spacingS,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.info_outline_rounded,
                                size: 18,
                                color: isOccupied
                                    ? AppColors.primary
                                    : AppColors.textSecondary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                context.t.common.residentDetailsLink,
                                style: AppTypography.body1.copyWith(
                                  color: isOccupied
                                      ? AppColors.primary
                                      : AppColors.textSecondary,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '₺${apt.monthlyDues.toStringAsFixed(0)}',
                        style: AppTypography.body1.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        context.t.common.perMonth
                            .trim()
                            .replaceAll('/', '')
                            .trim(),
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
          ],
        ),
      ),
    );

    if (showSelection) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppSizes.cardRadius),
          onTap: () => _toggleApartmentSelection(apt),
          child: card,
        ),
      );
    }
    return card;
  }

  void _showApartmentDetailsBottomSheet(
    BuildContext context,
    ApartmentEntity apt,
  ) {
    final isOccupied = apt.isOccupied;
    final resident = apt.resident;
    final statusInfo = _getStatusInfo(context, apt.paymentStatus);
    final phoneText = apt.phone != null
        ? _formatPhone(apt.phone!)
        : context.t.common.phoneNotShared;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        final bottomInset = MediaQuery.paddingOf(sheetContext).bottom;
        final screenH = MediaQuery.sizeOf(sheetContext).height;
        final maxSheetH = screenH * 0.85;

        return Container(
          constraints: BoxConstraints(maxHeight: maxSheetH),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSizes.spacingS),
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: AppColors.borderColor,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              // Header bar: başlık + sağda kapatma ikonu
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSizes.spacingL,
                  AppSizes.spacingM,
                  AppSizes.spacingS,
                  AppSizes.spacingS,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        isOccupied
                            ? context.t.common.residentDetailsSheetTitle
                            : context.t.common.apartmentDetailsSheetTitle,
                        style: AppTypography.h3.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    InkResponse(
                      onTap: () => Navigator.of(sheetContext).pop(),
                      radius: 24,
                      child: Container(
                        width: AppSizes.minTouchTarget,
                        height: AppSizes.minTouchTarget,
                        alignment: Alignment.center,
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.close_rounded,
                            size: 22,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    AppSizes.spacingL,
                    0,
                    AppSizes.spacingL,
                    AppSizes.spacingM,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildSheetHero(
                        context: context,
                        apt: apt,
                        statusInfo: statusInfo,
                      ),
                      const SizedBox(height: AppSizes.spacingM),
                      _buildStatGrid(context: context, apt: apt),
                      if (isOccupied && resident != null) ...[
                        const SizedBox(height: AppSizes.spacingM),
                        _buildContactCard(
                          context: context,
                          email: resident.email,
                          phone: phoneText,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  AppSizes.spacingL,
                  AppSizes.spacingS,
                  AppSizes.spacingL,
                  AppSizes.spacingM + bottomInset,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: AppSizes.minTouchTargetComfort,
                        child: FilledButton.icon(
                          onPressed: () => _afterApartmentSheetClosed(
                            context,
                            sheetContext,
                            () => EditApartmentBottomSheet.show(
                              context,
                              apartment: apt,
                            ),
                          ),
                          icon: const Icon(Icons.edit_outlined, size: 20),
                          label: Text(
                            context.t.common.editApartment,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                AppSizes.buttonRadius,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSizes.spacingS),
                    Expanded(
                      child: SizedBox(
                        height: AppSizes.minTouchTargetComfort,
                        child: isOccupied
                            ? FilledButton.icon(
                                onPressed: () => _afterApartmentSheetClosed(
                                  context,
                                  sheetContext,
                                  () => RemoveResidentDialog.show(
                                    context,
                                    apartment: apt,
                                  ),
                                ),
                                icon: const Icon(
                                  Icons.person_remove_outlined,
                                  size: 20,
                                ),
                                label: Text(
                                  context.t.common.removeResident,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                ),
                                style: FilledButton.styleFrom(
                                  backgroundColor: AppColors.warning,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                      AppSizes.buttonRadius,
                                    ),
                                  ),
                                ),
                              )
                            : FilledButton.icon(
                                onPressed: () => _afterApartmentSheetClosed(
                                  context,
                                  sheetContext,
                                  () => DeleteApartmentDialog.show(
                                    context,
                                    apartment: apt,
                                  ),
                                ),
                                icon: const Icon(
                                  Icons.delete_outline,
                                  size: 20,
                                ),
                                label: Text(
                                  context.t.common.deleteApartment,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                ),
                                style: FilledButton.styleFrom(
                                  backgroundColor: AppColors.error,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                      AppSizes.buttonRadius,
                                    ),
                                  ),
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Modern hero başlığı: büyük avatar + isim + durum etiketi + daire çipi.
  Widget _buildSheetHero({
    required BuildContext context,
    required ApartmentEntity apt,
    required _StatusInfo statusInfo,
  }) {
    final isOccupied = apt.isOccupied;
    final resident = apt.resident;
    final apartmentLabel = _formatApartmentLabel(context, apt.apartmentNumber);

    return Container(
      padding: const EdgeInsets.all(AppSizes.spacingM),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withValues(alpha: 0.06),
            AppColors.primaryLight.withValues(alpha: 0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(AppSizes.cardRadius),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.10)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isOccupied
                    ? [
                        AppColors.primary.withValues(alpha: 0.18),
                        AppColors.primaryLight.withValues(alpha: 0.12),
                      ]
                    : [
                        AppColors.borderColor.withValues(alpha: 0.6),
                        AppColors.borderColor.withValues(alpha: 0.3),
                      ],
              ),
              shape: BoxShape.circle,
              border: Border.all(
                color: isOccupied
                    ? AppColors.primary.withValues(alpha: 0.18)
                    : AppColors.borderColor,
                width: 1.5,
              ),
            ),
            alignment: Alignment.center,
            child: isOccupied && resident != null
                ? Text(
                    _initialsFromName(resident.name),
                    style: AppTypography.h2.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  )
                : Icon(
                    Icons.home_work_outlined,
                    color: AppColors.textSecondary,
                    size: 34,
                  ),
          ),
          const SizedBox(width: AppSizes.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isOccupied && resident != null
                      ? resident.name
                      : context.t.common.emptyApartmentText,
                  style: AppTypography.h3.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSizes.spacingXS),
                Wrap(
                  spacing: AppSizes.spacingXS,
                  runSpacing: AppSizes.spacingXS,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.borderColor),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            size: 14,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            apartmentLabel,
                            style: AppTypography.caption.copyWith(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isOccupied)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: statusInfo.bgColor,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          statusInfo.label,
                          style: AppTypography.caption.copyWith(
                            color: statusInfo.color,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.borderColor.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          context.t.common.vacantBadge,
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 3 mini stat kartı: Aidat / Bakiye / Son ödeme (varsa).
  Widget _buildStatGrid({
    required BuildContext context,
    required ApartmentEntity apt,
  }) {
    final tiles = <Widget>[
      _SheetStatTile(
        icon: Icons.receipt_long_outlined,
        label: context.t.common.monthlyDues,
        value: '₺${apt.monthlyDues.toStringAsFixed(0)}',
        tint: AppColors.primary,
      ),
      _SheetStatTile(
        icon: Icons.account_balance_wallet_outlined,
        label: context.t.common.balance,
        value: '₺${apt.balance.toStringAsFixed(0)}',
        tint: apt.balance > 0 ? AppColors.error : AppColors.success,
      ),
      if (apt.lastPaymentDate != null)
        _SheetStatTile(
          icon: Icons.event_available_outlined,
          label: context.t.common.lastPayment,
          value: _formatShortDate(apt.lastPaymentDate!),
          tint: AppColors.info,
        )
      else
        _SheetStatTile(
          icon: Icons.event_busy_outlined,
          label: context.t.common.lastPayment,
          value: '—',
          tint: AppColors.textSecondary,
        ),
    ];

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < tiles.length; i++) ...[
            if (i > 0) const SizedBox(width: AppSizes.spacingS),
            Expanded(child: tiles[i]),
          ],
        ],
      ),
    );
  }

  /// İletişim kartı: e-posta + telefon, ikon liderli satırlar.
  Widget _buildContactCard({
    required BuildContext context,
    required String email,
    required String phone,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.cardRadius),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Column(
        children: [
          _SheetContactRow(
            icon: Icons.mail_outline_rounded,
            label: context.t.features.auth.email,
            value: email,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.spacingM),
            child: Divider(height: 1, color: AppColors.borderColor),
          ),
          _SheetContactRow(
            icon: Icons.phone_outlined,
            label: context.t.features.auth.phone,
            value: phone,
          ),
        ],
      ),
    );
  }

  String _initialsFromName(String name) {
    final parts = name.trim().split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts.isNotEmpty ? parts[0][0].toUpperCase() : '?';
  }

  String _formatShortDate(DateTime d) {
    final day = d.day.toString().padLeft(2, '0');
    final month = d.month.toString().padLeft(2, '0');
    return '$day.$month.${d.year}';
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.spacingXL),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Column(
        children: [
          Icon(Icons.people_outline, size: 56, color: AppColors.textSecondary),
          const SizedBox(height: AppSizes.spacingM),
          Text(
            context.t.common.noApartmentsYet,
            style: AppTypography.body1.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  String _formatApartmentLabel(BuildContext context, String apartmentNumber) {
    final match = RegExp(r'(\d+)([A-Za-z]?)').firstMatch(apartmentNumber);
    if (match == null) return apartmentNumber;
    final floor = match.group(1);
    final letter = match.group(2);
    if (letter != null && letter.isNotEmpty) {
      return '$floor. ${context.t.common.floorLabel} • ${context.t.common.apartmentLabel} $letter';
    }
    return '$floor. ${context.t.common.floorLabel}';
  }

  String _formatPhone(String phone) {
    final clean = phone.replaceAll(RegExp(r'[^\d+]'), '');
    if (clean.startsWith('+90') && clean.length == 13) {
      return '+90 ${clean.substring(3, 6)} ${clean.substring(6, 9)} ${clean.substring(9, 11)} ${clean.substring(11)}';
    }
    return phone;
  }

  _StatusInfo _getStatusInfo(BuildContext context, PaymentStatus status) {
    switch (status) {
      case PaymentStatus.paid:
        return _StatusInfo(
          label: context.t.common.paidStatus,
          color: AppColors.success,
          bgColor: AppColors.success.withValues(alpha: 0.12),
        );
      case PaymentStatus.pending:
        return _StatusInfo(
          label: context.t.common.pendingStatus,
          color: AppColors.warning,
          bgColor: AppColors.warning.withValues(alpha: 0.12),
        );
      case PaymentStatus.overdue:
        return _StatusInfo(
          label: context.t.common.overdueStatus,
          color: AppColors.error,
          bgColor: AppColors.error.withValues(alpha: 0.12),
        );
    }
  }
}

/// Modern stat kartı (Aidat / Bakiye / Son ödeme).
class _SheetStatTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color tint;

  const _SheetStatTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.tint,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.spacingS),
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppSizes.cardRadius),
        border: Border.all(color: tint.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: tint.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 18, color: tint),
          ),
          const SizedBox(height: AppSizes.spacingS),
          Text(
            label,
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: AppTypography.body1.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

/// İkon liderli iletişim satırı.
class _SheetContactRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _SheetContactRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.spacingM,
        vertical: AppSizes.spacingS,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: AppSizes.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: AppTypography.body1.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusInfo {
  final String label;
  final Color color;
  final Color bgColor;

  _StatusInfo({
    required this.label,
    required this.color,
    required this.bgColor,
  });
}
