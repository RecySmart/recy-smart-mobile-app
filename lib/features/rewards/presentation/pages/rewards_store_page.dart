import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_router.dart';
import '../../../../core/utils/injection_container.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../domain/entities/reward.dart';
import '../bloc/rewards_bloc.dart';

class RewardsStorePage extends StatefulWidget {
  const RewardsStorePage({super.key});

  @override
  State<RewardsStorePage> createState() => _RewardsStorePageState();
}

class _RewardsStorePageState extends State<RewardsStorePage> {
  @override
  void initState() {
    super.initState();
    // Refresh wallet balance every time this tab is opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final authBloc = context.read<AuthBloc>();
      if (authBloc.state is AuthAuthenticated) {
        authBloc.add(AuthGetProfileEvent());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<RewardsBloc>()..add(RewardsLoadEvent()),
      child: const _RewardsView(),
    );
  }
}

class _RewardsView extends StatelessWidget {
  const _RewardsView();

  static const _categories = ['Todos', 'Comida y bebidas', 'Transporte', 'Eco', 'General'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: BlocListener<RewardsBloc, RewardsState>(
        listener: (context, state) {
          if (state is RewardsRedeemSuccess) {
            // Refresh balance after redemption
            context.read<AuthBloc>().add(AuthGetProfileEvent());
            context.push(
              AppRoutes.couponDetail.replaceFirst(':id', state.coupon.id),
              extra: state.coupon,
            );
          }
          if (state is RewardsError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        child: CustomScrollView(
          slivers: [
            SliverSafeArea(
              bottom: false,
              sliver: SliverToBoxAdapter(child: _BalanceHeader()),
            ),
            SliverToBoxAdapter(
              child: BlocBuilder<RewardsBloc, RewardsState>(
                builder: (context, state) {
                  final selected = state is RewardsLoaded
                      ? state.selectedCategory
                      : 'Todos';
                  return SizedBox(
                    height: 48,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _categories.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (_, i) {
                        final cat = _categories[i];
                        final isSelected = cat == selected;
                        return FilterChip(
                          label: Text(cat),
                          selected: isSelected,
                          onSelected: (_) => context
                              .read<RewardsBloc>()
                              .add(RewardsCategoryFilterEvent(cat)),
                          backgroundColor: AppColors.surfaceWhite,
                          selectedColor: AppColors.secondary,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : AppColors.textPrimary,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                          ),
                          side: BorderSide.none,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 16)),
            BlocBuilder<RewardsBloc, RewardsState>(
              buildWhen: (prev, current) => current is RewardsLoading ||
                  current is RewardsLoaded || current is RewardsError,
              builder: (context, state) {
                if (state is RewardsLoading) {
                  return SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (_, i) => Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Shimmer.fromColors(
                            baseColor: AppColors.surfaceGrey,
                            highlightColor: Colors.white,
                            child: Container(
                              height: 315,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        ),
                        childCount: 4,
                      ),
                    ),
                  );
                }
                if (state is RewardsLoaded) {
                  if (state.filtered.isEmpty) {
                    return const SliverFillRemaining(
                      child: Center(child: Text('No hay premios en esta categoría.')),
                    );
                  }
                  return SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                            (_, i) => Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _RewardCard(
                            reward: state.filtered[i],
                            isLoading: state.redeemingRewardId == state.filtered[i].id,
                            onRedeem: () => context
                                .read<RewardsBloc>()
                                .add(RewardsRedeemEvent(state.filtered[i].id)),
                          ),
                        ),
                        childCount: state.filtered.length,
                      ),
                    ),
                  );
                }
                if (state is RewardsError) {
                  return SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.wifi_off_rounded,
                                size: 48, color: AppColors.textMuted),
                            const SizedBox(height: 12),
                            Text('No se pudieron cargar los premios',
                                style: Theme.of(context).textTheme.titleMedium),
                            const SizedBox(height: 8),
                            Text(state.message, textAlign: TextAlign.center),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => context
                                  .read<RewardsBloc>()
                                  .add(RewardsLoadEvent()),
                              child: const Text('Reintentar'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }
                return const SliverToBoxAdapter(child: SizedBox.shrink());
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _BalanceHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Text('Tienda de Premios', style: Theme.of(context).textTheme.displaySmall),
          const SizedBox(height: 12),
          // BlocBuilder on AuthBloc so balance updates whenever profile refreshes
          BlocBuilder<AuthBloc, AuthState>(
            builder: (context, state) {
              final points = state is AuthAuthenticated
                  ? state.user.wallet?.currentBalance ?? 0
                  : 0;
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryDark],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.white24,
                      child: Icon(Icons.account_balance_wallet_outlined,
                          color: Colors.white, size: 16),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Saldo Disponible',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: Colors.white70)),
                        Text('$points pts.',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            )),
                      ],
                    ),
                    const Spacer(),
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white),
                        minimumSize: Size.zero,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 6),
                      ),
                      onPressed: () => context.push(AppRoutes.myCoupons),
                      child: const Text('Historial'),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _RewardCard extends StatelessWidget {
  final Reward reward;
  final VoidCallback onRedeem;
  final bool isLoading;
  const _RewardCard({
    required this.reward, 
    required this.onRedeem,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 160,
            width: double.infinity,
            decoration: const BoxDecoration(
              color: AppColors.surfaceGrey,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: const Center(
              child: Icon(Icons.card_giftcard_rounded,
                  size: 48, color: AppColors.textMuted),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      reward.category.toUpperCase(),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.warning,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${reward.costInPoints}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(reward.title,
                    style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 4),
                Text(reward.description,
                    style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 12),
                if (reward.remainingStock < 10)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      '¡Solo quedan ${reward.remainingStock}!',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.error,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondary,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: reward.isAvailable && !isLoading
                        ? onRedeem
                        : null,
                    child: isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : Text(
                            reward.availabilityLabel,
                          ),
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
