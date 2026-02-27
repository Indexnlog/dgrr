import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../teams/presentation/providers/current_team_provider.dart';

/// 승인 대기 화면 (status: pending)
/// 홈 진입 전에 표시
class PendingApprovalPage extends ConsumerWidget {
  const PendingApprovalPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.hourglass_top,
                size: 80,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 24),
              Text(
                '승인 대기 중',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              Text(
                '운영진이 가입 신청을 검토 중입니다.\n승인되면 알려드릴게요.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 48),
              OutlinedButton.icon(
                onPressed: () async {
                  await ref.read(signOutProvider)();
                  if (context.mounted) {
                    await ref.read(currentTeamIdProvider.notifier).clearTeam();
                  }
                },
                icon: const Icon(Icons.logout),
                label: const Text('다른 팀 선택하기'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
