import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_router.dart';
import '../../../../core/utils/injection_container.dart';
import '../../../auth/domain/usecases/get_profile_usecase.dart';
import '../../../profile/domain/usecases/get_transaction_history_usecase.dart';

class SessionSummaryPage extends StatefulWidget {
  final String sessionId;
  final int bottlesDropped;
  final int pointsEarned;
  final bool autoClosed;

  const SessionSummaryPage({
    super.key,
    required this.sessionId,
    required this.bottlesDropped,
    required this.pointsEarned,
    this.autoClosed = false,
  });

  @override
  State<SessionSummaryPage> createState() => _SessionSummaryPageState();
}

class _SessionSummaryPageState extends State<SessionSummaryPage> {
  bool _checking = false;
  bool _creditConfirmed = false;
  int? _balance;
  String? _error;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    if (_checking) return;
    setState(() {
      _checking = true;
      _error = null;
      _balance = null;
    });
    final history = await sl<GetTransactionHistoryUseCase>()();
    final profile = await sl<GetProfileUseCase>()();
    if (!mounted) return;
    setState(() {
      history.fold(
        (failure) => _error = 'No se pudo consultar el historial: ${failure.message}',
        (transactions) => _creditConfirmed = transactions.any((transaction) =>
            transaction.source == 'RECYCLING_DROP' &&
            transaction.reference == widget.sessionId),
      );
      profile.fold(
        (failure) => _error ??= 'No se pudo consultar el saldo: ${failure.message}',
        (user) => _balance = user.wallet?.currentBalance,
      );
      _checking = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceWhite,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: ListView(
            children: [
              const SizedBox(height: 24),

              // Icon
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: widget.autoClosed
                      ? const Color(0xFFFFF3E0)
                      : AppColors.primaryLight,
                  shape: BoxShape.circle,
                ),
                child: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: widget.autoClosed ? AppColors.warning : AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    widget.autoClosed ? Icons.lock_rounded : Icons.check_rounded,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              Text(
                'Sesión cerrada',
                style: Theme.of(context).textTheme.displaySmall,
              ),
              const SizedBox(height: 8),
              Text(
                widget.autoClosed
                    ? 'El cierre remoto fue confirmado tras agotarse el tiempo local.'
                    : 'El cierre de la sesión fue confirmado. El crédito de EcoPuntos se comprueba por separado.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 32),

              // Impact card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.backgroundLight,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'RESUMEN DE ESTA SESIÓN',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textMuted,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _ImpactTile(
                            value: '${widget.bottlesDropped}',
                            label: 'Botellas aceptadas',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _ImpactTile(
                            value: '+${widget.pointsEarned}',
                            label: 'EcoPuntos calculados',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _creditConfirmed
                            ? 'Crédito confirmado en el historial'
                            : 'Crédito pendiente de confirmar',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                  ],
                ),
              ),

              if (!_creditConfirmed) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'El cierre no confirma por sí solo el abono. Consulta nuevamente el historial y el saldo.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.primaryDark,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 24),

              Text(
                _balance == null
                    ? 'Saldo actual: no disponible'
                    : 'Saldo actual de la billetera: $_balance EcoPuntos',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),

              if (_error != null)
                Text(_error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.error)),
              TextButton.icon(
                onPressed: _checking ? null : _refresh,
                icon: _checking
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh),
                label: const Text('Actualizar crédito y saldo'),
              ),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () => context.go(AppRoutes.home),
                  child: const Text('Volver al Inicio'),
                ),
              ),
              const SizedBox(height: 12),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _ImpactTile extends StatelessWidget {
  final String value;
  final String label;
  const _ImpactTile({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}
