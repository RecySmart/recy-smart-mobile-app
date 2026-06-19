import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_router.dart';
import '../../../../core/utils/injection_container.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/domain/entities/user.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  @override
  void initState() {
    super.initState();
    // Silently refresh profile to get fresh wallet data every time we navigate here
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authBloc = context.read<AuthBloc>();
      if (authBloc.state is AuthAuthenticated) {
        authBloc.add(AuthGetProfileEvent());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthSessionExpired) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Tu sesión ha expirado. Por favor inicia sesión nuevamente.'),
              backgroundColor: AppColors.warning,
              duration: Duration(seconds: 3),
            ),
          );
          Future.delayed(const Duration(seconds: 1), () {
            if (mounted) context.go(AppRoutes.login);
          });
        }
        if (state is AuthUnauthenticated) {
          context.go(AppRoutes.login);
        }
      },
      builder: (context, state) {
        // Show skeleton while loading — not an infinite spinner
        if (state is AuthLoading || state is AuthInitial) {
          return const _ProfileSkeleton();
        }
        if (state is AuthAuthenticated) {
          return _ProfileContent(user: state.user);
        }
        // AuthError or other — show last known user if possible
        return const _ProfileSkeleton();
      },
    );
  }
}

// ── Skeleton while loading ────────────────────────────────────────────────────

