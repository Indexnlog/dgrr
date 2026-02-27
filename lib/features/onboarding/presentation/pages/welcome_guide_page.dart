import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_theme.dart';

/// 영원FC 신규 회원 온보딩 가이드 (STEP BY STEP)
/// - 운영시트 제거, 회비제(2026.1~) 반영
class WelcomeGuidePage extends StatelessWidget {
  const WelcomeGuidePage({super.key});

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDeep,
      appBar: AppBar(
        backgroundColor: AppTheme.bgDeep,
        foregroundColor: AppTheme.textPrimary,
        title: const Text('영원FC 안내'),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildHeader(context),
          const SizedBox(height: 24),
          _buildStep1(context),
          const SizedBox(height: 24),
          _buildStep2(context),
          const SizedBox(height: 24),
          _buildStep3(context),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.sports_soccer, color: AppTheme.accentLime, size: 32),
              const SizedBox(width: 12),
              Text(
                'Welcome to 영원FC!',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '영원FC 운영의 모든 기본 정보가 이 앱에 담겨 있어요!',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 14,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  /// STEP1: 회칙·역할, 회비 안내 (업데이트된 회비제)
  Widget _buildStep1(BuildContext context) {
    return _StepCard(
      step: 1,
      color: AppTheme.gold,
      title: 'STEP 1',
      children: [
        _GuideItem(
          icon: Icons.description,
          title: '영원FC 회칙 및 역할',
          onTap: () => _launchUrl(
            'https://docs.google.com/document/d/1M3i725g9L_7skueV8sKeMySfiuwmEUMdHOyJXcky2L0/edit#heading=h.7lzedws1hb0s',
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '꼭 읽어주세요! 회비, 운영 방식, 팀 내 역할에 관한 모든 기본 정보가 담겨 있어요.',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 8),
              Text(
                '• 구장 대관이 어려워 모두가 구장 대여 신청에 참여해요\n'
                '• 신규 회원은 우선 매주 월요일 구장 대여 참여만 하시면 됩니다',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 12, height: 1.5),
              ),
            ],
          ),
        ),
        const Divider(color: AppTheme.divider, height: 24),
        _GuideItem(
          icon: Icons.account_balance_wallet,
          title: '회비 안내 (2026.1~)',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '월별 등록제로 운영해요. 앱에서 매월 20~24일에 다음 달 등록 투표를 진행합니다.',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 12),
              _FeeRow(label: '등록', fee: '5만원', desc: '수업/경기 참가'),
              _FeeRow(label: '휴회', fee: '2만원', desc: '개인 사유 불참, 회원 자격 유지'),
              _FeeRow(label: '미등록', fee: '0원', desc: '부상·출산 등 인정 사유'),
            ],
          ),
        ),
      ],
    );
  }

  /// STEP2: 모임통장, 수업 등록 (앱에서 - 운영시트 제거)
  Widget _buildStep2(BuildContext context) {
    return _StepCard(
      step: 2,
      color: AppTheme.accentGreen,
      title: 'STEP 2',
      children: [
        _GuideItem(
          icon: Icons.savings,
          title: '모임통장 가입',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '카카오뱅크 모임통장 링크는 총무님이 단톡으로 공유해드립니다. '
                '회비는 모두 이 통장으로 관리돼요.',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, height: 1.4),
              ),
            ],
          ),
        ),
        const Divider(color: AppTheme.divider, height: 24),
        _GuideItem(
          icon: Icons.event_note,
          title: '수업 등록',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '매월 20~24일 앱에서 익월 등록 투표를 진행해요. '
                '등록/휴회/미등록 중 선택 후, 등록·휴회 회원은 모임통장에 입금해주세요.',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 8),
              Text(
                '25일~말일에는 일자별 수업 참석 가능 일자를 앱에서 체크해주세요.',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 12, height: 1.5),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// STEP3: 구장 위치, 플랩풋볼
  Widget _buildStep3(BuildContext context) {
    return _StepCard(
      step: 3,
      color: AppTheme.primaryBlue,
      title: 'STEP 3',
      children: [
        _GuideItem(
          icon: Icons.location_on,
          title: '주요 구장 위치',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _GroundItem(
                name: '금천구 풋살장',
                address: '서울 금천구 가산동 562-3',
                route: '1호선 독산역 3번 출구 도보 15분',
                mapUrl: 'https://naver.me/xrCF2n1V',
              ),
              const SizedBox(height: 12),
              _GroundItem(
                name: '석수 다목적구장',
                address: '서울 금천구 시흥동 673-3',
                route: '1호선 석수역 2번 출구 도보 7분',
                mapUrl: 'https://naver.me/GQSFWusX',
              ),
              const SizedBox(height: 12),
              _GroundItem(
                name: '신도림 로꼬 풋살아레나',
                address: '서울 구로구 신도림로 11나길 8, 지하1층',
                route: '1·2호선 신도림역 버스 10분 / 구로역 도보 15분',
                mapUrl: 'https://naver.me/FCAfJtFA',
              ),
            ],
          ),
        ),
        const Divider(color: AppTheme.divider, height: 24),
        _GuideItem(
          icon: Icons.sports_soccer,
          title: '플랩풋볼 팀 가입',
          onTap: () => _launchUrl('https://www.plabfootball.com/team/profile/foreveronefc/'),
          child: Text(
            '외부 매치나 대회 참여 시 사용하는 플랫폼이에요. '
            '팀에 적응하신 후 천천히 가입해주시면 됩니다!',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, height: 1.4),
          ),
        ),
      ],
    );
  }
}

class _StepCard extends StatelessWidget {
  const _StepCard({
    required this.step,
    required this.color,
    required this.title,
    required this.children,
  });

  final int step;
  final Color color;
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}

class _GuideItem extends StatelessWidget {
  const _GuideItem({
    required this.icon,
    required this.title,
    required this.child,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: AppTheme.accentLime),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (onTap != null)
              Icon(Icons.open_in_new, size: 16, color: AppTheme.fixedBlue),
          ],
        ),
        const SizedBox(height: 8),
        child,
      ],
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: content,
      );
    }
    return content;
  }
}

class _FeeRow extends StatelessWidget {
  const _FeeRow({
    required this.label,
    required this.fee,
    required this.desc,
  });

  final String label;
  final String fee;
  final String desc;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 56,
            child: Text(
              label,
              style: const TextStyle(
                color: AppTheme.accentLime,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
          Text(
            fee,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              desc,
              style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _GroundItem extends StatelessWidget {
  const _GroundItem({
    required this.name,
    required this.address,
    required this.route,
    required this.mapUrl,
  });

  final String name;
  final String address;
  final String route;
  final String mapUrl;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => launchUrl(Uri.parse(mapUrl), mode: LaunchMode.externalApplication),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.location_on, size: 16, color: AppTheme.teamRed),
                const SizedBox(width: 6),
                Text(
                  name,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const Spacer(),
                Icon(Icons.open_in_new, size: 14, color: AppTheme.fixedBlue),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              address,
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
            ),
            Text(
              route,
              style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}
