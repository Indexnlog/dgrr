import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/storage_remote_data_source.dart';
import '../../data/repositories/storage_repository_impl.dart';
import '../../domain/repositories/storage_repository.dart';
import '../../domain/usecases/upload_image.dart';

final storageDataSourceProvider = Provider<StorageRemoteDataSource>((ref) {
  return StorageRemoteDataSource();
});

final storageRepositoryProvider = Provider<StorageRepository>((ref) {
  final dataSource = ref.watch(storageDataSourceProvider);
  return StorageRepositoryImpl(dataSource);
});

final uploadImageProvider = Provider<UploadImage>((ref) {
  final repo = ref.watch(storageRepositoryProvider);
  return UploadImage(repo);
});
