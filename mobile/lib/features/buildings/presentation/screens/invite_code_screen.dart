import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../l10n/strings.g.dart';
import '../../../../shared/widgets/toast_overlay.dart';
import '../../../apartments/data/apartments_store.dart';
import '../../../apartments/domain/entities/apartment_entity.dart';
import '../../data/invite_code_store.dart';
import '../../domain/entities/building_entity.dart';
import '../../utils/invite_code_helpers.dart';
import '../widgets/invite_code_result_view.dart';
import '../widgets/invite_confirm_dialogs.dart';
import '../widgets/invite_selectable_tile.dart';
import '../widgets/invite_step_indicator.dart';

/// Davet kodu üretme akışı (3 adım): Bina → Daire → Kod.
class InviteCodeScreen extends ConsumerStatefulWidget {
  final List<BuildingEntity> buildings;

  const InviteCodeScreen({
    super.key,
    required this.buildings,
  });

  @override
  ConsumerState<InviteCodeScreen> createState() => _InviteCodeScreenState();
}

class _InviteCodeScreenState extends ConsumerState<InviteCodeScreen> {
  int _step = 0;
  BuildingEntity? _selectedBuilding;
  ApartmentEntity? _selectedApartment;
  String? _generatedCode;
  DateTime? _activeExpiresAt;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(context.t.common.createInviteCode),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _onBackPressed,
        ),
      ),
      body: Column(
        children: [
          InviteStepIndicator(currentStep: _step),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: _buildStepContent(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_step) {
      case 0:
        return _BuildingPickerStep(
          key: const ValueKey('step-0'),
          buildings: widget.buildings,
          onPick: _onBuildingPicked,
        );
      case 1:
        final asyncApts =
            ref.watch(apartmentsStoreProvider(_selectedBuilding!.id));
        return asyncApts.when(
          loading: () =>
              const Center(key: ValueKey('step-1-loading'), child: CircularProgressIndicator()),
          error: (e, _) => Center(
            key: const ValueKey('step-1-error'),
            child: Text(e.toString()),
          ),
          data: (apartments) => _ApartmentPickerStep(
            key: const ValueKey('step-1'),
            building: _selectedBuilding!,
            apartments: apartments,
            onPick: _onApartmentSelected,
            activeCodes: ref.watch(inviteCodeStoreProvider),
          ),
        );
      case 2:
        return InviteCodeResultView(
          key: const ValueKey('step-2'),
          code: _generatedCode!,
          building: _selectedBuilding!,
          apartment: _selectedApartment!,
          expiresAt: _activeExpiresAt!,
          onCopy: () => _copyCode(_generatedCode!),
          onShare: () => _shareCode(),
          onRevoke: _confirmRevoke,
          onPickAnother: _resetFlow,
          onGoHome: () => context.pop(),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  // ---------- AKIŞ ----------
  void _onBuildingPicked(BuildingEntity b) {
    setState(() {
      _selectedBuilding = b;
      _selectedApartment = null;
      _step = 1;
    });
  }

  void _onApartmentSelected(ApartmentEntity apt) {
    final active = ref.read(inviteCodeStoreProvider.notifier).activeFor(apt.id);
    if (active != null) {
      _showActiveCode(apt, active);
      return;
    }
    if (apt.phone != null) {
      showDialog<void>(
        context: context,
        builder: (_) => OccupiedApartmentConfirmDialog(
          apartment: apt,
          onConfirm: () => _generateAndShow(apt),
        ),
      );
    } else {
      _generateAndShow(apt);
    }
  }

  void _showActiveCode(ApartmentEntity apt, ActiveInviteCode active) {
    setState(() {
      _selectedApartment = apt;
      _generatedCode = active.code;
      _activeExpiresAt = active.expiresAt;
      _step = 2;
    });
  }

  Future<void> _generateAndShow(ApartmentEntity apt) async {
    final active = await ref
        .read(inviteCodeStoreProvider.notifier)
        .generateInviteCode(apt.id);
    if (!mounted) return;
    if (active == null) {
      ref.read(toastProvider.notifier).show(
            'Davet kodu oluşturulamadı',
            type: ToastType.error,
          );
      return;
    }
    setState(() {
      _selectedApartment = apt;
      _generatedCode = active.code;
      _activeExpiresAt = active.expiresAt;
      _step = 2;
    });
  }

  void _confirmRevoke() {
    final apt = _selectedApartment!;
    showDialog<void>(
      context: context,
      builder: (_) => RevokeInviteCodeDialog(
        onConfirm: () {
          ref.read(inviteCodeStoreProvider.notifier).revoke(apt.id);
          ref
              .read(toastProvider.notifier)
              .show(context.t.common.codeRevoked, type: ToastType.success);
          _resetFlow();
        },
      ),
    );
  }

  void _resetFlow() {
    setState(() {
      _step = 0;
      _selectedBuilding = null;
      _selectedApartment = null;
      _generatedCode = null;
      _activeExpiresAt = null;
    });
  }

  void _onBackPressed() {
    if (_step == 0) {
      Navigator.pop(context);
    } else if (_step == 1) {
      setState(() {
        _step = 0;
        _selectedBuilding = null;
      });
    } else {
      setState(() {
        _step = 1;
        _selectedApartment = null;
        _generatedCode = null;
        _activeExpiresAt = null;
      });
    }
  }

  // ---------- AKSİYONLAR ----------
  void _copyCode(String code) {
    Clipboard.setData(ClipboardData(text: code));
    ref
        .read(toastProvider.notifier)
        .show('${context.t.common.codeCopied}: $code', type: ToastType.success);
  }

  Future<void> _shareCode() async {
    final message = InviteCodeHelpers.buildShareMessage(
      code: _generatedCode!,
      building: _selectedBuilding!,
      apartment: _selectedApartment!,
      expiresAt: _activeExpiresAt!,
    );

    try {
      final box = context.findRenderObject() as RenderBox?;
      await SharePlus.instance.share(
        ShareParams(
          text: message,
          subject: 'AidatPanel Davet Kodu',
          sharePositionOrigin: box != null
              ? box.localToGlobal(Offset.zero) & box.size
              : null,
        ),
      );
    } catch (_) {
      Clipboard.setData(ClipboardData(text: message));
      if (mounted) {
        ref
            .read(toastProvider.notifier)
            .show(context.t.common.clipboardCopied, type: ToastType.info);
      }
    }
  }
}

// ============================================================================
//  ADIM 1: BİNA SEÇİMİ
// ============================================================================
class _BuildingPickerStep extends StatelessWidget {
  final List<BuildingEntity> buildings;
  final ValueChanged<BuildingEntity> onPick;

  const _BuildingPickerStep({
    super.key,
    required this.buildings,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    // OPTIMIZATION: ListView.builder kullanılıyor (lazy loading)
    // Büyük bina listelerinde memory efficient, scroll performance artar
    return ListView.builder(
      padding: AppSizes.screenBodyScrollPadding,
      itemCount: buildings.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSizes.spacingM),
            child: Text(
              context.t.common.whichBuildingForCode,
              style: AppTypography.h4.copyWith(color: AppColors.textPrimary),
            ),
          );
        }
        final b = buildings[index - 1];
        return InviteSelectableTile(
          icon: Icons.apartment,
          iconColor: AppColors.primary,
          title: b.name,
          subtitle: b.displayAddress,
          onTap: () => onPick(b),
        );
      },
    );
  }
}

