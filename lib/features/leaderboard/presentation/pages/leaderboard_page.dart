import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';

class LeaderboardPage extends StatefulWidget {
  const LeaderboardPage({super.key});

  @override
  State<LeaderboardPage> createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends State<LeaderboardPage> {
  bool _isWeekly = true;

  // Mock data - replace with real API when available
  static const _entries = [
    _LeaderEntry(rank: 1, name: 'Michael', points: 2150, bottles: 215, avatarLetter: 'M'),
    _LeaderEntry(rank: 2, name: 'Sarah', points: 1840, bottles: 184, avatarLetter: 'S'),
    _LeaderEntry(rank: 3, name: 'David', points: 1620, bottles: 162, avatarLetter: 'D'),
    _LeaderEntry(rank: 4, name: 'Emma Wilson', points: 1400, bottles: 140, avatarLetter: 'E'),
    _LeaderEntry(rank: 5, name: 'Carlos Ruiz', points: 1250, bottles: 125, avatarLetter: 'C'),
    _LeaderEntry(rank: 6, name: 'Jessica T.', points: 1100, bottles: 110, avatarLetter: 'J'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: Column(
        children: [
          // Green header
          Container(
            color: AppColors.primary,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 8,
              left: 16,
              right: 16,
              bottom: 16,
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_rounded,
                          color: Colors.white),
                      onPressed: () => context.pop(),
                    ),
                    Expanded(
                      child: Text(
                        'Leaderboard',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
                const SizedBox(height: 12),
                // Toggle
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.primaryDark,
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _isWeekly = true),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: _isWeekly
                                  ? Colors.white
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(25),
                            ),
                            child: Text(
                              'This Week',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: _isWeekly
                                    ? AppColors.primary
                                    : Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _isWeekly = false),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: !_isWeekly
                                  ? Colors.white
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(25),
                            ),
                            child: Text(
                              'All Time',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: !_isWeekly
                                    ? AppColors.primary
                                    : Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  // Podium top 3
                  _Podium(entries: _entries.take(3).toList()),
                  const SizedBox(height: 16),

                  // Remaining entries
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceWhite,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _entries.skip(3).length,
                      separatorBuilder: (_, __) =>
                      const Divider(height: 1, indent: 16, endIndent: 16),
                      itemBuilder: (_, i) {
                        final e = _entries.skip(3).toList()[i];
                        return _RankTile(entry: e);
                      },
                    ),
                  ),
                  const SizedBox(height: 16),

                  // My position
                  BlocBuilder<AuthBloc, AuthState>(
                    builder: (context, state) {
                      final name = state is AuthAuthenticated
                          ? state.user.name
                          : 'You';
                      final pts = state is AuthAuthenticated
                          ? state.user.wallet?.currentBalance ?? 0
                          : 0;
                      return Container(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'YOUR POSITION',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(letterSpacing: 1.2),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppColors.secondary,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    '42',
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineSmall
                                        ?.copyWith(color: Colors.white),
                                  ),
                                  const SizedBox(width: 12),
                                  CircleAvatar(
                                    radius: 18,
                                    backgroundColor: AppColors.primary,
                                    child: Text(
                                      name[0].toUpperCase(),
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '$name (You)',
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium
                                              ?.copyWith(color: Colors.white),
                                        ),
                                        Text(
                                          '${pts ~/ 10} bottles',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(
                                              color: Colors.white60),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.white12,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      '$pts pts',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LeaderEntry {
  final int rank;
  final String name;
  final int points;
  final int bottles;
  final String avatarLetter;

  const _LeaderEntry({
    required this.rank,
    required this.name,
    required this.points,
    required this.bottles,
    required this.avatarLetter,
  });
}

class _Podium extends StatelessWidget {
  final List<_LeaderEntry> entries;
  const _Podium({required this.entries});

  Color _medalColor(int rank) {
    if (rank == 1) return AppColors.tierGold;
    if (rank == 2) return AppColors.tierSilver;
    return AppColors.tierBronze;
  }

  @override
  Widget build(BuildContext context) {
    if (entries.length < 3) return const SizedBox.shrink();
    final first = entries[0];
    final second = entries[1];
    final third = entries[2];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // 2nd
          _PodiumEntry(entry: second, medalColor: _medalColor(2)),
          // 1st (taller)
          Column(
            children: [
              const Icon(Icons.emoji_events_rounded,
                  color: AppColors.tierGold, size: 28),
              _PodiumEntry(entry: first, medalColor: _medalColor(1), isFirst: true),
            ],
          ),
          // 3rd
          _PodiumEntry(entry: third, medalColor: _medalColor(3)),
        ],
      ),
    );
  }
}

class _PodiumEntry extends StatelessWidget {
  final _LeaderEntry entry;
  final Color medalColor;
  final bool isFirst;

  const _PodiumEntry({
    required this.entry,
    required this.medalColor,
    this.isFirst = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CircleAvatar(
          radius: isFirst ? 34 : 28,
          backgroundColor: medalColor.withOpacity(0.2),
          child: CircleAvatar(
            radius: isFirst ? 30 : 24,
            backgroundColor: medalColor,
            child: Text(
              entry.avatarLetter,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: isFirst ? 20 : 16,
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(entry.name, style: Theme.of(context).textTheme.titleMedium),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: medalColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '${entry.points} pts',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: medalColor, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

class _RankTile extends StatelessWidget {
  final _LeaderEntry entry;
  const _RankTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 24,
            child: Text(
              '${entry.rank}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.textMuted,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.surfaceGrey,
            child: Text(entry.avatarLetter,
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      title: Text(entry.name, style: Theme.of(context).textTheme.titleMedium),
      subtitle: Text('${entry.bottles} bottles',
          style: Theme.of(context).textTheme.bodySmall),
      trailing: Text(
        '${entry.points} pts',
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}