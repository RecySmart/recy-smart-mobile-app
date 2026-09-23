import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/injection_container.dart';
import '../../domain/entities/ranking.dart';
import '../bloc/ranking_bloc.dart';

class LeaderboardPage extends StatelessWidget {
  const LeaderboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<RankingBloc>()
        ..add(const RankingLoadRequested(period: RankingPeriod.weekly)),
      child: const _LeaderboardView(),
    );
  }
}

class _LeaderboardView extends StatefulWidget {
  const _LeaderboardView();

  @override
  State<_LeaderboardView> createState() => _LeaderboardViewState();
}

class _LeaderboardViewState extends State<_LeaderboardView> {
  RankingPeriod _period = RankingPeriod.weekly;

  void _load({int page = 1}) {
    context.read<RankingBloc>().add(
          RankingLoadRequested(period: _period, page: page),
        );
  }

  void _changePeriod(RankingPeriod period) {
    if (_period == period) return;
    setState(() => _period = period);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Ranking'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: SegmentedButton<RankingPeriod>(
              segments: RankingPeriod.values
                  .map(
                    (period) => ButtonSegment(
                      value: period,
                      label: Text(period.label),
                    ),
                  )
                  .toList(),
              selected: {_period},
              onSelectionChanged: (selection) => _changePeriod(selection.first),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              _period == RankingPeriod.weekly
                  ? 'EcoPuntos obtenidos por reciclaje desde el lunes, hora de Lima.'
                  : 'EcoPuntos históricos obtenidos exclusivamente por reciclaje.',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.textMuted),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: BlocBuilder<RankingBloc, RankingState>(
              builder: (context, state) {
                if (state is RankingLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state is RankingError) {
                  return _RankingError(message: state.message, onRetry: _load);
                }
                if (state is RankingLoaded) {
                  return _RankingContent(
                    ranking: state.ranking,
                    onRefresh: () async => _load(page: state.ranking.page),
                    onPageChanged: (page) => _load(page: page),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _RankingContent extends StatelessWidget {
  final Ranking ranking;
  final Future<void> Function() onRefresh;
  final ValueChanged<int> onPageChanged;

  const _RankingContent({
    required this.ranking,
    required this.onRefresh,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          if (ranking.currentUser != null)
            _CurrentPosition(entry: ranking.currentUser!),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'CLASIFICACIÓN',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              Text(
                '${ranking.totalParticipants} participantes',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: AppColors.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (ranking.entries.isEmpty)
            const _EmptyRanking()
          else
            Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceWhite,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: ranking.entries
                    .map((entry) => _RankTile(entry: entry))
                    .toList(),
              ),
            ),
          if (ranking.totalPages > 1) ...[
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  tooltip: 'Página anterior',
                  onPressed: ranking.page > 1
                      ? () => onPageChanged(ranking.page - 1)
                      : null,
                  icon: const Icon(Icons.chevron_left_rounded),
                ),
                Text('${ranking.page} / ${ranking.totalPages}'),
                IconButton(
                  tooltip: 'Página siguiente',
                  onPressed: ranking.page < ranking.totalPages
                      ? () => onPageChanged(ranking.page + 1)
                      : null,
                  icon: const Icon(Icons.chevron_right_rounded),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _CurrentPosition extends StatelessWidget {
  final RankingEntry entry;

  const _CurrentPosition({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Text(
            '#${entry.rank}',
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(color: Colors.white),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tu posición',
                  style: TextStyle(color: Colors.white70),
                ),
                Text(
                  entry.alias,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(color: Colors.white),
                ),
              ],
            ),
          ),
          Text(
            '${entry.points} pts',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _RankTile extends StatelessWidget {
  final RankingEntry entry;

  const _RankTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    final medalColor = switch (entry.rank) {
      1 => AppColors.tierGold,
      2 => AppColors.tierSilver,
      3 => AppColors.tierBronze,
      _ => AppColors.textMuted,
    };

    return ListTile(
      tileColor: entry.isCurrentUser ? AppColors.primaryLight : null,
      leading: CircleAvatar(
        backgroundColor: medalColor.withValues(alpha: 0.16),
        child: Text(
          '${entry.rank}',
          style: TextStyle(color: medalColor, fontWeight: FontWeight.w700),
        ),
      ),
      title: Text(
        entry.isCurrentUser ? '${entry.alias} (Tú)' : entry.alias,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: const Text('EcoPuntos por reciclaje'),
      trailing: Text(
        '${entry.points} pts',
        style: const TextStyle(
          color: AppColors.primary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _EmptyRanking extends StatelessWidget {
  const _EmptyRanking();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 56),
      child: Column(
        children: [
          const Icon(Icons.leaderboard_outlined,
              size: 52, color: AppColors.textMuted),
          const SizedBox(height: 12),
          Text(
            'Todavía no hay EcoPuntos de reciclaje en este período.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _RankingError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _RankingError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline,
                size: 48, color: AppColors.textMuted),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: onRetry, child: const Text('Reintentar')),
          ],
        ),
      ),
    );
  }
}