// ============================================================================
//  ADIM 2: DAİRE SEÇİMİ
// ============================================================================
class _ApartmentPickerStep extends StatelessWidget {
  final BuildingEntity building;
  final List<ApartmentEntity> apartments;
  final Map<String, ActiveInviteCode> activeCodes;
  final ValueChanged<ApartmentEntity> onPick;

  const _ApartmentPickerStep({
    super.key,
    required this.building,
    required this.apartments,
    required this.activeCodes,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    // OPTIMIZATION: ListView.builder kullanılıyor (lazy loading)
    // 50+ daireli binalarda scroll lag ve memory spike'ı önler
    // 50+ yaş kullanıcılar için kritik performans iyileştirmesi
    if (apartments.isEmpty) {
      final emptyItems = <Widget>[
        _buildBuildingBanner(),
        const SizedBox(height: AppSizes.spacingL),
        Text(
          context.t.common.whichApartmentForCode,
          style: AppTypography.h4.copyWith(color: AppColors.textPrimary),
        ),
        const SizedBox(height: AppSizes.spacingM),
        _buildEmptyState(context),
      ];
      return ListView.builder(
        padding: AppSizes.screenBodyScrollPadding,
        itemCount: emptyItems.length,
        itemBuilder: (_, i) => emptyItems[i],
      );
    }

    // Header: banner + başlık (2 sabit item)
    // Items: apartments
    const headerCount = 3;
    return ListView.builder(
      padding: AppSizes.screenBodyScrollPadding,
      itemCount: apartments.length + headerCount,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSizes.spacingL),
            child: _buildBuildingBanner(),
          );
        }
        if (index == 1) {
          return Text(
            context.t.common.whichApartmentForCode,
            style: AppTypography.h4.copyWith(color: AppColors.textPrimary),
          );
        }
        if (index == 2) {
          return const SizedBox(height: AppSizes.spacingM);
        }
        final apt = apartments[index - headerCount];
        return _buildApartmentTile(context, apt);
      },
    );
  }

  Widget _buildBuildingBanner() {
    return Container(
      padding: const EdgeInsets.all(AppSizes.spacingM),
      decoration: BoxDecoration(
        color: AppColors.primaryLight.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.apartment, color: AppColors.primary),
          const SizedBox(width: AppSizes.spacingS),
          Expanded(
            child: Text(
              building.name,
              style: AppTypography.body1.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApartmentTile(BuildContext context, ApartmentEntity apt) {
    final isOccupied = apt.phone != null;
    final activeCode = activeCodes[apt.id];
    final hasActiveCode = activeCode != null && !activeCode.isExpired;

    final tileIcon = hasActiveCode
        ? Icons.qr_code_2
        : Icons.door_front_door_outlined;
    final tileColor = hasActiveCode
        ? AppColors.accent
        : (isOccupied ? AppColors.textSecondary : AppColors.success);
    final subtitle = hasActiveCode
        ? '${context.t.common.activeCodePrefix}: ${activeCode.code} • ${InviteCodeHelpers.remainingText(activeCode.remaining)}'
        : (isOccupied
              ? '${context.t.common.residentPrefix}: ${apt.residentName}'
              : context.t.common.emptyApartment);

    return InviteSelectableTile(
      icon: tileIcon,
      iconColor: tileColor,
      title: InviteCodeHelpers.formatApartmentLabel(apt.apartmentNumber),
      subtitle: subtitle,
      trailing: _StatusBadge(
        hasActiveCode: hasActiveCode,
        isOccupied: isOccupied,
      ),
      onTap: () => onPick(apt),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.spacingXL),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Column(
        children: [
          Icon(
            Icons.door_back_door_outlined,
            size: 56,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: AppSizes.spacingM),
          Text(
            context.t.common.noApartmentsInBuilding,
            style: AppTypography.body1.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final bool hasActiveCode;
  final bool isOccupied;

  const _StatusBadge({required this.hasActiveCode, required this.isOccupied});

  @override
  Widget build(BuildContext context) {
    final (label, color) = _resolveBadge(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: AppTypography.caption.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  (String, Color) _resolveBadge(BuildContext context) {
    if (hasActiveCode) {
      return (context.t.common.activeCodeBadge, AppColors.accent);
    }
    if (isOccupied) return (context.t.common.occupiedBadge, AppColors.warning);
    return (context.t.common.emptyBadge, AppColors.success);
  }
}
