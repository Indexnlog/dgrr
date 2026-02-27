import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

/// 이용약관 (앱스토어 필수)
class TermsPage extends StatelessWidget {
  const TermsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('이용약관'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            '영원FC 앱 이용약관',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 24),
          _Section(
            title: '제1조 (목적)',
            content: '본 약관은 영원FC 앱(이하 "앱")의 이용 조건 및 절차를 정함을 목적으로 합니다.',
          ),
          _Section(
            title: '제2조 (서비스 이용)',
            content: '1. 앱은 팀 풋살 관리·출석·경기 기록·회비 관리 등을 지원합니다.\n\n'
                '2. 팀 가입은 관리자 승인 후 이루어집니다.\n\n'
                '3. 서비스 이용 시 팀 내부 규칙을 준수해 주세요.',
          ),
          _Section(
            title: '제3조 (금지 행위)',
            content: '• 타인의 정보 도용\n'
                '• 앱 서비스 방해\n'
                '• 팀원 비방·욕설 등',
          ),
          _Section(
            title: '제4조 (문의)',
            content: '본 약관 관련 문의: 앱 내 피드백 또는 팀 운영진에게 연락해 주세요.',
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
