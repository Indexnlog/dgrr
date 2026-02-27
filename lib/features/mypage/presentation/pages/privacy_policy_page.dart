import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

/// 개인정보처리방침 (앱스토어 필수)
class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('개인정보처리방침'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            '영원FC 앱 개인정보처리방침',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 24),
          _Section(
            title: '1. 수집하는 개인정보',
            content: '본 앱은 서비스 제공을 위해 다음 정보를 수집합니다.\n\n'
                '• 필수: 이메일, 이름 (구글 로그인)\n'
                '• 선택: 프로필 사진, 연락처, 등번호\n\n'
                '팀 가입 시 팀 운영진이 관리하는 추가 정보(등번호, 등록명 등)가 수집될 수 있습니다.',
          ),
          _Section(
            title: '2. 수집 목적',
            content: '• 팀원 관리 및 출석·경기 기록\n'
                '• 회비·등록 관리\n'
                '• 푸시 알림 발송\n'
                '• 서비스 개선',
          ),
          _Section(
            title: '3. 보관 기간',
            content: '회원 탈퇴 시까지 보관하며, 탈퇴 후 지체 없이 파기합니다.',
          ),
          _Section(
            title: '4. 제3자 제공',
            content: '개인정보는 원칙적으로 제3자에게 제공하지 않습니다. '
                '다만 법령에 의한 경우는 예외로 합니다.',
          ),
          _Section(
            title: '5. 문의',
            content: '개인정보 관련 문의: 앱 내 피드백 또는 팀 운영진에게 연락해 주세요.',
          ),
          const SizedBox(height: 32),
          Text(
            '시행일: 2026년 2월 23일',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondary,
                ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.content});

  final String title;
  final String content;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  height: 1.5,
                ),
          ),
        ],
      ),
    );
  }
}
