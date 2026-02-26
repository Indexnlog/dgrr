import 'dart:typed_data';

import '../repositories/storage_repository.dart';

/// 이미지 업로드 UseCase
/// 팀 단위 경로로 업로드 (teams/{teamId}/...)
class UploadImage {
  UploadImage(this._repository);

  final StorageRepository _repository;

  /// 멤버 프로필 사진 업로드
  /// 반환: 다운로드 URL
  Future<String> memberProfile({
    required String teamId,
    required String memberId,
    required Uint8List bytes,
  }) =>
      _repository.uploadImage(
        path: 'teams/$teamId/members/$memberId/profile.jpg',
        bytes: bytes,
      );

  /// 팀 로고 업로드
  Future<String> teamLogo({
    required String teamId,
    required Uint8List bytes,
  }) =>
      _repository.uploadImage(
        path: 'teams/$teamId/logo.jpg',
        bytes: bytes,
      );

  /// 경기 미디어 업로드 (사진/영상)
  Future<String> matchMedia({
    required String teamId,
    required String matchId,
    required String filename,
    required Uint8List bytes,
    String? contentType,
  }) =>
      _repository.uploadImage(
        path: 'teams/$teamId/matches/$matchId/$filename',
        bytes: bytes,
        contentType: contentType,
      );
}
