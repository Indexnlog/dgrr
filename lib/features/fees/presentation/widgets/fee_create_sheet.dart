import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/errors.dart';
import '../../../auth/presentation/providers/auth_state_provider.dart';
import '../../../teams/presentation/providers/current_team_provider.dart';
import '../../data/models/fee_model.dart';
import '../../domain/entities/fee.dart';
import '../providers/fee_providers.dart';

/// 회비 설정 생성 바텀시트 (총무용)
Future<void> showFeeCreateSheet(BuildContext context) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: _C.card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) => const _FeeCreateSheet(),
  );
}

class _C {
  _C._();
  static const card = Color(0xFF161B22);
  static const surface = Color(0xFF21262D);
  static const green = Color(0xFF2EA043);
  static const text = Color(0xFFF0F6FC);
  static const sub = Color(0xFF8B949E);
  static const muted = Color(0xFF484F58);
  static const divider = Color(0xFF30363D);
}

class _FeeCreateSheet extends ConsumerStatefulWidget {
  const _FeeCreateSheet();

  @override
  ConsumerState<_FeeCreateSheet> createState() => _FeeCreateSheetState();
}

class _FeeCreateSheetState extends ConsumerState<_FeeCreateSheet> {
  final _nameController = TextEditingController();
  final _amountController = TextEditingController(text: '50000');
  final _memoController = TextEditingController();
  FeeType _feeType = FeeType.membership;
  bool _isActive = true;
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _memoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final defaultName = '${now.year}년 ${now.month}월 회비';

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: _C.muted,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            '회비 설정 추가',
            style: TextStyle(
              color: _C.text,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 20),
          _buildLabel('유형'),
          const SizedBox(height: 6),
          Row(
            children: [
              _buildTypeChip('정기 회비', FeeType.membership),
              const SizedBox(width: 8),
              _buildTypeChip('수업비', FeeType.lesson),
            ],
          ),
          const SizedBox(height: 16),
          _buildLabel('이름'),
          const SizedBox(height: 6),
          TextField(
            controller: _nameController,
            decoration: _inputDecoration('예: $defaultName'),
            style: const TextStyle(color: _C.text),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),
          _buildLabel('금액 (원)'),
          const SizedBox(height: 6),
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            decoration: _inputDecoration('50000'),
            style: const TextStyle(color: _C.text),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),
          _buildLabel('메모 (선택)'),
          const SizedBox(height: 6),
          TextField(
            controller: _memoController,
            decoration: _inputDecoration(''),
            style: const TextStyle(color: _C.text),
            maxLines: 2,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: Checkbox(
                  value: _isActive,
                  onChanged: (v) => setState(() => _isActive = v ?? true),
                  activeColor: _C.green,
                  fillColor: WidgetStateProperty.resolveWith((_) => _C.muted),
                ),
              ),
              const SizedBox(width: 12),
              const Text('활성', style: TextStyle(color: _C.text, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton(
              onPressed: _saving ? null : () => _create(context),
              style: FilledButton.styleFrom(
                backgroundColor: _C.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('추가', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: _C.sub,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildTypeChip(String label, FeeType type) {
    final selected = _feeType == type;
    return GestureDetector(
      onTap: () => setState(() => _feeType = type),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? _C.green.withValues(alpha: 0.2) : _C.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? _C.green : _C.divider,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? _C.green : _C.sub,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: _C.muted),
      filled: true,
      fillColor: _C.surface,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }

  Future<void> _create(BuildContext context) async {
    final name = _nameController.text.trim();
    final amount = int.tryParse(_amountController.text.trim());
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('이름을 입력해 주세요')),
      );
      return;
    }
    if (amount == null || amount < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('올바른 금액을 입력해 주세요')),
      );
      return;
    }

    final teamId = ref.read(currentTeamIdProvider);
    final createdBy = ref.read(currentUserProvider)?.uid;
    if (teamId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('팀을 선택해 주세요')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final now = DateTime.now();
      final fee = FeeModel(
        feeId: '',
        feeType: _feeType,
        name: name,
        amount: amount,
        periodStart: DateTime(now.year, now.month, 1),
        periodEnd: DateTime(now.year, now.month + 1, 0),
        memo: _memoController.text.trim().isEmpty ? null : _memoController.text.trim(),
        isActive: _isActive,
        createdBy: createdBy,
        createdAt: now,
      );

      final ds = ref.read(feeDataSourceProvider);
      await ds.createFee(teamId, fee);

      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$name 추가되었습니다'), backgroundColor: _C.green),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ErrorHandler.showError(context, e, fallback: '저장에 실패했습니다');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
