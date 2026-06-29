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
        // ── Navigate to summary when session ends ─────────────────────────
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

        // ── Show SnackBar on every bottle rejection ───────────────────────
        if (state is RecyclingSessionActive && state.bottleRejected) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: const Row(
                  children: [
                    Icon(Icons.warning_rounded, color: Colors.white, size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Objeto no reconocido',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            'Solo se aceptan botellas de plástico PET.',
                            style: TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                backgroundColor: AppColors.error,
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              ),
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
              final rejected = state is RecyclingSessionActive
                  ? state.bottleRejected
                  : false;

              return SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),

                      // ── Header ──────────────────────────────────────────
                      Row(
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: rejected
                                  ? AppColors.error
                                  : AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            child: Text(
                              rejected
                                  ? 'OBJETO NO RECONOCIDO'
                                  : 'BIN CONNECTED',
                              key: ValueKey(rejected),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                color: rejected
                                    ? AppColors.error
                                    : AppColors.primary,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            'ID: ${binId.length > 8 ? binId.substring(0, 8).toUpperCase() : binId.toUpperCase()}',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: AppColors.textMuted),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // ── Location ────────────────────────────────────────
                      Center(
                        child: Text(
                          locationName,
                          style: Theme.of(context).textTheme.displaySmall,
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: Text(
                            rejected
                                ? 'Solo botellas de plástico PET'
                                : 'Listo para recibir tus botellas',
                            key: ValueKey(rejected),
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                              color: rejected
                                  ? AppColors.error
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // ── Status icon ─────────────────────────────────────
                      Center(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: rejected
                                ? AppColors.error
                                : AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            rejected
                                ? Icons.close_rounded
                                : Icons.lock_open_rounded,
                            color: Colors.white,
                            size: 56,
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // ── Info / Warning card ─────────────────────────────
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: rejected
                              ? const Color(0xFFFEE2E2)
                              : const Color(0xFFEEF2FF),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: rejected
                                    ? AppColors.error
                                    : AppColors.info,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                rejected
                                    ? Icons.warning_rounded
                                    : Icons.info_outline_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    rejected
                                        ? 'Objeto no válido'
                                        : 'Deposita uno a la vez',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                      color: rejected
                                          ? AppColors.error
                                          : AppColors.info,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    rejected
                                        ? 'El objeto ingresado no fue reconocido como botella PET. Intenta nuevamente.'
                                        : 'Espera la luz verde del tacho antes de depositar la siguiente botella.',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                        color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ── Stats card ──────────────────────────────────────
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
                              label: 'Botellas depositadas',
                              value: '${session?.bottlesDropped ?? 0}',
                            ),
                            const SizedBox(height: 12),
                            _StatRow(
                              icon: Icons.monetization_on_rounded,
                              iconColor: AppColors.primary,
                              label: 'Puntos ganados',
                              value: '+${session?.pointsEarned ?? 0}',
                              valueColor: AppColors.primary,
                            ),
                          ],
                        ),
                      ),

                      const Spacer(),

                      // ── Timer ───────────────────────────────────────────
                      Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.timer_outlined,
                              size: 16,
                              color: timerSeconds <= 10
                                  ? AppColors.error
                                  : AppColors.textMuted,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Se cierra en ${timerSeconds}s de inactividad',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                color: timerSeconds <= 10
                                    ? AppColors.error
                                    : AppColors.textMuted,
                                fontWeight: timerSeconds <= 10
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // ── Finish button ───────────────────────────────────
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.secondary,
                          ),
                          icon: const Icon(Icons.arrow_forward_rounded),
                          label: const Text('Finalizar Sesión'),
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