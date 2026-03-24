import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/providers/firebase_ready_provider.dart';
import '../../../../core/utils/navigate_admin_stub.dart'
    if (dart.library.html) '../../../../core/utils/navigate_admin_web.dart' as nav_admin;
import '../../../../core/theme/app_theme.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../auth/presentation/providers/auth_state_provider.dart';
import '../../../teams/presentation/providers/current_team_provider.dart';
import '../../../teams/presentation/providers/team_providers.dart';
import '../../../../admin/admin_config.dart';
import '../../domain/entities/public_team.dart';
import '../providers/public_teams_provider.dart';

/// 일단 우리팀(영원FC)만 노출 (다른 팀은 허위 데이터)
const _ourTeamId = 'youngwon_fc';

class TeamSelectPage extends ConsumerStatefulWidget {
  const TeamSelectPage({super.key});

  @override
  ConsumerState<TeamSelectPage> createState() => _TeamSelectPageState();
}

class _TeamSelectPageState extends ConsumerState<TeamSelectPage> {
  String? _selectedTeamId;
  bool _isSigningIn = false;
  final _searchController = TextEditingController();
  String _searchQuery = '';
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
    _searchController.dispose();
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
      debugPrint('[Debug] 익명 로그인 성공: $uid');

      final firestore = FirebaseFirestore.instance;

      // 샘플 팀 시딩 (항상 최신 데이터로 갱신)
      const teamId = 'youngwon_fc';
      await _seedTestData(firestore, teamId);
      debugPrint('[Debug] 샘플 데이터 시딩 완료');

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
      debugPrint('[Debug] 테스트 로그인 실패: $e');
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
      debugPrint('=== 로그인 에러 상세 ===');
      debugPrint('에러 타입: ${e.runtimeType}');
      debugPrint('에러 메시지: $e');
      debugPrint('스택 트레이스: $stackTrace');
      debugPrint('==================');
      
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

