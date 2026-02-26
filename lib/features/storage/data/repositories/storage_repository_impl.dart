import '../../domain/repositories/storage_repository.dart';
import '../datasources/storage_remote_data_source.dart';

class StorageRepositoryImpl implements StorageRepository {
  StorageRepositoryImpl(this._dataSource);

  final StorageRemoteDataSource _dataSource;

  @override
  Future<String> uploadImage({
    required String path,
    required Uint8List bytes,
    String? contentType,
  }) =>
      _dataSource.uploadImage(
        path: path,
        bytes: bytes,
        contentType: contentType,
      );

  @override
  Future<void> delete(String path) => _dataSource.delete(path);
}
