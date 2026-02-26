import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../auth/presentation/providers/auth_state_provider.dart';
import '../../../events/data/models/event_model.dart';
import '../../../events/presentation/providers/event_providers.dart';
import '../../../matches/data/models/match_model.dart';
import '../../../matches/presentation/providers/match_providers.dart';
import '../../../teams/presentation/providers/current_team_provider.dart';
import '../../data/models/reservation_notice_model.dart';
import '../../domain/entities/reservation_notice.dart';
import '../../domain/services/reservation_notice_service.dart';
import '../providers/reservation_notice_providers.dart';
import '../../../grounds/presentation/providers/ground_providers.dart';

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
  static const classBlue = Color(0xFF388BFD);
}

/// 예약 공지 만들기 페이지 (반자동)
class ReservationNoticeCreatePage extends ConsumerStatefulWidget {
  const ReservationNoticeCreatePage({super.key});

  @override
  ConsumerState<ReservationNoticeCreatePage> createState() =>
      _ReservationNoticeCreatePageState();
}

class _ReservationNoticeCreatePageState
    extends ConsumerState<ReservationNoticeCreatePage> {
  @override
  void dispose() {
    _fallbackTitle.dispose();
    _fallbackOpenAt.dispose();
    _fallbackUrl.dispose();
    _fallbackFee.dispose();
    _fallbackMemo.dispose();
    super.dispose();
  }
  ReservationNoticeForType _selectedType = ReservationNoticeForType.class_;
  String? _selectedEventId;
  String? _selectedMatchId;
  DateTime? _targetDate;
  String? _targetStartTime;
  String? _targetEndTime;
  bool _isCreating = false;
  bool _showFallback = false;
  final _fallbackTitle = TextEditingController();
  final _fallbackOpenAt = TextEditingController();
  final _fallbackUrl = TextEditingController();
  final _fallbackFee = TextEditingController();
  final _fallbackMemo = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final classesAsync = ref.watch(upcomingClassesProvider);
    final matchesAsync = ref.watch(upcomingMatchesProvider);
    final groundsAsync = ref.watch(activeGroundsProvider);
    final currentUser = ref.watch(currentUserProvider);
    final teamId = ref.watch(currentTeamIdProvider);

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
          '예약 공지 만들기',
          style: TextStyle(
            color: _DS.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '대상 유형',
              style: TextStyle(
                color: _DS.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _TypeChip(
                  label: '수업 (목)',
                  isSelected: _selectedType == ReservationNoticeForType.class_,
                  onTap: () {
                    setState(() {
                      _selectedType = ReservationNoticeForType.class_;
                      _selectedEventId = null;
                      _selectedMatchId = null;
                      _targetDate = null;
                      _targetStartTime = null;
                      _targetEndTime = null;
                    });
                  },
                ),
                const SizedBox(width: 12),
                _TypeChip(
                  label: '매치 (일)',
                  isSelected: _selectedType == ReservationNoticeForType.match,
                  onTap: () {
                    setState(() {
                      _selectedType = ReservationNoticeForType.match;
                      _selectedEventId = null;
                      _selectedMatchId = null;
                      _targetDate = null;
                      _targetStartTime = null;
                      _targetEndTime = null;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (_selectedType == ReservationNoticeForType.class_)
              _buildClassSelector(classesAsync)
            else
              _buildMatchSelector(matchesAsync),
            if (_targetDate != null && groundsAsync.value != null) ...[
              const SizedBox(height: 24),
              _buildPreview(groundsAsync.value!),
              const SizedBox(height: 16),
              _buildFallbackSection(),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isCreating ||
                          teamId == null ||
                          currentUser == null
                      ? null
                      : _createNotice,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _DS.attendGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isCreating
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('예약 공지 발송'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildClassSelector(AsyncValue<List<EventModel>> classesAsync) {
    return classesAsync.when(
      data: (classes) {
        if (classes.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _DS.bgCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _DS.divider),
            ),
            child: Text(
              '다가오는 수업이 없습니다',
              style: TextStyle(color: _DS.textMuted, fontSize: 14),
            ),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '수업 선택',
              style: TextStyle(
                color: _DS.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            ...classes.take(10).map((e) {
              final isSelected = _selectedEventId == e.eventId;
              final date = e.date != null ? _parseDate(e.date!) : null;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedEventId = e.eventId;
                      _targetDate = date;
                      _targetStartTime = e.startTime;
                      _targetEndTime = e.endTime;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? _DS.classBlue.withOpacity(0.15)
                          : _DS.bgCard,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected ? _DS.classBlue : _DS.divider,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.school,
                          color: isSelected ? _DS.classBlue : _DS.textMuted,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                e.title ?? '수업',
                                style: TextStyle(
                                  color: _DS.textPrimary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (e.date != null)
                                Text(
                                  '${e.date} ${e.startTime ?? ''}~${e.endTime ?? ''}',
                                  style: TextStyle(
                                    color: _DS.textMuted,
                                    fontSize: 12,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        if (isSelected)
                          Icon(Icons.check_circle, color: _DS.classBlue, size: 20),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        );
      },
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: CircularProgressIndicator(color: _DS.teamRed, strokeWidth: 2.5),
        ),
      ),
      error: (e, _) => Text(
        '수업 목록을 불러올 수 없습니다: $e',
        style: TextStyle(color: _DS.absentRed, fontSize: 13),
      ),
    );
  }

  Widget _buildMatchSelector(AsyncValue<List<MatchModel>> matchesAsync) {
    return matchesAsync.when(
      data: (matches) {
        if (matches.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _DS.bgCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _DS.divider),
            ),
            child: Text(
              '다가오는 경기가 없습니다',
              style: TextStyle(color: _DS.textMuted, fontSize: 14),
            ),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '경기 선택',
              style: TextStyle(
                color: _DS.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            ...matches.take(10).map((m) {
              final isSelected = _selectedMatchId == m.matchId;
              final date = m.date;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedMatchId = m.matchId;
                      _targetDate = date;
                      _targetStartTime = m.startTime;
                      _targetEndTime = m.endTime;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? _DS.gold.withOpacity(0.15)
                          : _DS.bgCard,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected ? _DS.gold : _DS.divider,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.sports_soccer,
                          color: isSelected ? _DS.gold : _DS.textMuted,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'VS ${m.opponentName ?? '상대 미정'}',
                                style: TextStyle(
                                  color: _DS.textPrimary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (date != null)
                                Text(
                                  '${date.month}/${date.day} ${m.startTime ?? ''}~${m.endTime ?? ''}',
                                  style: TextStyle(
                                    color: _DS.textMuted,
                                    fontSize: 12,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        if (isSelected)
                          Icon(Icons.check_circle, color: _DS.gold, size: 20),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        );
      },
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: CircularProgressIndicator(color: _DS.teamRed, strokeWidth: 2.5),
        ),
      ),
      error: (e, _) => Text(
        '경기 목록을 불러올 수 없습니다: $e',
        style: TextStyle(color: _DS.absentRed, fontSize: 13),
      ),
    );
  }

  Widget _buildFallbackSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => setState(() => _showFallback = !_showFallback),
          child: Row(
            children: [
              Icon(
                _showFallback ? Icons.expand_less : Icons.expand_more,
                color: _DS.textMuted,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                '대안 예약 추가 (금천구 실패 시)',
                style: TextStyle(
                  color: _DS.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        if (_showFallback) ...[
          const SizedBox(height: 12),
          _buildTextField(_fallbackTitle, '제목 (예: 고척 풋살구장)'),
          const SizedBox(height: 8),
          _buildTextField(_fallbackOpenAt, '신청 시점 (예: 2/25(수) 10:00)'),
          const SizedBox(height: 8),
          _buildTextField(_fallbackUrl, '예약 URL'),
          const SizedBox(height: 8),
          _buildTextField(_fallbackFee, '요금 (숫자만, 예: 62400)'),
          const SizedBox(height: 8),
          _buildTextField(_fallbackMemo, '메모 (예: 2시간 이내 결제)'),
        ],
      ],
    );
  }

  Widget _buildTextField(TextEditingController c, String hint) {
    return TextField(
      controller: c,
      style: const TextStyle(color: _DS.textPrimary, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: _DS.textMuted, fontSize: 13),
        filled: true,
        fillColor: _DS.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: _DS.divider),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
    );
  }

  Widget _buildPreview(List<dynamic> grounds) {
    if (_targetDate == null) return const SizedBox.shrink();

    final openAt = ReservationNoticeService.calculateOpenAt(
      _targetDate!,
      _selectedType,
    );
    final openAtStr = ReservationNoticeService.formatOpenAt(openAt);

    final slots = grounds
        .map((g) => ReservationNoticeSlot(
              groundId: g.groundId,
              groundName: g.name,
              address: g.address,
              url: g.url,
              managers: g.managers ?? [],
              result: SlotResult.pending,
            ))
        .toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _DS.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _DS.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '미리보기',
            style: TextStyle(
              color: _DS.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '이용일: ${_targetDate!.month}/${_targetDate!.day} ${_targetStartTime ?? ''}~${_targetEndTime ?? ''}',
            style: TextStyle(color: _DS.textPrimary, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(
            '예약 시도: $openAtStr',
            style: TextStyle(color: _DS.textMuted, fontSize: 13),
          ),
          const SizedBox(height: 12),
          Text(
            '구장 ${slots.length}개, 담당자 자동 채움',
            style: TextStyle(color: _DS.textSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }

  DateTime? _parseDate(String dateStr) {
    final parts = dateStr.split('-');
    if (parts.length != 3) return null;
    final y = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    final d = int.tryParse(parts[2]);
    if (y == null || m == null || d == null) return null;
    return DateTime(y, m, d);
  }

  Future<void> _createNotice() async {
    final teamId = ref.read(currentTeamIdProvider);
    final currentUser = ref.read(currentUserProvider);
    final grounds = ref.read(activeGroundsProvider).value;
    if (teamId == null || currentUser == null || grounds == null || _targetDate == null) {
      return;
    }

    setState(() => _isCreating = true);
    try {
      final openAt = ReservationNoticeService.calculateOpenAt(
        _targetDate!,
        _selectedType,
      );
      final slots = grounds
          .map((g) => ReservationNoticeSlot(
                groundId: g.groundId,
                groundName: g.name,
                address: g.address,
                url: g.url,
                managers: g.managers ?? [],
                result: SlotResult.pending,
              ))
          .toList();

      ReservationNoticeFallback? fallback;
      if (_showFallback &&
          (_fallbackTitle.text.isNotEmpty || _fallbackUrl.text.isNotEmpty)) {
        fallback = ReservationNoticeFallback(
          title: _fallbackTitle.text.isEmpty ? null : _fallbackTitle.text,
          openAtText: _fallbackOpenAt.text.isEmpty ? null : _fallbackOpenAt.text,
          url: _fallbackUrl.text.isEmpty ? null : _fallbackUrl.text,
          fee: int.tryParse(_fallbackFee.text),
          memo: _fallbackMemo.text.isEmpty ? null : _fallbackMemo.text,
        );
      }

      final notice = ReservationNoticeModel(
        noticeId: '',
        targetDate: _targetDate!,
        targetStartTime: _targetStartTime ?? '20:00',
        targetEndTime: _targetEndTime ?? '22:00',
        reservedForType: _selectedType,
        reservedForId: _selectedEventId ?? _selectedMatchId,
        venueType: VenueType.geumcheon,
        openAt: openAt,
        slots: slots,
        fallback: fallback,
        status: ReservationNoticeStatus.published,
        createdBy: currentUser.uid,
        publishedAt: DateTime.now(),
        createdAt: DateTime.now(),
      );

      final ds = ref.read(reservationNoticeDataSourceProvider);
      final id = await ds.createNotice(teamId, notice);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('예약 공지가 발송되었습니다.'),
            backgroundColor: _DS.attendGreen,
          ),
        );
        context.pop();
        context.push('/schedule/reservation-notices/$id');
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
      if (mounted) setState(() => _isCreating = false);
    }
  }
}

class _TypeChip extends StatelessWidget {
  const _TypeChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? _DS.teamRed.withOpacity(0.2) : _DS.bgCard,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? _DS.teamRed : _DS.divider,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? _DS.teamRed : _DS.textSecondary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
