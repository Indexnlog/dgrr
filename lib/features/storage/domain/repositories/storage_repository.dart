import 'dart:typed_data';

/// 이미지 저장소 인터페이스
abstract class StorageRepository {
  /// 이미지 업로드 후 다운로드 URL 반환
  Future<String> uploadImage({
    required String path,
    required Uint8List bytes,
    String? contentType,
  });

  /// 파일 삭제
  Future<void> delete(String path);
}
