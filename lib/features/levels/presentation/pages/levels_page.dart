import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/injection_container.dart';
import '../../../auth/domain/entities/user.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../domain/entities/level.dart';
import '../bloc/levels_bloc.dart';

class LevelsPage extends StatelessWidget {
  const LevelsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<LevelsBloc>()..add(LevelsLoadEvent()),
      child: const _LevelsView(),
    );
  }
}

class _LevelsView extends StatelessWidget {
  const _LevelsView();

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final user = authState is AuthAuthenticated ? authState.user : null;
    final currentPoints = user?.wallet?.lifetimeEarned ?? 0;
    final currentLevelName = user?.wallet?.level?.name;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Niveles'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: BlocBuilder<LevelsBloc, LevelsState>(
        builder: (context, state) {
          if (state is LevelsLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is LevelsError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline,
                      color: AppColors.textMuted, size: 48),
                  const SizedBox(height: 12),
                  Text(state.message,
                      style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () =>
                        context.read<LevelsBloc>().add(LevelsLoadEvent()),
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          }
          if (state is LevelsLoaded) {
            return _LevelsContent(
              levels: state.levels,
              currentPoints: currentPoints,
              currentLevelName: currentLevelName,
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _LevelsContent extends StatelessWidget {
  final List<Level> levels;
  final int currentPoints;
  final String? currentLevelName;

  const _LevelsContent({
    required this.levels,
    required this.currentPoints,
    required this.currentLevelName,
  });

  /// Find which level the user is currently at
  Level? _currentLevel() {
    Level? result;
    for (final level in levels) {
      if (currentPoints >= level.minPointsRequired) {
        result = level;
      }
    }
    return result;
  }

  /// Find the next level to unlock
  Level? _nextLevel() {
    for (final level in levels) {
      if (currentPoints < level.minPointsRequired) return level;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final current = _currentLevel();
    final next = _nextLevel();
    final pointsToNext = next != null ? next.minPointsRequired - currentPoints : 0;
    final isMaxLevel = next == null;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        // ── Current status card ────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.primaryDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    current?.emoji ?? '🌱',
                    style: const TextStyle(fontSize: 36),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tu nivel actual',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: Colors.white70),
                        ),
                        Text(
                          current?.name ?? 'Sin nivel',
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$currentPoints pts',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              if (!isMaxLevel) ...[
                const SizedBox(height: 16),
                // Progress bar toward next level
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Hacia ${next!.name}',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: Colors.white70),
                    ),
                    Text(
                      '$pointsToNext pts restantes',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: Colors.white70),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: _progressToNext(current, next),
                    backgroundColor: Colors.white24,
                    color: Colors.white,
                    minHeight: 8,
                  ),
                ),
              ] else ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.emoji_events_rounded,
                          color: Colors.white, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        '¡Has alcanzado el nivel máximo!',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 24),

        Text(
          'TODOS LOS NIVELES',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            letterSpacing: 1.5,
            fontWeight: FontWeight.w600,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 12),

        // ── Levels list ────────────────────────────────────────────────────
        ...levels.asMap().entries.map((entry) {
          final index = entry.key;
          final level = entry.value;
          final isCurrentLevel = level.name == (current?.name ?? '');
          final isUnlocked = currentPoints >= level.minPointsRequired;
          final isLast = index == levels.length - 1;

          // Points range label
          final nextLevelPoints = index < levels.length - 1
              ? levels[index + 1].minPointsRequired
              : null;
          final rangeLabel = nextLevelPoints != null
              ? '${level.minPointsRequired} – ${nextLevelPoints - 1} pts'
              : '${level.minPointsRequired}+ pts';

          return _LevelTile(
            level: level,
            rangeLabel: rangeLabel,
            isCurrentLevel: isCurrentLevel,
            isUnlocked: isUnlocked,
            isLast: isLast,
            currentPoints: currentPoints,
          );
        }),
      ],
    );
  }

  double _progressToNext(Level? current, Level? next) {
    if (current == null || next == null) return 0;
    final start = current.minPointsRequired;
    final end = next.minPointsRequired;
    if (end <= start) return 1.0;
    return ((currentPoints - start) / (end - start)).clamp(0.0, 1.0);
  }
}

class _LevelTile extends StatelessWidget {
  final Level level;
  final String rangeLabel;
  final bool isCurrentLevel;
  final bool isUnlocked;
  final bool isLast;
  final int currentPoints;

  const _LevelTile({
    required this.level,
    required this.rangeLabel,
    required this.isCurrentLevel,
    required this.isUnlocked,
    required this.isLast,
    required this.currentPoints,
  });

  Color get _tileColor {
    if (isCurrentLevel) return AppColors.primaryLight;
    if (isUnlocked) return AppColors.surfaceWhite;
    return AppColors.surfaceGrey;
  }

  Color get _iconBg {
    if (isCurrentLevel) return AppColors.primary;
    if (isUnlocked) return AppColors.primaryLight;
    return const Color(0xFFE5E7EB);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _tileColor,
            borderRadius: BorderRadius.circular(16),
            border: isCurrentLevel
                ? Border.all(color: AppColors.primary, width: 2)
                : null,
          ),
          child: Row(
            children: [
              // Level icon circle
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: _iconBg,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    level.emoji,
                    style: TextStyle(
                        fontSize: isCurrentLevel ? 26 : 22),
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // Name + range
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            level.name,
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: isUnlocked
                                  ? AppColors.textPrimary
                                  : AppColors.textMuted,
                            ),
                          ),
                        ),
                        if (isCurrentLevel)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'Actual',
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
                    const SizedBox(height: 4),
                    Text(
                      rangeLabel,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isUnlocked
                            ? AppColors.textSecondary
                            : AppColors.textMuted,
                      ),
                    ),
                    // Progress bar only for the current level
                    if (isCurrentLevel && !isLast) ...[
                      const SizedBox(height: 8),
                      _MiniProgressBar(
                        currentPoints: currentPoints,
                        levelMin: level.minPointsRequired,
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(width: 12),

              // Lock / check icon
              Icon(
                isUnlocked
                    ? Icons.check_circle_rounded
                    : Icons.lock_rounded,
                color: isCurrentLevel
                    ? AppColors.primary
                    : isUnlocked
                    ? AppColors.primary.withOpacity(0.5)
                    : AppColors.textMuted,
                size: 22,
              ),
            ],
          ),
        ),

        // Connector line between tiles
        if (!isLast)
          Padding(
            padding: const EdgeInsets.only(left: 26, bottom: 0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                width: 2,
                height: 8,
                color: isUnlocked
                    ? AppColors.primary.withOpacity(0.3)
                    : AppColors.surfaceGrey,
              ),
            ),
          ),
      ],
    );
  }
}

class _MiniProgressBar extends StatelessWidget {
  final int currentPoints;
  final int levelMin;

  const _MiniProgressBar({
    required this.currentPoints,
    required this.levelMin,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: LinearProgressIndicator(
        value: (currentPoints - levelMin) /
            (levelMin > 0 ? levelMin : 100),
        backgroundColor: AppColors.surfaceGrey,
        color: AppColors.primary,
        minHeight: 6,
      ),
    );
  }
}