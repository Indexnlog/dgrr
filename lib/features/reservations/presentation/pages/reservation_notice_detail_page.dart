import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../auth/presentation/providers/auth_state_provider.dart';
import '../../../teams/domain/entities/member.dart';
import '../../../teams/presentation/providers/current_team_provider.dart';
import '../../../teams/presentation/providers/team_members_provider.dart';
import '../../data/models/reservation_notice_model.dart';
import '../../domain/entities/reservation_notice.dart';
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

/// 예약 공지 상세 페이지 (성공 버튼 포함)
class ReservationNoticeDetailPage extends ConsumerStatefulWidget {
  const ReservationNoticeDetailPage({
    super.key,
    required this.noticeId,
  });

  final String noticeId;

  @override
  ConsumerState<ReservationNoticeDetailPage> createState() =>
      _ReservationNoticeDetailPageState();
}

class _ReservationNoticeDetailPageState
    extends ConsumerState<ReservationNoticeDetailPage> {
  final Map<String, bool> _reportingSlots = {};

  @override
  Widget build(BuildContext context) {
    final noticeAsync = ref.watch(
      reservationNoticeDetailProvider(widget.noticeId),
    );
    final currentUser = ref.watch(currentUserProvider);
    final memberMap = ref.watch(memberMapProvider);

    return Scaffold(
      backgroundColor: _DS.bgDeep,
      appBar: AppBar(
        backgroundColor: _DS.bgDeep,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: _DS.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          '예약 공지 상세',
          style: TextStyle(
            color: _DS.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: noticeAsync.when(
        data: (notice) {
          if (notice == null) {
            return const Center(
              child: Text(
                '공지를 찾을 수 없습니다',
                style: TextStyle(color: _DS.textSecondary),
              ),
            );
          }
          return _buildContent(notice, currentUser?.uid, memberMap);
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: _DS.teamRed, strokeWidth: 2.5),
        ),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: _DS.absentRed, size: 48),
              const SizedBox(height: 12),
              Text(
                '데이터를 불러올 수 없습니다',
                style: TextStyle(color: _DS.textSecondary, fontSize: 15),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(
    ReservationNoticeModel notice,
    String? currentUid,
    Map<String, Member> memberMap,
  ) {
    final typeLabel =
        notice.reservedForType == ReservationNoticeForType.class_
            ? '수업'
            : '매치';
    final dateStr =
        '${notice.targetDate.month}/${notice.targetDate.day} (${_weekday(notice.targetDate.weekday)})';
    final timeStr = notice.targetStartTime != null && notice.targetEndTime != null
        ? '${notice.targetStartTime!.substring(0, 5)}~${notice.targetEndTime!.substring(0, 5)}'
        : '';

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: _DS.teamRed.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$dateStr $typeLabel',
                        style: const TextStyle(
                          color: _DS.teamRed,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                if (timeStr.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    '시간: $timeStr',
                    style: TextStyle(color: _DS.textSecondary, fontSize: 14),
                  ),
                ],
                if (notice.openAt != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    '예약 시도: ${_formatOpenAt(notice.openAt!)}',
                    style: TextStyle(
                      color: _DS.textMuted,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            '구장별 담당',
            style: TextStyle(
              color: _DS.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          ...(notice.slots ?? []).map((slot) => _SlotCard(
                slot: slot,
                currentUid: currentUid,
                memberMap: memberMap,
                isReporting: _reportingSlots[slot.groundId] ?? false,
                onReportSuccess: () => _reportSuccess(slot.groundId),
                onReportFailed: () => _reportFailed(slot.groundId),
              )),
          if (notice.fallback != null) ...[
            const SizedBox(height: 24),
            _buildFallbackCard(notice.fallback!),
          ],
        ],
      ),
    );
  }

  Widget _SlotCard({
    required ReservationNoticeSlot slot,
    required String? currentUid,
    required Map<String, Member> memberMap,
    required bool isReporting,
    required VoidCallback onReportSuccess,
    required VoidCallback onReportFailed,
  }) {
    final isSuccess = slot.result == SlotResult.success;
    final isFailed = slot.result == SlotResult.failed;
    final isManager = currentUid != null &&
        (slot.managers?.contains(currentUid) ?? false);
    final canReport = isManager && !isSuccess && !isFailed && !isReporting;

    final managerNames = (slot.managers ?? [])
        .map((uid) => memberMap[uid]?.uniformName ?? memberMap[uid]?.name ?? uid.substring(0, 6))
        .join(', ');

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _DS.bgCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSuccess
                ? _DS.attendGreen.withOpacity(0.4)
                : isFailed
                    ? _DS.absentRed.withOpacity(0.4)
                    : _DS.divider,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  slot.groundName,
                  style: const TextStyle(
                    color: _DS.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                if (isSuccess) ...[
                  Icon(Icons.check_circle, color: _DS.attendGreen, size: 20),
                  const SizedBox(width: 6),
                  Text(
                    slot.successBy != null
                        ? '${memberMap[slot.successBy!]?.uniformName ?? memberMap[slot.successBy!]?.name ?? slot.successBy} 성공!'
                        : '성공',
                    style: const TextStyle(
                      color: _DS.attendGreen,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ] else if (isFailed) ...[
                  Icon(Icons.cancel, color: _DS.absentRed, size: 20),
                  const SizedBox(width: 6),
                  Text(
                    '실패',
                    style: const TextStyle(
                      color: _DS.absentRed,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
            if (slot.address != null && slot.address!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                slot.address!,
                style: TextStyle(color: _DS.textMuted, fontSize: 12),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 8),
            Text(
              '담당: $managerNames',
              style: TextStyle(color: _DS.textSecondary, fontSize: 13),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
            ),
            if (slot.url != null && slot.url!.isNotEmpty) ...[
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () => _launchUrl(slot.url!),
                child: Row(
                  children: [
                    Icon(Icons.link, color: _DS.fixedBlue, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      '예약 페이지 열기',
                      style: TextStyle(
                        color: _DS.fixedBlue,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (canReport) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: isReporting ? null : onReportSuccess,
                      icon: isReporting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.celebration, size: 18),
                      label: const Text('성공!'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _DS.attendGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: isReporting ? null : onReportFailed,
                      icon: const Icon(Icons.cancel, size: 18),
                      label: const Text('실패'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _DS.absentRed,
                        side: const BorderSide(color: _DS.absentRed),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFallbackCard(ReservationNoticeFallback fallback) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _DS.gold.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _DS.gold.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: _DS.gold, size: 20),
              const SizedBox(width: 8),
              Text(
                fallback.title ?? '대안 예약',
                style: const TextStyle(
                  color: _DS.gold,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          if (fallback.openAtText != null) ...[
            const SizedBox(height: 8),
            Text(
              '신청: ${fallback.openAtText}',
              style: TextStyle(color: _DS.textSecondary, fontSize: 13),
            ),
          ],
          if (fallback.fee != null) ...[
            const SizedBox(height: 4),
            Text(
              '${fallback.fee!.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}원',
              style: TextStyle(color: _DS.textSecondary, fontSize: 13),
            ),
          ],
          if (fallback.url != null && fallback.url!.isNotEmpty) ...[
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => _launchUrl(fallback.url!),
              child: Row(
                children: [
                  Icon(Icons.link, color: _DS.gold, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    '예약 페이지 열기',
                    style: TextStyle(
                      color: _DS.gold,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _reportSuccess(String groundId) async {
    final noticeRef = ref.read(reservationNoticeDetailProvider(widget.noticeId));
    final notice = noticeRef.value;
    if (notice == null) return;

    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return;

    final memberMap = ref.read(memberMapProvider);
    final member = memberMap[currentUser.uid];
    final userName = member?.uniformName ?? member?.name ?? currentUser.displayName ?? '회원';

    setState(() => _reportingSlots[groundId] = true);
    try {
      await ref.read(reservationNoticeDataSourceProvider).reportSuccess(
            teamId: ref.read(currentTeamIdProvider)!,
            noticeId: widget.noticeId,
            groundId: groundId,
            userId: currentUser.uid,
            userName: userName,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('예약 성공! 전체 멤버에게 알림이 전송됩니다.'),
            backgroundColor: _DS.attendGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('오류: $e'),
            backgroundColor: _DS.absentRed,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _reportingSlots[groundId] = false);
    }
  }

  Future<void> _reportFailed(String groundId) async {
    final teamId = ref.read(currentTeamIdProvider);
    final currentUser = ref.read(currentUserProvider);
    if (teamId == null || currentUser == null) return;

    setState(() => _reportingSlots[groundId] = true);
    try {
      await ref.read(reservationNoticeDataSourceProvider).reportFailed(
            teamId: teamId,
            noticeId: widget.noticeId,
            groundId: groundId,
            userId: currentUser.uid,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('실패로 기록되었습니다.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('오류: $e'),
            backgroundColor: _DS.absentRed,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _reportingSlots[groundId] = false);
    }
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  String _formatOpenAt(DateTime openAt) {
    final nextDay = openAt.add(const Duration(minutes: 2));
    const weekdays = ['월', '화', '수', '목', '금', '토', '일'];
    final w1 = weekdays[openAt.weekday - 1];
    final w2 = weekdays[nextDay.weekday - 1];
    return '$w1(${openAt.month}/${openAt.day})→$w2(${nextDay.month}/${nextDay.day}) 23:58~59';
  }

  String _weekday(int wd) {
    const days = ['월', '화', '수', '목', '금', '토', '일'];
    return days[wd - 1];
  }
}
