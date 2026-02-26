import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_state_provider.dart';
import '../../../teams/domain/entities/member.dart';
import '../../../teams/presentation/providers/current_team_provider.dart';
import '../../../teams/presentation/providers/team_members_provider.dart';
import '../../domain/entities/event.dart';
import '../providers/event_providers.dart';

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
  static const absentRed = Color(0xFFDA3633);
  static const gold = Color(0xFFFBBF24);
  static const fixedBlue = Color(0xFF58A6FF);
  static const divider = Color(0xFF30363D);
}

class ClassDetailPage extends ConsumerWidget {
  const ClassDetailPage({super.key, required this.eventId});
  final String eventId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventAsync = ref.watch(classDetailProvider(eventId));
    final user = ref.watch(currentUserProvider);
    final memberMap = ref.watch(memberMapProvider);

    return Scaffold(
      backgroundColor: _DS.bgDeep,
      appBar: AppBar(
        backgroundColor: _DS.bgDeep,
        foregroundColor: _DS.textPrimary,
        title: const Text('수업 상세',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
        elevation: 0,
      ),
      body: eventAsync.when(
        data: (event) {
          if (event == null) {
            return const Center(
              child: Text('수업을 찾을 수 없습니다',
                  style: TextStyle(color: _DS.textSecondary)),
            );
          }
          return _ClassDetailBody(
            event: event,
            uid: user?.uid,
            memberMap: memberMap,
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: _DS.teamRed, strokeWidth: 2.5),
        ),
        error: (e, _) => Center(
          child: Text('오류: $e', style: const TextStyle(color: _DS.absentRed)),
        ),
      ),
    );
  }
}

class _ClassDetailBody extends ConsumerStatefulWidget {
  const _ClassDetailBody({
    required this.event,
    required this.uid,
    required this.memberMap,
  });

  final Event event;
  final String? uid;
  final Map<String, Member> memberMap;

  @override
  ConsumerState<_ClassDetailBody> createState() => _ClassDetailBodyState();
}

class _ClassDetailBodyState extends ConsumerState<_ClassDetailBody> {
  bool _isVoting = false;

  Future<void> _handleVote(AttendeeStatus status, {String? reason}) async {
    if (widget.uid == null || _isVoting) return;
    setState(() => _isVoting = true);

    final teamId = ref.read(currentTeamIdProvider);
    if (teamId == null) return;

    final member = widget.memberMap[widget.uid];
    try {
      await ref.read(eventDataSourceProvider).updateAttendeeStatus(
            teamId: teamId,
            eventId: widget.event.eventId,
            userId: widget.uid!,
            userName: member?.uniformName ?? member?.name ?? '알 수 없음',
            number: member?.number,
            status: status,
            reason: reason,
          );
    } finally {
      if (mounted) setState(() => _isVoting = false);
    }
  }

