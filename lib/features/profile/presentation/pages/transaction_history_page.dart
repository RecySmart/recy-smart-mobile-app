import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/injection_container.dart';
import '../../data/datasources/profile_remote_datasource.dart';
import '../bloc/profile_bloc.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';

class TransactionHistoryPage extends StatelessWidget {
  const TransactionHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<ProfileBloc>()..add(ProfileLoadTransactionsEvent()),
      child: const _TransactionHistoryView(),
    );
  }
}

class _TransactionHistoryView extends StatefulWidget {
  const _TransactionHistoryView();

  @override
  State<_TransactionHistoryView> createState() =>
      _TransactionHistoryViewState();
}

class _TransactionHistoryViewState extends State<_TransactionHistoryView> {
  String _filter = 'All';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Transaction History'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: BlocBuilder<ProfileBloc, ProfileState>(
        builder: (context, state) {
          if (state is ProfileLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is ProfileError) {
            return Center(child: Text(state.message));
          }
          if (state is ProfileTransactionsLoaded) {
            return _TransactionContent(
              transactions: state.transactions,
              filter: _filter,
              onFilterChanged: (f) => setState(() => _filter = f),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _TransactionContent extends StatelessWidget {
  final List<TransactionModel> transactions;
  final String filter;
  final ValueChanged<String> onFilterChanged;

  const _TransactionContent({
    required this.transactions,
    required this.filter,
    required this.onFilterChanged,
  });

  List<TransactionModel> get _filtered {
    if (filter == 'Deposits') {
      return transactions.where((t) => t.amount > 0).toList();
    }
    if (filter == 'Rewards') {
      return transactions.where((t) => t.amount < 0).toList();
    }
    return transactions;
  }

  int get _earnedThisMonth {
    final now = DateTime.now();
    return _filtered
        .where((t) => t.createdAt.month == now.month && t.amount > 0)
        .fold(0, (sum, t) => sum + t.amount);
  }

  int get _redeemedThisMonth {
    final now = DateTime.now();
    return _filtered
        .where((t) => t.createdAt.month == now.month && t.amount < 0)
        .fold(0, (sum, t) => sum + t.amount.abs());
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final grouped = <String, List<TransactionModel>>{};
    for (final tx in _filtered) {
      final diff = now.difference(tx.createdAt);
      String key;
      if (diff.inDays == 0) key = 'TODAY';
      else if (diff.inDays == 1) key = 'YESTERDAY';
      else key = DateFormat('MMMM d').format(tx.createdAt).toUpperCase();
      grouped.putIfAbsent(key, () => []).add(tx);
    }

    return Column(
      children: [
        // Month summary
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.secondary,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'THIS MONTH (${DateFormat('MMMM').format(now).toUpperCase()})',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white54,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Earned',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white54,
                      ),
                    ),
                    Text(
                      '+$_earnedThisMonth pts',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Container(width: 1, height: 48, color: Colors.white24),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      Text(
                        'Redeemed',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white54,
                        ),
                      ),
                      Text(
                        '-$_redeemedThisMonth pts',
                        style:
                        Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // Filter chips
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: ['All', 'Deposits', 'Rewards'].map((f) {
              final isSelected = f == filter;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(f),
                  selected: isSelected,
                  onSelected: (_) => onFilterChanged(f),
                  backgroundColor: AppColors.surfaceWhite,
                  selectedColor: AppColors.secondary,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : AppColors.textPrimary,
                    fontWeight:
                    isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                  side: BorderSide.none,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 8),

        // List
        Expanded(
          child: grouped.isEmpty
              ? const Center(child: Text('No transactions found.'))
              : ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: grouped.entries.map((entry) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      entry.key,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(letterSpacing: 1.2),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surfaceWhite,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: entry.value.length,
                      separatorBuilder: (_, __) => const Divider(
                          height: 1, indent: 16, endIndent: 16),
                      itemBuilder: (_, i) =>
                          _TransactionTile(tx: entry.value[i]),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final TransactionModel tx;
  const _TransactionTile({required this.tx});

  @override
  Widget build(BuildContext context) {
    final isEarned = tx.amount > 0;
    final isDeposit = tx.source == 'RECYCLING_DROP';
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isEarned ? AppColors.primaryLight : const Color(0xFFFFF3E0),
          shape: BoxShape.circle,
        ),
        child: Icon(
          isDeposit ? Icons.recycling_rounded : Icons.redeem_rounded,
          color: isEarned ? AppColors.primary : AppColors.warning,
          size: 18,
        ),
      ),
      title: Text(
        isDeposit ? 'Smart Bin Deposit' : 'Reward Redeemed',
        style: Theme.of(context).textTheme.titleMedium,
      ),
      subtitle: Text(
        tx.binLocation ?? tx.source,
        style: Theme.of(context).textTheme.bodySmall,
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            isEarned ? '+${tx.amount} pts' : '-${tx.amount.abs()} pts',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: isEarned ? AppColors.primary : AppColors.warning,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (!isDeposit)
            Text(
              DateFormat('h:mm a').format(tx.createdAt),
              style: Theme.of(context).textTheme.bodySmall,
            ),
        ],
      ),
    );
  }
}