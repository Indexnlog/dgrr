import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/permissions/permission_checker.dart';
import '../../../../core/widgets/error_retry_view.dart';
import '../../domain/entities/poll.dart';
import '../providers/poll_providers.dart';

class _DS {
  _DS._();
  static const bgDeep = Color(0xFF0D1117);
  static const bgCard = Color(0xFF161B22);
  static const surface = Color(0xFF21262D);
  static const teamRed = Color(0xFFDC2626);
  static const textPrimary = Color(0xFFF0F6FC);
  static const textSecondary = Color(0xFF8B949E);
  static const textMuted = Color(0xFF484F58);
  static const attendGreen = Color(0xFF2EA043);
  static const divider = Color(0xFF30363D);
  static const gold = Color(0xFFFBBF24);
}

class PollListPage extends ConsumerWidget {
  const PollListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pollsAsync = ref.watch(allPollsProvider);
    final isAdmin = PermissionChecker.isAdmin(ref);

    return Scaffold(
      backgroundColor: _DS.bgDeep,
      appBar: AppBar(
        backgroundColor: _DS.bgDeep,
        foregroundColor: _DS.textPrimary,
        title: const Text('투표',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
        elevation: 0,
        actions: [
          if (isAdmin)
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: () => context.push('/schedule/polls/create'),
              tooltip: '투표 만들기',
            ),
        ],
      ),
      body: pollsAsync.when(
        data: (polls) {
          if (polls.isEmpty) {
            return RefreshIndicator(
              onRefresh: () async => ref.invalidate(allPollsProvider),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: SizedBox(
                  height: MediaQuery.of(context).size.height - 200,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.ballot_outlined,
                            size: 48, color: _DS.textMuted.withValues(alpha:0.4)),
                        const SizedBox(height: 12),
                        Text('아직 투표가 없습니다',
                            style: TextStyle(color: _DS.textMuted, fontSize: 14)),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(allPollsProvider),
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            itemCount: polls.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) =>
                _PollCard(poll: polls[index]),
            ),
          );
        },
        loading: () => const Center(
            child: CircularProgressIndicator(
                color: _DS.teamRed, strokeWidth: 2.5)),
        error: (e, _) => ErrorRetryView(
            message: '투표 목록을 불러올 수 없습니다',
            detail: e.toString(),
            onRetry: () => ref.invalidate(allPollsProvider)),
      ),
    );
  }
}

class _PollCard extends StatelessWidget {
  const _PollCard({required this.poll});
  final Poll poll;

  @override
  Widget build(BuildContext context) {
    final isActive = poll.isActive ?? false;
    final totalVotes = poll.options
            ?.fold<int>(0, (sum, o) => sum + (o.voteCount ?? 0)) ??
        0;

    return GestureDetector(
      onTap: () => context.push('/schedule/polls/${poll.pollId}'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _DS.bgCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: isActive
                  ? _DS.gold.withValues(alpha:0.4)
                  : _DS.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isActive
                        ? _DS.attendGreen.withValues(alpha:0.15)
                        : _DS.surface,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    isActive ? '진행중' : '종료',
                    style: TextStyle(
                        color: isActive ? _DS.attendGreen : _DS.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 8),
                if (poll.type != null)
                  Text(
                    poll.type == PollType.date ? '날짜 투표' : '선택 투표',
                    style: TextStyle(
                        color: _DS.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w600),
                  ),
                const Spacer(),
                Text('$totalVotes명 참여',
                    style: TextStyle(
                        color: _DS.textMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w500)),
              ],
            ),
            const SizedBox(height: 10),
            Text(poll.title,
                style: const TextStyle(
                    color: _DS.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700)),
            if (poll.description != null) ...[
              const SizedBox(height: 4),
              Text(poll.description!,
                  style: TextStyle(color: _DS.textSecondary, fontSize: 13),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
            ],
            const SizedBox(height: 12),
            // 옵션 미리보기
            if (poll.options != null)
              ...poll.options!.take(3).map((o) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: _OptionPreview(
                        text: o.text ?? '옵션',
                        count: o.voteCount ?? 0,
                        total: totalVotes > 0 ? totalVotes : 1),
                  )),
            if ((poll.options?.length ?? 0) > 3)
              Text('외 ${poll.options!.length - 3}개 항목',
                  style: TextStyle(
                      color: _DS.textMuted,
                      fontSize: 11,
                      fontStyle: FontStyle.italic)),
          ],
        ),
      ),
    );
  }
}

class _OptionPreview extends StatelessWidget {
  const _OptionPreview({
    required this.text,
    required this.count,
    required this.total,
  });
  final String text;
  final int count;
  final int total;

  @override
  Widget build(BuildContext context) {
    final ratio = count / total;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
                child: Text(text,
                    style: const TextStyle(
                        color: _DS.textSecondary, fontSize: 12))),
            Text('$count',
                style: TextStyle(
                    color: _DS.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w700)),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: SizedBox(
            height: 4,
            child: LinearProgressIndicator(
              value: ratio,
              backgroundColor: _DS.surface,
              color: _DS.gold,
            ),
          ),
        ),
      ],
    );
  }
}
