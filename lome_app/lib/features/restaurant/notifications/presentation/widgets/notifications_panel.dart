import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_theme.dart';
import '../providers/notifications_provider.dart';

/// Panel desplegable de notificaciones.
///
/// Se muestra como un bottom sheet con la lista de notificaciones recientes,
/// separando las no leídas (arriba) de las leídas.
class NotificationsPanel extends ConsumerWidget {
  const NotificationsPanel({super.key});

  /// Muestra el panel como modal bottom sheet.
  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const NotificationsPanel(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nState = ref.watch(notificationsProvider);
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, controller) => Container(
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppTheme.radiusXl),
          ),
        ),
        child: Column(
          children: [
            // Handle + Header
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppTheme.spacingMd,
                AppTheme.spacingSm,
                AppTheme.spacingSm,
                0,
              ),
              child: Column(
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: AppTheme.spacingMd),
                      decoration: BoxDecoration(
                        color: AppColors.grey300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Notificaciones',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (nState.unreadCount > 0) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.error,
                                borderRadius: BorderRadius.circular(
                                  AppTheme.radiusFull,
                                ),
                              ),
                              child: Text(
                                '${nState.unreadCount}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: AppColors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (nState.unreadCount > 0)
                        TextButton(
                          onPressed: () => ref
                              .read(notificationsProvider.notifier)
                              .markAllAsRead(),
                          child: const Text('Marcar todas'),
                        ),
                    ],
                  ),
                ],
              ),
            ),

            const Divider(),

            // Lista
            Expanded(
              child: nState.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : nState.notifications.isEmpty
                  ? _EmptyNotifications()
                  : ListView.builder(
                      controller: controller,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spacingMd,
                      ),
                      itemCount: nState.notifications.length,
                      itemBuilder: (context, index) {
                        final notif = nState.notifications[index];
                        return _NotificationTile(
                          notification: notif,
                        ).animate().fadeIn(
                          delay: Duration(
                            milliseconds: index.clamp(0, 10) * 50,
                          ),
                          duration: 300.ms,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Notification tile
// =============================================================================

class _NotificationTile extends ConsumerWidget {
  final AppNotification notification;

  const _NotificationTile({required this.notification});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isUnread = !notification.isRead;
    final icon = _iconForType(notification.iconType);
    final color = _colorForType(notification.type);
    final timeAgo = _formatTimeAgo(notification.createdAt);

    return InkWell(
      onTap: () {
        if (isUnread) {
          ref.read(notificationsProvider.notifier).markAsRead(notification.id);
        }
      },
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: AppTheme.spacingSm,
          horizontal: AppTheme.spacingSm,
        ),
        margin: const EdgeInsets.only(bottom: 2),
        decoration: BoxDecoration(
          color: isUnread
              ? AppColors.primary.withValues(alpha: 0.04)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(width: AppTheme.spacingSm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: isUnread
                                ? FontWeight.w700
                                : FontWeight.w500,
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        timeAgo,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.grey400,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    notification.body,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.grey600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (isUnread)
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(top: 6, left: 4),
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }

  IconData _iconForType(String iconType) {
    return switch (iconType) {
      'receipt' => PhosphorIcons.receipt(),
      'kitchen' => PhosphorIcons.forkKnife(),
      'inventory' => PhosphorIcons.package(),
      'message' => PhosphorIcons.chatCircle(),
      'star' => PhosphorIcons.star(),
      'warning' => PhosphorIcons.warning(),
      _ => PhosphorIcons.bell(),
    };
  }

  Color _colorForType(String type) {
    return switch (type) {
      'new_order' || 'order_update' => AppColors.info,
      'order_ready' => AppColors.success,
      'low_stock' => AppColors.warning,
      'incident' => AppColors.error,
      'new_review' => AppColors.primary,
      _ => AppColors.grey600,
    };
  }

  String _formatTimeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'Ahora';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return '${date.day}/${date.month}';
  }
}

// =============================================================================
// Empty
// =============================================================================

class _EmptyNotifications extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(PhosphorIcons.bellSlash(), size: 48, color: AppColors.grey300),
          const SizedBox(height: AppTheme.spacingSm),
          Text(
            'Sin notificaciones',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.grey400),
          ),
        ],
      ),
    );
  }
}
