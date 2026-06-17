import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_router.dart';
import '../../../../core/utils/injection_container.dart';
import '../bloc/rewards_bloc.dart';
import '../../domain/entities/reward.dart';

class CouponDetailPage extends StatelessWidget {
  final String couponId;
  const CouponDetailPage({super.key, required this.couponId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<RewardsBloc>()..add(RewardsLoadCouponsEvent()),
      child: _CouponDetailView(couponId: couponId),
    );
  }
}

class _CouponDetailView extends StatelessWidget {
  final String couponId;
  const _CouponDetailView({required this.couponId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Digital Coupon'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: BlocBuilder<RewardsBloc, RewardsState>(
        builder: (context, state) {
          UserCoupon? coupon;
          if (state is RewardsCouponsLoaded) {
            try {
              coupon = state.coupons.firstWhere((c) => c.id == couponId);
            } catch (_) {}
          }
          // Also accept coupon from redeem success state passed via extra
          if (state is RewardsRedeemSuccess && state.coupon.id == couponId) {
            coupon = state.coupon;
          }

          if (coupon == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Coupon card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceWhite,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Status badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: coupon.isUnused
                              ? AppColors.primaryLight
                              : AppColors.surfaceGrey,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          coupon.isUnused ? 'Success Redemption' : coupon.status,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: coupon.isUnused
                                ? AppColors.primary
                                : AppColors.textMuted,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        coupon.rewardTitle,
                        style: Theme.of(context).textTheme.headlineMedium,
                        textAlign: TextAlign.center,
                      ),
                      const Divider(height: 32),

                      // QR Code
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.backgroundLight,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: QrImageView(
                          data: coupon.qrCode,
                          version: QrVersions.auto,
                          size: 180,
                          backgroundColor: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Code
                      Text(
                        coupon.qrCode,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          letterSpacing: 2,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Valid at:  ',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          Text(
                            coupon.companyName,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),

                      if (coupon.isRedeemed) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF3E0),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.info_outline_rounded,
                                  color: AppColors.warning, size: 16),
                              const SizedBox(width: 8),
                              Text('This coupon has been used.',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(color: AppColors.warning)),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.secondary),
                    onPressed: () => context.go(AppRoutes.rewards),
                    child: const Text('Back to Rewards'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}