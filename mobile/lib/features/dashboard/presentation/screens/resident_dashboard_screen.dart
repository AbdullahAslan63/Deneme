import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/platform/system_navigator_bridge.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../l10n/strings.g.dart';
import '../../../../shared/providers/navigation_provider.dart';
import '../../../../shared/widgets/empty_state_widget.dart';
import '../../../../shared/widgets/settings_tab.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../dues/domain/entities/due_entity.dart';
import '../../../dues/presentation/providers/dues_provider.dart';
import '../../../dues/presentation/screens/resident_dues_tab.dart';

class ResidentDashboardScreen extends ConsumerStatefulWidget {
  const ResidentDashboardScreen({super.key});

  @override
  ConsumerState<ResidentDashboardScreen> createState() =>
      _ResidentDashboardScreenState();
}

class _ResidentDashboardScreenState
    extends ConsumerState<ResidentDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _requestedInitialDues = false;

  @override
  void initState() {
    super.initState();
    final initialIndex = ref.read(residentTabIndexProvider);
    _tabController = TabController(
      length: 4,
      vsync: this,
      initialIndex: initialIndex,
    );
    _tabController.addListener(() {
      ref.read(residentTabIndexProvider.notifier).state = _tabController.index;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_requestedInitialDues) {
      _requestedInitialDues = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ref.read(duesNotifierProvider.notifier).loadMyDues();
      });
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await SystemNavigatorBridge.moveAppToBackground();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(context.t.features.apartments.residentPanel),
          centerTitle: true,
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildHomeTab(),
            _buildDuesTab(),
            _buildIssuesTab(),
            _buildSettingsTab(),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.home_outlined),
              selectedIcon: const Icon(Icons.home),
              label: context.t.common.home,
            ),
            NavigationDestination(
              icon: const Icon(Icons.receipt_outlined),
              selectedIcon: const Icon(Icons.receipt),
              label: context.t.common.dues,
            ),
            NavigationDestination(
              icon: const Icon(Icons.warning_amber_outlined),
              selectedIcon: const Icon(Icons.warning_amber_rounded),
              label: context.t.common.issues,
            ),
            NavigationDestination(
              icon: const Icon(Icons.settings_outlined),
              selectedIcon: const Icon(Icons.settings),
              label: context.t.common.settings,
            ),
          ],
          selectedIndex: ref.watch(residentTabIndexProvider),
          onDestinationSelected: (index) {
            ref.read(residentTabIndexProvider.notifier).state = index;
            _tabController.animateTo(index);
          },
        ),
      ),
    );
  }

  Widget _buildHomeTab() {
    final authState = ref.watch(authStateProvider);
    final dues = ref.watch(duesNotifierProvider).dues;
    final userName = authState.user?.name ?? context.t.common.user;
    final pendingCount = dues.where((d) => d.status == DueStatus.pending).length;
    final overdueCount = dues.where((d) => d.status == DueStatus.overdue).length;
    final paidCount = dues.where((d) => d.status == DueStatus.paid).length;

    return SingleChildScrollView(
      padding: AppSizes.screenBodyScrollPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ResidentWelcomeCard(
            userName: userName,
            pendingCount: pendingCount,
            overdueCount: overdueCount,
            paidCount: paidCount,
          ),
          const SizedBox(height: AppSizes.spacingL),
          _buildQuickActionsRow(),
          const SizedBox(height: AppSizes.spacingL),
          Text(
            context.t.common.recentTransactions,
            style: AppTypography.h3.copyWith(color: AppColors.textPrimary),
          ),
          const SizedBox(height: AppSizes.spacingM),
          _buildTransactionHistory(),
        ],
      ),
    );
  }

  Widget _buildDuesTab() {
    return const ResidentDuesTab();
  }

  Widget _buildIssuesTab() {
    return Center(
      child: Text(
        context.t.common.issuesTab,
        style: AppTypography.h2.copyWith(color: AppColors.textPrimary),
      ),
    );
  }

  Widget _buildSettingsTab() {
    return const SettingsTab();
  }

  Widget _buildQuickActionsRow() {
    return Row(
      children: [
        Expanded(
          child: _buildActionButton(
            icon: Icons.payment_outlined,
            label: context.t.common.makePayment,
            onTap: () {},
          ),
        ),
        const SizedBox(width: AppSizes.spacingM),
        Expanded(
          child: _buildActionButton(
            icon: Icons.receipt_outlined,
            label: context.t.common.bills,
            onTap: () {},
          ),
        ),
        const SizedBox(width: AppSizes.spacingM),
        Expanded(
          child: _buildActionButton(
            icon: Icons.help_outline,
            label: context.t.common.support,
            onTap: () {},
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSizes.spacingM),
        decoration: BoxDecoration(
          color: AppColors.primaryLight.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primary, size: 28),
            const SizedBox(height: AppSizes.spacingS),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.caption.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionHistory() {
    final transactions = <Map<String, String>>[];

    if (transactions.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.receipt_long_outlined,
        title: context.t.common.recentTransactions,
        subtitle: context.t.common.comingSoon,
      );
    }

    return Column(
      children: transactions
          .map(
            (tx) => Container(
              margin: const EdgeInsets.only(bottom: AppSizes.spacingM),
              padding: const EdgeInsets.all(AppSizes.spacingM),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderColor),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tx['type']!,
                        style: AppTypography.h4.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: AppSizes.spacingXS),
                      Text(
                        tx['date']!,
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        tx['amount']!,
                        style: AppTypography.h4.copyWith(
                          color: AppColors.success,
                        ),
                      ),
                      const SizedBox(height: AppSizes.spacingXS),
                      Text(
                        tx['status']!,
                        style: AppTypography.caption.copyWith(
                          color: AppColors.success,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

class _ResidentWelcomeCard extends StatelessWidget {
  final String userName;
  final int pendingCount;
  final int overdueCount;
  final int paidCount;

  const _ResidentWelcomeCard({
    required this.userName,
    required this.pendingCount,
    required this.overdueCount,
    required this.paidCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.spacingM,
        vertical: AppSizes.spacingL,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSizes.cardRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${context.t.common.welcome}, $userName',
            style: AppTypography.h3.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSizes.spacingXS),
          Text(
            context.t.features.apartments.residentPanel,
            style: AppTypography.body2.copyWith(
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(height: AppSizes.spacingL),
          Row(
            children: [
              _WelcomeMetric(
                icon: Icons.pending_outlined,
                value: pendingCount.toString(),
                label: context.t.common.pendingStatus,
              ),
              Container(
                width: 1,
                height: 32,
                margin: const EdgeInsets.symmetric(
                  horizontal: AppSizes.spacingL,
                ),
                color: Colors.white.withValues(alpha: 0.3),
              ),
              _WelcomeMetric(
                icon: Icons.warning_amber_rounded,
                value: overdueCount.toString(),
                label: context.t.common.overdueStatus,
              ),
              Container(
                width: 1,
                height: 32,
                margin: const EdgeInsets.symmetric(
                  horizontal: AppSizes.spacingL,
                ),
                color: Colors.white.withValues(alpha: 0.3),
              ),
              _WelcomeMetric(
                icon: Icons.check_circle_outline,
                value: paidCount.toString(),
                label: context.t.common.paidStatus,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WelcomeMetric extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _WelcomeMetric({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.white.withValues(alpha: 0.85), size: 18),
        const SizedBox(height: AppSizes.spacingXS),
        Text(
          value,
          style: AppTypography.h3.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          label,
          style: AppTypography.caption.copyWith(
            color: Colors.white.withValues(alpha: 0.75),
          ),
        ),
      ],
    );
  }
}