  void _showLateTimeDialog() {
    const options = ['5분', '10분', '15분', '20분', '30분'];
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _DS.bgCard,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: const Text('지각 예상 시간',
            style: TextStyle(
                color: _DS.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: options
              .map((opt) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _handleVote(AttendeeStatus.late, reason: opt);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _DS.surface,
                          foregroundColor: _DS.textPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        child: Text(opt),
                      ),
                    ),
                  ))
              .toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('취소',
                style: TextStyle(color: _DS.textMuted)),
          ),
        ],
      ),
    );
  }

  void _showAbsentReasonDialog() {
    final controller = TextEditingController();
    String? selectedReason;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            backgroundColor: _DS.bgCard,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            title: const Text('불참 사유',
                style: TextStyle(
                    color: _DS.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: ['야근', '부상', '개인 사유'].map((r) {
                    final isSelected = selectedReason == r;
                    return GestureDetector(
                      onTap: () {
                        setDialogState(() {
                          selectedReason = r;
                          controller.text = r;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? _DS.teamRed.withOpacity(0.2)
                              : _DS.surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: isSelected ? _DS.teamRed : _DS.divider),
                        ),
                        child: Text(r,
                            style: TextStyle(
                                color: isSelected
                                    ? _DS.teamRed
                                    : _DS.textSecondary,
                                fontSize: 13,
                                fontWeight: FontWeight.w600)),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: controller,
                  style:
                      const TextStyle(color: _DS.textPrimary, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: '직접 입력...',
                    hintStyle:
                        TextStyle(color: _DS.textMuted, fontSize: 14),
                    filled: true,
                    fillColor: _DS.surface,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: _DS.divider)),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: _DS.divider)),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: _DS.teamRed)),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                  ),
                  onChanged: (val) =>
                      setDialogState(() => selectedReason = null),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('취소',
                    style: TextStyle(color: _DS.textMuted)),
              ),
              TextButton(
                onPressed: () {
                  final reason = controller.text.trim();
                  if (reason.isEmpty) return;
                  Navigator.pop(ctx);
                  _handleVote(AttendeeStatus.absent, reason: reason);
                },
                child: const Text('확인',
                    style: TextStyle(
                        color: _DS.teamRed, fontWeight: FontWeight.w700)),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final event = widget.event;
    final attendees = event.attendees ?? [];
    final isFinished = event.status == EventStatus.finished;

    final myStatus = attendees
        .where((a) => a.userId == widget.uid)
        .map((a) => a.status)
        .firstOrNull;

    final attending =
        attendees.where((a) => a.status == AttendeeStatus.attending).toList();
    final late_ =
        attendees.where((a) => a.status == AttendeeStatus.late).toList();
    final absent =
        attendees.where((a) => a.status == AttendeeStatus.absent).toList();

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildInfoCard(event),
        const SizedBox(height: 16),
        _buildAttendanceSummary(attending.length, late_.length, absent.length),
        const SizedBox(height: 16),
        if (!isFinished) ...[
          _buildVoteButtons(myStatus),
          const SizedBox(height: 20),
        ],
        _buildAttendeeSection('참석', attending, _DS.attendGreen),
        if (late_.isNotEmpty) ...[
          const SizedBox(height: 12),
          _buildAttendeeSection('지각', late_, _DS.gold),
        ],
        if (absent.isNotEmpty) ...[
          const SizedBox(height: 12),
          _buildAttendeeSection('불참', absent, _DS.absentRed),
        ],
        if (isFinished) ...[
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: _DS.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Text('수업 종료',
                  style: TextStyle(
                      color: _DS.textMuted,
                      fontSize: 14,
                      fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildInfoCard(Event event) {
    final dateStr = event.date ?? '날짜 미정';
    final time = '${event.startTime ?? '--:--'} ~ ${event.endTime ?? '--:--'}';
    final location = event.location ?? '장소 미정';

    return Container(
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _DS.fixedBlue.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text('수업',
                    style: TextStyle(
                        color: _DS.fixedBlue,
                        fontSize: 12,
                        fontWeight: FontWeight.w700)),
              ),
              const Spacer(),
              _StatusBadge(status: event.status),
            ],
          ),
          const SizedBox(height: 14),
          Text(event.title ?? '정기 수업',
              style: const TextStyle(
                  color: _DS.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 14),
          _InfoRow(icon: Icons.calendar_today_outlined, text: dateStr),
          const SizedBox(height: 8),
          _InfoRow(icon: Icons.schedule_outlined, text: time),
          const SizedBox(height: 8),
          _InfoRow(icon: Icons.location_on_outlined, text: location),
        ],
      ),
    );
  }

  Widget _buildAttendanceSummary(int attending, int late_, int absent) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: _DS.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _DS.divider),
      ),
      child: Row(
        children: [
          _SummaryCell(
              label: '참석', count: attending, color: _DS.attendGreen),
          Container(width: 1, height: 36, color: _DS.divider),
          _SummaryCell(label: '지각', count: late_, color: _DS.gold),
          Container(width: 1, height: 36, color: _DS.divider),
          _SummaryCell(label: '불참', count: absent, color: _DS.absentRed),
        ],
      ),
    );
  }

  Widget _buildVoteButtons(AttendeeStatus? myStatus) {
    return Row(
      children: [
        _VoteButton(
          label: '참석',
          icon: Icons.check_circle_outline,
          activeIcon: Icons.check_circle,
          isActive: myStatus == AttendeeStatus.attending,
          color: _DS.attendGreen,
          isLoading: _isVoting,
          onTap: () => _handleVote(AttendeeStatus.attending),
        ),
        const SizedBox(width: 8),
        _VoteButton(
          label: '지각',
          icon: Icons.watch_later_outlined,
          activeIcon: Icons.watch_later,
          isActive: myStatus == AttendeeStatus.late,
          color: _DS.gold,
          isLoading: _isVoting,
          onTap: _showLateTimeDialog,
        ),
        const SizedBox(width: 8),
        _VoteButton(
          label: '불참',
          icon: Icons.cancel_outlined,
          activeIcon: Icons.cancel,
          isActive: myStatus == AttendeeStatus.absent,
          color: _DS.absentRed,
          isLoading: _isVoting,
          onTap: () => _showAbsentReasonDialog(),
        ),
      ],
    );
  }

  Widget _buildAttendeeSection(
    String label,
    List<EventAttendee> attendees,
    Color color,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(width: 3, height: 14, color: color),
            const SizedBox(width: 8),
            Text('$label ${attendees.length}명',
                style: TextStyle(
                    color: color,
                    fontSize: 13,
                    fontWeight: FontWeight.w700)),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: attendees.map((a) {
            return Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: color.withOpacity(0.25), width: 0.5),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (a.number != null) ...[
                    Text('#${a.number}',
                        style: TextStyle(
                            color: color.withOpacity(0.7),
                            fontSize: 10,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(width: 4),
                  ],
                  Text(a.userName ?? '알 수 없음',
                      style: const TextStyle(
                          color: _DS.textPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
                  if (a.reason != null) ...[
                    const SizedBox(width: 4),
                    Text('(${a.reason})',
                        style: TextStyle(
                            color: _DS.textMuted,
                            fontSize: 10,
                            fontStyle: FontStyle.italic)),
                  ],
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final EventStatus? status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      EventStatus.active => ('진행중', _DS.attendGreen),
      EventStatus.confirmed => ('확정', _DS.fixedBlue),
      EventStatus.finished => ('종료', _DS.textMuted),
      EventStatus.cancelled => ('취소', _DS.absentRed),
      null => ('대기', _DS.textMuted),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 11, fontWeight: FontWeight.w700)),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: _DS.textMuted),
        const SizedBox(width: 8),
        Text(text,
            style: const TextStyle(color: _DS.textSecondary, fontSize: 14)),
      ],
    );
  }
}

class _SummaryCell extends StatelessWidget {
  const _SummaryCell({
    required this.label,
    required this.count,
    required this.color,
  });
  final String label;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text('$count',
              style: TextStyle(
                  color: color, fontSize: 22, fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(label,
              style: TextStyle(
                  color: _DS.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _VoteButton extends StatelessWidget {
  const _VoteButton({
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.isActive,
    required this.color,
    required this.isLoading,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final IconData activeIcon;
  final bool isActive;
  final Color color;
  final bool isLoading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: isLoading ? null : onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 48,
          decoration: BoxDecoration(
            color: isActive ? color : _DS.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: isActive ? color : _DS.divider, width: 1.5),
          ),
          child: Center(
            child: isLoading
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: _DS.textPrimary))
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(isActive ? activeIcon : icon,
                          size: 18,
                          color: isActive ? Colors.white : _DS.textSecondary),
                      const SizedBox(width: 6),
                      Text(label,
                          style: TextStyle(
                              color: isActive
                                  ? Colors.white
                                  : _DS.textSecondary,
                              fontSize: 14,
                              fontWeight: FontWeight.w700)),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
