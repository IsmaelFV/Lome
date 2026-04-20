import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/router/route_names.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_theme.dart';
import '../providers/notifications_provider.dart';

/// Banner flotante que avisa al camarero cuando un pedido está listo.
///
/// Se muestra automáticamente al detectar una notificación `order_ready`
/// no leída. Al tocarla, navega al pedido y la marca como leída.
class OrderReadyBanner extends ConsumerWidget {
  const OrderReadyBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final readyNotif = ref.watch(latestOrderReadyProvider);

    if (readyNotif == null) return const SizedBox.shrink();

    final orderNumber = readyNotif.data['order_number'] ?? '?';

    return Padding(
          padding: const EdgeInsets.fromLTRB(
            AppTheme.spacingMd,
            AppTheme.spacingSm,
            AppTheme.spacingMd,
            0,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                ref
                    .read(notificationsProvider.notifier)
                    .markAsRead(readyNotif.id);
                // Navegar al pedido si tiene table_session_id
                final tableSessionId =
                    readyNotif.data['table_session_id'] as String?;
                if (tableSessionId != null) {
                  context.pushNamed(
                    RouteNames.tableOrder,
                    queryParameters: {'tableId': tableSessionId},
                  );
                }
              },
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingMd,
                  vertical: AppTheme.spacingSm,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.success, AppColors.primary],
                  ),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.success.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                      ),
                      child: Icon(
                        PhosphorIcons.forkKnife(),
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacingMd),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Pedido #$orderNumber listo',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Toca para ver el pedido',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        PhosphorIcons.x(),
                        color: Colors.white70,
                        size: 20,
                      ),
                      onPressed: () => ref
                          .read(notificationsProvider.notifier)
                          .markAsRead(readyNotif.id),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
              ),
            ),
          ),
        )
        .animate()
        .fadeIn(duration: 400.ms)
        .slideY(begin: -0.5, end: 0, duration: 400.ms)
        .shimmer(duration: 1500.ms, delay: 400.ms);
  }
}
