import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/extensions/context_extensions.dart';
import '../../../../../core/widgets/lome_button.dart';
import '../../../../../core/widgets/lome_card.dart';
import '../../../../../core/widgets/lome_loading.dart';
import '../../../../../core/widgets/tactile_wrapper.dart';
import '../../../domain/entities/admin_entities.dart';
import '../providers/admin_moderation_provider.dart';

class AdminModerationPage extends ConsumerStatefulWidget {
  const AdminModerationPage({super.key});

  @override
  ConsumerState<AdminModerationPage> createState() =>
      _AdminModerationPageState();
}

class _AdminModerationPageState extends ConsumerState<AdminModerationPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 1, vsync: this);
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
        title: Text(context.l10n.adminModerationTitle),
        actions: [
          TactileWrapper(
            onTap: () => ref.invalidate(flaggedReviewsProvider),
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
          tabs: [Tab(text: context.l10n.adminModerationFlaggedReviewsTab)],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_ReviewsModerationTab()],
      ),
    );
  }
}

// ─── Reviews Moderation Tab ──────────────────────────────────────────────────

class _ReviewsModerationTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviewsAsync = ref.watch(flaggedReviewsProvider);

    return reviewsAsync.when(
      loading: () => const LomeLoading(),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (reviews) {
        if (reviews.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  PhosphorIcons.checkCircle(PhosphorIconsStyle.duotone),
                  size: 64,
                  color: AppColors.grey300,
                ),
                const SizedBox(height: AppTheme.spacingMd),
                Text(
                  context.l10n.adminModerationNoReviews,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.grey500,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingSm),
                Text(
                  context.l10n.adminModerationAllReviewed,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.grey400,
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(flaggedReviewsProvider),
          color: AppColors.primary,
          child: ListView.builder(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(AppTheme.spacingMd),
            itemCount: reviews.length,
            itemBuilder: (context, index) {
              return _ReviewModerationCard(
                review: reviews[index],
              ).animate().fadeIn(delay: (index * 100).ms, duration: 300.ms);
            },
          ),
        );
      },
    );
  }
}

// ─── Review Moderation Card ──────────────────────────────────────────────────

class _ReviewModerationCard extends ConsumerWidget {
  const _ReviewModerationCard({required this.review});

  final FlaggedReview review;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LomeCard(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingMd),
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Flag reason
          if (review.flagReason != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    PhosphorIcons.flag(PhosphorIconsStyle.fill),
                    size: 12,
                    color: AppColors.warning,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    review.flagReason!,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.warning,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: AppTheme.spacingMd),

          // User info + rating
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.primaryLight.withOpacity(0.2),
                child: Text(
                  (review.userName ?? '?')[0],
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: AppTheme.spacingSm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.userName ?? context.l10n.adminModerationUser,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.grey900,
                      ),
                    ),
                    if (review.tenantName != null)
                      Text(
                        review.tenantName!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.grey500,
                        ),
                      ),
                  ],
                ),
              ),
              // Stars
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(5, (i) {
                  return Icon(
                    i < review.rating
                        ? PhosphorIcons.star(PhosphorIconsStyle.fill)
                        : PhosphorIcons.star(),
                    size: 16,
                    color: AppColors.warning,
                  );
                }),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingSm),

          // Comentario
          if (review.comment != null)
            Text(
              review.comment!,
              style: const TextStyle(fontSize: 14, color: AppColors.grey700),
            ),

          const Divider(height: AppTheme.spacingLg),

          // Acciones
          Row(
            children: [
              Expanded(
                child: LomeButton(
                  label: context.l10n.adminModerationApprove,
                  variant: LomeButtonVariant.outlined,
                  onPressed: () {
                    ref.read(approveReviewProvider(review.id));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          context.l10n.adminModerationReviewApproved,
                        ),
                      ),
                    );
                  },
                  icon: PhosphorIcons.check(),
                  isExpanded: true,
                ),
              ),
              const SizedBox(width: AppTheme.spacingSm),
              Expanded(
                child: LomeButton(
                  label: context.l10n.adminModerationReject,
                  variant: LomeButtonVariant.danger,
                  onPressed: () {
                    ref.read(rejectReviewProvider(review.id));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          context.l10n.adminModerationReviewRejected,
                        ),
                      ),
                    );
                  },
                  icon: PhosphorIcons.x(),
                  isExpanded: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
