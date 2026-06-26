import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_router.dart';
import '../../../../core/utils/injection_container.dart';
import '../../domain/entities/reward.dart';
import '../bloc/rewards_bloc.dart';

class MyCouponsPage extends StatelessWidget {
  const MyCouponsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<RewardsBloc>()..add(RewardsLoadCouponsEvent()),
      child: const _MyCouponsView(),
    );
  }
}

class _MyCouponsView extends StatefulWidget {
  const _MyCouponsView();

  @override
  State<_MyCouponsView> createState() => _MyCouponsViewState();
}

class _MyCouponsViewState extends State<_MyCouponsView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
        title: const Text('Mis Cupones'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textMuted,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          labelStyle: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 13,
            fontWeight: FontWeight.w400,
          ),
          tabs: const [
            Tab(text: 'Disponibles'),
            Tab(text: 'Usados'),
            Tab(text: 'Expirados'),
          ],
        ),
      ),
      body: BlocBuilder<RewardsBloc, RewardsState>(
        builder: (context, state) {
          if (state is RewardsLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is RewardsError) {
            return _EmptyState(
              icon: Icons.wifi_off_rounded,
              title: 'Error al cargar',
              subtitle: state.message,
              actionLabel: 'Reintentar',
              onAction: () =>
                  context.read<RewardsBloc>().add(RewardsLoadCouponsEvent()),
            );
          }

          if (state is RewardsCouponsLoaded) {
            final unused = state.coupons.where((c) => c.isUnused).toList();
            final redeemed = state.coupons.where((c) => c.isRedeemed).toList();
            final expired = state.coupons.where((c) => c.isExpired).toList();

            return TabBarView(
              controller: _tabController,
              children: [
                _CouponList(
                  coupons: unused,
                  emptyIcon: Icons.card_giftcard_rounded,
                  emptyTitle: 'Sin cupones disponibles',
                  emptySubtitle: 'Canjea tus puntos en la tienda de premios.',
                  actionLabel: 'Ir a Premios',
                  onAction: () => context.go(AppRoutes.rewards),
                ),
                _CouponList(
                  coupons: redeemed,
                  emptyIcon: Icons.check_circle_outline_rounded,
                  emptyTitle: 'Sin cupones usados',
                  emptySubtitle: 'Los cupones que uses aparecerán aquí.',
                ),
                _CouponList(
                  coupons: expired,
                  emptyIcon: Icons.timer_off_rounded,
                  emptyTitle: 'Sin cupones expirados',
                  emptySubtitle: 'Usa tus cupones antes de que venzan.',
                ),
              ],
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}

// ── Coupon List ───────────────────────────────────────────────────────────────

class _CouponList extends StatelessWidget {
  final List<UserCoupon> coupons;
  final IconData emptyIcon;
  final String emptyTitle;
  final String emptySubtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _CouponList({
    required this.coupons,
    required this.emptyIcon,
    required this.emptyTitle,
    required this.emptySubtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    if (coupons.isEmpty) {
      return _EmptyState(
        icon: emptyIcon,
        title: emptyTitle,
        subtitle: emptySubtitle,
        actionLabel: actionLabel,
        onAction: onAction,
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () async =>
          context.read<RewardsBloc>().add(RewardsLoadCouponsEvent()),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        itemCount: coupons.length,
        itemBuilder: (_, i) => _CouponCard(coupon: coupons[i]),
      ),
    );
  }
}

// ── Coupon Card ───────────────────────────────────────────────────────────────

class _CouponCard extends StatelessWidget {
  final UserCoupon coupon;
  const _CouponCard({required this.coupon});

  Color get _statusColor {
    if (coupon.isUnused) return AppColors.primary;
    if (coupon.isRedeemed) return AppColors.textMuted;
    return AppColors.error;
  }

  String get _statusLabel {
    if (coupon.isUnused) return 'Disponible';
    if (coupon.isRedeemed) return 'Utilizado';
    return 'Expirado';
  }

  IconData get _statusIcon {
    if (coupon.isUnused) return Icons.check_circle_rounded;
    if (coupon.isRedeemed) return Icons.done_all_rounded;
    return Icons.timer_off_rounded;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: coupon.isUnused
          ? () => _showCouponDetail(context)
          : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.surfaceWhite,
          borderRadius: BorderRadius.circular(16),
          border: coupon.isUnused
              ? Border.all(color: AppColors.primary.withOpacity(0.3), width: 1.5)
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            // Top section — ticket style
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // QR thumbnail
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: coupon.isUnused
                          ? AppColors.backgroundLight
                          : AppColors.surfaceGrey,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: coupon.isUnused
                        ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: QrImageView(
                        data: coupon.qrCode,
                        version: QrVersions.auto,
                        size: 72,
                        backgroundColor: Colors.white,
                      ),
                    )
                        : Icon(
                      coupon.isRedeemed
                          ? Icons.done_all_rounded
                          : Icons.timer_off_rounded,
                      size: 32,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Status chip
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: _statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(_statusIcon,
                                  size: 11, color: _statusColor),
                              const SizedBox(width: 4),
                              Text(
                                _statusLabel,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: _statusColor,
                                  letterSpacing: .5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          coupon.rewardTitle,
                          style:
                          Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: coupon.isUnused
                                ? AppColors.textPrimary
                                : AppColors.textMuted,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          coupon.companyName,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  if (coupon.isUnused)
                    const Icon(Icons.chevron_right_rounded,
                        color: AppColors.textMuted),
                ],
              ),
            ),

            // Dashed divider — ticket tear line
            _TicketDivider(color: _statusColor.withOpacity(.2)),

            // Bottom section — code + expiry
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'CÓDIGO',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textMuted,
                          letterSpacing: 1,
                          fontSize: 9,
                        ),
                      ),
                      Text(
                        coupon.qrCode,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontFamily: 'monospace',
                          letterSpacing: 1.5,
                          color: coupon.isUnused
                              ? AppColors.textPrimary
                              : AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        coupon.isRedeemed ? 'USADO EL' : 'VÁLIDO HASTA',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textMuted,
                          letterSpacing: 1,
                          fontSize: 9,
                        ),
                      ),
                      Text(
                        coupon.isRedeemed && coupon.redeemedAt != null
                            ? DateFormat('dd MMM yyyy').format(coupon.redeemedAt!)
                            : DateFormat('dd MMM yyyy').format(coupon.expiresAt),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: coupon.isExpired
                              ? AppColors.error
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCouponDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CouponFullSheet(coupon: coupon),
    );
  }
}

