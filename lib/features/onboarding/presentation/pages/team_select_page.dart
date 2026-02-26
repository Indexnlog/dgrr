import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/providers/firebase_ready_provider.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../auth/presentation/providers/auth_state_provider.dart';
import '../../../teams/presentation/providers/current_team_provider.dart';
import '../../../teams/presentation/providers/team_providers.dart';
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

  /// 에뮬레이터 전용: 익명 로그인 + 샘플 데이터 시딩 + 팀 자동 참여
  Future<void> _handleDebugLogin() async {
    if (!kDebugMode) return;

    setState(() => _isSigningIn = true);

    try {
      final credential = await ref.read(signInAnonymouslyProvider)();
      final uid = credential.user!.uid;
      print('[Debug] 익명 로그인 성공: $uid');

      final firestore = FirebaseFirestore.instance;

      // 샘플 팀 시딩 (항상 최신 데이터로 갱신)
      const teamId = 'youngwon_fc';
      await _seedTestData(firestore, teamId);
      print('[Debug] 샘플 데이터 시딩 완료');

      // 멤버십 생성 (active로 바로 진입)
      await firestore
          .collection('teams')
          .doc(teamId)
          .collection('members')
          .doc(uid)
          .set({
        'memberId': uid,
        'name': '테스트 유저',
        'uniformName': 'TEST',
        'number': 99,
        'role': '운영진',
        'status': 'active',
        'joinedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await ref.read(currentTeamIdProvider.notifier).selectTeam(teamId);
      _showSnackBar('테스트 로그인 완료! 홈으로 이동합니다.');
    } catch (e) {
      print('[Debug] 테스트 로그인 실패: $e');
      _showSnackBar('테스트 로그인 실패: $e');
    } finally {
      if (mounted) setState(() => _isSigningIn = false);
    }
  }

  /// 에뮬레이터용 샘플 데이터 시딩
  Future<void> _seedTestData(FirebaseFirestore firestore, String teamId) async {
    // teams_public (공개 팀 인덱스)
    await firestore.collection('teams_public').doc(teamId).set({
      'name': '영원FC',
      'region': '서울 금천구',
      'intro': '매주 일요일 풋살을 즐기는 팀입니다.',
      'isOpenJoin': true,
      'memberCount': 18,
      'logoUrl': null,
    });

    // teams (코어)
    await firestore.collection('teams').doc(teamId).set({
      'name': '영원FC',
      'createdAt': FieldValue.serverTimestamp(),
    });

    // 샘플 멤버 데이터
    final membersRef = firestore.collection('teams').doc(teamId).collection('members');
    final sampleMembers = [
      {'id': 'member_01', 'name': '김영원', 'uniformName': '영원', 'number': 10, 'role': '운영진'},
      {'id': 'member_02', 'name': '박상하', 'uniformName': '상하', 'number': 7, 'role': '일반'},
      {'id': 'member_03', 'name': '이지우', 'uniformName': '지우', 'number': 11, 'role': '총무'},
      {'id': 'member_04', 'name': '정가연', 'uniformName': '가연', 'number': 5, 'role': '일반'},
      {'id': 'member_05', 'name': '최선주', 'uniformName': '선주', 'number': 9, 'role': '일반'},
    ];
    for (final m in sampleMembers) {
      await membersRef.doc(m['id'] as String).set({
        'memberId': m['id'],
        'name': m['name'],
        'uniformName': m['uniformName'],
        'number': m['number'],
        'role': m['role'],
        'status': 'active',
        'joinedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }

    // 샘플 매치 (미래의 2, 4주차 일요일)
    final futureSundays = _nextTwoSundays();
    for (final date in futureSundays) {
      final matchId = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      await firestore
          .collection('teams')
          .doc(teamId)
          .collection('matches')
          .doc(matchId)
          .set({
        'date': Timestamp.fromDate(date),
        'startTime': '18:00',
        'endTime': '20:00',
        'location': '금천구 풋살장 1-2',
        'type': 'match',
        'matchType': 'regular',
        'status': 'pending',
        'minPlayers': 7,
        'isTimeConfirmed': true,
        'attendees': <String>[],
        'absentees': <String>[],
        'opponent': {'name': null, 'contact': null, 'status': 'seeking'},
        'createdBy': 'system',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  /// 오늘 이후 가장 가까운 2주차, 4주차 일요일 2개 반환
  List<DateTime> _nextTwoSundays() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final results = <DateTime>[];

    // 이번 달과 다음 달을 탐색해서 미래의 2, 4주차 일요일을 찾는다
    for (int offset = 0; offset <= 2 && results.length < 2; offset++) {
      final month = DateTime(now.year, now.month + offset, 1);
      var firstSunday = month;
      while (firstSunday.weekday != DateTime.sunday) {
        firstSunday = firstSunday.add(const Duration(days: 1));
      }
      final week2 = firstSunday.add(const Duration(days: 7));
      final week4 = firstSunday.add(const Duration(days: 21));

      if (week2.isAfter(today) || week2.isAtSameMomentAs(today)) {
        results.add(week2);
      }
      if (results.length < 2 && (week4.isAfter(today) || week4.isAtSameMomentAs(today))) {
        results.add(week4);
      }
    }
    return results;
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
      // 1. 구글 로그인
      await ref.read(signInWithGoogleProvider).call();
      
      // 2. 로그인 성공 후 팀 가입 신청
      final user = ref.read(currentUserProvider);
      if (user != null && mounted) {
        // 멤버 신청 생성 (status: 'pending')
        await ref.read(requestJoinTeamProvider).call(
              teamId: team.id,
              userId: user.uid,
            );
        
        // 현재 팀 선택 (로컬 저장)
        await ref.read(currentTeamIdProvider.notifier).selectTeam(team.id);
        
        _showSnackBar('${team.name}에 참여 신청이 완료되었습니다.');
      }
    } on AuthCanceledException {
      _showSnackBar('로그인이 취소되었습니다.');
    } catch (e, stackTrace) {
      // 에러 메시지를 자세히 표시
      print('=== 로그인 에러 상세 ===');
      print('에러 타입: ${e.runtimeType}');
      print('에러 메시지: $e');
      print('스택 트레이스: $stackTrace');
      print('==================');
      
      // 사용자에게 더 명확한 메시지 표시
      String errorMessage = '로그인에 실패했습니다.';
      if (e.toString().contains('network')) {
        errorMessage = '네트워크 연결을 확인해주세요.';
      } else if (e.toString().contains('sign_in_failed')) {
        errorMessage = '구글 로그인 설정을 확인해주세요.';
      } else if (e.toString().contains('platform')) {
        errorMessage = '플랫폼 설정 오류입니다.';
      } else {
        errorMessage = '로그인 실패: ${e.toString().split(':').last.trim()}';
      }
      
      _showSnackBar(errorMessage);
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
        actions: [
          if (kDebugMode)
            TextButton.icon(
              onPressed: _isSigningIn ? null : _handleDebugLogin,
              icon: const Icon(Icons.bug_report, size: 18),
              label: const Text('테스트 로그인'),
            ),
        ],
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
