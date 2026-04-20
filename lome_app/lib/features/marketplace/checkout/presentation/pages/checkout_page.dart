import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../../core/router/route_names.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_shadows.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/extensions/context_extensions.dart';
import '../../../../../core/widgets/lome_app_bar.dart';
import '../../../../../core/widgets/tactile_wrapper.dart';
import '../../../cart/presentation/providers/cart_provider.dart';
import '../../../domain/entities/checkout_entities.dart';
import '../providers/address_provider.dart';
import '../providers/checkout_provider.dart';

/// Página de checkout con pasos: Dirección → Pago → Confirmación.
class CheckoutPage extends ConsumerWidget {
  const CheckoutPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final checkout = ref.watch(checkoutProvider);
    final cart = ref.watch(cartProvider);

    return PopScope(
      canPop: checkout.step == CheckoutStep.address,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) ref.read(checkoutProvider.notifier).previousStep();
      },
      child: Scaffold(
        backgroundColor: AppColors.backgroundLight,
        appBar: LomeAppBar(
          title: _stepTitle(context, checkout.step),
          showBack: true,
          onBack: () {
            if (checkout.step == CheckoutStep.address) {
              context.pop();
            } else {
              ref.read(checkoutProvider.notifier).previousStep();
            }
          },
        ),
        body: Column(
          children: [
            // Progress indicator
            _StepIndicator(current: checkout.step),

            // Error banner
            if (checkout.error != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppTheme.spacingSm),
                color: AppColors.error.withValues(alpha: 0.1),
                child: Row(
                  children: [
                    Icon(
                      PhosphorIcons.warningCircle(PhosphorIconsStyle.duotone),
                      size: 16,
                      color: AppColors.error,
                    ),
                    const SizedBox(width: AppTheme.spacingSm),
                    Expanded(
                      child: Text(
                        checkout.error!,
                        style: const TextStyle(
                          color: AppColors.error,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Step content
            Expanded(
              child: AnimatedSwitcher(
                duration: 250.ms,
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.05, 0),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                ),
                child: switch (checkout.step) {
                  CheckoutStep.address => const _AddressStep(
                    key: ValueKey('addr'),
                  ),
                  CheckoutStep.payment => const _PaymentStep(
                    key: ValueKey('pay'),
                  ),
                  CheckoutStep.confirmation => const _ConfirmationStep(
                    key: ValueKey('confirm'),
                  ),
                },
              ),
            ),

            // Bottom bar
            if (checkout.createdOrder == null)
              _BottomBar(checkout: checkout, cart: cart),
          ],
        ),
      ),
    );
  }

  String _stepTitle(BuildContext context, CheckoutStep step) {
    switch (step) {
      case CheckoutStep.address:
        return context.l10n.marketplaceCheckoutDeliveryAddress;
      case CheckoutStep.payment:
        return context.l10n.marketplaceCheckoutPaymentMethod;
      case CheckoutStep.confirmation:
        return context.l10n.marketplaceCheckoutTitle;
    }
  }
}

// =============================================================================
// Step Indicator
// =============================================================================

class _StepIndicator extends StatelessWidget {
  final CheckoutStep current;

  const _StepIndicator({required this.current});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingLg,
        vertical: AppTheme.spacingMd,
      ),
      child: Row(
        children: [
          _dot(
            0,
            context.l10n.marketplaceCheckoutStepAddress,
            current.index >= 0,
            current.index == 0,
          ),
          _line(current.index >= 1),
          _dot(
            1,
            context.l10n.marketplaceCheckoutStepPayment,
            current.index >= 1,
            current.index == 1,
          ),
          _line(current.index >= 2),
          _dot(
            2,
            context.l10n.marketplaceCheckoutStepConfirm,
            current.index >= 2,
            current.index == 2,
          ),
        ],
      ),
    );
  }

  Widget _dot(int idx, String label, bool reached, bool active) {
    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: reached ? AppColors.primary : AppColors.grey100,
            boxShadow: active
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 8,
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: reached
                ? Icon(
                    PhosphorIcons.check(PhosphorIconsStyle.duotone),
                    size: 14,
                    color: Colors.white,
                  )
                : Text(
                    '${idx + 1}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.grey500,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: active ? FontWeight.w600 : FontWeight.w400,
            color: active ? AppColors.primary : AppColors.grey500,
          ),
        ),
      ],
    );
  }

  Widget _line(bool active) {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 16),
        color: active ? AppColors.primary : AppColors.grey200,
      ),
    );
  }
}

