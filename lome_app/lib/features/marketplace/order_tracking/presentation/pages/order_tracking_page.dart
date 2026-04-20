import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../../core/router/route_names.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_shadows.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/widgets/tactile_wrapper.dart';
import '../../../../../core/utils/extensions/context_extensions.dart';
import '../../../../../core/widgets/lome_app_bar.dart';
import '../../../../../core/widgets/lome_button.dart';
import '../../../domain/entities/checkout_entities.dart';
import '../../../reviews/presentation/providers/review_provider.dart';
import '../providers/order_tracking_provider.dart';

/// Página de seguimiento de pedido en tiempo real.
class OrderTrackingPage extends ConsumerWidget {
  final String orderId;

  const OrderTrackingPage({super.key, required this.orderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderAsync = ref.watch(deliveryOrderProvider(orderId));

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: LomeAppBar(
        title: context.l10n.marketplaceOrderTrackingScreenTitle,
        showBack: true,
        onBack: () => context.go(RoutePaths.marketplace),
      ),
      body: orderAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (order) {
          if (order == null) {
            return Center(
              child: Text(context.l10n.marketplaceOrderTrackingNotFound),
            );
          }
          return _TrackingBody(order: order);
        },
      ),
    );
  }
}

class _TrackingBody extends ConsumerWidget {
  final DeliveryOrder order;

  const _TrackingBody({required this.order});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header card
          _OrderHeader(order: order).animate().fadeIn(duration: 300.ms),

          const SizedBox(height: AppTheme.spacingLg),

          // Progress timeline
          Text(
            context.l10n.marketplaceOrderTrackingStatus,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.grey900,
            ),
          ),
          const SizedBox(height: AppTheme.spacingMd),

          if (order.isCancelled)
            _CancelledBanner(reason: order.cancellationReason)
          else
            _ProgressTimeline(
              status: order.status,
            ).animate().fadeIn(duration: 400.ms, delay: 100.ms),

          // Botón de cancelar (solo si el pedido puede cancelarse)
          if (order.canBeCancelled) ...[
            const SizedBox(height: AppTheme.spacingMd),
            _CancelOrderButton(orderId: order.id),
          ],

          const SizedBox(height: AppTheme.spacingLg),

          // Review section (solo para pedidos entregados/completados)
          if (order.isDelivered)
            _ReviewSection(orderId: order.id, tenantId: order.tenantId),

          // Order details
          Text(
            context.l10n.marketplaceOrderTrackingDetailsTitle,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.grey900,
            ),
          ),
          const SizedBox(height: AppTheme.spacingSm),
          _OrderDetails(order: order),

          const SizedBox(height: AppTheme.spacingXl),
        ],
      ),
    );
  }
}

// =============================================================================
// Order header
// =============================================================================

class _OrderHeader extends StatelessWidget {
  final DeliveryOrder order;

