import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_sizes.dart';
import '../../core/theme/app_typography.dart';

enum ToastType { info, success, error, warning }

class ToastMessage {
  final String id;
  final String message;
  final ToastType type;
  final bool exiting;

  const ToastMessage({
    required this.id,
    required this.message,
    required this.type,
    this.exiting = false,
  });

  ToastMessage copyWith({bool? exiting}) {
    return ToastMessage(
      id: id,
      message: message,
      type: type,
      exiting: exiting ?? this.exiting,
    );
  }
}

class ToastNotifier extends StateNotifier<List<ToastMessage>> {
  ToastNotifier() : super([]);

  static const int maxVisible = 3;
  static const Duration displayDuration = Duration(seconds: 3);
  static const Duration fadeDuration = Duration(milliseconds: 300);

  int _idCounter = 0;

  void show(
    String message, {
    ToastType type = ToastType.info,
    Duration? duration,
  }) {
    final id = '${DateTime.now().millisecondsSinceEpoch}_${_idCounter++}';
    final toast = ToastMessage(id: id, message: message, type: type);

    state = [...state, toast];

    if (state.where((t) => !t.exiting).length > maxVisible) {
      final oldest = state.firstWhere((t) => !t.exiting);
      _markAsExiting(oldest.id);
    }

    final visibleFor = duration ?? displayDuration;
    Future.delayed(visibleFor, () {
      _markAsExiting(id);
    });
  }

  void _markAsExiting(String id) {
    if (!state.any((t) => t.id == id && !t.exiting)) return;

    state = [
      for (final t in state)
        if (t.id == id) t.copyWith(exiting: true) else t,
    ];

    Future.delayed(fadeDuration, () {
      state = state.where((t) => t.id != id).toList();
    });
  }

  void dismiss(String id) => _markAsExiting(id);
}

final toastProvider =
    StateNotifierProvider<ToastNotifier, List<ToastMessage>>(
      (ref) => ToastNotifier(),
    );

class ToastOverlay extends ConsumerWidget {
  final Widget child;

  const ToastOverlay({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final toasts = ref.watch(toastProvider);

    return Stack(
      children: [
        child,
        if (toasts.isNotEmpty)
          Positioned(
            left: AppSizes.spacingM,
            right: AppSizes.spacingM,
            bottom: AppSizes.spacingL,
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  for (final toast in toasts)
                    _ToastItem(
                      key: ValueKey(toast.id),
                      toast: toast,
                      onTap: () =>
                          ref.read(toastProvider.notifier).dismiss(toast.id),
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _ToastItem extends StatefulWidget {
  final ToastMessage toast;
  final VoidCallback onTap;

  const _ToastItem({super.key, required this.toast, required this.onTap});

  @override
  State<_ToastItem> createState() => _ToastItemState();
}

class _ToastItemState extends State<_ToastItem> {
  bool _entered = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _entered = true);
    });
  }

  IconData get _icon {
    switch (widget.toast.type) {
      case ToastType.success:
        return Icons.check_circle_outline;
      case ToastType.error:
        return Icons.error_outline;
      case ToastType.warning:
        return Icons.warning_amber_outlined;
      case ToastType.info:
        return Icons.info_outline;
    }
  }

  Color get _accentColor {
    switch (widget.toast.type) {
      case ToastType.success:
        return AppColors.success;
      case ToastType.error:
        return AppColors.error;
      case ToastType.warning:
        return AppColors.warning;
      case ToastType.info:
        return AppColors.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isExiting = widget.toast.exiting;
    final visible = _entered && !isExiting;

    return AnimatedOpacity(
      opacity: visible ? 1 : 0,
      duration: ToastNotifier.fadeDuration,
      curve: Curves.easeOut,
      child: AnimatedSlide(
        offset: visible
            ? Offset.zero
            : (isExiting ? const Offset(0, -0.2) : const Offset(0, 0.3)),
        duration: ToastNotifier.fadeDuration,
        curve: Curves.easeOut,
        child: Padding(
          padding: const EdgeInsets.only(top: AppSizes.spacingS),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onTap,
              borderRadius: BorderRadius.circular(AppSizes.cardRadius),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.spacingM,
                  vertical: AppSizes.spacingM,
                ),
                decoration: BoxDecoration(
                  color: AppColors.textPrimary,
                  borderRadius: BorderRadius.circular(AppSizes.cardRadius),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(_icon, size: AppSizes.iconSize, color: _accentColor),
                    const SizedBox(width: AppSizes.spacingM),
                    Expanded(
                      child: Text(
                        widget.toast.message,
                        style: AppTypography.body1.copyWith(
                          color: Colors.white,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
