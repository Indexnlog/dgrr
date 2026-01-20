import '../../domain/entities/public_team.dart';
import '../../domain/repositories/teams_public_repository.dart';
import '../datasources/teams_public_remote_data_source.dart';

class TeamsPublicRepositoryImpl implements TeamsPublicRepository {
  TeamsPublicRepositoryImpl(this.remoteDataSource);

  final TeamsPublicRemoteDataSource remoteDataSource;

  @override
  Stream<List<PublicTeam>> watchTeams() {
    return remoteDataSource.watchTeams().map((teams) {
      if (teams.isEmpty) {
        return _mockTeams;
      }
      return teams;
    });
  }
}

class TeamsPublicMockRepository implements TeamsPublicRepository {
  @override
  Stream<List<PublicTeam>> watchTeams() {
    return Stream.value(_mockTeams);
  }
}

const List<PublicTeam> _mockTeams = [
  PublicTeam(
    id: 'mock-1',
    name: '영원FC',
    logoUrl: '',
    region: '서울',
    intro: '함께 성장하는 풋살 팀입니다.',
  ),
  PublicTeam(
    id: 'mock-2',
    name: '드리블러즈',
    logoUrl: '',
    region: '경기',
    intro: '실전 중심 트레이닝을 즐깁니다.',
  ),
  PublicTeam(
    id: 'mock-3',
    name: '골게터스',
    logoUrl: '',
    region: '인천',
    intro: '즐겁고 건강한 풋살을 지향합니다.',
  ),
];
