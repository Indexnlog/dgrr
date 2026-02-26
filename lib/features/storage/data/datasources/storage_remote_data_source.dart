import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';

/// Firebase Storage 이미지 업로드 데이터소스
/// 경로 규칙: teams/{teamId}/... (팀 단위 격리)
class StorageRemoteDataSource {
  StorageRemoteDataSource({FirebaseStorage? storage})
      : _storage = storage ?? FirebaseStorage.instance;

  final FirebaseStorage _storage;

  Reference _ref(String path) => _storage.ref(path);

  /// 이미지 업로드 후 다운로드 URL 반환
  /// [path] 예: teams/{teamId}/members/{memberId}/profile.jpg
  Future<String> uploadImage({
    required String path,
    required Uint8List bytes,
    String? contentType,
  }) async {
    final ref = _ref(path);
    final metadata = SettableMetadata(contentType: contentType ?? 'image/jpeg');
    await ref.putData(bytes, metadata);
    return ref.getDownloadURL();
  }

  /// 파일 삭제
  Future<void> delete(String path) async {
    await _ref(path).delete();
  }

  /// 다운로드 URL 조회 (이미 업로드된 파일)
  Future<String> getDownloadUrl(String path) async {
    return _ref(path).getDownloadURL();
  }
}
