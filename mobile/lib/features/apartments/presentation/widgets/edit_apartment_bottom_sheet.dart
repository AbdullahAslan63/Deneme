import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../l10n/strings.g.dart';
import '../../../../shared/widgets/toast_overlay.dart';
import '../../data/apartments_store.dart';
import '../../domain/entities/apartment_entity.dart';

/// Daire numarası ve katı düzenler.
/// Belge §6: PUT /buildings/:bId/apartments/:id body `number?`, `floor?`.
class EditApartmentBottomSheet extends ConsumerStatefulWidget {
  final ApartmentEntity apartment;

  const EditApartmentBottomSheet({super.key, required this.apartment});

  static Future<void> show(
    BuildContext context, {
    required ApartmentEntity apartment,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EditApartmentBottomSheet(apartment: apartment),
    );
  }

  @override
  ConsumerState<EditApartmentBottomSheet> createState() =>
      _EditApartmentBottomSheetState();
}

class _EditApartmentBottomSheetState
    extends ConsumerState<EditApartmentBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _numberController;
  late final TextEditingController _floorController;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _numberController = TextEditingController(text: widget.apartment.apartmentNumber);
    _floorController = TextEditingController(
      text: widget.apartment.floor?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _numberController.dispose();
    _floorController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final number = _numberController.text.trim();
    final floorRaw = _floorController.text.trim();
    final floor = floorRaw.isEmpty ? null : int.tryParse(floorRaw);

    final original = widget.apartment;
    final payloadNumber = number == original.apartmentNumber ? null : number;
    final payloadFloor = floor == original.floor ? null : floor;

    if (payloadNumber == null && payloadFloor == null) {
      if (mounted) Navigator.of(context).pop();
      return;
    }

    try {
      await ref
          .read(apartmentsStoreProvider(original.buildingId).notifier)
          .editApartment(
            apartmentId: original.id,
            number: payloadNumber,
            floor: payloadFloor,
          );
      if (!mounted) return;
      Navigator.of(context).pop();
      ref.read(toastProvider.notifier).show(
            context.t.common.apartmentUpdated,
            type: ToastType.success,
          );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ref.read(toastProvider.notifier).show(
            e.message.isNotEmpty
                ? e.message
                : context.t.common.apartmentUpdateFailed,
            type: ToastType.error,
          );
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ref.read(toastProvider.notifier).show(
            context.t.common.apartmentUpdateFailed,
            type: ToastType.error,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: AppSizes.screenBodyScrollPadding,
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
                      decoration: BoxDecoration(
                        color: AppColors.borderColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSizes.spacingM),
                  Text(
                    context.t.common.editApartment,
                    style: AppTypography.h3.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSizes.spacingL),
                  TextFormField(
                    controller: _numberController,
                    style: AppTypography.body1.copyWith(color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      labelText: context.t.common.apartmentNumberLabel,
                      prefixIcon: const Icon(
                        Icons.door_front_door_outlined,
                        color: AppColors.primary,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppSizes.inputRadius),
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return context.t.common.fieldRequired;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSizes.spacingM),
                  TextFormField(
                    controller: _floorController,
                    keyboardType: const TextInputType.numberWithOptions(signed: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^-?\d*')),
                    ],
                    style: AppTypography.body1.copyWith(color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      labelText: context.t.common.floorOptional,
                      prefixIcon: const Icon(
                        Icons.stairs_outlined,
                        color: AppColors.primary,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppSizes.inputRadius),
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return null;
                      final n = int.tryParse(v.trim());
                      if (n == null) {
                        return context.t.common.fieldRequired;
                      }
                      // Backend §6: floor -5..200 (validation şemasından).
                      if (n < -5 || n > 200) {
                        return context.t.common.fieldRequired;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSizes.spacingXL),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: AppSizes.buttonHeightPrimary,
                          child: OutlinedButton(
                            onPressed:
                                _saving ? null : () => Navigator.of(context).pop(),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.textPrimary,
                              side: const BorderSide(
                                color: AppColors.borderColor,
                                width: 1.5,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: Text(
                              context.t.common.cancelBtn,
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSizes.spacingM),
                      Expanded(
                        child: SizedBox(
                          height: AppSizes.buttonHeightPrimary,
                          child: ElevatedButton.icon(
                            onPressed: _saving ? null : _save,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                            ),
                            icon: _saving
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : const Icon(Icons.save_outlined),
                            label: Text(context.t.common.save),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