// =============================================================================
// Step 1: Address
// =============================================================================

class _AddressStep extends ConsumerStatefulWidget {
  const _AddressStep({super.key});

  @override
  ConsumerState<_AddressStep> createState() => _AddressStepState();
}

class _AddressStepState extends ConsumerState<_AddressStep> {
  bool _showNewForm = false;

  final _labelCtrl = TextEditingController();
  bool _labelDefaultSet = false;
  final _line1Ctrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _postalCtrl = TextEditingController();
  final _instructionsCtrl = TextEditingController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_labelDefaultSet) {
      _labelCtrl.text = context.l10n.checkoutAddressHome;
      _labelDefaultSet = true;
    }
  }

  @override
  void dispose() {
    _labelCtrl.dispose();
    _line1Ctrl.dispose();
    _cityCtrl.dispose();
    _postalCtrl.dispose();
    _instructionsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final addressesAsync = ref.watch(customerAddressesProvider);
    final selected = ref.watch(checkoutProvider).address;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Existing addresses
          addressesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text(
              context.l10n.marketplaceCheckoutErrorLoadingAddresses(
                e.toString(),
              ),
            ),
            data: (addresses) {
              if (addresses.isEmpty && !_showNewForm) {
                return Column(
                  children: [
                    Icon(
                      PhosphorIcons.warningCircle(PhosphorIconsStyle.duotone),
                      size: 48,
                      color: AppColors.grey300,
                    ),
                    const SizedBox(height: AppTheme.spacingSm),
                    Text(context.l10n.marketplaceCheckoutNoAddresses),
                    const SizedBox(height: AppTheme.spacingMd),
                    OutlinedButton.icon(
                      onPressed: () => setState(() => _showNewForm = true),
                      icon: Icon(PhosphorIcons.plus(PhosphorIconsStyle.duotone)),
                      label: Text(context.l10n.marketplaceCheckoutAddAddress),
                    ),
                  ],
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ...addresses.map(
                    (addr) => _AddressTile(
                      address: addr,
                      isSelected: selected?.id == addr.id,
                      onTap: () => ref
                          .read(checkoutProvider.notifier)
                          .selectAddress(addr),
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingSm),
                  if (!_showNewForm)
                    TextButton.icon(
                      onPressed: () => setState(() => _showNewForm = true),
                      icon: Icon(PhosphorIcons.plus(PhosphorIconsStyle.duotone), size: 18),
                      label: Text(context.l10n.marketplaceCheckoutNewAddress),
                    ),
                ],
              );
            },
          ),

          // New address form
          if (_showNewForm) ...[
            const Divider(height: AppTheme.spacingLg),
            Text(
              context.l10n.marketplaceCheckoutNewAddress,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.grey900,
              ),
            ),
            const SizedBox(height: AppTheme.spacingMd),
            _FormField(
              ctrl: _labelCtrl,
              label: context.l10n.marketplaceCheckoutLabelField,
              hint: context.l10n.marketplaceCheckoutLabelHint,
            ),
            _FormField(
              ctrl: _line1Ctrl,
              label: context.l10n.marketplaceCheckoutAddressField,
              hint: context.l10n.marketplaceCheckoutAddressHint,
            ),
            Row(
              children: [
                Expanded(
                  child: _FormField(
                    ctrl: _postalCtrl,
                    label: context.l10n.marketplaceCheckoutPostalCode,
                    hint: '28001',
                  ),
                ),
                const SizedBox(width: AppTheme.spacingSm),
                Expanded(
                  child: _FormField(
                    ctrl: _cityCtrl,
                    label: context.l10n.marketplaceCheckoutCity,
                    hint: context.l10n.marketplaceCheckoutCityHint,
                  ),
                ),
              ],
            ),
            _FormField(
              ctrl: _instructionsCtrl,
              label: context.l10n.marketplaceCheckoutInstructions,
              hint: context.l10n.marketplaceCheckoutInstructionsHint,
            ),
            const SizedBox(height: AppTheme.spacingSm),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => setState(() => _showNewForm = false),
                    child: Text(context.l10n.cancel),
                  ),
                ),
                const SizedBox(width: AppTheme.spacingSm),
                Expanded(
                  child: FilledButton(
                    onPressed: _saveAddress,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                    ),
                    child: Text(context.l10n.save),
                  ),
                ),
              ],
            ),
          ],

          // Delivery notes
          const SizedBox(height: AppTheme.spacingLg),
          Text(
            context.l10n.marketplaceCheckoutDeliveryNotes,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.grey900,
            ),
          ),
          const SizedBox(height: AppTheme.spacingSm),
          TextField(
            maxLines: 2,
            decoration: InputDecoration(
              hintText: context.l10n.marketplaceCheckoutDeliveryNotesHint,
              border: OutlineInputBorder(),
            ),
            onChanged: (v) =>
                ref.read(checkoutProvider.notifier).setDeliveryNotes(v),
          ),
        ],
      ),
    );
  }

  Future<void> _saveAddress() async {
    if (_line1Ctrl.text.isEmpty ||
        _cityCtrl.text.isEmpty ||
        _postalCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.marketplaceCheckoutFillRequired)),
      );
      return;
    }

    final service = ref.read(addressServiceProvider);
    final addr = await service.createAddress(
      label: _labelCtrl.text,
      addressLine1: _line1Ctrl.text,
      city: _cityCtrl.text,
      postalCode: _postalCtrl.text,
      instructions: _instructionsCtrl.text.isNotEmpty
          ? _instructionsCtrl.text
          : null,
    );

    ref.read(checkoutProvider.notifier).selectAddress(addr);
    ref.invalidate(customerAddressesProvider);
    if (mounted) setState(() => _showNewForm = false);
  }
}