  const _OrderHeader({required this.order});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      decoration: BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (order.orderNumber != null)
                Text(
                  context.l10n.orderLabel(order.orderNumber!.toString()),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                ),
                child: Text(
                  order.status.label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingSm),
          if (order.restaurantName != null)
            Row(
              children: [
                Icon(
                  PhosphorIcons.storefront(PhosphorIconsStyle.duotone),
                  size: 16,
                  color: Colors.white70,
                ),
                const SizedBox(width: 6),
                Text(
                  order.restaurantName!,
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatDate(order.createdAt),
                style: const TextStyle(color: Colors.white60, fontSize: 12),
              ),
              Text(
                '€${order.total.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

// =============================================================================
// Progress Timeline
// =============================================================================

class _ProgressTimeline extends StatelessWidget {
  final DeliveryOrderStatus status;

  const _ProgressTimeline({required this.status});

  static List<_StepData> _getSteps(BuildContext context) => [
    _StepData(
      icon: PhosphorIcons.receipt(PhosphorIconsStyle.duotone),
      label: context.l10n.marketplaceOrderTrackingStepReceived,
      subtitle: context.l10n.marketplaceOrderTrackingStepReceivedSub,
    ),
    _StepData(
      icon: PhosphorIcons.cookingPot(PhosphorIconsStyle.duotone),
      label: context.l10n.marketplaceOrderTrackingStepPreparing,
      subtitle: context.l10n.marketplaceOrderTrackingStepPreparingSub,
    ),
    _StepData(
      icon: PhosphorIcons.checkCircle(PhosphorIconsStyle.duotone),
      label: context.l10n.marketplaceOrderTrackingStepReady,
      subtitle: context.l10n.marketplaceOrderTrackingStepReadySub,
    ),
    _StepData(
      icon: PhosphorIcons.moped(PhosphorIconsStyle.duotone),
      label: context.l10n.marketplaceOrderTrackingStepOnTheWay,
      subtitle: context.l10n.marketplaceOrderTrackingStepOnTheWaySub,
    ),
    _StepData(
      icon: PhosphorIcons.house(PhosphorIconsStyle.duotone),
      label: context.l10n.marketplaceOrderTrackingStepDelivered,
      subtitle: context.l10n.marketplaceOrderTrackingStepDeliveredSub,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final steps = _getSteps(context);
    final currentStep = status.stepIndex;

    return Column(
      children: List.generate(steps.length, (i) {
        final step = steps[i];
        final isCompleted = i < currentStep;
        final isActive = i == currentStep;
        final isLast = i == steps.length - 1;

        return _TimelineStep(
          step: step,
          isCompleted: isCompleted,
          isActive: isActive,
          showLine: !isLast,
        )
            .animate()
            .fadeIn(
              delay: Duration(milliseconds: i * 80),
              duration: 300.ms,
            )
            .slideX(begin: -0.05, end: 0);
      }),
    );
  }
}

class _StepData {
  final IconData icon;
  final String label;
  final String subtitle;

  const _StepData({
    required this.icon,
    required this.label,
    required this.subtitle,
  });
}

class _TimelineStep extends StatelessWidget {
  final _StepData step;
  final bool isCompleted;
  final bool isActive;
  final bool showLine;

  const _TimelineStep({
    required this.step,
    required this.isCompleted,
    required this.isActive,
    required this.showLine,
  });

  @override
  Widget build(BuildContext context) {
    final color = isCompleted
        ? AppColors.success
        : isActive
        ? AppColors.primary
        : AppColors.grey300;

    Widget iconWidget = Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: isCompleted || isActive
            ? color.withValues(alpha: 0.15)
            : AppColors.grey100,
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 2),
      ),
      child: Icon(
        isCompleted
            ? PhosphorIcons.check(PhosphorIconsStyle.bold)
            : step.icon,
        size: 18,
        color: color,
      ),
    );
    if (isActive) {
      iconWidget = iconWidget
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .scale(
            begin: const Offset(1, 1),
            end: const Offset(1.1, 1.1),
            duration: 800.ms,
          );
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left: icon + line
          SizedBox(
            width: 48,
            child: Column(
              children: [
                iconWidget,
                if (showLine)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: isCompleted
                          ? AppColors.success
                          : AppColors.grey200,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppTheme.spacingSm),

          // Right: text
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: showLine ? 20 : 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    step.label,
                    style: TextStyle(
                      fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                      fontSize: 15,
                      color: isActive
                          ? AppColors.primary
                          : isCompleted
                          ? AppColors.grey800
                          : AppColors.grey400,
                    ),
                  ),
                  if (isActive || isCompleted)
                    Text(
                      step.subtitle,
                      style: TextStyle(fontSize: 12, color: AppColors.grey500),
                    ),
                  if (isActive)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: SizedBox(
                        width: 120,
                        child:
                            LinearProgressIndicator(
                                  backgroundColor: AppColors.grey200,
                                  color: AppColors.primary,
                                )
                                .animate(onPlay: (c) => c.repeat())
                                .shimmer(
                                  duration: 1200.ms,
                                  color: AppColors.primaryLight.withValues(
                                    alpha: 0.4,
                                  ),
                                ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Cancelled banner
// =============================================================================

class _CancelledBanner extends StatelessWidget {
  final String? reason;

  const _CancelledBanner({this.reason});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                PhosphorIcons.xCircle(PhosphorIconsStyle.fill),
                color: AppColors.error,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Pedido cancelado',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.error,
                ),
              ),
            ],
          ),
          if (reason != null && reason!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              reason!,
              style: TextStyle(fontSize: 13, color: AppColors.grey600),
            ),
          ],
        ],
      ),
    );
  }
}

// =============================================================================
// Order details
// =============================================================================

class _OrderDetails extends StatelessWidget {
  final DeliveryOrder order;

