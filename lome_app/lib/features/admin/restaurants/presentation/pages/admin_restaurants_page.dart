import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../../core/router/route_names.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/extensions/context_extensions.dart';
import '../../../../../core/widgets/lome_card.dart';
import '../../../../../core/widgets/lome_loading.dart';
import '../../../../../core/widgets/lome_text_field.dart';
import '../../../domain/entities/admin_entities.dart';
import '../providers/admin_restaurants_provider.dart';
import '../../../../../core/widgets/tactile_wrapper.dart';

class AdminRestaurantsPage extends ConsumerStatefulWidget {
  const AdminRestaurantsPage({super.key});

  @override
  ConsumerState<AdminRestaurantsPage> createState() =>
      _AdminRestaurantsPageState();
}

class _AdminRestaurantsPageState extends ConsumerState<AdminRestaurantsPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _searchController = TextEditingController();

  static const _filters = ['all', 'active', 'pending', 'suspended'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_onTabChanged);
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      ref.read(adminRestaurantFilterProvider.notifier).state =
          _filters[_tabController.index];
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final restaurantsAsync = ref.watch(adminRestaurantsProvider);
    final counts = ref.watch(adminStatusCountsProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(context.l10n.adminRestaurantsTitle),
        actions: [
          TactileWrapper(
            onTap: () {
              ref.invalidate(adminRestaurantsProvider);
              ref.invalidate(adminAllRestaurantsProvider);
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
            Tab(text: context.l10n.adminRestaurantsFilterAll),
            Tab(text: context.l10n.adminRestaurantsFilterActive),
            Tab(text: context.l10n.adminRestaurantsFilterPending),
            Tab(text: context.l10n.adminRestaurantsFilterSuspended),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppTheme.spacingMd),
            child: LomeSearchField(
              controller: _searchController,
              hint: context.l10n.adminRestaurantsSearchHint,
              onChanged: (value) {
                ref.read(adminRestaurantSearchProvider.notifier).state = value;
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMd),
            child: Row(
              children: [
                _QuickStat(
                  label: context.l10n.total,
                  value: '${counts['total'] ?? 0}',
                  color: AppColors.primary,
                ),
                const SizedBox(width: AppTheme.spacingSm),
                _QuickStat(
                  label: context.l10n.adminRestaurantsFilterActive,
                  value: '${counts['active'] ?? 0}',
                  color: AppColors.success,
                ),
                const SizedBox(width: AppTheme.spacingSm),
                _QuickStat(
                  label: context.l10n.adminRestaurantsFilterPending,
                  value: '${counts['pending'] ?? 0}',
                  color: AppColors.warning,
                ),
                const SizedBox(width: AppTheme.spacingSm),
                _QuickStat(
                  label: context.l10n.adminRestaurantsFilterSuspended,
                  value: '${counts['suspended'] ?? 0}',
                  color: AppColors.error,
                ),
              ],
            ),
          ).animate().fadeIn(duration: 300.ms),
          const SizedBox(height: AppTheme.spacingMd),
          Expanded(
            child: restaurantsAsync.when(
              loading: () => const LomeLoading(),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (restaurants) {
                if (restaurants.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          PhosphorIcons.storefront(PhosphorIconsStyle.duotone),
                          size: 64,
                          color: AppColors.grey300,
                        ),
                        const SizedBox(height: AppTheme.spacingMd),
                        Text(
                          context.l10n.adminRestaurantsEmpty,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.grey500,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () async {
                    ref.invalidate(adminRestaurantsProvider);
                    ref.invalidate(adminAllRestaurantsProvider);
                  },
                  child: ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spacingMd,
                    ),
                    itemCount: restaurants.length,
                    itemBuilder: (context, index) {
                      return _RestaurantTile(restaurant: restaurants[index])
                          .animate()
                          .fadeIn(delay: (index * 50).ms, duration: 300.ms)
                          .slideX(begin: 0.03);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickStat extends StatelessWidget {
  const _QuickStat({
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
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingSm,
          vertical: AppTheme.spacingSm,
        ),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(label, style: TextStyle(fontSize: 11, color: color)),
          ],
        ),
      ),
    );
  }
}

class _RestaurantTile extends ConsumerWidget {
  const _RestaurantTile({required this.restaurant});
  final AdminRestaurant restaurant;

  Color _statusColor(String status) {
    switch (status) {
      case 'active':
        return AppColors.success;
      case 'pending':
        return AppColors.warning;
      case 'suspended':
        return AppColors.error;
      default:
        return AppColors.grey500;
    }
  }

  String _statusLabel(BuildContext context, String status) {
    switch (status) {
      case 'active':
        return context.l10n.active;
      case 'pending':
        return context.l10n.statusPending;
      case 'suspended':
        return context.l10n.statusSuspended;
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = _statusColor(restaurant.status);

    return LomeCard(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingSm),
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      onTap: () {
        context.pushNamed(
          RouteNames.adminRestaurantDetail,
          pathParameters: {'id': restaurant.id},
        );
      },
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.primaryLight.withOpacity(0.2),
            backgroundImage: restaurant.logoUrl != null
                ? NetworkImage(restaurant.logoUrl!)
                : null,
            child: restaurant.logoUrl == null
                ? Text(
                    restaurant.name.isNotEmpty ? restaurant.name[0] : '?',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: AppTheme.spacingMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  restaurant.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.grey900,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    if (restaurant.city != null) ...[
                      Icon(
                        PhosphorIcons.mapPin(PhosphorIconsStyle.fill),
                        size: 14,
                        color: AppColors.grey500,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        restaurant.city!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.grey500,
                        ),
                      ),
                    ],
                    if (restaurant.rating > 0) ...[
                      const SizedBox(width: AppTheme.spacingMd),
                      Icon(
                        PhosphorIcons.star(PhosphorIconsStyle.fill),
                        size: 14,
                        color: AppColors.warning,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        restaurant.rating.toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.grey500,
                        ),
                      ),
                    ],
                    if (restaurant.totalOrders > 0) ...[
                      const SizedBox(width: AppTheme.spacingMd),
                      Text(
                        context.l10n.adminRestaurantsOrderCount(
                          restaurant.totalOrders,
                        ),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.grey500,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusFull),
            ),
            child: Text(
              _statusLabel(context, restaurant.status),
              style: TextStyle(
                fontSize: 11,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: AppTheme.spacingSm),
          PopupMenuButton<String>(
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'view',
                child: Text(context.l10n.adminRestaurantsViewDetail),
              ),
              if (restaurant.status == 'active')
                PopupMenuItem(
                  value: 'suspend',
                  child: Text(context.l10n.adminRestaurantDetailSuspend),
                ),
              if (restaurant.status == 'suspended')
                PopupMenuItem(
                  value: 'activate',
                  child: Text(context.l10n.adminRestaurantsActivate),
                ),
              if (restaurant.status == 'pending')
                PopupMenuItem(
                  value: 'activate',
                  child: Text(context.l10n.adminRestaurantDetailApprove),
                ),
            ],
            onSelected: (value) {
              if (value == 'view') {
                context.pushNamed(
                  RouteNames.adminRestaurantDetail,
                  pathParameters: {'id': restaurant.id},
                );
              } else if (value == 'suspend') {
                ref.read(
                  toggleRestaurantStatusProvider((
                    id: restaurant.id,
                    newStatus: 'suspended',
                  )),
                );
              } else if (value == 'activate') {
                ref.read(
                  toggleRestaurantStatusProvider((
                    id: restaurant.id,
                    newStatus: 'active',
                  )),
                );
              }
            },
            icon: Icon(
              PhosphorIcons.dotsThreeVertical(PhosphorIconsStyle.duotone),
              color: AppColors.grey500,
            ),
          ),
        ],
      ),
    );
  }
}
