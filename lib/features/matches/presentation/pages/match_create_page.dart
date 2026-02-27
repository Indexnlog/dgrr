import 'package:flutter/material.dart';

import '../../../../core/errors/errors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../auth/presentation/providers/auth_state_provider.dart';
import '../../../opponents/presentation/providers/opponent_providers.dart';
import '../../../teams/presentation/providers/current_team_provider.dart';
import '../providers/match_providers.dart';

class _C {
  _C._();
  static const bg = Color(0xFF0D1117);
  static const card = Color(0xFF161B22);
  static const red = Color(0xFFDC2626);
  static const green = Color(0xFF2EA043);
  static const text = Color(0xFFF0F6FC);
  static const sub = Color(0xFF8B949E);
  static const muted = Color(0xFF484F58);
  static const divider = Color(0xFF30363D);
}

class MatchCreatePage extends ConsumerStatefulWidget {
  const MatchCreatePage({super.key});

  @override
  ConsumerState<MatchCreatePage> createState() => _MatchCreatePageState();
}

class _MatchCreatePageState extends ConsumerState<MatchCreatePage> {
  final _formKey = GlobalKey<FormState>();
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  final _locationController = TextEditingController();
  final _opponentController = TextEditingController();
  final _contactController = TextEditingController();
  int _minPlayers = 7;
  String _opponentStatus = 'seeking';
  bool _saving = false;
  /// 기존 상대팀 선택 시 opponentId (null = 직접 입력)
  String? _selectedOpponentId;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDate = DateTime(now.year, now.month, now.day);
    _selectedTime = const TimeOfDay(hour: 18, minute: 0);
  }

  @override
  void dispose() {
    _locationController.dispose();
    _opponentController.dispose();
    _contactController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final teamId = ref.read(currentTeamIdProvider);
    if (teamId == null) return;

    final opponentName = _opponentController.text.trim();
    if (opponentName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('상대팀명을 입력해 주세요')),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      final date = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );
      final startTime = '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}';
      final endHour = (_selectedTime.hour + 2) % 24;
      final endTime = '${endHour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}';

      String? opponentId = _selectedOpponentId;
      if (opponentId == null && opponentName.isNotEmpty) {
        final ds = ref.read(opponentDataSourceProvider);
        opponentId = await ds.upsertOpponent(
          teamId,
          name: opponentName,
          contact: _contactController.text.trim().isEmpty ? null : _contactController.text.trim(),
          status: _opponentStatus,
        );
      }

      final matchId = await ref.read(matchDataSourceProvider).createMatch(
        teamId,
        date: date,
        startTime: startTime,
        endTime: endTime,
        location: _locationController.text.trim().isEmpty ? null : _locationController.text.trim(),
        opponentName: opponentName,
        opponentContact: _contactController.text.trim().isEmpty ? null : _contactController.text.trim(),
        opponentStatus: _opponentStatus,
        opponentId: opponentId,
        minPlayers: _minPlayers,
        createdBy: ref.read(currentUserProvider)?.uid,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('경기가 생성되었습니다'), backgroundColor: _C.green),
        );
        context.go('/match/$matchId');
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.showError(context, e, fallback: '경기 생성에 실패했습니다');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      appBar: AppBar(
        backgroundColor: _C.card,
        foregroundColor: _C.text,
        title: const Text('경기 생성'),
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _buildDateField(),
            const SizedBox(height: 16),
            _buildTimeField(),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _locationController,
              label: '장소',
              hint: '예: 석수 다목적구장',
              icon: Icons.location_on,
            ),
            const SizedBox(height: 16),
            _buildOpponentSection(),
            const SizedBox(height: 16),
            _buildStatusSelector(),
            const SizedBox(height: 16),
            _buildMinPlayersSelector(),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                onPressed: _saving ? null : _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: _C.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _saving
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('경기 생성', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('날짜', style: TextStyle(color: _C.sub, fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _pickDate,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: _C.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _C.divider),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today, color: _C.sub, size: 20),
                const SizedBox(width: 12),
                Text(
                  '${_selectedDate.year}.${_selectedDate.month.toString().padLeft(2, '0')}.${_selectedDate.day.toString().padLeft(2, '0')}',
                  style: const TextStyle(color: _C.text, fontSize: 16),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimeField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('시간', style: TextStyle(color: _C.sub, fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _pickTime,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: _C.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _C.divider),
            ),
            child: Row(
              children: [
                const Icon(Icons.schedule, color: _C.sub, size: 20),
                const SizedBox(width: 12),
                Text(
                  _selectedTime.format(context),
                  style: const TextStyle(color: _C.text, fontSize: 16),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: _C.sub, fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          validator: validator,
          style: const TextStyle(color: _C.text),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: _C.muted),
            prefixIcon: Icon(icon, color: _C.sub, size: 20),
            filled: true,
            fillColor: _C.card,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _C.divider)),
          ),
        ),
      ],
    );
  }

  Widget _buildOpponentSection() {
    final opponentsAsync = ref.watch(opponentsProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('상대팀', style: TextStyle(color: _C.sub, fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        opponentsAsync.when(
          data: (opponents) {
            if (opponents.isEmpty) {
              return _buildOpponentInput();
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _buildOpponentModeChip(
                      label: '기존 선택',
                      selected: _selectedOpponentId != null,
                      onTap: () {
                        if (opponents.isNotEmpty) {
                          final o = opponents.first;
                          setState(() {
                            _selectedOpponentId = o.opponentId;
                            _opponentController.text = o.name ?? '';
                            _contactController.text = o.contact ?? '';
                            _opponentStatus = o.status ?? 'seeking';
                          });
                        }
                      },
                    ),
                    const SizedBox(width: 8),
                    _buildOpponentModeChip(
                      label: '직접 입력',
                      selected: _selectedOpponentId == null,
                      onTap: () => setState(() {
                        _selectedOpponentId = null;
                        _opponentController.clear();
                        _contactController.clear();
                      }),
                    ),
                  ],
                ),
                if (_selectedOpponentId != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: _C.card,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _C.divider),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedOpponentId,
                        isExpanded: true,
                        hint: const Text('상대팀 선택', style: TextStyle(color: _C.muted)),
                        dropdownColor: _C.card,
                        style: const TextStyle(color: _C.text),
                        items: opponents.map((o) => DropdownMenuItem(
                          value: o.opponentId,
                          child: Text(o.name ?? o.opponentId),
                        )).toList(),
                        onChanged: (id) {
                          if (id == null) return;
                          final o = opponents.where((x) => x.opponentId == id).firstOrNull;
                          setState(() {
                            _selectedOpponentId = id;
                            _opponentController.text = o?.name ?? '';
                            _contactController.text = o?.contact ?? '';
                            _opponentStatus = o?.status ?? 'seeking';
                          });
                        },
                      ),
                    ),
                  ),
                ] else
                  _buildOpponentInput(),
              ],
            );
          },
          loading: () => _buildOpponentInput(),
          error: (_, __) => _buildOpponentInput(),
        ),
      ],
    );
  }

  Widget _buildOpponentModeChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? _C.green.withValues(alpha: 0.15) : _C.muted.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: selected ? _C.green : _C.divider),
        ),
        child: Text(label, style: TextStyle(color: selected ? _C.green : _C.sub, fontWeight: FontWeight.w600, fontSize: 12)),
      ),
    );
  }

  Widget _buildOpponentInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        _buildTextField(
          controller: _opponentController,
          label: '상대팀명',
          hint: '필수',
          icon: Icons.groups,
          validator: (v) => ((v ?? '').trim().isEmpty) ? '상대팀명을 입력해 주세요' : null,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _contactController,
          label: '상대팀 연락처',
          hint: '선택',
          icon: Icons.phone,
        ),
      ],
    );
  }

  Widget _buildStatusSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('상대팀 상태', style: TextStyle(color: _C.sub, fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildStatusChip('seeking', '모집 중'),
            const SizedBox(width: 8),
            _buildStatusChip('confirmed', '확정'),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusChip(String value, String label) {
    final selected = _opponentStatus == value;
    return GestureDetector(
      onTap: () => setState(() => _opponentStatus = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? _C.green.withValues(alpha:0.15) : _C.muted.withValues(alpha:0.2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? _C.green : _C.divider),
        ),
        child: Text(label, style: TextStyle(color: selected ? _C.green : _C.sub, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _buildMinPlayersSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('최소 인원', style: TextStyle(color: _C.sub, fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Row(
          children: [5, 6, 7, 8].map((n) {
            final selected = _minPlayers == n;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => setState(() => _minPlayers = n),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: selected ? _C.green.withValues(alpha:0.15) : _C.muted.withValues(alpha:0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: selected ? _C.green : _C.divider),
                  ),
                  child: Text('$n명', style: TextStyle(color: selected ? _C.green : _C.sub, fontWeight: FontWeight.w700)),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