class _AddressTile extends StatelessWidget {
  final DeliveryAddress address;
  final bool isSelected;
  final VoidCallback onTap;

  const _AddressTile({
    required this.address,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return TactileWrapper(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppTheme.spacingSm),
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          border: isSelected
              ? Border.all(color: AppColors.primary, width: 2)
              : null,
          boxShadow: AppShadows.card,
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primarySoft : AppColors.grey50,
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
              child: Icon(
                address.label == context.l10n.checkoutAddressWork
                    ? PhosphorIcons.buildings(PhosphorIconsStyle.duotone)
                    : address.label == context.l10n.checkoutAddressHome
                    ? PhosphorIcons.house(PhosphorIconsStyle.duotone)
                    : PhosphorIcons.mapPin(PhosphorIconsStyle.duotone),
                color: isSelected ? AppColors.primary : AppColors.grey500,
              ),
            ),
              const SizedBox(width: AppTheme.spacingMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          address.label,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        if (address.isDefault) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'Default',
                              style: TextStyle(
                                fontSize: 10,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      address.fullAddress,
                      style: TextStyle(fontSize: 13, color: AppColors.grey600),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(
                  PhosphorIcons.checkCircle(PhosphorIconsStyle.duotone),
                  color: AppColors.primary,
                ),
            ],
          ),
        ),
    );
  }
}

// =============================================================================
// Step 2: Payment
// =============================================================================