  const _OrderDetails({required this.order});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        boxShadow: AppShadows.card,
      ),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...order.items.map(
              (item) => Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: AppTheme.spacingXs,
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 26,
                      child: Text(
                        '${item.quantity}x',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.name),
                          if (item.notes != null && item.notes!.isNotEmpty)
                            Text(
                              item.notes!,
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.grey500,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Text(
                      '€${item.totalPrice.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingSm),
              child: Divider(height: 1, color: AppColors.grey100),
            ),
            _DetailRow('Subtotal', '€${order.subtotal.toStringAsFixed(2)}'),
            _DetailRow('IVA', '€${order.taxAmount.toStringAsFixed(2)}'),
            if (order.deliveryFee > 0)
              _DetailRow('Envío', '€${order.deliveryFee.toStringAsFixed(2)}'),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                ),
                Text(
                  '€${order.total.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingSm),
            Row(
              children: [
                Icon(
                  PhosphorIcons.creditCard(PhosphorIconsStyle.duotone),
                  size: 14,
                  color: AppColors.grey500,
                ),
                const SizedBox(width: 6),
                Text(
                  order.paymentMethod ?? 'Sin definir',
                  style: TextStyle(fontSize: 12, color: AppColors.grey500),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: order.paymentStatus == 'paid'
                        ? AppColors.success.withValues(alpha: 0.1)
                        : AppColors.warning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                  ),
                  child: Text(
                    order.paymentStatus == 'paid'
                        ? 'Pagado'
                        : 'Pendiente de pago',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: order.paymentStatus == 'paid'
                          ? AppColors.success
                          : AppColors.warning,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),

    );
  }
}

// =============================================================================
// Review section (post-delivery)
// =============================================================================

class _ReviewSection extends ConsumerStatefulWidget {
  final String orderId;
  final String tenantId;

  const _ReviewSection({required this.orderId, required this.tenantId});

  @override
  ConsumerState<_ReviewSection> createState() => _ReviewSectionState();
}

class _ReviewSectionState extends ConsumerState<_ReviewSection> {
  int _selectedRating = 0;
  final _commentCtrl = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasReviewed = ref.watch(hasReviewedOrderProvider(widget.orderId));

    return hasReviewed.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (reviewed) {
        if (reviewed) {
          return Padding(
            padding: const EdgeInsets.only(bottom: AppTheme.spacingLg),
            child: Container(
              padding: const EdgeInsets.all(AppTheme.spacingMd),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                border: Border.all(
                  color: AppColors.success.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    PhosphorIcons.checkCircle(PhosphorIconsStyle.fill),
                    color: AppColors.success,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '¡Gracias por tu valoración!',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.success,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: AppTheme.spacingLg),
          child: Container(
            padding: const EdgeInsets.all(AppTheme.spacingMd),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              border: Border.all(
                color: AppColors.warning.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '¿Cómo fue tu experiencia?',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.grey900,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingSm),
                // Star rating
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (i) {
                    final star = i + 1;
                    return TactileWrapper(
                      onTap: () => setState(() => _selectedRating = star),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Icon(
                          star <= _selectedRating
                              ? PhosphorIcons.star(PhosphorIconsStyle.fill)
                              : PhosphorIcons.star(PhosphorIconsStyle.duotone),
                          color: star <= _selectedRating
                              ? AppColors.accentDark
                              : AppColors.grey300,
                          size: 38,
                        ),
                      ),
                    );
                  }),
                ),
                if (_selectedRating > 0) ...[
                  const SizedBox(height: AppTheme.spacingSm),
                  TextField(
                    controller: _commentCtrl,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Cuéntanos más (opcional)',
                      hintStyle: TextStyle(color: AppColors.grey400),
                      filled: true,
                      fillColor: AppColors.grey50,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                        borderSide: BorderSide(color: AppColors.primary, width: 1.5),
                      ),
                      contentPadding: const EdgeInsets.all(14),
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingSm),
                  TactileWrapper(
                    onTap: _submitting ? null : _submit,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        gradient: _submitting ? null : AppColors.heroGradient,
                        color: _submitting ? AppColors.grey200 : null,
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                        boxShadow: _submitting
                            ? null
                            : [
                                BoxShadow(
                                  color: AppColors.primary.withAlpha(60),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                      ),
                      child: Center(
                        child: _submitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                context.l10n.marketplaceOrderTrackingReviewSubmit,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                ),
                              ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ).animate().fadeIn(duration: 400.ms, delay: 200.ms);
      },
    );
  }

  Future<void> _submit() async {
    try {
      final submission = ReviewSubmission(
        tenantId: widget.tenantId,
        orderId: widget.orderId,
        rating: _selectedRating,
        comment: _commentCtrl.text.isNotEmpty ? _commentCtrl.text : null,
      );
      await ref.read(submitReviewProvider(submission).future);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Valoración enviada!'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al enviar: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }
}

// =============================================================================
// Order details
// =============================================================================

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: AppColors.grey600)),
          Text(value),
        ],
      ),
    );
  }
}

// =============================================================================
// Cancel order button
// =============================================================================

class _CancelOrderButton extends ConsumerStatefulWidget {
  final String orderId;
  const _CancelOrderButton({required this.orderId});

  @override
  ConsumerState<_CancelOrderButton> createState() => _CancelOrderButtonState();
}

class _CancelOrderButtonState extends ConsumerState<_CancelOrderButton> {
  bool _loading = false;

  Future<void> _showCancelDialog() async {
    final reasonCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        ),
        title: Text(context.l10n.cancelOrderButton),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(context.l10n.cancelOrderConfirmMessage),
            const SizedBox(height: AppTheme.spacingMd),
            TextField(
              controller: reasonCtrl,
              decoration: InputDecoration(
                hintText: context.l10n.refundReasonHint,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(context.l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text(context.l10n.cancelOrderButton),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _loading = true);
    try {
      await ref.read(customerOrderActionsProvider).cancelOrder(
            widget.orderId,
            reason: reasonCtrl.text.trim().isEmpty
                ? null
                : reasonCtrl.text.trim(),
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.cancelOrderButton)),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al cancelar el pedido')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LomeButton(
      label: context.l10n.cancelOrderButton,
      variant: LomeButtonVariant.danger,
      icon: PhosphorIcons.prohibit(PhosphorIconsStyle.duotone),
      isExpanded: true,
      isLoading: _loading,
      onPressed: _loading ? null : _showCancelDialog,
    ).animate().fadeIn(duration: 400.ms, delay: 150.ms);
  }
}
