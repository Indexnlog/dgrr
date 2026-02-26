import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/match.dart';
import '../providers/match_providers.dart';

class MatchTabPage extends ConsumerWidget {
  const MatchTabPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matchesAsync = ref.watch(upcomingMatchesProvider);

    return Scaffold(
      backgroundColor: AppTheme.bgDeep,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              child: Text(
                '매치',
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            Expanded(
              child: matchesAsync.when(
                data: (matches) {
                  if (matches.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(PhosphorIconsRegular.soccerBall, size: 56, color: AppTheme.textMuted.withValues(alpha: 0.4)),
                          const SizedBox(height: 12),
                          const Text('예정된 매치가 없습니다', style: TextStyle(color: AppTheme.textMuted, fontSize: 14)),
                        ],
                      ),
                    );
                  }
                  return ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                    itemCount: matches.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final match = matches[index];
                      return _MatchListTile(match: match, index: index);
                    },
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppTheme.accentLime, strokeWidth: 2),
                ),
                error: (e, _) => Center(
                  child: Text('$e', style: const TextStyle(color: AppTheme.textSecondary)),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/match/create'),
        backgroundColor: AppTheme.accentLime,
        foregroundColor: Colors.black,
        child: const Icon(PhosphorIconsFill.plus, size: 28),
      ),
    );
  }
}

class _MatchListTile extends StatelessWidget {
  const _MatchListTile({required this.match, required this.index});
  final Match match;
  final int index;

  int? _daysUntil() {
    if (match.date == null) return null;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final matchDay = DateTime(match.date!.year, match.date!.month, match.date!.day);
    return matchDay.difference(today).inDays;
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = match.date != null
        ? '${match.date!.month}/${match.date!.day}'
        : '미정';
    final daysUntil = _daysUntil();
    final (statusLabel, statusColor) = switch (match.status) {
      MatchStatus.pending => ('PENDING', AppTheme.gold),
      MatchStatus.fixed => ('FIXED', AppTheme.primaryBlue),
      MatchStatus.confirmed => ('CONFIRMED', AppTheme.accentGreen),
      MatchStatus.inProgress => ('LIVE', AppTheme.teamRed),
      MatchStatus.finished => ('DONE', AppTheme.textMuted),
      MatchStatus.cancelled => ('취소', AppTheme.textMuted),
      null => ('', AppTheme.textMuted),
    };

    final cardColor = AppTheme.cardColorByIndex(index);

    return GestureDetector(
      onTap: () => context.push('/match/${match.matchId}'),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: cardColor.withValues(alpha: 0.25),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: cardColor.withValues(alpha: 0.5),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: cardColor.withValues(alpha: 0.15),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'vs ${match.opponentName ?? '상대 미정'}',
                    style: const TextStyle(color: AppTheme.textPrimary, fontSize: 17, fontWeight: FontWeight.w800),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (daysUntil != null && daysUntil >= 0) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: daysUntil == 0 ? AppTheme.teamRed.withValues(alpha: 0.3) : AppTheme.textMuted.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            daysUntil == 0 ? 'D-day' : 'D-$daysUntil',
                            style: TextStyle(
                              color: daysUntil == 0 ? AppTheme.teamRed : AppTheme.textMuted,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Expanded(
                        child: Text(
                          '$dateStr · ${match.startTime ?? '--:--'} · ${match.location ?? '미정'}',
                          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                statusLabel,
                style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(width: 8),
            Icon(PhosphorIconsRegular.caretRight, color: AppTheme.textMuted, size: 18),
          ],
        ),
      ),
    );
  }
}
