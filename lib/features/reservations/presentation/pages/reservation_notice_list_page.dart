import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:dgrr_app/core/widgets/error_retry_view.dart';
import '../../../teams/presentation/providers/team_members_provider.dart';
import '../../domain/entities/reservation_notice.dart';
import '../../data/models/reservation_notice_model.dart';
import '../providers/reservation_notice_providers.dart';

class _DS {
  _DS._();
  static const bgDeep = Color(0xFF0D1117);
  static const bgCard = Color(0xFF161B22);
  static const surface = Color(0xFF21262D);
  static const teamRed = Color(0xFFDC2626);
  static const gold = Color(0xFFFBBF24);
  static const textPrimary = Color(0xFFF0F6FC);
  static const textSecondary = Color(0xFF8B949E);
  static const textMuted = Color(0xFF484F58);
  static const attendGreen = Color(0xFF2EA043);
  static const absentRed = Color(0xFFDA3633);
  static const divider = Color(0xFF30363D);
  static const fixedBlue = Color(0xFF58A6FF);
}

/// 예약 공지 목록 페이지
class ReservationNoticeListPage extends ConsumerWidget {
  const ReservationNoticeListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final noticesAsync = ref.watch(upcomingReservationNoticesProvider);

    return Scaffold(
      backgroundColor: _DS.bgDeep,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/schedule/reservation-notices/create'),
        backgroundColor: _DS.teamRed,
        icon: const Icon(Icons.add),
        label: const Text('예약 공지 만들기'),
      ),
      appBar: AppBar(
        backgroundColor: _DS.bgDeep,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: _DS.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          '구장 예약 공지',
          style: TextStyle(
            color: _DS.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: noticesAsync.when(
        data: (notices) {
          if (notices.isEmpty) {
            return RefreshIndicator(
              onRefresh: () async => ref.invalidate(upcomingReservationNoticesProvider),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: SizedBox(
                  height: MediaQuery.of(context).size.height - 200,
                  child: Center(
                    child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.sports_soccer, color: _DS.textMuted, size: 48),
                  const SizedBox(height: 12),
                  Text(
                    '예정된 예약 공지가 없습니다',
                    style: TextStyle(color: _DS.textSecondary, fontSize: 15),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '수업관리팀이 예약 공지를 만들면 여기에 표시됩니다',
                    style: TextStyle(color: _DS.textMuted, fontSize: 13),
                  ),
                ],
                    ),
                  ),
                ),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(upcomingReservationNoticesProvider),
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
            itemCount: notices.length,
            itemBuilder: (context, index) {
              final notice = notices[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _NoticeCard(notice: notice),
              );
            },
            ),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: _DS.teamRed, strokeWidth: 2.5),
        ),
        error: (e, _) => ErrorRetryView(
          message: '공지 목록을 불러올 수 없습니다',
          detail: e.toString(),
          onRetry: () => ref.invalidate(upcomingReservationNoticesProvider)),
      ),
    );
  }
}

class _NoticeCard extends ConsumerWidget {
  const _NoticeCard({required this.notice});

  final ReservationNoticeModel notice;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final memberMap = ref.watch(memberMapProvider);
    final typeLabel = notice.reservedForType == ReservationNoticeForType.class_
        ? '수업'
        : '매치';
    final dateStr =
        '${notice.targetDate.month}/${notice.targetDate.day}';
    final timeStr = notice.targetStartTime != null && notice.targetEndTime != null
        ? '${notice.targetStartTime!.substring(0, 5)}~${notice.targetEndTime!.substring(0, 5)}'
        : '';

    final successCount =
        notice.slots?.where((s) => s.result == SlotResult.success).length ?? 0;
    final totalSlots = notice.slots?.length ?? 0;

    return GestureDetector(
      onTap: () => context.push(
        '/schedule/reservation-notices/${notice.noticeId}',
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _DS.bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _DS.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _DS.teamRed.withValues(alpha:0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '$dateStr $typeLabel',
                    style: const TextStyle(
                      color: _DS.teamRed,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (timeStr.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Text(
                    timeStr,
                    style: TextStyle(color: _DS.textMuted, fontSize: 12),
                  ),
                ],
                const Spacer(),
                if (successCount > 0)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle, color: _DS.attendGreen, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        '$successCount/$totalSlots 성공',
                        style: const TextStyle(
                          color: _DS.attendGreen,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            if (notice.openAt != null) ...[
              const SizedBox(height: 12),
              Text(
                '예약 시도: ${_formatOpenAt(notice.openAt!)}',
                style: TextStyle(
                  color: _DS.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatOpenAt(DateTime openAt) {
    final nextDay = openAt.add(const Duration(minutes: 2));
    const weekdays = ['월', '화', '수', '목', '금', '토', '일'];
    final w1 = weekdays[openAt.weekday - 1];
    final w2 = weekdays[nextDay.weekday - 1];
    return '$w1(${openAt.month}/${openAt.day})→$w2(${nextDay.month}/${nextDay.day}) 23:58';
  }
}
