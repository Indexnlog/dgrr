import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/providers/firebase_ready_provider.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/entities/public_team.dart';
import '../providers/public_teams_provider.dart';

class TeamSelectPage extends ConsumerStatefulWidget {
  const TeamSelectPage({super.key});

  @override
  ConsumerState<TeamSelectPage> createState() => _TeamSelectPageState();
}

class _TeamSelectPageState extends ConsumerState<TeamSelectPage> {
  String? _selectedTeamId;
  bool _isSigningIn = false;
  ProviderSubscription<AsyncValue<List<PublicTeam>>>? _teamsSubscription;

  @override
  void initState() {
    super.initState();
    _teamsSubscription = ref.listenManual<AsyncValue<List<PublicTeam>>>(
      publicTeamsStreamProvider,
      (previous, next) {
        if (next.hasError) {
          _showSnackBar('팀 목록을 불러오지 못했습니다.');
        }
      },
    );
  }

  @override
  void dispose() {
    _teamsSubscription?.close();
    super.dispose();
  }

  void _showSnackBar(String message) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    });
  }

  Future<void> _handleJoin(PublicTeam team) async {
    final firebaseReady = ref.read(firebaseReadyProvider);
    if (!firebaseReady) {
      _showSnackBar('Firebase 설정이 필요합니다.');
      return;
    }

    setState(() {
      _isSigningIn = true;
    });

    try {
      await ref.read(signInWithGoogleProvider).call();
      if (mounted) {
        _showSnackBar('구글 로그인이 완료되었습니다.');
      }
    } on AuthCanceledException {
      _showSnackBar('로그인이 취소되었습니다.');
    } catch (_) {
      _showSnackBar('로그인에 실패했습니다.');
    } finally {
      if (mounted) {
        setState(() {
          _isSigningIn = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final teamsAsync = ref.watch(publicTeamsStreamProvider);
    final firebaseReady = ref.watch(firebaseReadyProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('팀 선택'),
      ),
      body: teamsAsync.when(
        data: (teams) {
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: teams.length + (firebaseReady ? 0 : 1),
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              if (!firebaseReady && index == 0) {
                return _FirebaseNoticeCard(
                  onTap: () => _showSnackBar('Firebase 설정을 완료해 주세요.'),
                );
              }

              final teamIndex = firebaseReady ? index : index - 1;
              final team = teams[teamIndex];
              final isSelected = _selectedTeamId == team.id;

              return _TeamCard(
                team: team,
                isSelected: isSelected,
                isSigningIn: _isSigningIn && isSelected,
                onTap: () {
                  setState(() {
                    _selectedTeamId = team.id;
                  });
                },
                onJoin: isSelected && !_isSigningIn
                    ? () => _handleJoin(team)
                    : null,
              );
            },
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (_, __) => const Center(
          child: Text('팀 목록을 불러오는 중 문제가 발생했습니다.'),
        ),
      ),
    );
  }
}

class _FirebaseNoticeCard extends StatelessWidget {
  const _FirebaseNoticeCard({
    required this.onTap,
  });

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      color: colorScheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: colorScheme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Firebase 설정이 아직 완료되지 않았습니다. '
                  '설정 후 구글 로그인을 사용할 수 있어요.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TeamCard extends StatelessWidget {
  const _TeamCard({
    required this.team,
    required this.isSelected,
    required this.isSigningIn,
    required this.onTap,
    required this.onJoin,
  });

  final PublicTeam team;
  final bool isSelected;
  final bool isSigningIn;
  final VoidCallback onTap;
  final VoidCallback? onJoin;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? colorScheme.primary : Colors.transparent,
          width: 1.5,
        ),
      ),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: colorScheme.primaryContainer,
                    child: Text(
                      team.name.isNotEmpty ? team.name.substring(0, 1) : '팀',
                      style: TextStyle(color: colorScheme.onPrimaryContainer),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      team.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  Chip(
                    label: Text(team.region),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                team.intro,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: onJoin,
                  child: isSigningIn
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('참여하기'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
