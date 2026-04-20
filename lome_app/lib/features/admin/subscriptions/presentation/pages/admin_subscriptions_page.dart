import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/extensions/context_extensions.dart';
import '../../../../../core/widgets/lome_button.dart';
import '../../../../../core/widgets/lome_card.dart';
import '../../../../../core/widgets/lome_loading.dart';
import '../../../../../core/widgets/tactile_wrapper.dart';
import '../../../domain/entities/admin_entities.dart';
import '../providers/admin_subscriptions_provider.dart';

class AdminSubscriptionsPage extends ConsumerStatefulWidget {
  const AdminSubscriptionsPage({super.key});

  @override
  ConsumerState<AdminSubscriptionsPage> createState() =>
      _AdminSubscriptionsPageState();
}

class _AdminSubscriptionsPageState
    extends ConsumerState<AdminSubscriptionsPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(context.l10n.adminSubscriptionsBillingTitle),
        actions: [
          TactileWrapper(
            onTap: () {
              ref.invalidate(adminSubscriptionStatsProvider);
              ref.invalidate(adminSubscriptionsProvider);
              ref.invalidate(adminInvoicesProvider);
            },
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spacingSm),
              child: Icon(
                PhosphorIcons.arrowClockwise(PhosphorIconsStyle.duotone),
                color: AppColors.grey700,
              ),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: context.l10n.adminSubscriptionsTabSubscriptions),
            Tab(text: context.l10n.adminSubscriptionsTabInvoices),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _SubscriptionsTab(),
          _InvoicesTab(),
        ],
      ),
    );
  }
}

// ─── Stats Header ────────────────────────────────────────────────────────────

class _StatsHeader extends ConsumerWidget {
  const _StatsHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(adminSubscriptionStatsProvider);