class _PaymentStep extends ConsumerWidget {
  const _PaymentStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(checkoutProvider).paymentMethod;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.marketplaceCheckoutSelectPayment,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.grey900,
            ),
          ),
          const SizedBox(height: AppTheme.spacingMd),
          ...PaymentMethod.values.map((method) {
            final isActive = selected == method;
            return _PaymentMethodCard(
              method: method,
              isSelected: isActive,
              onTap: () => ref
                  .read(checkoutProvider.notifier)
                  .selectPaymentMethod(method),
            );
          }),
          const SizedBox(height: AppTheme.spacingLg),
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingMd),
            decoration: BoxDecoration(
              color: AppColors.info.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              border: Border.all(color: AppColors.info.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Icon(PhosphorIcons.info(PhosphorIconsStyle.duotone), size: 18, color: AppColors.info),
                const SizedBox(width: AppTheme.spacingSm),
                Expanded(
                  child: Text(
                    selected == PaymentMethod.cash
                        ? context.l10n.marketplaceCheckoutPaymentCashInfo
                        : selected == PaymentMethod.card
                        ? context.l10n.marketplaceCheckoutPaymentCardInfo
                        : selected == PaymentMethod.online
                        ? context.l10n.marketplaceCheckoutPaymentOnlineInfo
                        : context.l10n.marketplaceCheckoutPaymentSelectInfo,
                    style: const TextStyle(fontSize: 13, color: AppColors.info),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentMethodCard extends StatelessWidget {
  final PaymentMethod method;
  final bool isSelected;
  final VoidCallback onTap;

  const _PaymentMethodCard({
    required this.method,
    required this.isSelected,
    required this.onTap,
  });

  IconData get _icon {
    switch (method) {
      case PaymentMethod.card:
        return PhosphorIcons.creditCard(PhosphorIconsStyle.duotone);
      case PaymentMethod.online:
        return PhosphorIcons.globe(PhosphorIconsStyle.duotone);
      case PaymentMethod.cash:
        return PhosphorIcons.money(PhosphorIconsStyle.duotone);
    }
  }

  String _subtitle(BuildContext context) {
    switch (method) {
      case PaymentMethod.card:
        return context.l10n.marketplaceCheckoutPaymentCardSubtitle;
      case PaymentMethod.online:
        return context.l10n.marketplaceCheckoutPaymentOnlineSubtitle;
      case PaymentMethod.cash:
        return context.l10n.marketplaceCheckoutPaymentCashSubtitle;
    }
  }

  @override
  Widget build(BuildContext context) {
    return TactileWrapper(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppTheme.spacingSm),
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          border: isSelected
              ? Border.all(color: AppColors.primary, width: 2)
              : null,
          boxShadow: AppShadows.card,
        ),
        child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primarySoft
                      : AppColors.grey50,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
                child: Icon(
                  _icon,
                  color: isSelected ? AppColors.primary : AppColors.grey500,
                ),
              ),
              const SizedBox(width: AppTheme.spacingMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      method.label,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      _subtitle(context),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.grey500,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(
                  PhosphorIcons.checkCircle(PhosphorIconsStyle.duotone),
                  color: AppColors.primary,
                ),
            ],
          ),
        ),
    );
  }
}

// =============================================================================
// Step 3: Confirmation
// =============================================================================

class _ConfirmationStep extends ConsumerWidget {
  const _ConfirmationStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final checkout = ref.watch(checkoutProvider);
    final cart = ref.watch(cartProvider);

