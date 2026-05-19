import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_sizes.dart';
import '../../../../l10n/strings.g.dart';
import '../providers/notifications_provider.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(notificationsNotifierProvider.notifier).load(refresh: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(notificationsNotifierProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(context.t.common.notifications),
        centerTitle: true,
        actions: [
          if (state.unreadCount > 0)
            TextButton(
              onPressed: () =>
                  ref.read(notificationsNotifierProvider.notifier).markAllRead(),
              child: Text(context.t.features.notifications.markAllRead),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () =>
            ref.read(notificationsNotifierProvider.notifier).load(refresh: true),
        child: state.isLoading && state.items.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : ListView.builder(
                padding: AppSizes.screenBodyScrollPadding,
                itemCount: state.items.length,
                itemBuilder: (context, i) {
                  final n = state.items[i];
                  return ListTile(
                    title: Text(
                      n.title,
                      style: TextStyle(
                        fontWeight:
                            n.isRead ? FontWeight.normal : FontWeight.w700,
                      ),
                    ),
                    subtitle: Text(n.body),
                    trailing: n.isRead
                        ? null
                        : const Icon(Icons.circle, size: 10, color: Colors.blue),
                    onTap: () {
                      if (!n.isRead) {
                        ref
                            .read(notificationsNotifierProvider.notifier)
                            .markRead(n.id);
                      }
                      final ticketId = n.data?['ticketId'];
                      if (ticketId is String && ticketId.isNotEmpty) {
                        context.push('/tickets/$ticketId');
                      }
                    },
                  );
                },
              ),
      ),
    );
  }
}