// ── Full Coupon Sheet ─────────────────────────────────────────────────────────

class _CouponFullSheet extends StatelessWidget {
  final UserCoupon coupon;
  const _CouponFullSheet({required this.coupon});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: AppColors.surfaceGrey,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Status
          Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Cupón Disponible',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            coupon.rewardTitle,
            style: Theme.of(context).textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            'Válido en ${coupon.companyName}',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: AppColors.textSecondary),
          ),
          const Divider(height: 32),

          // QR Code large
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.backgroundLight,
              borderRadius: BorderRadius.circular(16),
            ),
            child: QrImageView(
              data: coupon.qrCode,
              version: QrVersions.auto,
              size: 200,
              backgroundColor: Colors.white,
            ),
          ),
          const SizedBox(height: 16),

          // Code
          Text(
            coupon.qrCode,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              letterSpacing: 3,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Expira: ${DateFormat('dd MMM yyyy').format(coupon.expiresAt)}',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary),
              onPressed: () => Navigator.pop(context),
              child: const Text('Cerrar'),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Ticket Divider ────────────────────────────────────────────────────────────

class _TicketDivider extends StatelessWidget {
  final Color color;
  const _TicketDivider({required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(
        40,
            (i) => Expanded(
          child: Container(
            height: 1,
            color: i.isEven ? color : Colors.transparent,
          ),
        ),
      ),
    );
  }
}

// ── Empty State ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.surfaceGrey,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 36, color: AppColors.textMuted),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: onAction,
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}