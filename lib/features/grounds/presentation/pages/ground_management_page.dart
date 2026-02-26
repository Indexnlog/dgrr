import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/permissions/permission_checker.dart';
import '../../../teams/domain/entities/member.dart';
import '../../../teams/presentation/providers/team_members_provider.dart';
import '../../data/models/ground_model.dart';
import '../providers/ground_providers.dart';

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
}

/// 구장 관리 페이지 (운영진 전용)
/// - 구장 등록/수정/비활성화
/// - 구장별 고정 담당자 배정
class GroundManagementPage extends ConsumerWidget {
  const GroundManagementPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAdmin = PermissionChecker.isAdmin(ref);
    final groundsAsync = ref.watch(allGroundsProvider);
    final memberMap = ref.watch(memberMapProvider);

    if (!isAdmin) {
      return Scaffold(
        backgroundColor: _DS.bgDeep,
        appBar: AppBar(
          backgroundColor: _DS.bgDeep,
          foregroundColor: _DS.textPrimary,
          title: const Text('구장 관리',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
          elevation: 0,
        ),
        body: const Center(
          child: Text(
            '운영진만 구장을 관리할 수 있습니다.',
            style: TextStyle(color: _DS.textSecondary),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: _DS.bgDeep,
      appBar: AppBar(
        backgroundColor: _DS.bgDeep,
        foregroundColor: _DS.textPrimary,
        title: const Text('구장 관리',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
        elevation: 0,
      ),
      body: groundsAsync.when(
        data: (grounds) {
          if (grounds.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.stadium_outlined,
                      size: 48, color: _DS.textMuted.withOpacity(0.4)),
                  const SizedBox(height: 12),
                  Text('등록된 구장이 없습니다',
                      style: TextStyle(color: _DS.textMuted, fontSize: 14)),
                  const SizedBox(height: 8),
                  Text(
                    '운영진이 구장을 등록해 주세요',
                    style: TextStyle(color: _DS.textMuted, fontSize: 12),
                  ),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: grounds.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, index) => _GroundCard(
              ground: grounds[index],
              memberMap: memberMap,
              ref: ref,
            ),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(
            color: _DS.teamRed,
            strokeWidth: 2.5,
          ),
        ),
        error: (e, _) => Center(
          child: Text('오류: $e',
              style: const TextStyle(color: _DS.textSecondary)),
        ),
      ),
    );
  }
}

class _GroundCard extends StatelessWidget {
  const _GroundCard({
    required this.ground,
    required this.memberMap,
    required this.ref,
  });

  final GroundModel ground;
  final Map<String, Member> memberMap;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final isActive = ground.active ?? true;
    final managerNames = (ground.managers ?? [])
        .map((uid) => memberMap[uid]?.uniformName ?? memberMap[uid]?.name ?? uid)
        .join(', ');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _DS.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _DS.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isActive
                      ? _DS.attendGreen.withOpacity(0.15)
                      : _DS.surface,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isActive ? '활성' : '비활성',
                  style: TextStyle(
                    color: isActive ? _DS.attendGreen : _DS.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (ground.priority != null)
                Text(
                  '우선순위 ${ground.priority}',
                  style: TextStyle(
                    color: _DS.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            ground.name,
            style: const TextStyle(
              color: _DS.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (ground.address != null && ground.address!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              ground.address!,
              style: TextStyle(color: _DS.textSecondary, fontSize: 13),
            ),
          ],
          if (managerNames.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              '담당: $managerNames',
              style: TextStyle(color: _DS.textMuted, fontSize: 12),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (ground.url != null && ground.url!.isNotEmpty) ...[
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () {},
              child: Text(
                '예약 링크',
                style: TextStyle(
                  color: _DS.textSecondary,
                  fontSize: 12,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
