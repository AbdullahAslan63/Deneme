import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../l10n/strings.g.dart';
import '../../../../shared/widgets/empty_state_widget.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/notification_entity.dart';
import '../providers/notifications_provider.dart';
import '../utils/notification_labels.dart';

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

  void _openNotification(NotificationEntity n) {
    if (!n.isRead) {
      ref.read(notificationsNotifierProvider.notifier).markRead(n.id);
    }
    final role = ref.read(authStateProvider).user?.role;
    final path = n.toPayload().resolveNavigationPath(role: role);
    if (path == null || !mounted) return;
    context.push(path);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(notificationsNotifierProvider);
    final t = context.t.features.notifications;
    final locale = Localizations.localeOf(context).toString();

    return Scaffold(
      appBar: AppBar(
        title: Text(context.t.common.notifications),
        centerTitle: true,
        actions: [
          if (state.unreadCount > 0)
            TextButton(
              onPressed: state.isLoading
                  ? null
                  : () => ref
                      .read(notificationsNotifierProvider.notifier)
                      .markAllRead(),
              child: Text(t.markAllRead),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () =>
            ref.read(notificationsNotifierProvider.notifier).load(refresh: true),
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
      itemCount: itemCount,
      itemBuilder: (context, i) {
        if (i >= state.items.length) {
          return const Padding(
            padding: EdgeInsets.all(AppSizes.spacingL),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        return _NotificationTile(
          notification: state.items[i],
          locale: locale,
          onTap: () => _openNotification(state.items[i]),
        );
      },
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final NotificationEntity notification;
  final String locale;
  final VoidCallback onTap;

  const _NotificationTile({
    required this.notification,
    required this.locale,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final n = notification;
    final dateStr = DateFormat('d MMM yyyy, HH:mm', locale).format(n.createdAt);

    return Card(
      margin: const EdgeInsets.only(bottom: AppSizes.spacingS),
      color: n.isRead ? AppColors.surface : AppColors.primaryLight.withValues(alpha: 0.08),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizes.cardRadius),
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.spacingM),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            n.title,
                            style: AppTypography.body1.copyWith(
                              fontWeight:
                                  n.isRead ? FontWeight.w500 : FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        if (!n.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.only(left: 8),
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSizes.spacingXS),
                    Text(
                      n.type.label(context),
                      style: AppTypography.caption.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSizes.spacingXS),
                    Text(
                      n.body,
                      style: AppTypography.body2.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSizes.spacingXS),
                    Text(
                      dateStr,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}