  Future<void> _handleEnterTeam(PublicTeam team) async {
    await ref.read(currentTeamIdProvider.notifier).selectTeam(team.id);
    if (mounted) {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final teamsAsync = ref.watch(publicTeamsStreamProvider);
    final userTeamsAsync = ref.watch(userTeamsAsPublicProvider);
    final firebaseReady = ref.watch(firebaseReadyProvider);
    final currentUser = ref.watch(currentUserProvider);
    final canOpenAdmin =
        kIsWeb &&
        currentUser?.email != null &&
        adminAllowedEmails.contains(currentUser!.email);

    return Scaffold(
      backgroundColor: AppTheme.bgDeep,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          '팀 선택',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: () => context.push('/welcome'),
            icon: Icon(Icons.menu_book, size: 18, color: Colors.white.withValues(alpha: 0.9)),
            label: Text(
              '영원FC 안내',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 13),
            ),
          ),
          if (canOpenAdmin)
            IconButton(
              onPressed: () => nav_admin.navigateToAdmin(),
              icon: Icon(Icons.admin_panel_settings, size: 20, color: Colors.white.withValues(alpha: 0.9)),
              tooltip: '어드민 (팀 등록·가입 승인)',
              style: IconButton.styleFrom(foregroundColor: Colors.white),
            ),
          if (kDebugMode && kIsWeb)
            TextButton.icon(
              onPressed: _isSigningIn ? null : _handleDebugLogin,
              icon: Icon(Icons.bug_report, size: 18, color: Colors.white.withValues(alpha: 0.9)),
              label: Text(
                '테스트 로그인',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 13),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          if (canOpenAdmin)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Material(
                color: AppTheme.primaryBlue.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
                child: InkWell(
                  onTap: () => nav_admin.navigateToAdmin(),
                  borderRadius: BorderRadius.circular(10),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        Icon(Icons.admin_panel_settings, size: 20, color: AppTheme.primaryBlue),
                        const SizedBox(width: 10),
                        Text(
                          '운영진 어드민 접속',
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _searchQuery = v.trim().toLowerCase()),
              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
              decoration: InputDecoration(
                hintText: '팀명, 지역으로 검색',
                hintStyle: TextStyle(color: AppTheme.textMuted, fontSize: 14),
                prefixIcon: Icon(Icons.search, color: AppTheme.textMuted, size: 20),
                filled: true,
                fillColor: AppTheme.bgCard,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                isDense: true,
              ),
            ),
          ),
          Expanded(
            child: CustomScrollView(
              slivers: [
                if (!firebaseReady)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      child: _FirebaseNoticeCard(
                        onTap: () => _showSnackBar('Firebase 설정을 완료해 주세요.'),
                      ),
                    ),
                  ),
                userTeamsAsync.when(
                  data: (myTeams) {
                    final ourTeams = myTeams.where((t) => t.id == _ourTeamId).toList();
                    if (ourTeams.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());
                    return SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          Text(
                            '내가 속한 팀',
                            style: const TextStyle(
                              color: AppTheme.primaryBlue,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ...ourTeams.map((team) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _TeamCard(
                                  team: team,
                                  isSelected: _selectedTeamId == team.id,
                                  isSigningIn: false,
                                  onTap: () => setState(() => _selectedTeamId = team.id),
                                  onEnter: () => _handleEnterTeam(team),
                                ),
                              )),
                          const SizedBox(height: 16),
                        ]),
                      ),
                    );
                  },
                  loading: () => const SliverToBoxAdapter(child: SizedBox.shrink()),
                  error: (_, __) => const SliverToBoxAdapter(child: SizedBox.shrink()),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                    child: Text(
                      '참여 가능한 팀',
                      style: const TextStyle(
                        color: AppTheme.primaryBlue,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                teamsAsync.when(
                  data: (teams) {
                    // 일단 우리팀만 노출
                    final ourTeamList = teams.where((t) => t.id == _ourTeamId).toList();
                    final filtered = _searchQuery.isEmpty
                        ? ourTeamList
                        : ourTeamList.where((t) =>
                            t.name.toLowerCase().contains(_searchQuery) ||
                            t.region.toLowerCase().contains(_searchQuery) ||
                            t.intro.toLowerCase().contains(_searchQuery)).toList();
                    return SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final team = filtered[index];
                          final isSelected = _selectedTeamId == team.id;
                          return Padding(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                            child: _TeamCard(
                              team: team,
                              isSelected: isSelected,
                              isSigningIn: _isSigningIn && isSelected,
                              onTap: () => setState(() => _selectedTeamId = team.id),
                              onJoin: isSelected && !_isSigningIn
                                  ? () => _handleJoin(team)
                                  : null,
                            ),
                          );
                        },
                        childCount: filtered.length,
                      ),
                    );
                  },
                  loading: () => const SliverFillRemaining(
                    child: Center(
                      child: CircularProgressIndicator(color: AppTheme.primaryBlue, strokeWidth: 2.5),
                    ),
                  ),
                  error: (_, __) => const SliverFillRemaining(
                    child: Center(
                      child: Text(
                        '팀 목록을 불러오는 중 문제가 발생했습니다.',
                        style: TextStyle(color: AppTheme.textSecondary),
                      ),
                    ),
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

class _FirebaseNoticeCard extends StatelessWidget {
  const _FirebaseNoticeCard({
    required this.onTap,
  });

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.fixedBlue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.fixedBlue.withValues(alpha: 0.3)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Row(
          children: [
            Icon(Icons.info_outline, color: AppTheme.fixedBlue, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Firebase 설정이 아직 완료되지 않았습니다. '
                '설정 후 구글 로그인을 사용할 수 있어요.',
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TeamLogo extends StatelessWidget {
  const _TeamLogo({required this.team});
  final PublicTeam team;

  @override
  Widget build(BuildContext context) {
    final hasRemoteLogo = team.logoUrl.isNotEmpty;
    final useAssetLogo = !hasRemoteLogo && team.id == _ourTeamId;
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: !hasRemoteLogo && !useAssetLogo
            ? AppTheme.primaryBlue.withValues(alpha: 0.15)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: hasRemoteLogo
          ? CachedNetworkImage(
              imageUrl: team.logoUrl,
              fit: BoxFit.cover,
              errorWidget: (_, __, ___) => _buildFallback(),
            )
              : useAssetLogo
              ? Padding(
                  padding: const EdgeInsets.all(6),
                  child: Image.asset(
                    'assets/images/logo_frfc.png',
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => _buildFallback(),
                  ),
                )
              : _buildFallback(),
    );
  }

  Widget _buildFallback() {
    return Center(
      child: Text(
        team.name.isNotEmpty ? team.name.substring(0, 1) : '팀',
        style: const TextStyle(
          color: AppTheme.primaryBlue,
          fontSize: 20,
          fontWeight: FontWeight.w800,
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
    this.onJoin,
    this.onEnter,
  });

  final PublicTeam team;
  final bool isSelected;
  final bool isSigningIn;
  final VoidCallback onTap;
  final VoidCallback? onJoin;
  final VoidCallback? onEnter;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? AppTheme.primaryBlue : AppTheme.divider,
          width: isSelected ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _TeamLogo(team: team),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        team.name,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        team.region,
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  team.intro,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 14,
                  ),
                ),
                if (onEnter != null || onJoin != null) ...[
                  const SizedBox(height: 14),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton(
                      onPressed: onEnter ?? (isSigningIn ? null : onJoin),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.accentGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: isSigningIn && onJoin != null
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(onEnter != null ? '들어가기' : '참여하기'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
