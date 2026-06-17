import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_router.dart';
import '../bloc/recycling_bloc.dart';

class ActiveSessionPage extends StatelessWidget {
  final String binId;
  final String locationName;
  final String sessionId;

  const ActiveSessionPage({
    super.key,
    required this.binId,
    required this.locationName,
    required this.sessionId,
  });

  @override
  Widget build(BuildContext context) {
    return BlocListener<RecyclingBloc, RecyclingState>(
      listener: (context, state) {
        if (state is RecyclingSessionCompleted) {
          context.pushReplacement(
            AppRoutes.sessionSummary,
            extra: {
              'bottlesDropped': state.session.bottlesDropped,
              'pointsEarned': state.session.pointsEarned,
              'co2Saved': state.session.co2Saved,
              'autoClosed': state.autoClosed,
            },
          );
        }
      },
      child: PopScope(
        canPop: false,
        child: Scaffold(
          backgroundColor: AppColors.backgroundLight,
          body: BlocBuilder<RecyclingBloc, RecyclingState>(
            builder: (context, state) {
              final session = state is RecyclingSessionActive
                  ? state.session
                  : null;
              final timerSeconds = state is RecyclingSessionActive
                  ? state.timerSeconds
                  : 60;

              return SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),

                      // Header
                      Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'BIN CONNECTED',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            'ID: ${binId.toUpperCase()}',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: AppColors.textMuted),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Location
                      Center(
                        child: Text(
                          locationName,
                          style: Theme.of(context).textTheme.displaySmall,
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: Text(
                          'Ready to receive your items',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Unlock icon
                      Center(
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.lock_open_rounded,
                            color: Colors.white,
                            size: 56,
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Instruction card
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEF2FF),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: const BoxDecoration(
                                color: AppColors.info,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.info_outline_rounded,
                                  color: Colors.white, size: 18),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Drop items one by one',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(color: AppColors.info),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Please wait for the green light on the bin before dropping the next bottle.',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Stats card
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceWhite,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            _StatRow(
                              icon: Icons.liquor_rounded,
                              iconColor: AppColors.info,
                              label: 'Bottles Dropped',
                              value: '${session?.bottlesDropped ?? 0}',
                            ),
                            const SizedBox(height: 12),
                            _StatRow(
                              icon: Icons.monetization_on_rounded,
                              iconColor: AppColors.primary,
                              label: 'Points Earned',
                              value: '+${session?.pointsEarned ?? 0}',
                              valueColor: AppColors.primary,
                            ),
                          ],
                        ),
                      ),

                      const Spacer(),

                      // Auto-close timer
                      Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.timer_outlined,
                                size: 16, color: AppColors.textMuted),
                            const SizedBox(width: 6),
                            Text(
                              'Auto-closes in ${timerSeconds}s of inactivity',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: AppColors.textMuted),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Finish button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.secondary,
                          ),
                          icon: const Icon(Icons.arrow_forward_rounded),
                          label: const Text('Finish Session'),
                          onPressed: () => context
                              .read<RecyclingBloc>()
                              .add(RecyclingFinishSessionEvent()),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final Color? valueColor;

  const _StatRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: valueColor ?? AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}