class _ProfileSkeleton extends StatelessWidget {
  const _ProfileSkeleton();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: Column(
        children: [
          Container(
            height: 200,
            color: AppColors.primary,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 16,
              left: 20,
              right: 20,
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white24,
                ),
                const SizedBox(width: 16),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                        width: 120, height: 16,
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(8),
                        )),
                    const SizedBox(height: 8),
                    Container(
                        width: 180, height: 12,
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(6),
                        )),
                  ],
                ),
              ],
            ),
          ),
          const Expanded(
            child: Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Profile Content ───────────────────────────────────────────────────────────

class _ProfileContent extends StatelessWidget {
  final User user;
  const _ProfileContent({required this.user});

  @override
  Widget build(BuildContext context) {
    final wallet = user.wallet;
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: CustomScrollView(
        slivers: [
          // Green header
          SliverToBoxAdapter(
            child: Container(
              color: AppColors.primary,
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 16,
                left: 20,
                right: 20,
                bottom: 0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Perfil',
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(color: Colors.white),
                      ),
                      IconButton(
                        icon: const Icon(Icons.settings_outlined,
                            color: Colors.white),
                        onPressed: () {},
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.white24,
                        child: Text(
                          user.name.isNotEmpty
                              ? user.name[0].toUpperCase()
                              : '?',
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.name,
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(color: Colors.white),
                            ),
                            Text(
                              user.email,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: Colors.white70),
                            ),
                            const SizedBox(height: 6),
                            if (wallet?.level != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white24,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  wallet!.level!.name,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          // Stats card
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surfaceWhite,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _StatItem(
                    value: '${wallet?.totalBottles ?? 0}',
                    label: 'BOTELLAS',
                  ),
                  Container(
                      width: 1, height: 36, color: AppColors.surfaceGrey),
                  _StatItem(
                    value: wallet != null
                        ? _formatPoints(wallet.lifetimeEarned)
                        : '0',
                    label: 'PTS TOTALES',
                    valueColor: AppColors.primary,
                  ),
                  Container(
                      width: 1, height: 36, color: AppColors.surfaceGrey),
                  _StatItem(
                    value:
                    '${wallet?.co2Saved.toStringAsFixed(1) ?? '0.0'} kg',
                    label: 'CO2 AHORRADO',
                  ),
                ],
              ),
            ),
          ),

          // If no wallet, show warning
          if (wallet == null)
            SliverToBoxAdapter(
              child: Container(
                margin:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded,
                        color: AppColors.warning, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Tu wallet aún se está inicializando. Intenta cerrar y abrir la app.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.warning,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _SectionLabel(label: 'CUENTA'),
                const SizedBox(height: 8),
                _MenuCard(items: [
                  _MenuItem(
                    icon: Icons.person_outline_rounded,
                    iconColor: const Color(0xFFBBDEFB),
                    label: 'Información Personal',
                    onTap: () => context.push(AppRoutes.editProfile),
                  ),
                  _MenuItem(
                    icon: Icons.receipt_long_rounded,
                    iconColor: AppColors.primaryLight,
                    label: 'Historial de Transacciones',
                    onTap: () => context.push(AppRoutes.transactionHistory),
                  ),
                  _MenuItem(
                    icon: Icons.emoji_events_rounded,
                    iconColor: const Color(0xFFFFF9C4),
                    label: 'Mis Logros',
                    onTap: () => context.push(AppRoutes.achievements),
                  ),
                  _MenuItem(
                    icon: Icons.leaderboard_rounded,
                    iconColor: const Color(0xFFE8EAF6),
                    label: 'Tabla de posiciones',
                    onTap: () => context.push(AppRoutes.leaderboard),
                  ),
                ]),
                const SizedBox(height: 20),
                _SectionLabel(label: 'PREFERENCIAS'),
                const SizedBox(height: 8),
                _MenuCard(items: [
                  _MenuItem(
                    icon: Icons.notifications_outlined,
                    iconColor: const Color(0xFFEDE7F6),
                    label: 'Notificaciones',
                    trailing: Switch(
                      value: true,
                      onChanged: (_) {},
                      activeColor: AppColors.primary,
                    ),
                  ),
                  const _MenuItem(
                    icon: Icons.language_rounded,
                    iconColor: Color(0xFFFFF3E0),
                    label: 'Idioma',
                    trailingText: 'Español',
                  ),
                ]),
                const SizedBox(height: 20),
                _MenuCard(items: [
                  _MenuItem(
                    icon: Icons.logout_rounded,
                    iconColor: const Color(0xFFFFEBEE),
                    label: 'Cerrar Sesión',
                    labelColor: AppColors.error,
                    onTap: () => showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('Cerrar Sesión'),
                        content: const Text(
                            '¿Estás seguro que deseas cerrar sesión?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancelar'),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                              context
                                  .read<AuthBloc>()
                                  .add(AuthLogoutEvent());
                            },
                            child: Text('Salir',
                                style:
                                TextStyle(color: AppColors.error)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ]),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  String _formatPoints(int pts) {
    if (pts >= 1000) return '${(pts / 1000).toStringAsFixed(1)}k';
    return '$pts';
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  final Color? valueColor;
  const _StatItem({required this.value, required this.label, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: valueColor,
          ),
        ),
        const SizedBox(height: 2),
        Text(label,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(letterSpacing: 0.5)),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) => Text(
    label,
    style: Theme.of(context).textTheme.bodySmall?.copyWith(
      letterSpacing: 1.2,
      fontWeight: FontWeight.w600,
    ),
  );
}

class _MenuItem {
  final IconData icon;
  final Color iconColor;
  final String label;
  final Color? labelColor;
  final VoidCallback? onTap;
  final Widget? trailing;
  final String? trailingText;

  const _MenuItem({
    required this.icon,
    required this.iconColor,
    required this.label,
    this.labelColor,
    this.onTap,
    this.trailing,
    this.trailingText,
  });
}

class _MenuCard extends StatelessWidget {
  final List<_MenuItem> items;
  const _MenuCard({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        separatorBuilder: (_, __) =>
        const Divider(height: 1, indent: 60, endIndent: 0),
        itemBuilder: (_, i) {
          final item = items[i];
          return ListTile(
            leading: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: item.iconColor,
                shape: BoxShape.circle,
              ),
              child: Icon(item.icon,
                  size: 18, color: AppColors.textSecondary),
            ),
            title: Text(
              item.label,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: item.labelColor,
              ),
            ),
            trailing: item.trailing ??
                (item.trailingText != null
                    ? Text(item.trailingText!,
                    style: Theme.of(context).textTheme.bodyMedium)
                    : item.onTap != null
                    ? const Icon(Icons.chevron_right_rounded,
                    color: AppColors.textMuted)
                    : null),
            onTap: item.onTap,
          );
        },
      ),
    );
  }
}