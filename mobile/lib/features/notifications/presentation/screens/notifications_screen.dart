import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../l10n/strings.g.dart';
import '../../../../shared/widgets/empty_state_widget.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/notification_entity.dart';
import '../providers/notifications_provider.dart';
import '../utils/notification_labels.dart';
import '../widgets/notification_detail_sheet.dart';
import '../widgets/notification_list_tile.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(notificationsNotifierProvider.notifier).load(refresh: true);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final max = _scrollController.position.maxScrollExtent;
    final offset = _scrollController.offset;
    if (max - offset < 120) {
      ref.read(notificationsNotifierProvider.notifier).loadMore();
    }
  }

  Future<void> _openNotification(NotificationEntity n) async {
    if (!n.isRead) {
      await ref.read(notificationsNotifierProvider.notifier).markRead(n.id);
    }

    final role = ref.read(authStateProvider).user?.role;
    final path = n.toPayload().resolveNavigationPath(role: role);

    if (!mounted) return;

    var shown = n;
    for (final e in ref.read(notificationsNotifierProvider).items) {
      if (e.id == n.id) {
        shown = e;
        break;
      }
    }

    await NotificationDetailSheet.show(
      context,
      notification: shown,
      onMarkRead: () {},
      onNavigate: path != null ? () => context.push(path) : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(notificationsNotifierProvider);
    final t = context.t.features.notifications;
    final locale = Localizations.localeOf(context).toString();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(context.t.common.notifications),
        centerTitle: true,
        actions: [
          if (state.unreadCount > 0)
            IconButton(
              tooltip: t.markAllRead,
              onPressed: state.isLoading
                  ? null
                  : () => ref
                      .read(notificationsNotifierProvider.notifier)
                      .markAllRead(),
              icon: const Icon(Icons.done_all_rounded),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () =>
            ref.read(notificationsNotifierProvider.notifier).load(refresh: true),
        color: AppColors.primary,
        child: _buildBody(context, state, locale),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    NotificationsState state,
    String locale,
  ) {
    final t = context.t.features.notifications;

    if (state.isLoading && state.items.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 200),
          Center(child: CircularProgressIndicator()),
        ],
      );
    }

    if (state.error != null && state.items.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.sizeOf(context).height * 0.2),
          Center(
            child: Padding(
              padding: AppSizes.screenBodyScrollPadding,
              child: Column(
                children: [
                  Text(
                    t.loadError,
                    style: AppTypography.body1,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSizes.spacingM),
                  FilledButton(
                    onPressed: () => ref
                        .read(notificationsNotifierProvider.notifier)
                        .load(refresh: true),
                    child: Text(context.t.common.tryAgain),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    if (state.items.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          EmptyStateWidget(
            icon: Icons.notifications_none_outlined,
            title: t.emptyTitle,
            subtitle: t.emptySubtitle,
          ),
        ],
      );
    }

    final itemCount = state.items.length + (state.isLoadingMore ? 1 : 0);

    return ListView.builder(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: AppSizes.screenBodyScrollPadding,
      itemCount: itemCount + 1,
      itemBuilder: (context, i) {
        if (i == 0) {
          if (state.unreadCount <= 0) return const SizedBox.shrink();
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSizes.spacingM),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.spacingM,
                vertical: AppSizes.spacingS,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.12),
                    AppColors.primaryLight.withValues(alpha: 0.06),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.15),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.mark_email_unread_rounded,
                    color: AppColors.primary,
                    size: 22,
                  ),
                  const SizedBox(width: AppSizes.spacingS),
                  Expanded(
                    child: Text(
                      '${state.unreadCount} ${t.unreadBadge.toLowerCase()}',
                      style: AppTypography.body2.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final index = i - 1;
        if (index >= state.items.length) {
          return const Padding(
            padding: EdgeInsets.all(AppSizes.spacingL),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        return NotificationListTile(
          notification: state.items[index],
          locale: locale,
          onTap: () => _openNotification(state.items[index]),
        );
      },
    );
  }
}
