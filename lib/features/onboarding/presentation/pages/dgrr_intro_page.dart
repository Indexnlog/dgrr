import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

/// DGRR 소개/사용 흐름 안내 페이지
class DgrrIntroPage extends StatelessWidget {
  const DgrrIntroPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDeep,
      appBar: AppBar(
        backgroundColor: AppTheme.bgDeep,
        foregroundColor: AppTheme.textPrimary,
        title: const Text('DGRR 소개'),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _Card(
            title: 'Less Admin, More Focus',
            subtitle:
                'DGRR은 팀 운영에서 반복되는 일을 줄이고, 중요한 의사결정만 남기기 위해 만든 팀 관리 앱이에요.',
            icon: Icons.auto_awesome,
            accent: AppTheme.accentLime,
          ),
          const SizedBox(height: 12),
          _Card(
            title: '처음 사용 흐름',
            subtitle:
                '1) 팀을 선택하고\n2) 구글 로그인 후\n3) 가입 요청을 보내면\n운영진이 승인해요.',
            icon: Icons.flag_outlined,
            accent: AppTheme.primaryBlue,
          ),
          const SizedBox(height: 12),
          _Card(
            title: '주요 기능',
            subtitle:
                '• 월별 등록/회비 관리\n• 수업/매치 참석 투표\n• 공지/예약 공지\n• 알림/딥링크',
            icon: Icons.dashboard_customize_outlined,
            accent: AppTheme.accentGreen,
          ),
          const SizedBox(height: 12),
          _Card(
            title: '안내는 팀별로 달라요',
            subtitle:
                '팀 운영 방식(회비, 구장, 규칙)은 팀마다 달라요.\n팀을 선택한 뒤 “팀 안내”에서 확인해 주세요.',
            icon: Icons.info_outline,
            accent: AppTheme.gold,
          ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: accent.withValues(alpha: 0.25)),
            ),
            child: Icon(icon, color: accent, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