    return statsAsync.when(
      loading: () => const SizedBox(
        height: 100,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => const SizedBox.shrink(),
      data: (stats) {
        final fmt = NumberFormat.currency(locale: 'es_ES', symbol: '€');
        return Padding(
          padding: const EdgeInsets.all(AppTheme.spacingMd),
          child: Column(
            children: [
              Row(
                children: [
                  _MiniStat(
                    label: context.l10n.adminSubscriptionsMrr,
                    value: fmt.format(stats.mrr),
                    color: AppColors.primary,
                  ),
                  _MiniStat(
                    label: context.l10n.adminSubscriptionsActiveLabel,
                    value: '${stats.activeSubscriptions}',
                    color: AppColors.success,
                  ),
                  _MiniStat(
                    label: context.l10n.adminSubscriptionsPastDue,
                    value: '${stats.pastDueSubscriptions}',
                    color: AppColors.warning,
                  ),
                  _MiniStat(
                    label: context.l10n.adminSubscriptionsCancelledLabel,
                    value: '${stats.cancelledSubscriptions}',
                    color: AppColors.error,
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacingSm),
              // Plan distribution
              if (stats.planDistribution.isNotEmpty)
                Row(
                  children: stats.planDistribution.entries.map((e) {
                    return Expanded(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        padding: const EdgeInsets.symmetric(
                            vertical: 6, horizontal: 4),
                        decoration: BoxDecoration(
                          color: _planColor(e.key).withOpacity(0.1),
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusSm),
                        ),
                        child: Column(
                          children: [
                            Text(
                              '${e.value}',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: _planColor(e.key),
                              ),
                            ),
                            Text(
                              _planLabel(context, e.key),
                              style: TextStyle(
                                fontSize: 11,
                                color: _planColor(e.key),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: color.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Subscriptions Tab ───────────────────────────────────────────────────────

class _SubscriptionsTab extends ConsumerWidget {
  const _SubscriptionsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(adminSubscriptionFilterProvider);
    final subsAsync = ref.watch(adminSubscriptionsProvider);

    return Column(
      children: [
        const _StatsHeader(),

        // Filter chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMd),
          child: Row(
            children: [
              _FilterChip(
                label: context.l10n.adminSubscriptionsAllFilter,
                selected: filter == 'all',
                onTap: () => ref
                    .read(adminSubscriptionFilterProvider.notifier)
                    .state = 'all',
              ),
              _FilterChip(
                label: context.l10n.adminSubscriptionsActiveLabel,
                selected: filter == 'active',
                onTap: () => ref
                    .read(adminSubscriptionFilterProvider.notifier)
                    .state = 'active',
              ),
              _FilterChip(
                label: context.l10n.adminSubscriptionsPastDue,
                selected: filter == 'past_due',
                onTap: () => ref
                    .read(adminSubscriptionFilterProvider.notifier)
                    .state = 'past_due',
              ),
              _FilterChip(
                label: context.l10n.adminSubscriptionsCancelledLabel,
                selected: filter == 'cancelled',
                onTap: () => ref
                    .read(adminSubscriptionFilterProvider.notifier)
                    .state = 'cancelled',
              ),
            ],
          ),
        ),
        const SizedBox(height: AppTheme.spacingSm),

        // List
        Expanded(
          child: subsAsync.when(
            loading: () => const LomeLoading(),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (subs) {
              if (subs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(PhosphorIcons.creditCard(PhosphorIconsStyle.duotone),
                          size: 64,
                          color: AppColors.grey300),
                      const SizedBox(height: AppTheme.spacingMd),
                      Text(context.l10n.adminSubscriptionsNoSubscriptions,
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.grey500)),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                color: AppColors.primary,
                onRefresh: () async =>
                    ref.invalidate(adminSubscriptionsProvider),
                child: ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(AppTheme.spacingMd),
                  itemCount: subs.length,
                  itemBuilder: (context, index) {
                    return _SubscriptionTile(subscription: subs[index])
                        .animate()
                        .fadeIn(delay: (index * 80).ms, duration: 300.ms);
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ─── Subscription Tile ───────────────────────────────────────────────────────

class _SubscriptionTile extends ConsumerWidget {
  const _SubscriptionTile({required this.subscription});

  final Subscription subscription;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateFmt = DateFormat('dd/MM/yyyy');

    return LomeCard(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingSm),
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Plan Badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color:
                      _planColor(subscription.plan).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
                child: Text(
                  _planLabel(context, subscription.plan).toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    color: _planColor(subscription.plan),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: AppTheme.spacingSm),
              // Status Badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _statusColor(subscription.status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
                child: Text(
                  _statusLabel(context, subscription.status),
                  style: TextStyle(
                    fontSize: 11,
                    color: _statusColor(subscription.status),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                '${subscription.amount.toStringAsFixed(2)} \u20ac/${subscription.billingCycle == 'monthly' ? context.l10n.adminSubscriptionsBillingMonthly : context.l10n.adminSubscriptionsBillingYearly}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingSm),

          // Tenant Name
          Text(
            subscription.tenantName ?? subscription.tenantId,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.grey900,
            ),
          ),
          const SizedBox(height: AppTheme.spacingXs),

          // Period info
          Row(
            children: [
              Icon(PhosphorIcons.calendarBlank(PhosphorIconsStyle.duotone),
                  size: 14, color: AppColors.grey400),
              const SizedBox(width: 4),
              Text(
                context.l10n.adminSubscriptionsPeriodDates(dateFmt.format(subscription.currentPeriodStart), dateFmt.format(subscription.currentPeriodEnd)),
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.grey500,
                ),
              ),
            ],
          ),

          if (subscription.renewalDate != null) ...[
            const SizedBox(height: 2),
            Row(
              children: [
                Icon(PhosphorIcons.arrowClockwise(PhosphorIconsStyle.duotone),
                    size: 14, color: AppColors.grey400),
                const SizedBox(width: 4),
                Text(
                  context.l10n.adminSubscriptionsRenewalDate(dateFmt.format(subscription.renewalDate!)),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.grey500,
                  ),
                ),
              ],
            ),
          ],

          // Actions for past_due
          if (subscription.status == 'past_due') ...[
            const Divider(height: AppTheme.spacingLg),
            Row(
              children: [
                Expanded(
                  child: LomeButton(
                    label: context.l10n.adminSubscriptionsReactivate,
                    variant: LomeButtonVariant.primary,
                    onPressed: () {
                      ref.read(updateSubscriptionProvider(
                        (id: subscription.id, data: {'status': 'active'}),
                      ));
                    },
                    icon: PhosphorIcons.arrowClockwise(PhosphorIconsStyle.duotone),
                    isExpanded: true,
                  ),
                ),
                const SizedBox(width: AppTheme.spacingSm),
                Expanded(
                  child: LomeButton(
                    label: context.l10n.cancel,
                    variant: LomeButtonVariant.danger,
                    onPressed: () {
                      ref.read(updateSubscriptionProvider(
                        (
                          id: subscription.id,
                          data: {
                            'status': 'cancelled',
                            'cancelled_at': DateTime.now().toIso8601String(),
                          }
                        ),
                      ));
                    },
                    icon: PhosphorIcons.x(PhosphorIconsStyle.duotone),
                    isExpanded: true,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Invoices Tab ────────────────────────────────────────────────────────────

class _InvoicesTab extends ConsumerWidget {
  const _InvoicesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(adminInvoiceFilterProvider);
    final invoicesAsync = ref.watch(adminInvoicesProvider);

    return Column(
      children: [
        // Invoice stats row
        const _InvoiceStatsRow(),

        // Filter chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMd),
          child: Row(
            children: [
              _FilterChip(
                label: context.l10n.adminSubscriptionsAllFilter,
                selected: filter == 'all',
                onTap: () => ref
                    .read(adminInvoiceFilterProvider.notifier)
                    .state = 'all',
              ),
              _FilterChip(
                label: context.l10n.adminSubscriptionsPendingLabel,
                selected: filter == 'pending',
                onTap: () => ref
                    .read(adminInvoiceFilterProvider.notifier)
                    .state = 'pending',
              ),
              _FilterChip(
                label: context.l10n.adminSubscriptionsPaidFilter,
                selected: filter == 'paid',
                onTap: () => ref
                    .read(adminInvoiceFilterProvider.notifier)
                    .state = 'paid',
              ),
              _FilterChip(
                label: context.l10n.adminSubscriptionsOverdueLabel,
                selected: filter == 'overdue',
                onTap: () => ref
                    .read(adminInvoiceFilterProvider.notifier)
                    .state = 'overdue',
              ),
            ],
          ),
        ),
        const SizedBox(height: AppTheme.spacingSm),

        // List
        Expanded(
          child: invoicesAsync.when(
            loading: () => const LomeLoading(),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (invoices) {
              if (invoices.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(PhosphorIcons.receipt(PhosphorIconsStyle.duotone),
                          size: 64,
                          color: AppColors.grey300),
                      const SizedBox(height: AppTheme.spacingMd),
                      Text(context.l10n.adminSubscriptionsNoInvoices,
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.grey500)),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                color: AppColors.primary,
                onRefresh: () async =>
                    ref.invalidate(adminInvoicesProvider),
                child: ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(AppTheme.spacingMd),
                  itemCount: invoices.length,
                  itemBuilder: (context, index) {
                    return _InvoiceTile(invoice: invoices[index])
                        .animate()
                        .fadeIn(delay: (index * 80).ms, duration: 300.ms);
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ─── Invoice Stats Row ───────────────────────────────────────────────────────

class _InvoiceStatsRow extends ConsumerWidget {
  const _InvoiceStatsRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(adminSubscriptionStatsProvider);

    return statsAsync.when(
      loading: () => const SizedBox(height: 60),
      error: (_, __) => const SizedBox.shrink(),
      data: (stats) {
        final fmt = NumberFormat.currency(locale: 'es_ES', symbol: '€');
        return Padding(
          padding: const EdgeInsets.all(AppTheme.spacingMd),
          child: Row(
            children: [
              _MiniStat(
                label: context.l10n.adminSubscriptionsInvoicedLabel,
                value: fmt.format(stats.totalRevenueInvoices),
                color: AppColors.primary,
              ),
              _MiniStat(
                label: context.l10n.adminSubscriptionsPendingLabel,
                value: '${stats.pendingInvoices}',
                color: AppColors.warning,
              ),
              _MiniStat(
                label: context.l10n.adminSubscriptionsOverdueLabel,
                value: '${stats.overdueInvoices}',
                color: AppColors.error,
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── Invoice Tile ────────────────────────────────────────────────────────────

class _InvoiceTile extends ConsumerWidget {
  const _InvoiceTile({required this.invoice});

  final Invoice invoice;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateFmt = DateFormat('dd/MM/yyyy');
    final currFmt = NumberFormat.currency(locale: 'es_ES', symbol: '€');

    return LomeCard(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingSm),
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(PhosphorIcons.receipt(PhosphorIconsStyle.duotone),
                  size: 20, color: AppColors.grey500),
              const SizedBox(width: AppTheme.spacingSm),
              Expanded(
                child: Text(
                  invoice.invoiceNumber,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.grey900,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _invoiceStatusColor(invoice.status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
                child: Text(
                  _invoiceStatusLabel(context, invoice.status),
                  style: TextStyle(
                    fontSize: 11,
                    color: _invoiceStatusColor(invoice.status),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingSm),

          // Tenant name
          Text(
            invoice.tenantName ?? invoice.tenantId,
            style: const TextStyle(fontSize: 14, color: AppColors.grey700),
          ),
          const SizedBox(height: AppTheme.spacingXs),

          // Amount breakdown
          Row(
            children: [
              Text(context.l10n.adminSubscriptionsSubtotalAmount(currFmt.format(invoice.amount)),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.grey500,
                  )),
              const SizedBox(width: AppTheme.spacingMd),
              Text(context.l10n.adminSubscriptionsTaxAmount(currFmt.format(invoice.tax)),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.grey500,
                  )),
              const Spacer(),
              Text(
                currFmt.format(invoice.total),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingXs),

          // Dates
          Row(
            children: [
              Text(
                context.l10n.adminSubscriptionsPeriodDates(dateFmt.format(invoice.periodStart), dateFmt.format(invoice.periodEnd)),
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.grey400,
                ),
              ),
              const Spacer(),
              Text(
                context.l10n.adminSubscriptionsDueDate(dateFmt.format(invoice.dueDate)),
                style: TextStyle(
                  fontSize: 12,
                  color: invoice.status == 'overdue'
                      ? AppColors.error
                      : AppColors.grey400,
                  fontWeight: invoice.status == 'overdue'
                      ? FontWeight.w600
                      : null,
                ),
              ),
            ],
          ),

          // Mark as paid action
          if (invoice.status == 'pending' || invoice.status == 'overdue') ...[
            const Divider(height: AppTheme.spacingLg),
            Align(
              alignment: Alignment.centerRight,
              child: LomeButton(
                label: context.l10n.adminSubscriptionsMarkPaid,
                variant: LomeButtonVariant.primary,
                onPressed: () {
                  ref.read(markInvoicePaidProvider(invoice.id));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(context.l10n.adminSubscriptionsInvoicePaid)),
                  );
                },
                icon: PhosphorIcons.check(PhosphorIconsStyle.duotone),
              ),
            ),
          ],

          // Paid date
          if (invoice.paidAt != null) ...[
            const SizedBox(height: AppTheme.spacingXs),
            Row(
              children: [
                Icon(PhosphorIcons.checkCircle(PhosphorIconsStyle.fill),
                    size: 14, color: AppColors.success),
                const SizedBox(width: 4),
                Text(
                  context.l10n.adminSubscriptionsPaidDate(dateFmt.format(invoice.paidAt!)),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.success,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Filter Chip ─────────────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: AppTheme.spacingSm),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        selectedColor: AppColors.primary.withOpacity(0.15),
        checkmarkColor: AppColors.primary,
        labelStyle: TextStyle(
          color: selected ? AppColors.primary : AppColors.grey600,
          fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
    );
  }
}

// ─── Helpers ─────────────────────────────────────────────────────────────────

Color _planColor(String plan) {
  switch (plan) {
    case 'free':
      return AppColors.grey500;
    case 'basic':
      return AppColors.info;
    case 'pro':
      return AppColors.primary;
    case 'enterprise':
      return Colors.deepPurple;
    default:
      return AppColors.grey500;
  }
}

String _planLabel(BuildContext context, String plan) {
  switch (plan) {
    case 'free':
      return context.l10n.adminSubscriptionsPlanFree;
    case 'basic':
      return context.l10n.adminSubscriptionsPlanBasic;
    case 'pro':
      return context.l10n.adminSubscriptionsPlanPro;
    case 'enterprise':
      return context.l10n.adminSubscriptionsPlanEnterprise;
    default:
      return plan;
  }
}

Color _statusColor(String status) {
  switch (status) {
    case 'active':
      return AppColors.success;
    case 'past_due':
      return AppColors.warning;
    case 'cancelled':
      return AppColors.error;
    case 'trialing':
      return AppColors.info;
    default:
      return AppColors.grey500;
  }
}

String _statusLabel(BuildContext context, String status) {
  switch (status) {
    case 'active':
      return context.l10n.adminSubscriptionsStatusActive;
    case 'past_due':
      return context.l10n.adminSubscriptionsStatusPastDue;
    case 'cancelled':
      return context.l10n.adminSubscriptionsStatusCancelled;
    case 'trialing':
      return context.l10n.adminSubscriptionsStatusTrialing;
    default:
      return status;
  }
}

Color _invoiceStatusColor(String status) {
  switch (status) {
    case 'pending':
      return AppColors.warning;
    case 'paid':
      return AppColors.success;
    case 'overdue':
      return AppColors.error;
    case 'cancelled':
      return AppColors.grey500;
    case 'refunded':
      return AppColors.info;
    default:
      return AppColors.grey500;
  }
}

String _invoiceStatusLabel(BuildContext context, String status) {
  switch (status) {
    case 'pending':
      return context.l10n.adminSubscriptionsInvoiceStatusPending;
    case 'paid':
      return context.l10n.adminSubscriptionsInvoiceStatusPaid;
    case 'overdue':
      return context.l10n.adminSubscriptionsInvoiceStatusOverdue;
    case 'cancelled':
      return context.l10n.adminSubscriptionsInvoiceStatusCancelled;
    case 'refunded':
      return context.l10n.adminSubscriptionsInvoiceStatusRefunded;
    default:
      return status;
  }
}