    // If order was created, show success
    if (checkout.createdOrder != null) {
      return _OrderSuccess(order: checkout.createdOrder!);
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Delivery address summary
          _SummarySection(
            icon: PhosphorIcons.mapPin(PhosphorIconsStyle.duotone),
            title: 'Entrega en',
            content: checkout.address!.fullAddress,
            subtitle: checkout.deliveryNotes,
          ),
          const SizedBox(height: AppTheme.spacingMd),

          // Payment method summary
          _SummarySection(
            icon: PhosphorIcons.creditCard(PhosphorIconsStyle.duotone),
            title: 'Pago',
            content: checkout.paymentMethod!.label,
          ),
          const SizedBox(height: AppTheme.spacingMd),

          // Order items
          Text(
            'Resumen del pedido',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.grey900,
            ),
          ),
          const SizedBox(height: AppTheme.spacingSm),
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingMd),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              boxShadow: AppShadows.card,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (cart.restaurantName != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppTheme.spacingSm),
                    child: Row(
                      children: [
                        Icon(
                          PhosphorIcons.storefront(PhosphorIconsStyle.duotone),
                          size: 16,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          cart.restaurantName!,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ...cart.items.map(
                  (item) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingXs),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 24,
                          child: Text(
                            '${item.quantity}x',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        Expanded(child: Text(item.name)),
                        Text(
                          '€${item.totalPrice.toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),
                const Divider(height: AppTheme.spacingLg),
                _TotalRow('Subtotal', cart.subtotal),
                _TotalRow('IVA (10%)', cart.subtotal * 0.10),
                const SizedBox(height: AppTheme.spacingSm),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                    ),
                    Text(
                      '€${(cart.subtotal * 1.10).toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SummarySection extends StatelessWidget {
  final IconData icon;
  final String title;
  final String content;
  final String? subtitle;

  const _SummarySection({
    required this.icon,
    required this.title,
    required this.content,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        boxShadow: AppShadows.card,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: AppTheme.spacingMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 11, color: AppColors.grey500),
                ),
                Text(
                  content,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                if (subtitle != null && subtitle!.isNotEmpty)
                  Text(
                    subtitle!,
                    style: TextStyle(fontSize: 12, color: AppColors.grey500),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TotalRow extends StatelessWidget {
  final String label;
  final double amount;

  const _TotalRow(this.label, this.amount);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: AppColors.grey600)),
          Text('€${amount.toStringAsFixed(2)}'),
        ],
      ),
    );
  }
}

// =============================================================================
// Order success
// =============================================================================

class _OrderSuccess extends StatelessWidget {
  final DeliveryOrder order;

  const _OrderSuccess({required this.order});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingLg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                gradient: AppColors.heroGradient,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                PhosphorIcons.check(PhosphorIconsStyle.duotone),
                size: 42,
                color: Colors.white,
              ),
            ).animate().scale(
              begin: const Offset(0, 0),
              duration: 400.ms,
              curve: Curves.elasticOut,
            ),
            const SizedBox(height: AppTheme.spacingLg),
            Text(
              '¡Pedido realizado!',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: AppColors.grey900,
              ),
            ),
            const SizedBox(height: AppTheme.spacingSm),
            Text(
              order.orderNumber != null
                  ? context.l10n.orderLabel(order.orderNumber!.toString())
                  : context.l10n.orderOnItsWay,
              style: TextStyle(color: AppColors.grey600),
            ),
            const SizedBox(height: AppTheme.spacingXl),
            TactileWrapper(
              onTap: () => context.pushReplacementNamed(
                RouteNames.orderTracking,
                pathParameters: {'orderId': order.id},
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  gradient: AppColors.heroGradient,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      PhosphorIcons.moped(PhosphorIconsStyle.duotone),
                      color: AppColors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      context.l10n.trackOrder,
                      style: const TextStyle(
                        color: AppColors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppTheme.spacingSm),
            TactileWrapper(
              onTap: () => context.go(RoutePaths.marketplace),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  context.l10n.marketplaceCheckoutBackToHome,
                  style: const TextStyle(
                    color: AppColors.grey500,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Bottom bar
// =============================================================================

class _BottomBar extends ConsumerWidget {
  final CheckoutState checkout;
  final CartState cart;

  const _BottomBar({required this.checkout, required this.cart});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusLg),
        ),
        boxShadow: AppShadows.navigation,
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: TactileWrapper(
            onTap: checkout.canProceed && !checkout.isSubmitting
                ? () async {
                    if (checkout.step == CheckoutStep.confirmation) {
                      await ref.read(checkoutProvider.notifier).placeOrder();
                    } else {
                      ref.read(checkoutProvider.notifier).nextStep();
                    }
                  }
                : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(vertical: 15),
              decoration: BoxDecoration(
                gradient: checkout.canProceed && !checkout.isSubmitting
                    ? AppColors.heroGradient
                    : null,
                color: checkout.canProceed && !checkout.isSubmitting
                    ? null
                    : AppColors.grey200,
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                boxShadow: checkout.canProceed && !checkout.isSubmitting
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: checkout.isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        checkout.step == CheckoutStep.confirmation
                            ? 'Confirmar pedido · €${(cart.subtotal * 1.10).toStringAsFixed(2)}'
                            : 'Continuar',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: checkout.canProceed
                              ? AppColors.white
                              : AppColors.grey400,
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// Helpers
// =============================================================================

class _FormField extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final String hint;

  const _FormField({
    required this.ctrl,
    required this.label,
    required this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacingSm),
      child: TextField(
        controller: ctrl,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}
